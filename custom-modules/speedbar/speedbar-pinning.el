;;; speedbar-pinning.el --- Project-root pinning for Speedbar / sr-speedbar (file view only) -*- lexical-binding: t; -*-

;; Copyright (C) 2026 Simon Watson
;; SPDX-License-Identifier: MIT

;; Author: Simon Watson

;;; Commentary:
;; Project-root pinning system tightly bound to file view mode only.
;;
;; State is stored as frame parameters so that multiple IDE frames can
;; have independent pinning, current-file and tree-root values.
;; The Speedbar buffer content itself remains shared (as in the original
;; design); only the control decisions are per-frame.
;;
;; Strong IDE-frame + file-view guards are retained.
;;
;; 2026-08-23: Hardened against the classic dframe "dead frame" error
;; (wrong-type-argument frame-live-p #<dead frame IDE: …>).
;; See my-speedbar--safe-attached-frame and the tightened
;; my-speedbar--in-ide-frame-p.

;;; Code:

(require 'speedbar)
(require 'dframe)
(require 'logging-config)

;;;;; Frame-parameter accessors

(defun my-speedbar--get-pin-project-root (&optional frame)
  "Return the pin-project-root flag for FRAME (default: selected frame)."
  (frame-parameter (or frame (selected-frame)) 'my-speedbar-pin-project-root))

(defun my-speedbar--set-pin-project-root (value &optional frame)
  "Set the pin-project-root flag for FRAME to VALUE.
Returns VALUE."
  (set-frame-parameter (or frame (selected-frame)) 'my-speedbar-pin-project-root value)
  value)

(defun my-speedbar--get-current-file (&optional frame)
  "Return the current-file value for FRAME (default: selected frame)."
  (frame-parameter (or frame (selected-frame)) 'my-speedbar-current-file))

(defun my-speedbar--set-current-file (value &optional frame)
  "Set the current-file value for FRAME to VALUE.
Returns VALUE."
  (set-frame-parameter (or frame (selected-frame)) 'my-speedbar-current-file value)
  value)

(defun my-speedbar--get-file-tree-root (&optional frame)
  "Return the file-tree-root value for FRAME (default: selected frame)."
  (frame-parameter (or frame (selected-frame)) 'my-speedbar-file-tree-root))

(defun my-speedbar--set-file-tree-root (value &optional frame)
  "Set the file-tree-root value for FRAME to VALUE.
Returns VALUE."
  (set-frame-parameter (or frame (selected-frame)) 'my-speedbar-file-tree-root value)
  value)

;;;;; Internal one-shot flags (remain global — they are transient)

(defvar my-speedbar--ignore-next-buffer-change nil
  "Internal one-shot flag used to ignore the immediate buffer change after kill/bury.")

(defvar my-speedbar--divert-message-shown nil
  "Internal flag to avoid repeating pinned-mode messages.")

;;;;; Safe frame helpers (new – protect against dead-frame errors)

(defun my-speedbar--safe-attached-frame ()
  "Return the frame that dframe/speedbar considers attached, but only if it is live.
Never returns a dead frame object.  This is the primary defence against
the error:

  (wrong-type-argument frame-live-p #<dead frame IDE: …>)

which originates in `dframe-select-attached-frame' /
`speedbar-reconfigure-keymaps'."
  (let ((f (ignore-errors
             (or (and (fboundp 'dframe-attached-frame)
                      (dframe-attached-frame))
                 (and (boundp 'speedbar-frame) speedbar-frame)
                 (and (boundp 'sr-speedbar-frame) sr-speedbar-frame)))))
    (and f (frame-live-p f) f)))

(defun my-speedbar--speedbar-context-live-p ()
  "Return non-nil when it is safe to call speedbar update / keymap functions.
Requires both a live attached frame (if any) *and* a live speedbar buffer."
  (let ((sb-buf (or (and (boundp 'speedbar-buffer) speedbar-buffer)
                    (get-buffer "*speedbar*")
                    (and (boundp 'sr-speedbar-buffer) sr-speedbar-buffer))))
    (and (or (null (my-speedbar--safe-attached-frame)) ; no attached frame is fine for sr-speedbar
             (my-speedbar--safe-attached-frame))
         sb-buf
         (buffer-live-p sb-buf))))

;;;;; Helpers

(defun my-speedbar--in-ide-frame-p ()
  "Return non-nil if the *selected* frame is a live IDE frame (or dedicated Speedbar).

Requires the selected frame itself to be live.  The previous version could
return non-nil after the IDE frame had been deleted (via the
`sr-speedbar-window' fallback), which allowed advice to run and then hit
a dead frame inside dframe."
  (let* ((frame (selected-frame))
         (name  (and (frame-live-p frame) (frame-parameter frame 'name)))
         (ui-type (and (frame-live-p frame) (frame-parameter frame 'UI-TYPE))))
    (and (frame-live-p frame)
         (or (eq ui-type 'IDE)
             (and (stringp name) (string-prefix-p "IDE:" name))
             ;; Accept the dedicated speedbar frame only when it is the
             ;; currently selected (and live) frame.
             (and (boundp 'speedbar-frame)
                  (eq frame speedbar-frame)
                  (frame-live-p speedbar-frame))
             ;; Weaker signal: sr-speedbar window exists *and* the current
             ;; frame still looks like an IDE frame.
             (and (boundp 'sr-speedbar-window)
                  sr-speedbar-window
                  (or (eq ui-type 'IDE)
                      (and (stringp name) (string-prefix-p "IDE:" name))))))))

(defun my-speedbar--in-file-view-p ()
  "Return non-nil if Speedbar is currently in file view mode."
  (and (boundp 'speedbar-initial-expansion-list-name)
       (string-equal speedbar-initial-expansion-list-name "files")))

(defun my-speedbar--special-buffer-p (BUF)
  "Return non-nil if BUF should never affect the pinned Speedbar view."
  (let ((name (buffer-name BUF)))
    (or (null (buffer-file-name BUF))
        (string-match-p "^\\*\\(Messages\\|Warnings\\|scratch\\|Ibuffer\\|Help\\)" name)
        (string-prefix-p " " name)
        (eq BUF (get-buffer "*speedbar*"))
        (and (boundp 'sr-speedbar-buffer) (eq BUF sr-speedbar-buffer)))))

(defun my-speedbar/find-project-root (FILE)
  "Return the project root directory for FILE (or its own directory as fallback)."
  (let* ((dir (file-name-directory (expand-file-name FILE)))
         (root nil))
    (when (fboundp 'project-current)
      (let ((proj (condition-case nil
                      (project-current nil dir)
                    (wrong-number-of-arguments
                     (condition-case nil
                         (let ((default-directory dir))
                           (project-current nil))
                       (error nil)))
                    (error nil))))
        (when proj
          (setq root (condition-case nil
                         (if (fboundp 'project-root)
                             (project-root proj)
                           (if (consp proj) (cdr proj) proj))
                       (error nil))))))
    (unless root
      (when (fboundp 'vc-root-dir)
        (setq root (condition-case nil
                       (let ((default-directory dir))
                         (vc-root-dir))
                     (error nil)))))
    (or root dir)))

(defun my-speedbar/expand-to-file (FILE)
  "Expand ancestors and highlight FILE. Safe for new files."
  (let* ((root (expand-file-name default-directory))
         (file-dir (file-name-directory (expand-file-name FILE)))
         (rel (file-relative-name file-dir root))
         (ancestors (if (or (string= rel ".") (string= rel "")) '()
                      (split-string rel "/" t))))
    (dolist (anc ancestors)
      (setq root (expand-file-name anc root))
      (condition-case nil
          (save-excursion
            (when (speedbar-directory-line root)
              (speedbar-expand-line)))
        (error nil))))
  (when (fboundp 'speedbar-find-selected-file)
    (speedbar-with-writable
      (condition-case nil
          (when (speedbar-find-selected-file FILE)
            (put-text-property (match-beginning 1) (match-end 1)
                               'face 'speedbar-selected-face))
        (error nil))))
  (setq speedbar-last-selected-file FILE))

(defun my-speedbar/apply-pinning-for-file (FILE)
  "Apply project pinning for FILE on the selected frame.
When pinning is active, switch Speedbar to the project root of FILE
(if different) and expand to the file.

Hardened: never calls `speedbar-update-contents' unless the speedbar
context (attached frame + buffer) is still live."
  (when (and (my-speedbar--get-pin-project-root)
             (my-speedbar--in-file-view-p)
             (my-speedbar--in-ide-frame-p)
             FILE
             (not (my-speedbar--special-buffer-p (current-buffer))))
    (my-speedbar--set-current-file (expand-file-name FILE))
    (let* ((project-root (my-speedbar/find-project-root FILE))
           (sb-buf (or (and (boundp 'speedbar-buffer) speedbar-buffer)
                       (get-buffer "*speedbar*")
                       (and (boundp 'sr-speedbar-buffer) sr-speedbar-buffer))))
      (when (and sb-buf
                 (buffer-live-p sb-buf)
                 (my-speedbar--speedbar-context-live-p))   ; ← new guard
        (with-current-buffer sb-buf
          (let ((current-root (expand-file-name (or default-directory "")))
                (new-root (expand-file-name project-root)))
            (unless (string-equal current-root new-root)
              ;; Different project → switch root
              (setq default-directory (file-name-as-directory new-root))
              (my-speedbar--set-file-tree-root default-directory)
              (let ((speedbar-smart-directory-expand-flag t))
                (speedbar-update-contents)))
            ;; Always try to expand/highlight the file
            (my-speedbar/expand-to-file FILE)))))))

;;;;; Directory / File click advice

(defun my-speedbar/dir-follow-advice (orig-fun TEXT TOKEN INDENT)
  "Directory clicks still expand normally when pinning is active."
  (if (and (my-speedbar--get-pin-project-root)
           (my-speedbar--in-file-view-p)
           (my-speedbar--in-ide-frame-p))
      (progn
        (speedbar-toggle-line-expansion)
        nil)
    (funcall orig-fun TEXT TOKEN INDENT)))

(advice-add 'speedbar-dir-follow :around #'my-speedbar/dir-follow-advice)

(defun my-speedbar/find-file-advice (orig-fun TEXT TOKEN INDENT)
  "File clicks work normally and trigger pinning (IDE frame only)."
  (when (and (my-speedbar--get-pin-project-root)
             (my-speedbar--in-file-view-p)
             (my-speedbar--in-ide-frame-p))
    (let* ((line-dir (speedbar-line-directory INDENT))
           (file-path (concat line-dir TEXT)))
      (my-speedbar/apply-pinning-for-file file-path)))
  (funcall orig-fun TEXT TOKEN INDENT))

(advice-add 'speedbar-find-file :around #'my-speedbar/find-file-advice)

;;;;; External buffer changes

(defun my-speedbar/handle-buffer-change ()
  "Only acts when pinning is active and we are in an IDE frame."
  (when (and (my-speedbar--get-pin-project-root)
             (my-speedbar--in-file-view-p)
             (my-speedbar--in-ide-frame-p)
             (not my-speedbar--ignore-next-buffer-change))
    (let ((file (buffer-file-name)))
      (when (and file (not (my-speedbar--special-buffer-p (current-buffer))))
        (my-speedbar/apply-pinning-for-file file))))
  (setq my-speedbar--ignore-next-buffer-change nil))

(add-hook 'find-file-hook #'my-speedbar/handle-buffer-change)
(add-hook 'buffer-list-update-hook #'my-speedbar/handle-buffer-change)

;;;;; Kill / bury

(defun my-speedbar/kill-buffer-advice (orig-fun &rest ARGS)
  "Ignore immediate focus change when pinning is active (IDE frame only)."
  (when (and (my-speedbar--get-pin-project-root)
             (my-speedbar--in-file-view-p)
             (my-speedbar--in-ide-frame-p))
    (setq my-speedbar--ignore-next-buffer-change t))
  (apply orig-fun ARGS))

(advice-add 'kill-buffer :around #'my-speedbar/kill-buffer-advice)
(advice-add 'bury-buffer :around #'my-speedbar/kill-buffer-advice)

;;;;; Update contents protection

(defun my-speedbar/speedbar-update-contents-advice (orig-fun &rest args)
  "Protect pinning during updates, but allow project switches.

Hardened: the whole body is skipped if the attached frame or speedbar
buffer is no longer live.  This prevents the nested call into
`dframe-select-attached-frame' from seeing a dead frame object."
  (if (and (my-speedbar--get-pin-project-root)
           (my-speedbar--get-current-file)
           (my-speedbar--in-file-view-p)
           (my-speedbar--in-ide-frame-p)
           (my-speedbar--speedbar-context-live-p))          ; ← new guard
      (let ((sb-buf (or (and (boundp 'speedbar-buffer) speedbar-buffer)
                        (get-buffer "*speedbar*")
                        (and (boundp 'sr-speedbar-buffer) sr-speedbar-buffer)))
            (result nil))
        (when (and sb-buf (buffer-live-p sb-buf))
          (with-current-buffer sb-buf
            ;; Do NOT force the old root here any more.
            ;; Let apply-pinning-for-file decide based on the current file.
            (setq result (apply orig-fun args))
            ;; Re-apply pinning only if the context is still healthy
            ;; (guards inside apply-pinning-for-file also protect us).
            (when (my-speedbar--speedbar-context-live-p)
              (my-speedbar/apply-pinning-for-file (my-speedbar--get-current-file)))))
        result)
    (apply orig-fun args)))

(advice-add 'speedbar-update-contents :around #'my-speedbar/speedbar-update-contents-advice)

;;;;; Toggle command

(defun my-speedbar/toggle-pin-project-root ()
  "Toggle pinning (only effective in IDE frame / file view)."
  (interactive)
  (when (my-speedbar--in-ide-frame-p)
    (my-speedbar--set-pin-project-root (not (my-speedbar--get-pin-project-root)))
    (if (my-speedbar--get-pin-project-root)
        (progn
          (message "🔒 Project pinning ENABLED (file view only)")
          (when (and (my-speedbar--get-current-file) (my-speedbar--in-file-view-p))
            (my-speedbar/apply-pinning-for-file (my-speedbar--get-current-file))))
      (message "🔓 Project pinning DISABLED – Speedbar behaves normally"))))

;;;;; Cleanup on IDE frame deletion (new)

(defun my-speedbar--cleanup-on-frame-delete (frame)
  "Clear stale dframe/speedbar frame references when an IDE frame is deleted.
Prevents a deleted frame object from remaining in `dframe-attached-frame'
or `speedbar-frame' and later causing a wrong-type-argument error."
  (when (and (frame-parameter frame 'UI-TYPE)
             (eq (frame-parameter frame 'UI-TYPE) 'IDE))
    (when (and (boundp 'dframe-attached-frame)
               (eq dframe-attached-frame frame))
      (setq dframe-attached-frame nil))
    (when (and (boundp 'speedbar-frame)
               (eq speedbar-frame frame))
      (setq speedbar-frame nil))
    (when (and (boundp 'sr-speedbar-frame)
               (eq sr-speedbar-frame frame))
      (setq sr-speedbar-frame nil))))

(add-hook 'delete-frame-functions #'my-speedbar--cleanup-on-frame-delete)

(provide 'speedbar-pinning)
;;; speedbar-pinning.el ends here
