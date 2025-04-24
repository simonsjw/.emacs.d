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


  ;; set the current directory to the project root.
  (cd project-path)
  (setq default-directory project-path)

  (let* ((frame-class 'IDE)
         (frame
          (make-frame `(
                        (UI-TYPE . ,frame-class)
                        (width . 300) (height . 75)
                        (bottom-divider-width . 5) (right-divider-width . 5)
                        ))))
    
    (with-selected-frame frame

      (setq frame-title-format
            '((:eval
               (concat "IDE:  " (buffer-name)))))
      (progn
        (get-buffer-create "sr-speedbar")
        (get-buffer-create "edit")
        (get-buffer-create "logs")
        (get-buffer-create "data")
        (get-buffer-create "config")
        (get-buffer-create "vc")
        (get-buffer-create "terminal")
        (get-buffer-create "edit")

        ;; data
        (cell-sheet-create "20" "20")

        ;; config
        (find-file my-paths/default-config-file)
        (toggle-truncate-lines 1)
        (ibuffer)
        (goto-char (point-min))

        ;; vc
        (project-vc-dir)

        ;; terminal
        (project-dired)
        (scratch-buffer)
        (vterm)

        ;; logs
        (find-file my-paths/default-log-file)
        (view-echo-area-messages)
        
        ;; edit
        (dashboard-open))

      ;; Load `IDE' window-tree from the stored file.
      (let ((ide-file (expand-file-name "IDE.el" my-paths/desktop-layout-folder)))
        
        (setq my-window-state/ide
              (with-temp-buffer
                (insert-file-contents ide-file)
                (read (current-buffer)))))
      
      (window-state-put my-window-state/ide (frame-root-window frame))
      
      ;; tag the windows in the frame.
      (let ((tag-list (list  'edit 'data 'config 'logs 'vc 'terminal)))
        (my-window-tools/tag-windows-by-list frame tag-list))
      (global-tab-line-mode)
      (message "Created %s frame!" frame-class)
      frame)))

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


                                                                                  ; LocalWords:  speedbar dired
                                                                                  ; LocalWords:  magit bufler
                                                                                  ; LocalWords:  sr vc
                                                                                  ; LocalWords:  tabline

