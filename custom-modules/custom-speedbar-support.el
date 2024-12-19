;;; custom-speedbar-support.el --- Speedbar configuration -*- mode: emacs-lisp; mode: outline-minor; lexical-binding: t; -*-

;;; License
;; Copyright (C) 2022
;; SPDX-License-Identifier: MIT

;; Author: Simon Watson

;;; Commentary:

;; This file was made with outline-minor-mode in mind
;; and therefore have ";;;+"-comments as headders.

;; Configuration for speedbar, a file-tree (and more), that comes
;; builtin to Emacs it also has integration with some packages like
;; Rmail and projectile

(defvar speedbar-mode-map)
(defvar speedbar-indentation-width)
(defvar speedbar-update-flag)
(defvar speedbar-show-unknown-files)
(defvar speedbar-smart-directory-expand-flag)
(defvar speedbar-directory-unshown-regexp)
(defvar speedbar-file-unshown-regexp)
(defvar speedbar-directory-arguments)
(defvar speedbar-add-supported-extension)
(defvar my-speedbar/speedbar-filter-state nil
  "Holds the current state of the filter in speedbar.")

(defvar sr-speedbar-auto-refresh)
(defvar sr-speedbar-max-width)
(defvar sr-speedbar-width)
(defvar sr-speedbar-right-side)

(defvar info-theme-dark-blue)
(defvar info-theme-light-grey)
(defvar info-theme-white-grey)
(defvar info-theme-blue-steel)
(defvar info-theme-light-white)
(defvar info-theme-white-grey)
(defvar info-theme-magenta)
(defvar info-theme-dark-red)

(defvar pretty-speedbar-font)
(defvar pretty-speedbar-icons-dir)                                                ; Icon location storage folder.
(defvar pretty-speedbar-icon-size)
(defvar pretty-speedbar-icon-fill)                                                ; Fill color for all non-folder icons.
(defvar pretty-speedbar-icon-stroke)                                              ; Stroke color for all non-folder icons.
(defvar pretty-speedbar-icon-folder-fill)                                         ; Fill color for all folder icons.
(defvar pretty-speedbar-icon-folder-stroke)                                       ; Stroke color for all folder icons.
(defvar pretty-speedbar-about-fill)                                               ; Fill color for all icons placed to the right of the file name, including checks and locks.
(defvar pretty-speedbar-about-stroke)                                             ; Stroke color for all icons placed to the right of the file name, including checks and locks.
(defvar pretty-speedbar-signs-fill)                                               ; Fill color for plus and minus signs used on non-folder icons.

;; test
(defvar projectile-speedbar-enable)

(declare-function projectile-project-p "projectile")
(declare-function projectile-project-root "projectile")
(declare-function speedbar-refresh "speedbar")
(declare-function speedbar-change-initial-expansion-list "speedbar")
(declare-function speedbar-add-supported-extension "speedbar")


;;; Code:

(use-package sr-speedbar)
(use-package projectile-speedbar)
(use-package pretty-speedbar)

;;; Customise Speedbar
(custom-set-variables
 '(speedbar-use-images t)                                                         ; Use icon images. (not needed with pretty-speedbar)
 '(speedbar-directory-button-trim-method 'trim)
 '(speedbar-update-flag t)                                                        ; Auto-update when the attached frame changes directory
 '(projectile-speedbar-enable t)
 '(sr-speedbar-auto-refresh t)
 '(speedbar-indentation-width 3)                                                  ; Increase the indentation for better useability.
 '(pretty-speedbar-icon-size 20)                                                  ; Icon height in pixels.
 '(setq speedbar-vc-do-check t)                                                   ; Disable check-marks if nil. 
 '(speedbar-show-unknown-files t)
 '(speedbar-smart-directory-expand-flag t)
 '(speedbar-directory-button-trim-method 'trim)
 '(sr-speedbar-max-width 170)
 '(sr-speedbar-width 40)
 '(sr-speedbar-right-side nil)
 '(speedbar-directory-unshown-regexp "^\\(CVS\\|RCS\\|SCCS\\|\\.\\.*$\\)\\'")
 ;;'(speedbar-hide-button-brackets-flag t)                                          ; this stops icons being shown.
 
 ;; '(speedbar-frame-parameters                                                     ; set speedbar frame parameters (overwritten if sr-speedbar is used). 
 ;;   '((name . "*SPEEDBAR*")
 ;;     (title . "*SPEEDBAR*")
 ;;     (minibuffer . nil)
 ;;     (border-width . 10)
 ;;     (width . 40)
 ;;     (menu-bar-lines . 0)
 ;;     (tool-bar-lines . 0)
 ;;     (unsplittable . t)
 ;;     (left-fringe . 10)))
 
