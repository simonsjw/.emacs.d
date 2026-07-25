;;; startup-config.el --- Emacs configuration -*- mode: emacs-lisp; lexical-binding: t; -*-

;;; License
;; Copyright (C) 2025
;; SPDX-License-Identifier: MIT

;; Author: Simon Watson

;;; Commentary:

;; Configuration for speedbar, a file-tree (and more), that comes builtin to
;; Emacs it also has integration with some packages like Rmail.

;;; Code:



(require 'path-support)
(require 'logging-config)
(log/debug :fn 'startup-config
           :msg "Starting load of the startup-config module."
           :obj t)


;; Imports
(require 'summary-support)
(require 'system-window-management)
(require 'ui-config)
(require 'system-tools)

(declare-function speedbar "speedbar")

(declare-function sr-speedbar-exist-p "sr-speedbar")
(declare-function sr-speedbar-close "sr-speedbar")

(declare-function sr-speedbar-select-window "sr-speedbar")
(declare-function sr-speedbar-open "sr-speedbar")
(declare-function sr-speedbar "sr-speedbar")

(declare-function vterm "vterm")
(declare-function dired "dired")
(declare-function cell-sheet-create "cell-mode")
(declare-function my-startup-screen/startup-screen "custom-summary-config")

(defvar my-paths/default-config-file)
(defvar my-paths/default-log-file)
(defvar my-paths/spreadsheet-dir)

;;; ----------------------------------------------------------------------
;;; Robust IDE frame creation (handles uniquify + residual buffers)
;;; ----------------------------------------------------------------------
(defun my-ui--ensure-layout-buffers ()
  "Make sure the six buffers named in IDE_TEMPLATE.eld exist with exact names."
  (my-ui--force-buffer-name (or (get-buffer "*Emacs*") (get-buffer "*GNU Emacs*"))
                            "*Emacs*")
  (my-ui--force-buffer-name (or (get-buffer "xAI Chat")
                                (progn (my-llm/new-chat) (current-buffer)))
                            "xAI Chat")
  (my-ui--force-buffer-name (get-buffer-create "*Ibuffer*") "*Ibuffer*")
  (my-ui--force-buffer-name (get-buffer-create "*Warnings*") "*Warnings*")
  (my-ui--ensure-clean-vc-dir default-directory)
  (my-ui--force-buffer-name (or (get-buffer "*scratch*") (scratch-buffer))
                            "*scratch*"))

(defun my-ui--force-buffer-name (buffer desired-name)
  "Rename BUFFER to DESIRED-NAME if it is live and different.
Kills any pre-existing buffer of the desired name first.
Returns the buffer that now has the desired name, or nil."
  (when (and buffer (buffer-live-p buffer))
    (let ((existing (get-buffer desired-name)))
      (when (and existing (not (eq existing buffer)))
        (let ((kill-buffer-query-functions nil)
              (kill-buffer-hook nil))
          (kill-buffer existing))))
    (with-current-buffer buffer
      (unless (string= (buffer-name) desired-name)
        (rename-buffer desired-name t)))
    (get-buffer desired-name)))

(defun my-ui--create-and-force (creator-fn desired-name &optional setup-fn)
  "Call CREATOR-FN, then force the resulting buffer to DESIRED-NAME.
If CREATOR-FN does not produce a new buffer, create one explicitly
and optionally run SETUP-FN in it.
Returns the live buffer with the desired name."
  (let ((before (current-buffer)))
    (funcall creator-fn)
    (let ((after (current-buffer)))
      (cond
       ;; Creator switched to a different live buffer – rename it
       ((and (not (eq after before)) (buffer-live-p after))
        (my-ui--force-buffer-name after desired-name))
       ;; Creator did nothing useful – create explicitly
       (t
        (let ((buf (get-buffer-create desired-name)))
          (with-current-buffer buf
            (when setup-fn (funcall setup-fn)))
          (my-ui--force-buffer-name buf desired-name)
          buf))))))

(defun my-ui--neutralize-git-processes ()
  "Prevent any pending or running git processes from selecting deleted buffers.
This is the only reliable way to stop the classic
\"Selecting deleted buffer\" error that appears when a vc-dir
status process outlives its buffer."
  (dolist (proc (process-list))
    (when (string-match-p "\\`git" (process-name proc))
      (set-process-sentinel proc #'ignore)
      (when (process-live-p proc)
        (ignore-errors (delete-process proc))))))

(defun my-ui--ensure-clean-vc-dir (dir)
  "Ensure a *vc-dir* buffer for DIR exists under the exact name \"*vc-dir*\".

- Neutralises every git process first (stops residual callbacks).
- Reuses an existing buffer for the same directory when possible.
- Only kills *vc-dir* buffers that belong to a different directory.
- Forces the exact name the IDE template expects.

Returns the live *vc-dir* buffer."
  (setq dir (file-name-as-directory (expand-file-name dir)))

  ;; 1. Stop every git process that could still fire a callback
  (my-ui--neutralize-git-processes)

  ;; 2. Kill only *vc-dir* buffers that are NOT for this directory
  (dolist (buf (buffer-list))
    (when (and (buffer-live-p buf)
               (string-match-p "^\\*vc-dir" (buffer-name buf)))
      (with-current-buffer buf
        (let ((buf-dir (and (local-variable-p 'default-directory)
                            (file-name-as-directory
                             (expand-file-name default-directory)))))
          (unless (and buf-dir (string= buf-dir dir))
            ;; Different directory – safe to destroy
            (when (fboundp 'vc-dir-kill-dir-status-process)
              (ignore-errors (vc-dir-kill-dir-status-process)))
            (when-let ((proc (get-buffer-process buf)))
              (set-process-sentinel proc #'ignore)
              (ignore-errors (delete-process proc)))
            (when (and (boundp 'vc-dir-process-buffer)
                       (buffer-live-p vc-dir-process-buffer))
              (when-let ((p (get-buffer-process vc-dir-process-buffer)))
                (set-process-sentinel p #'ignore)
                (ignore-errors (delete-process p)))
              (let ((kill-buffer-query-functions nil)
                    (kill-buffer-hook nil))
                (kill-buffer vc-dir-process-buffer)))
            (let ((kill-buffer-query-functions nil)
                  (kill-buffer-hook nil))
              (kill-buffer buf)))))))

  ;; 3. Let vc-dir reuse (or create) a buffer for this directory
  (vc-dir dir)
  (vc-dir-hide-up-to-date)

  ;; 4. Force the exact name the template hard-codes
  (my-ui--force-buffer-name (current-buffer) "*vc-dir*")

  ;; 5. Keep the global list tidy
  (when (boundp 'vc-dir-buffers)
    (setq vc-dir-buffers
          (cl-delete-if-not #'buffer-live-p vc-dir-buffers))
    (cl-pushnew (get-buffer "*vc-dir*") vc-dir-buffers :test #'eq))

  (get-buffer "*vc-dir*"))



(defun my-ui/create-project-frame (project-path)
  "Create a new frame with a UI-TYPE of IDE.
The frame has a current working directory PROJECT-PATH.

This version is robust against uniquify and residual buffers left
behind when an IDE frame is closed without restarting the Emacs
server.  All buffer names that appear in IDE_TEMPLATE.eld are
forced to their exact expected strings before the window state is
restored."
  (interactive)
  (cd project-path)
  (setq default-directory project-path)
  (message "Project path set to: %s" project-path)

  (let ((existing-ide-frame
         (seq-find (lambda (f) (eq (frame-parameter f 'UI-TYPE) 'IDE))
                   (frame-list))))
    (if existing-ide-frame
        (progn
          (unless (frame-parameter existing-ide-frame 'custom-window-management)
            (set-frame-parameter existing-ide-frame 'custom-window-management t)
            (log/debug :fn 'my-ui/create-project-frame
                       :msg "Tagged existing IDE frame"
                       :obj (list :frame existing-ide-frame)))
          (select-frame-set-input-focus existing-ide-frame)
          (log/debug :fn 'my-ui/create-project-frame
                     :msg "IDE frame already exists; focusing it."
                     :obj nil)
          existing-ide-frame)

      ;; === Create a brand-new IDE frame ===
      (let* ((frame-class 'IDE)
             (frame (make-frame `((UI-TYPE . ,frame-class)
                                  (width . 300)
                                  (height . 75)
                                  (no-focus-on-map . t)
                                  (custom-window-management . t)))))

        (log/debug :fn 'my-ui/create-project-frame
                   :msg "Created new frame"
                   :obj (list :frame frame :params (frame-parameters frame)))

        ;; Initialise any frame-specific state *after* the frame exists
        (set-frame-parameter frame 'my-window-tools/in-ediff-session nil)

        (let ((old-frame (selected-frame))
              (old-buffer (current-buffer)))
          (unwind-protect
              (with-selected-frame frame
                ;; Temporarily force same-window behaviour while we build the layout
                (my-window-tools/with-temporary-display-buffer-settings
                 '((display-buffer-alist (".*" . (display-buffer-same-window)))
                   (switch-to-buffer-obey-display-actions . nil)
                   (pop-up-windows . nil)
                   (pop-up-frames . nil))
                 (lambda ()
                   (log/debug :fn 'my-ui/create-project-frame
                              :msg "Starting buffer creation in new frame..."
                              :obj nil)

                   ;; ---- 1. Create / force the exact names the template expects ----

                   ;; *Emacs* (dashboard)
                   (my-ui--create-and-force #'dashboard-open "*Emacs*")

                   ;; xAI Chat – must be a *new* buffer
                   (my-ui--create-and-force #'my-llm/new-chat "xAI Chat"
                                            (lambda ()
                                              ;; optional: any extra setup the chat needs
                                              ))

                   ;; *Ibuffer*
                   (my-ui--create-and-force
                    (lambda ()
                      (ibuffer)
                      (ibuffer-update nil t)
                      (goto-char (point-min)))
                    "*Ibuffer*")

                   ;; *Warnings* (template expects this name)
                   (my-ui--create-and-force
                    (lambda () (get-buffer-create "*Warnings*"))
                    "*Warnings*")

                   ;; keep *Messages* alive for logging
                   (view-echo-area-messages)

                   ;; *vc-dir* (already hardened)
                   (my-ui--ensure-clean-vc-dir project-path)

                   ;; *scratch*
                   (my-ui--create-and-force #'scratch-buffer "*scratch*")

                   ;; Background buffers that only appear in prev-buffers
                   (find-file "spreadsheet.ses")
                   (vterm nil)
                   (dired project-path)

                   ;; ---- 2. Verify the exact set the template needs ----
                   (let ((required '("*Emacs*" "xAI Chat" "*Ibuffer*"
                                     "*Warnings*" "*vc-dir*" "*scratch*")))
                     (dolist (name required)
                       (unless (get-buffer name)
                         (log/warn :fn 'my-ui/create-project-frame
                                   :msg "Required buffer still missing after force-rename!"
                                   :obj (list :buffer name)))))
                   (log/info :fn 'my-ui/create-project-frame
                             :msg "Buffer creation + name forcing complete"
                             :obj nil)))

                ;; ---- 3. Apply the saved window layout ----
                (condition-case err
                    (progn
                      ;; Re-guarantee the exact names the template expects
                      (my-ui--ensure-layout-buffers)

                      (let ((ide-file
                             (expand-file-name "IDE_TEMPLATE.eld"
                                               my-paths/desktop-layout-folder)))
                        (when (file-readable-p ide-file)
                          (setq my-window-state/ide
                                (with-temp-buffer
                                  (insert-file-contents ide-file)
                                  (read (current-buffer))))))

                      (window-state-put my-window-state/ide
                                        (frame-root-window frame))

                      ;; Tag first so we can address windows by category
                      (let ((tag-list (cdr (assoc :IDE my-window-tools/category-map))))
                        (my-window-tools/tag-windows-by-list frame tag-list t))

                      ;; Explicitly put the right buffers into the data & config windows
                      ;; (protects against any collapse that occurred during the put)
                      (when-let ((data-win (my-window-tools/get-window-for-window-category 'data frame)))
                        (set-window-buffer data-win (get-buffer "xAI Chat")))
                      (when-let ((config-win (my-window-tools/get-window-for-window-category 'config frame)))
                        (set-window-buffer config-win (get-buffer "*Ibuffer*")))

                      (log/info :fn 'my-ui/create-project-frame
                                :msg "Window layout applied to new frame."
                                :obj nil)

                      ;; Visual polish
                      (my-visual/apply-all-customisations)

                      (setq frame-title-format
                            '((:eval
                               (if (eq (frame-parameter nil 'UI-TYPE) 'IDE)
                                   (concat "IDE: " (buffer-name))
                                 "%b"))))
                      (global-tab-line-mode))
                  (error
                   (log/error :fn 'my-ui/create-project-frame
                              :msg "Layout apply error | Check missing buffers?"
                              :obj err)))
                )

            ;; Restore previous frame/buffer
            (when (frame-live-p old-frame)
              (select-frame old-frame 'norecord))
            (when (buffer-live-p old-buffer)
              (set-buffer old-buffer)))

          (make-frame-visible frame)
          (log/info :fn 'my-ui/create-project-frame
                    :msg "Created frame with layout applied!"
                    :obj frame-class)
          frame)))))

(defun my-ui/startup-layout()
  "Reset the Emacs session to the default window layout.

The default windows will be created and the default buffers assigned to them.
 If those buffers are not present, they will be opened.  No buffers should be
closed as a result of this action."
  (interactive)
  (my-ui/create-project-frame user-emacs-directory))

(defalias 'IDE-refresh 'my-ui/startup-layout
  "Alias for `my-ui/startup-layout' to refresh the Emacs session layout.")

;; Use the function on startup
;;(add-hook 'emacs-startup-hook 'my-ui/startup-layout)

;; ensure that all frames unique to a frame are killed when
;; the frame is closed.
(add-hook 'delete-frame-functions #'my-frame-tools/kill-buffers-on-frame-close)


;; Ensure we handle git process buffers
(defun my-ui--cleanup-vc-on-frame-delete (frame)
  "Neutralise git processes before buffers belonging to FRAME are killed."
  (my-ui--neutralize-git-processes))

(add-hook 'delete-frame-functions #'my-ui--cleanup-vc-on-frame-delete)


(log/debug :fn 'startup-config
           :msg "Finishing load of the startup-config module."
           :obj t)


(provide 'startup-config)
;;; startup-config.el ends here
