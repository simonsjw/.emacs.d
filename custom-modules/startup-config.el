;;; startup-config.el --- Emacs configuration -*- mode: emacs-lisp; lexical-binding: t; -*-

;;; License
;; Copyright (C) 2025
;; SPDX-License-Identifier: MIT

;; Author: Simon Watson

;;; Commentary:

;; Configuration for speedbar, a file-tree (and more), that comes builtin to
;; Emacs it also has integration with some packages like Rmail.

;;; Code:

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
(declare-function my-tab-line/close-specific-buffer "tabline-support")

(defvar my-paths/default-config-file)
(defvar my-paths/default-log-file)


(defun my-ui/create-project-frame (project-path)
  "Create a new frame with a UI-TYPE of IDE.
The frame has a current working directory PROJECT-PATH."
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
          (message "IDE frame already exists; focusing it.")
          existing-ide-frame)
      
      (let* ((frame-class 'IDE)
             (frame (make-frame `((UI-TYPE . ,frame-class)
                                  (width . 300) (height . 75)
                                  (bottom-divider-width . 5)
                                  (right-divider-width . 5)
                                  (visibility . nil)  ; Make the new frame invisible.
                                  (no-focus-on-map . t)
                                  (inhibit-switch-frame . t)
                                  (custom-window-management . t)))))
        (log/debug :fn 'my-ui/create-project-frame
                   :msg "Created new frame"
                   :obj (list :frame frame :params (frame-parameters frame)))
        
        ;; Load the IDE layout from file
        (let ((ide-file
               (expand-file-name "IDE.el" my-paths/desktop-layout-folder)))
          (if (file-readable-p ide-file)
              (setq my-window-state/ide
                    (with-temp-buffer
                      (insert-file-contents ide-file)
                      (read (current-buffer))))
            (error "IDE.el not found or unreadable: %s" ide-file)))
        (message "IDE layout loaded from IDE.el")

        (let ((old-frame (selected-frame))
              (old-buffer (current-buffer)))
          (unwind-protect
              (with-selected-frame frame
                ;; Temporarily allow same-window displays (confined to this invisible frame)
                (my-window-tools/with-temporary-display-buffer-settings
                 '((display-buffer-alist (".*" . (display-buffer-same-window)))
                   (switch-to-buffer-obey-display-actions . nil)
                   (pop-up-windows . nil)
                   (pop-up-frames . nil))
                 (lambda ()
                   (message "Starting buffer creation in new frame...")
                   (dashboard-open)
                   (message "Opened dashboard")
                   (cell-sheet-create "20" "20")
                   (message "Opened cell-sheet")
                   (with-current-buffer (get-buffer-create "*Ibuffer*")
                     (unless (eq major-mode 'ibuffer-mode)
                       (ibuffer-mode))
                     (ibuffer-update nil t)
                     (goto-char (point-min)))
                   (message "Opened Ibuffer")
                   (find-file-noselect my-paths/default-log-file)
                   (log/display-load-history)
                   (message "Opened load history & log file.")
                   (vc-dir project-path)
                   (vc-dir-hide-up-to-date)
                   (message "Opened vc-dir")
                   (scratch-buffer)
                   (message "Opened scratch-buffer")
                   (vterm nil)
                   (message "Opened vterm")
                   (dired project-path)
                   (message "Opened dired")
                   (dolist (req-buf '("*Emacs*" "*cell sheet*" "*Ibuffer*" "init.log" "*vc-dir*" "*scratch*"))
                     (unless (get-buffer req-buf)
                       (message "Warning: Required buffer %s not created!" req-buf)))
                   (message "Buffer creation complete")))

                (condition-case err
                    (progn
                      (window-state-put my-window-state/ide (frame-root-window frame))
                      (let ((tag-list (list 'edit 'data 'config 'logs 'vc 'terminal)))
                        (my-window-tools/tag-windows-by-list frame tag-list))
                      (message "Window layout applied to new frame"))
                  (error (message "Layout apply error: %s | Check missing buffers?" err)))

                (setq frame-title-format
                      '((:eval (concat "IDE: " (buffer-name)))))
                (global-tab-line-mode))

            (when (frame-live-p old-frame)
              (select-frame old-frame 'norecord))
            (when (buffer-live-p old-buffer)
              (set-buffer old-buffer))))

        (make-frame-visible frame)
        (message "Created %s frame with layout applied!" frame-class)
        frame))))




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

(provide 'startup-config)
;;; startup-config.el ends here