;;; Customize text color (need to run `pretty-speedbar-generate' on change)
 '(pretty-speedbar-font "Symbols Nerd Font Mono")
 '(pretty-speedbar-folder '("\uf07b" t))                                          ;  Closed folder icon.
 '(pretty-speedbar-folder-open '("\uf07c" t))                                     ;  Open folder icon.
 '(pretty-speedbar-blank-page '("\uf15b"))                                        ;  Used for plus and minus file icons.
 '(pretty-speedbar-page  '("\uf15c"))                                             ;  Default file icon. 
 '(pretty-speedbar-box-closed  '("\uebb4"))                                       ;  Closed box icon with plus added during generation.
 '(pretty-speedbar-box-open  '("\uebb5" ))                                        ;  Open box icon with minus added during generation. 
 '(pretty-speedbar-book '("\uf02d"))                                              ;  Book icon used for documentation available. 
 '(pretty-speedbar-mail '("\uf0e0"))                                              ;  Envelope icon.
 '(pretty-speedbar-info '("\uf05a"))                                              ;  Info icon.
 '(pretty-speedbar-tags '("\uf02c"))                                              ;  Tags icon used for plus and minus tags generation. 
 '(pretty-speedbar-tag '("\uf02b"))                                               ;  Single tag icon. Most frequent tag icon.
 '(speedbar-add-supported-extension
   '(
   ;;;; General Lisp Languages
     ".cl" ".li?sp"
   ;;;; Lua/Fennel (Lisp that transpiles to lua)
     ".lua" ".fnl" ".fennel"
   ;;;; JVM languages (Java, Kotlin, Clojure)
     ".kt" ".mvn" ".gradle" ".properties" ".cljs?"
   ;;;; shellscript
     ".sh" ".bash"
   ;;;; Web Languages and Markup/Styling
     ".php" ".ts" ".html?" ".css" ".less" ".scss" ".sass"
   ;;;; Data languages
     ".py" ".p" ".q" ".k"
   ;;;; Rust
     ".rs" ".lock"
   ;;;; Makefile
     "makefile" "MAKEFILE" "Makefile"
   ;;;; Data formats
     ".json" ".yaml" ".toml"
;;;; Notes and Markup
     ".md" ".markdown" ".org" ".txt" "README")))

;; set base colour scheme for pretty-speedbar. 
`(setq pretty-speedbar-icon-fill ,info-theme-light-white)                         ; Fill color for all non-folder icons. white: #FFFFFF
`(setq pretty-speedbar-icon-stroke ,info-theme-dark-red)                          ; Stroke color for all non-folder icons. light grey: #DCDCDC
`(setq pretty-speedbar-icon-folder-fill ,info-theme-dark-red)                     ; Fill color for all folder icons: purple (fuchia?): #D9B3FF
`(setq pretty-speedbar-icon-folder-stroke ,info-theme-dark-red)                   ; Stroke color for all folder icons: deep magenta: #CC00CC
`(setq pretty-speedbar-about-fill ,info-theme-dark-red)                           ; Fill color for all icons placed to the right of the file name, including checks and locks.lighter gray: EFEFEF
`(setq pretty-speedbar-about-stroke ,info-theme-light-white)                      ; Stroke color for all icons placed to the right of the file name, including checks and locks.
`(setq pretty-speedbar-signs-fill ,info-theme-light-white)                        ; Fill color for plus and minus signs used on non-folder icons. darkblue/magenta: #594968


(custom-set-faces
 `(speedbar-button-face ((t (:foreground ,info-theme-white-grey))))
 `(speedbar-directory-face ((t (:foreground ,info-theme-white-grey))))
 `(speedbar-file-face ((t (:foreground ,info-theme-white-grey))))
 '(speedbar-selected-face ((t (:foreground "gray98" :underline nil))))
 `(speedbar-highlight-face ((t (:inherit 'popup-menu-selection-face))))
 `(speedbar-tag-face ((t (:inherit 'font-lock-variable-name-face))))
 `(speedbar-separator-face ((t (:inherit 'org-level-2
                                         :forground  ,info-theme-white-grey
                                         :background ,info-theme-dark-blue)))))


;; This function overrides the original speedbar function so that
;; the correct speedbar width is reported when speedbar is not the only
;; window in a frame. 
(defun speedbar-frame-width ()
  "Return the width of the sr-speedbar window, or a default value."
  (if (and (boundp 'sr-speedbar-window) sr-speedbar-window)
      (window-width sr-speedbar-window) ;; Use sr-speedbar window width
    30)) ;; Fallback default width

(defun my-speedbar/show-relative-path ()
  "This function displays the relative path from the project root.

If no project root is found fallback to `parent/current-directory'."
  (let* (
         (current-dir default-directory)

         (project-root
          (if (projectile-project-p) (projectile-project-root) nil))
         
         (relative-path
          (if project-root
              (file-relative-name current-dir project-root)
            (concat
             (file-name-nondirectory
              (directory-file-name
               (file-name-directory current-dir)))
             "/" (file-name-nondirectory current-dir))))
         )
    
    (with-current-buffer (get-buffer "*SPEEDBAR*")
      (let ((inhibit-read-only t))
        (goto-char (point-min))
        (insert (format "Path: %s\n" relative-path))))))


;; (add-hook 'speedbar-mode-hook 'my-speedbar-display-parent-directory)

(setq my-speedbar/speedbar-filter-state t)

(defun my-speedbar/toggle-filter ()
  "Toggle the visibility of dotfiles in speedbar."
  (interactive)
  (if my-speedbar/speedbar-filter-state
      (setq my-speedbar/speedbar-filter-state nil)
    (setq my-speedbar/speedbar-filter-state t))
  ;; Check if the current regexp hides dot files
  (if my-speedbar/speedbar-filter-state
      ;; If dot files are hidden, modify regexp to show them
      (progn
        ;; Hide dot files, directories beginning with "_", and specific VCS directories
        ;; but always show the `..' file.
        (setq speedbar-directory-unshown-regexp "^\\(\\.[^/.].*\\|_[^/]*\\|CVS\\|RCS\\|SCCS\\)$")

        ;; (setq speedbar-directory-unshown-regexp "^\\(\\.[^/.][^/]*\\|_[^/]*\\|CVS\\|RCS\\|SCCS\\)$")

        ;;  (setq speedbar-directory-unshown-regexp "^\\(\\.[^/]*\\|_[^/]*\\|CVS\\|RCS\\|SCCS\\)$")
        (setq speedbar-file-unshown-regexp "^\\(\\.[^/]*\\|CVS\\|RCS\\|SCCS\\)$"))
    ;; If dot files are shown, modify regexp to hide them
    (progn
      ;; the dot here is the folder denoting the current folder.
      ;; (just gives a recursive tree)
      (setq speedbar-directory-unshown-regexp "^\\.$")
      (setq speedbar-file-unshown-regexp "^$")))
  ;; Refresh speedbar to apply changes
  (speedbar-refresh))


(add-hook 'speedbar-mode-hook
          (lambda ()
            ;;   (visual-line-mode 0) ; Disable word wrapping in speedbar if you always enable it globally.
            ;;  (setq-local truncate-lines t)                                     ; Ensure lines do not wrap
            
            ;; Change speedbar's text size.  May need to alter the icon size if you change size.
            (text-scale-adjust -0.25)

            ;; Adjust horizontal scrolling behaviour

            (setq-local auto-hscroll-mode 'current-line) ; Horizontal scroll on the current line
            (setq-local hscroll-margin 0) ; No margin for horizontal scrolling

            ;; Bind the toggle function to the '.' key in speedbar mode
            (define-key speedbar-mode-map "." 'my-speedbar/toggle-filter)))


;; get the name of the available views from
;; speedbar-initial-expansion-mode-alist
(defun my-speedbar/switch-speedbar-view (speedbar-view)
  "Temporarily switch to quick-buffers expansion list.
Useful for quickly switching to an open buffer.
Current view is given in SPEEDBAR-VIEW."
  (interactive)
  (speedbar-change-initial-expansion-list speedbar-view))

;; set up key-bindings for `quick-buffers' and `info' (files is already f)
(keymap-set
 speedbar-mode-map
 "b" #'(lambda () (interactive)
         (my-speedbar/switch-speedbar-view "quick buffers")))

(keymap-set
 speedbar-mode-map
 "i" #'(lambda () (interactive)
         (my-speedbar/switch-speedbar-view  "Info")))

(provide 'custom-speedbar-support)
;;; custom-speedbar-support.el ends here

                                                                                  ; LocalWords:  FFFFFF shellscript fnl sp Makefile
