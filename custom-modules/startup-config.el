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

(defun my-ui--force-buffer-name (buffer desired-name)
  "Rename BUFFER to DESIRED-NAME, killing any existing buffer of that name first.
Returns the (possibly renamed) live buffer, or nil."
  (when (and buffer (buffer-live-p buffer))
    (let ((existing (get-buffer desired-name)))
      (when (and existing (not (eq existing buffer)))
        (kill-buffer existing)))
    (with-current-buffer buffer
      (rename-buffer desired-name t))          ; t = unique if somehow still conflict
    (get-buffer desired-name)))

(defun my-ui--ensure-clean-vc-dir (dir)
  "Kill every buffer whose name matches ^\\*vc-dir and create a fresh
one for DIR that is forced to the exact name \"*vc-dir*\".
Returns the live *vc-dir* buffer."
  (dolist (buf (buffer-list))
    (when (and (buffer-live-p buf)
               (string-match-p "^\\*vc-dir" (buffer-name buf)))
      (kill-buffer buf)))
  (vc-dir dir)
  (vc-dir-hide-up-to-date)
  (my-ui--force-buffer-name (current-buffer) "*vc-dir*"))

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
                   (dashboard-open)
                   (my-ui--force-buffer-name (current-buffer) "*Emacs*")

                   ;; Create the chat *before* any project file is visited
                   (my-llm/new-chat)
                   (my-ui--force-buffer-name (current-buffer) "xAI Chat")

                   (with-current-buffer (get-buffer-create "*Ibuffer*")
                     (unless (eq major-mode 'ibuffer-mode)
                       (ibuffer-mode))
                     (ibuffer-update nil t)
                     (goto-char (point-min)))
                   (my-ui--force-buffer-name (get-buffer "*Ibuffer*") "*Ibuffer*")

                   ;; Template wants *Warnings*
                   (get-buffer-create "*Warnings*")
                   (my-ui--force-buffer-name (get-buffer "*Warnings*") "*Warnings*")
                   (view-echo-area-messages)               ; keeps *Messages* alive for logs

                   ;; Critical: clean + force exact *vc-dir*
                   (my-ui--ensure-clean-vc-dir project-path)

                   (scratch-buffer)
                   (my-ui--force-buffer-name (current-buffer) "*scratch*")

                   ;; Background buffers that only appear in prev-buffers of the template
                   (find-file "spreadsheet.ses")           ; safe – chat already exists
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

                      (let ((tag-list (cdr (assoc :IDE my-window-tools/category-map))))
                        (my-window-tools/tag-windows-by-list frame tag-list t))

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
                              :obj err))))

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


(log/debug :fn 'startup-config
           :msg "Finishing load of the startup-config module."
           :obj t)


(provide 'startup-config)
;;; startup-config.el ends here
