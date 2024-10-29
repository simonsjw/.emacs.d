;;; custom-speedbar-support.el --- Speedbar configuration -*- mode: emacs-lisp; mode: outline-minor; lexical-binding: t; -*-

;;; License
;; Copyright (C) 2022
;; SPDX-License-Identifier: MIT

;; Author: Erik Lundstedt, System Crafters Community

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

(defvar my-speedbar/speedbar-filter-state nil
  "Holds the current state of the filter in speedbar.")

(defvar sr-speedbar-auto-refresh)  
(defvar sr-speedbar-max-width)  
(defvar sr-speedbar-width)
(defvar sr-speedbar-right-side)

(defvar info-theme-dark-blue)
(defvar info-theme-light-grey)
(defvar info-theme-white-grey)

(defvar pretty-speedbar-font)
(defvar pretty-speedbar-icons-dir)          ;; Icon location storage folder.
(defvar pretty-speedbar-icon-size)
(defvar pretty-speedbar-icon-fill)          ;; Fill color for all non-folder icons.
(defvar pretty-speedbar-icon-stroke)        ;; Stroke color for all non-folder icons.
(defvar pretty-speedbar-icon-folder-fill)   ;; Fill color for all folder icons.
(defvar pretty-speedbar-icon-folder-stroke) ;; Stroke color for all folder icons.
(defvar pretty-speedbar-about-fill)         ;; Fill color for all icons placed to the right of the file name, including checks and locks.
(defvar pretty-speedbar-about-stroke)       ;; Stroke color for all icons placed to the right of the file name, including checks and locks.
(defvar pretty-speedbar-signs-fill)         ;; Fill color for plus and minus signs used on non-folder icons.

(defvar projectile-speedbar-enable)

(declare-function speedbar-refresh speedbar)
(declare-function speedbar-change-initial-expansion-list speedbar)
(declare-function speedbar-add-supported-extension speedbar)
;;; Code:

(use-package sr-speedbar
  :straight (:type git
                   :flavor melpa
                   :host github
                   :repo "emacsorphanage/sr-speedbar"))

(use-package projectile-speedbar
  :straight (:type git
                   :flavor melpa
                   :host github
                   :repo "anshulverma/projectile-speedbar"))

;; Note:  pretty-speedbar-icons-dir has been redefined in custom-file-support
;; to point to a directory in the icon stash. 
(use-package pretty-speedbar
  :straight (:type git
                   :flavor melpa
                   :host github
                   :repo "kcyarn/pretty-speedbar"))

;;; Look & Feel

(setq pretty-speedbar-icons-dir
      (expand-file-name
       (concat user-emacs-directory "etc/images/pretty-speedbar-icons"))
      )

;; Auto-update when the attached frame changes directory
(setq speedbar-update-flag nil)
(setq projectile-speedbar-enable nil)
(setq sr-speedbar-auto-refresh t) 

;; Increase the indentation for better useability.
(setq speedbar-indentation-width 3)

;; Disable check-marks
;; (setq speedbar-vc-do-check nil)

(add-hook 'speedbar-mode-hook
          (lambda()
            ;; Disable word wrapping in speedbar if you always enable it globally.
            (visual-line-mode 0) 
            ;; Change speedbar's text size.  May need to alter the icon size if you change size.
            ;;(text-scale-adjust 1)
            ))

(setq pretty-speedbar-icon-size 14) ;; Icon height in pixels.

;; Use icon images. (not needed with pretty-speedbar)
;;(customize-set-variable 'speedbar-use-images t)

;; Customize Speedbar Frame
;; (customize-set-variable 'speedbar-frame-parameters
;;                         '((name . "speedbar")
;;                           (title . "speedbar")
;;                           ;;(minibuffer . nil)
;;                           (border-width . 10)
;;                           (width . 40)
;;                           (menu-bar-lines . 0)
;;                           (tool-bar-lines . 0)
;;                           ;;  (unsplittable . t)
;;                           (left-fringe . 10)))

