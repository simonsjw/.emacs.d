;;; custom-startup-config.el --- Emacs configuration -*- mode: emacs-lisp; mode: outline-minor; lexical-binding: t; -*-

;;; License
;; Copyright (C) 2022
;; SPDX-License-Identifier: MIT

;; Author: Erik Lundstedt, System Crafters Community

;;; Commentary:

;; This file was made with outline-minor-mode in mind
;; and therefore have ";;;+"-comments as headers.

;; Configuration for speedbar, a file-tree (and more), that comes
;; builtin to Emacs it also has integration with some packages like
;; Rmail and projectile

;;; Code:

;; Imports
(require 'custom-summary-config)
(require 'custom-logging-config)
(require 'custom-system-window-management)
(require 'custom-ui-config)
(require 'custom-system-tools)

(defvar magit-display-buffer-function)
(defvar magit-display-buffer-noselect)

(declare-function speedbar "speedbar")

(declare-function sr-speedbar-exist-p "sr-speedbar")
(declare-function sr-speedbar-close "sr-speedbar")

(declare-function sr-speedbar-select-window "sr-speedbar")
(declare-function sr-speedbar-open "sr-speedbar")
(declare-function sr-speedbar "sr-speedbar")

(declare-function projectile "projectile")
(declare-function projectile-speedbar "projectile-speedbar")

(declare-function magit "magit")
(declare-function magit-status-setup-buffer "magit")

(declare-function bufler "bufler")
(declare-function vterm "vterm")
(declare-function dired "dired")
(declare-function cell-sheet-create "cell-mode")


(defun my-ui/create-project-frame (given-project-path)
  "Set up the window layout and names for a project.
The window names are based on the frame.
If no directory path is given, use Dired to navigate to one.

GIVEN-PROJECT-PATH is the path to the project folder for which an ide will be
created."

  ;; (setq given-project-path user-emacs-directory)
  ;; (setq project-path

  ;;       (my-strings/ensure-directory-path    ; ensure the path ends in a '/'
  ;;        (if
  ;;            (and
  ;;             given-project-path
  ;;             (not (string= given-project-path "")))
  ;;            given-project-path
  ;;          (my-interactive-tools/select-directory-using-dired))))
  ;; (setq magit-display-buffer-function #'my-window-tools/magit-display-buffer)
  ;; (setq new-frame
  ;;       (make-frame
  ;;        `((name . ,(file-name-nondirectory
  ;;                    (directory-file-name project-path))))))



  ;; Prompt user to select directory
  (interactive "DSelect project directory: ")
  ;; (setq debug-on-error t)

  ;; This `let' uses dired to help the user navigate to a directory
  (let
      ((project-path
        (my-strings/ensure-directory-path    ; ensure the path ends in a '/'
         (if
             (and
              given-project-path
              (not (string= given-project-path "")))
             given-project-path
           (my-interactive-tools/select-directory-using-dired))))
       ;; setting the below variable means that when we do (magit-status),
       ;; magit will use my-window-tools/magit-display-buffer to find the
       ;; appropriate window and show the buffer there.
       (magit-display-buffer-function #'my-window-tools/magit-display-buffer)
       )

    ;; If speedbar is open, close it.
    (when
        (sr-speedbar-exist-p)
      (sr-speedbar-close))

    ;; set global variables
    (defconst ide-init/default-config-file
      (expand-file-name "conf.org" user-emacs-directory)
      "Path to the literate config file.")
    (defconst ide-init/default-log-file
      (expand-file-name "init.log" user-emacs-directory)
      "Path to the init log file.")

    ;; Temporarily disable the buffer-list-update-hook
    ;; (remove-hook 'buffer-list-update-hook
    ;;             'my-window-tools/assign-buffer-to-window-hook)

    ;; Here we create a new frame and name it.
    (let
        ((new-frame
          (make-frame
           `((name . ,(file-name-nondirectory
                       (directory-file-name project-path)))))))

      ;; (when
      ;;   (not (string= (projectile-project-name) ".emacs.d"))
      ;;   (projectile-switch-project project-path))

      (with-selected-frame new-frame
        (let* (
               (frame-name (frame-parameter nil 'name))
               (top-left  (selected-window))
               (bottom-left
                (split-window-below
                 (floor (* 3.0 (/ (frame-height) 4.0)))))
               (top-right-sub-upper
                (split-window-right
                 (floor (* 2 (/ (frame-width) 3.0)))))
               (top-right-sub-lower
                (progn
                  (select-window top-right-sub-upper)
                  (split-window-vertically)))
               (bottom-middle
                (progn
                  (select-window bottom-left)
                  (split-window-right (floor (/ (frame-width) 3.0)))))
               (bottom-right
                (progn
                  (select-window bottom-middle)
                  (split-window-right)))
               )

          ;; set the current directory to the project root and ensure
          ;; projectile is also looking at that directory.
          (cd project-path)
          (setq default-directory project-path)

          ;; Create and assign buffers to the windows


          (progn
            (set-window-buffer bottom-left (get-buffer-create "logs"))
            (with-current-buffer "logs"
              (tab-line-mode 1)))

          (progn
            (set-window-buffer  top-right-sub-upper (get-buffer-create "data"))
            (with-current-buffer "data"
              (tab-line-mode 1)))

          (progn
            (set-window-buffer top-right-sub-lower (get-buffer-create "config"))
            (with-current-buffer "config"
              (tab-line-mode 1)))

          (progn
            (set-window-buffer bottom-middle (get-buffer-create "vc"))
            (with-current-buffer "vc"
              (tab-line-mode 1)))

          (progn
            (set-window-buffer bottom-right (get-buffer-create "terminal"))
            (with-current-buffer "terminal"
              (tab-line-mode 1)))

          ;; Speedbar (create from the edit window before creating a buffer)
          (with-selected-window top-left
            (sr-speedbar-open))

          (progn
            (set-window-buffer top-left (get-buffer-create "edit"))
            (with-current-buffer "edit"
              (tab-line-mode 1)))

          ;; Naming the windows uniquely based on frame

          (let ((speedbar-win (sr-speedbar-select-window)))
            (set-window-parameter
             speedbar-win 'name (concat frame-name "-[speedbar]"))
            ;; (set-window-parameter speedbar-win  'tag 'speedbar)
            ;;  (my-window-tools/add-window speedbar-win 'speedbar)
            ;; (my-os-tools/set-sr-speedbar-directory-to-file-path project-path)
            )

          (set-window-parameter
           top-left 'name (concat frame-name "-top-middle-[edit]"))
          ;; Assigning the 'edit tag to the window and adding it to the
          ;; my-window-tools/buffer-window-map hash table.
          (set-window-parameter top-left 'tag 'edit)
          (my-window-tools/add-window top-left 'edit)

          (set-window-parameter
           top-right-sub-upper
           'name (concat frame-name "-top-right-upper-[data]"))
          ;; Assigning the 'data tag to the window and adding it to the
          ;; my-window-tools/buffer-window-map hash table.
          (set-window-parameter top-right-sub-upper 'tag 'data)
          (my-window-tools/add-window top-right-sub-upper 'data)

          (set-window-parameter
           top-right-sub-lower
           'name (concat frame-name "-top-right-lower-[config]"))
          ;; Assigning the 'config tag to the window and adding it to the
          ;; my-window-tools/buffer-window-map hash table.
          (set-window-parameter top-right-sub-lower 'tag 'config)
          (my-window-tools/add-window top-right-sub-lower 'config)

          (set-window-parameter
           bottom-left
           'name (concat frame-name "-bottom-left-[logs]"))
          ;; Assigning the 'logs tag to the window and adding it to the
          ;; my-window-tools/buffer-window-map hash table.
          (set-window-parameter bottom-left 'tag 'logs)
          (my-window-tools/add-window bottom-left 'logs)

          (set-window-parameter
           bottom-middle
           'name (concat frame-name "-bottom-middle-[vc]"))
          ;; Assigning the 'vc tag to the window and adding it to the
          ;; my-window-tools/buffer-window-map hash table.
          (set-window-parameter bottom-middle 'tag 'vc)
          (my-window-tools/add-window bottom-middle 'vc)

          (set-window-parameter
           bottom-right
           'name (concat frame-name "-bottom-right-[terminal]"))
          ;; Assigning the 'terminal tag to the window and adding it to the
          ;; my-window-tools/buffer-window-map hash table.
          (set-window-parameter bottom-right 'tag 'terminal)
          (my-window-tools/add-window bottom-right 'terminal)

          ;; Side windows: top right upper
          (with-selected-window top-right-sub-upper
            (cell-sheet-create "20" "20")
            (my-tab-line/close-specific-buffer "*scratch*"))

          ;; Side windows: top right lower
          (with-selected-window top-right-sub-lower
            (find-file ide-init/default-config-file)
            (ibuffer)
            (my-tab-line/close-specific-buffer "*scratch*"))

          ;; Bottom windows: bottom middle
          (with-selected-window bottom-middle
            (let ((default-directory project-path)
                  (magit-display-buffer-noselect t))
              (magit-status-setup-buffer))
            (my-tab-line/close-specific-buffer "*scratch*"))

          ;; Bottom windows: bottom right
          ;; do this last so any windows containing only scratch buffers
          ;; don't get deleted before they are populated.
          (with-selected-window bottom-right
            (projectile-dired)
            (scratch-buffer)
            (eshell)
            (vterm))

          ;; Bottom windows: bottom left
          (with-selected-window bottom-left
            (find-file ide-init/default-log-file)
            (view-echo-area-messages)
            (my-tab-line/close-specific-buffer "*scratch*"))

          ;;  (with-selected-window top-left
          ;;   (my-os-tools/set-sr-speedbar-directory-to-file-path project-path)
          ;;    (message "speedbar directory set at %s" project-path))

          ;;(select-window top-left)

          ;; Main window
          (with-selected-window top-left
            (crafted-startup-screen)
            (my-tab-line/close-specific-buffer "*scratch*")
            )
          )
        )
      ;; clean up the start-up frame.
      ;; (let ((startup-frame (my-frame-tools/get-frame-by-name "startup")))
      ;; (if startup-frame (delete-frame startup-frame))
      ;;  )
      )
    )
  )

(defun my-ui/startup-layout()
  "Reset the Emacs session to the default window layout.

The default windows will be created and the default buffers assigned to them.
 If those buffers are not present, they will be opened.  No buffers should be
closed as a result of this action."
  (interactive)
  (my-frame-tools/set-current-frame-name "startup")
  (my-ui/create-project-frame user-emacs-directory)
  ;; With windows and tags now set, enable the buffer-window
  ;; relationships for new buffers specified in
  ;; custom-system-window-management.el
  ;; (add-hook 'buffer-list-update-hook
  ;;           #'my-window-tools/detect-new-non-system-buffer)
  )

;; Use the function on startup
(add-hook 'emacs-startup-hook 'my-ui/startup-layout)


(provide 'custom-startup-config)
;;; custom-startup-config.el ends here


                                                                                  ; LocalWords:  speedbar dired
                                                                                  ; LocalWords:  magit bufler
                                                                                  ; LocalWords:  sr vc

