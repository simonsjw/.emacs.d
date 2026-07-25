;;; speedbar-pinning.el --- Project-root pinning for Speedbar / sr-speedbar (file view only) -*- lexical-binding: t; -*-

;; Copyright (C) 2026 Simon Watson
;; SPDX-License-Identifier: MIT

;; Author: Simon Watson

;;; Commentary:
;; Project-root pinning system tightly bound to file view mode only.
;; Uses ordinary variables + strong IDE-frame guards (no make-variable-frame-local).

;;; Code:

(require 'speedbar)
(require 'dframe)
(require 'logging-config)

;;;;; User Variables

(defvar my-speedbar/pin-project-root nil
  "When non-nil and Speedbar is in file view, project-root pinning mode is active.
Only the IDE frame is allowed to change or act on this variable.")

(defvar my-speedbar/current-file nil
  "The most recently selected real file path (absolute) when pinning is active.")

(defvar my-speedbar/file-tree-root nil
  "Current project root directory displayed in Speedbar when pinning is active.")

(defvar my-speedbar--ignore-next-buffer-change nil
  "Internal one-shot flag used to ignore the immediate buffer change after kill/bury.")

(defvar my-speedbar--divert-message-shown nil
  "Internal flag to avoid repeating pinned-mode messages.")

;;;;; Helpers

(defun my-speedbar--in-ide-frame-p ()
  "Return non-nil if the current frame is the IDE frame (or the dedicated Speedbar frame)."
  (let ((name (frame-parameter nil 'name))
        (ui-type (frame-parameter nil 'UI-TYPE)))
    (or (eq ui-type 'IDE)
        (string-prefix-p "IDE:" (or name ""))
        (and (boundp 'speedbar-frame) (eq (selected-frame) speedbar-frame))
        (and (boundp 'sr-speedbar-window) sr-speedbar-window))))

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
  "Apply project pinning logic for FILE (only on IDE frame)."
  (when (and my-speedbar/pin-project-root
             (my-speedbar--in-file-view-p)
             (my-speedbar--in-ide-frame-p)
             FILE
             (not (my-speedbar--special-buffer-p (current-buffer))))
    (setq my-speedbar/current-file (expand-file-name FILE))
    (let* ((project-root (my-speedbar/find-project-root FILE))
           (sb-buf (or (and (boundp 'speedbar-buffer) speedbar-buffer)
                       (get-buffer "*speedbar*"))))
      (when (and sb-buf (buffer-live-p sb-buf))
        (with-current-buffer sb-buf
          (let ((current-root (expand-file-name default-directory))
                (new-root (expand-file-name project-root)))
            (if (string-equal current-root new-root)
                (my-speedbar/expand-to-file FILE)
              (progn
                (setq default-directory (file-name-as-directory new-root))
                (let ((speedbar-smart-directory-expand-flag t))
                  (speedbar-update-contents))
                (setq my-speedbar/file-tree-root default-directory)
                (my-speedbar/expand-to-file FILE)))))))))

;;;;; Directory / File click advice

(defun my-speedbar/dir-follow-advice (orig-fun TEXT TOKEN INDENT)
  "Directory clicks still expand normally when pinning is active."
  (if (and my-speedbar/pin-project-root
           (my-speedbar--in-file-view-p)
           (my-speedbar--in-ide-frame-p))
      (progn
        (speedbar-toggle-line-expansion)
        nil)
    (funcall orig-fun TEXT TOKEN INDENT)))

(advice-add 'speedbar-dir-follow :around #'my-speedbar/dir-follow-advice)

(defun my-speedbar/find-file-advice (orig-fun TEXT TOKEN INDENT)
  "File clicks work normally and trigger pinning (IDE frame only)."
  (when (and my-speedbar/pin-project-root
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
  (when (and my-speedbar/pin-project-root
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
  (when (and my-speedbar/pin-project-root
             (my-speedbar--in-file-view-p)
             (my-speedbar--in-ide-frame-p))
    (setq my-speedbar--ignore-next-buffer-change t))
  (apply orig-fun ARGS))

(advice-add 'kill-buffer :around #'my-speedbar/kill-buffer-advice)
(advice-add 'bury-buffer :around #'my-speedbar/kill-buffer-advice)

;;;;; Update contents protection

(defun my-speedbar/speedbar-update-contents-advice (orig-fun &rest args)
  "Protect pinned state during updates (IDE frame only)."
  (if (and my-speedbar/pin-project-root
           my-speedbar/current-file
           (my-speedbar--in-file-view-p)
           (my-speedbar--in-ide-frame-p))
      (let ((sb-buf (or (and (boundp 'speedbar-buffer) speedbar-buffer)
                        (get-buffer "*speedbar*")))
            (pinned-root my-speedbar/file-tree-root)
            (result nil))
        (when (and sb-buf (buffer-live-p sb-buf))
          (with-current-buffer sb-buf
            (when pinned-root
              (setq default-directory (file-name-as-directory pinned-root)))
            (setq result (apply orig-fun args))
            (my-speedbar/apply-pinning-for-file my-speedbar/current-file)))
        result)
    (apply orig-fun args)))

(advice-add 'speedbar-update-contents :around #'my-speedbar/speedbar-update-contents-advice)

;;;;; Toggle command

(defun my-speedbar/toggle-pin-project-root ()
  "Toggle pinning (only effective in IDE frame / file view)."
  (interactive)
  (when (my-speedbar--in-ide-frame-p)
    (setq my-speedbar/pin-project-root (not my-speedbar/pin-project-root))
    (if my-speedbar/pin-project-root
        (progn
          (message "🔒 Project pinning ENABLED (file view only)")
          (when (and my-speedbar/current-file (my-speedbar--in-file-view-p))
            (my-speedbar/apply-pinning-for-file my-speedbar/current-file)))
      (message "🔓 Project pinning DISABLED – Speedbar behaves normally"))))

(provide 'speedbar-pinning)
;;; speedbar-pinning.el ends here