;; (customize-set-variable 'speedbar-hide-button-brackets-flag t) - this stops icons being shown. 
(setq speedbar-show-unknown-files t)             
(setq speedbar-smart-directory-expand-flag t)       

(setq sr-speedbar-max-width 170)  
(setq sr-speedbar-width 40)
(setq sr-speedbar-right-side nil)

(setq speedbar-directory-unshown-regexp
      "^\\(CVS\\|RCS\\|SCCS\\|\\.\\.*$\\)\\'")

   ;;; File Extensions
(speedbar-add-supported-extension
 (list
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
  ".md" ".markdown" ".org" ".txt" "README"))

;;; Customize text color

;; (setq pretty-speedbar-font "Font Awesome 5 Free Solid")
(setq pretty-speedbar-font "Symbols Nerd Font Mono")

;; (setq pretty-speedbar-icon-fill "#FFFFFF")          ;; Fill color for all non-folder icons. white: #FFFFFF
;; (setq pretty-speedbar-icon-stroke "#DCDCDC")        ;; Stroke color for all non-folder icons. light grey: #DCDCDC
;; (setq pretty-speedbar-icon-folder-fill "#D9B3FF")   ;; Fill color for all folder icons: purple (fuchia?): D9B3FF
;; (setq pretty-speedbar-icon-folder-stroke "#CC00CC") ;; Stroke color for all folder icons: deep magenta: #CC00CC
;; (setq pretty-speedbar-about-fill "#EFEFEF")         ;; Fill color for all icons placed to the right of the file name, including checks and locks.lighter gray: EFEFEF
;; (setq pretty-speedbar-about-stroke "#DCDCDC")       ;; Stroke color for all icons placed to the right of the file name, including checks and locks.
;; (setq pretty-speedbar-signs-fill "#CC00CC")         ;; Fill color for plus and minus signs used on non-folder icons. darkblue/magenta: #594968



(custom-set-faces
 '(speedbar-button-face ((t (:foreground "#FFFFFF"))))
 `(speedbar-directory-face ((t (:foreground ,info-theme-light-grey))))
 `(speedbar-file-face ((t (:foreground ,info-theme-white-grey))))
 '(speedbar-selected-face ((t (:foreground "gray98" :underline nil))))
 )



(set-face-attribute 'speedbar-highlight-face
                    nil :inherit 'popup-menu-selection-face)

(set-face-attribute 'speedbar-tag-face
                    nil :inherit 'font-lock-variable-name-face)

;; `((bg-main ,info-theme-dark-blue)           ; primary background "#0d0e1c"
;;   (bg-dim ,info-theme-dark-grey)            ; dimmed background  "#1d2235"
;;   (fg-main ,info-theme-white-grey)          ; primary font color "#ffffff"
;;   (fg-dim ,info-theme-flat-grey)            ; dimmed font colour  "#989898"
;;   (fg-alt ,info-theme-bold-code-green)      ; alt. font colour    "#c6daff"
;;   (bg-active ,info-theme-flat-grey)         ; "#042027"
;;   (bg-inactive ,info-theme-dark-grey)       ; "#2b3045"
;;   (border ,info-theme-white-grey)           ; "#61647a")


;;; Keybindings

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
            ;; Disable word wrapping in speedbar if you always enable it globally.
            (visual-line-mode 0)

            ;; Adjust horizontal scrolling behavior
            (setq-local truncate-lines t) ; Ensure lines do not wrap
            (setq-local auto-hscroll-mode 'current-line) ; Horizontal scroll on the current line
            (setq-local hscroll-margin 0) ; No margin for horizontal scrolling

            ;; Bind the toggle function to the '.' key in speedbar mode
            (define-key speedbar-mode-map "." 'my-speedbar/toggle-filter)
            ;; First, inherit properties from 'org-level-2
            (set-face-attribute 'speedbar-separator-face nil :inherit 'org-level-2)
            ;; Then, change the background color while preserving other inherited properties
            (set-face-attribute 'speedbar-separator-face nil :background info-theme-dark-blue)))



;; get the name of the available views from
;; speedbar-initial-expansion-mode-alist
(defun my-speedbar/switch-speedbar-view (speedbar-view)
  "Temporarily switch to quick-buffers expansion list.
Useful for quickly switching to an open buffer."
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
