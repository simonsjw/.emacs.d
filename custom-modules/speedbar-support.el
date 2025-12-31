;;; speedbar-support.el --- Speedbar configuration -*- mode: emacs-lisp; mode: outline-minor; lexical-binding: t; -*-

;;; License
;; Copyright (C) 2022
;; SPDX-License-Identifier: MIT

;; Author: Simon Watson

;;; Commentary:

;; This file was made with outline-minor-mode in mind
;; and therefore have ";;;+"-comments as headers.

;; Configuration for speedbar, a file-tree (and more), that comes
;; builtin to Emacs it also has integration with some packages like
;; Rmail.

(defvar speedbar-mode-map)
(defvar speedbar-indentation-width)
(defvar speedbar-update-flag)
(defvar speedbar-show-unknown-files)
(defvar speedbar-smart-directory-expand-flag)
(defvar speedbar-directory-unshown-regexp)
(defvar speedbar-file-unshown-regexp)
(defvar speedbar-directory-arguments)
(defvar speedbar-add-supported-extension)
(defvar my-speedbar/speedbar-filter-state t
  "Variable to hold the state of the filter in speedbar.
Used in `my-speedbar/toggle-filter'.  t or nil.")

(defvar speedbar-breadcrumbs-updating nil "This variable is t when running.
Use it to stop erroneous recursion.")

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

(declare-function speedbar-refresh "speedbar")
(declare-function speedbar-change-initial-expansion-list "speedbar")
(declare-function speedbar-add-supported-extension "speedbar")
(declare-function my-on-disk-tools/summary-path "system-tools")

;;; Code:

(use-package sr-speedbar)
(use-package pretty-speedbar)

;; memory-object-tree - custom package to visualise artefacts in memory.
(add-to-list 'load-path my-paths/memory-object-tree-folder)
(use-package memory-object-tree
  :ensure nil                                                                     ; Indicates this is a local package, not from a repository
  :demand t                                                                       ; Forces the package to load immediately at startup
  )

;;;; functions:
;;   ----------

(defun my-speedbar/set-speedbar-directory-to-file-path (file-path)
  "Set the speedbar directory to FILE-PATH and refresh it.
If `sr-speedbar' is not open, open it first."
  (interactive "DDirectory: ")
  (let ((expanded-path (expand-file-name file-path)))
    (when (file-directory-p expanded-path)
      ;; Open sr-speedbar if it's not already open
      ;; Set the default directory
      (setq default-directory expanded-path)
      (speedbar-refresh)
      ;; Clear speedbar cache and force refresh
      ;; Display a message indicating the new directory
      (message "speedbar directory set to %s" expanded-path))))

(defun my-speedbar/toggle ()
  "If the selected frame is an IDE, open `sr-speedbar' else open `speedbar'.

In the case where `sr-speedbar' is opened, it is opened in the  top-left window
using `sr-speedbar-toggle'."
  (interactive)
  (let ((my-selected-frame-name (frame-parameter nil 'name))
        (my-selected-frame (selected-frame)))
    (if (string-prefix-p "IDE:" (frame-parameter nil 'name))
        (progn
          (log/debug :fn 'my-speedbar/toggle
                     :msg "Frame is an IDE - use sr-speedbar."
                     :obj (list :name my-selected-frame-name
                                :frame my-selected-frame))
          (let ((top-left-window
                 (car
                  (sort (window-list)
                        (lambda (w1 w2)
                          (let ((edges1 (window-edges w1))
                                (edges2 (window-edges w2)))
                            (or (< (nth 1 edges1) (nth 1 edges2))                 ; Compare top edges
                                (and (= (nth 1 edges1) (nth 1 edges2))
                                     (< (nth 0 edges1) (nth 0 edges2))))))))))
            (select-window top-left-window))
          (sr-speedbar-toggle))
      (progn
        (log/debug :fn 'my-speedbar/toggle
                   :msg "Frame is not an IDE - use speedbar. "
                   :obj (list :name my-selected-frame-name
                              :frame my-selected-frame))
        (speedbar))
      )
    )
  )

(defun my-speedbar/open-vterm-in-dir ()
  "Open a vterm session in the directory under the cursor in Speedbar.

This function retrieves the current directory from the Speedbar line,
binds it as the default directory, and launches vterm with a buffer
name indicating the directory.  If no directory is selected, it signals
an error."
  (interactive)
  (let* ((dir (speedbar-line-directory))                                          ; Get the directory path from the current line.
         (buf-name
          (concat "Vterm: "
                  (file-name-nondirectory (directory-file-name dir)))))           ; Create a descriptive buffer name.
    (if dir
        (let ((default-directory dir))                                            ; Temporarily bind default-directory to the selected path.
          (vterm buf-name))                                                       ; Launch vterm in that directory.
      (error "No directory selected in Speedbar"))))                              ; Handle case where no dir is under cursor.


(defun my-speedbar/open-in-file-explorer ()
  "Open the current directory or file in GNOME Files (Nautilus).
If on a directory line, open that directory externally.
If on a file line, open the file with the system default application."
  (interactive)
  (let ((path (speedbar-line-directory)))
    (when path
      (start-process "xdg-open" nil "xdg-open" path))))


(defun my-speedbar/go-home ()
  "Switch SPEEDBAR to home directory if in file mode."
  (interactive)
  (when (and (bound-and-true-p speedbar-frame)                                    ; Speedbar frame exists
             (eq speedbar-frame (selected-frame))                                 ; Speedbar window is active
             (eq speedbar-buffer (current-buffer))                                ; In Speedbar buffer
             (string-equal speedbar-initial-expansion-list-name "files"))         ; In file mode
    (my-speedbar/set-speedbar-directory-to-file-path
     (expand-file-name "~/"))))

(defun my-speedbar/go-workspace ()
  "Switch SPEEDBAR to the workspace directory if in file mode."
  (interactive)
  (when (and (bound-and-true-p speedbar-frame)                                    ; Speedbar frame exists
             (eq speedbar-frame (selected-frame))                                 ; Speedbar window is active
             (eq speedbar-buffer (current-buffer))                                ; In Speedbar buffer
             (string-equal speedbar-initial-expansion-list-name "files"))         ; In file mode
    (my-speedbar/set-speedbar-directory-to-file-path
     (expand-file-name "/mnt/HDD04_WDD_08TB/workspace/"))))

;; This function overrides the original speedbar function so that
;; the correct speedbar width is reported when speedbar is not the only
;; window in a frame.
(defun speedbar-frame-width ()
  "Return the width of the sr-speedbar window, or a default value."
  (if (and (boundp 'sr-speedbar-window) sr-speedbar-window)
      (window-width sr-speedbar-window)                                           ; Use sr-speedbar window width
    30))                                                                          ; Fallback default width

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
        ;; Hide dot files, directories beginning with "_", and specific VCS
        ;; directories but always show the `..' file.
        ;; (old expressions:
        ;;    "^\\(\\.[^/.][^/]*\\|_[^/]*\\|CVS\\|RCS\\|SCCS\\)$"
        ;;    "^\\(\\.[^/]*\\|_[^/]*\\|CVS\\|RCS\\|SCCS\\)$"
        ;; )
        (setq speedbar-directory-unshown-regexp
              "^\\(\\.[^/.].*\\|_[^/]*\\|CVS\\|RCS\\|SCCS\\)$")
        (setq speedbar-file-unshown-regexp
              "^\\(\\.[^/]*\\|CVS\\|RCS\\|SCCS\\)$"))
    ;; If dot files are shown, modify regexp to hide them
    (progn
      ;; the dot here is the folder denoting the current folder.
      ;; (just gives a recursive tree)
      (setq speedbar-directory-unshown-regexp "^\\.$")
      (setq speedbar-file-unshown-regexp "^$")))
  ;; Refresh speedbar to apply changes
  (speedbar-refresh))

;; get the name of the available views from
;; speedbar-initial-expansion-mode-alist
(defun my-speedbar/switch-speedbar-view (speedbar-view)
  "Temporarily switch to quick-buffers expansion list.
Useful for quickly switching to an open buffer.
Current view is given in SPEEDBAR-VIEW."
  (interactive)
  (speedbar-change-initial-expansion-list speedbar-view))


;;;; Customise Speedbar and Related elements
;;   ---------------------------------------

;; Variable to hold the state of the filter in speedbar.  t or nil.
;; used in `my-speedbar/toggle-filter'.
(setq my-speedbar/speedbar-filter-state t)


(custom-set-variables
 '(speedbar-indentation-width 3)                                                  ; Increase the indentation for better usability.
 ;; '(speedbar-use-images t)                                                      ; Use icon images. (not needed with pretty-speedbar)
 '(speedbar-directory-button-trim-method 'trim)                                   ;    Indicates how the directory button will be displayed. Hide
                                                                                  ; Possible values are:
                                                                                  ;       `span’ - span large directories over multiple lines.
                                                                                  ;       `trim’ - trim large directories to only show the last few.
                                                                                  ;       `nil'    - no trimming.
 '(speedbar-update-flag t)                                                        ; Auto-update when the attached frame changes directory
 '(semantic-sb-info-format-tag-function 'semantic-format-tag-short-doc)           ; Display a short form of TAG’s documentation.  (Comments, or docstring.)
                                                                                  ;     Optional argument PARENT is the parent type if TAG is a detail.
                                                                                  ;     Optional argument COLOR means highlight the prototype with font-lock colours.
                                                                                  ;     (fn TAG &optional PARENT COLOR)
 '(speedbar-vc-do-check t)                                                        ; Disable check-marks if nil.
 '(speedbar-show-unknown-files t)
 '(speedbar-smart-directory-expand-flag t)
 '(speedbar-directory-unshown-regexp "^\\(CVS\\|RCS\\|SCCS\\|\\.\\.*$\\)\\'")
 ;;'(speedbar-hide-button-brackets-flag t)                                        ; this stops icons being shown.
 
 '(speedbar-frame-parameters                                                      ; set speedbar frame parameters (overwritten if sr-speedbar is used).
   '(
     ;; (name . "*SPEEDBAR*")
     ;; (title . "*SPEEDBAR*")
     (minibuffer . nil)
     (border-width . 4)
     (width . 40)
     (menu-bar-lines . 0)
     (tool-bar-lines . 0)
     (unsplittable . t)
     (left-fringe . 4)))

 '(speedbar-add-supported-extension
   '(
     ".cl" ".li?sp"                                                               ; General Lisp Languages
     ".lua" ".fnl" ".fennel"                                                      ; Lua/Fennel (Lisp that transpiles to lua)
     ".kt" ".mvn" ".gradle" ".properties" ".cljs?"                                ; JVM languages (Java, Kotlin, Clojure)
     ".sh" ".bash"                                                                ; shellscript
     ".php" ".ts" ".html?" ".css" ".less" ".scss" ".sass"                         ; Web Languages and Markup/Styling
     ".py" ".p" ".q" ".k"                                                         ; Data languages
     ".rs" ".lock"                                                                ; Rust
     "makefile" "MAKEFILE" "Makefile"                                             ; Makefile
     ".json" ".yaml" ".toml"                                                      ; Data formats
     ".md" ".markdown" ".org" ".txt" "README"))                                   ; Notes and Markup
 
 '(sr-speedbar-auto-refresh t)
 '(sr-speedbar-max-width 170)
 '(sr-speedbar-width 40)
 '(sr-speedbar-right-side nil)

;;;;; Customise icons (need to run `pretty-speedbar-generate' on change)
 '(pretty-speedbar-icon-size 20)                                                  ; Icon height in pixels.

 '(pretty-speedbar-font "Symbols Nerd Font Mono")
 '(pretty-speedbar-folder '("\uf07b" t))                                          ;  Closed folder icon.
 '(pretty-speedbar-folder-open '("\uf07c" t))                                     ;  Open folder icon.
 '(pretty-speedbar-blank-page '("\uf15b"))                                        ;  Used for plus and minus file icons.
 '(pretty-speedbar-page '("\uf15c"))                                              ;  Default file icon.
 '(pretty-speedbar-box-closed '("\uebb4"))                                        ;  Closed box icon with plus added during generation.
 '(pretty-speedbar-box-open '("\uebb5" ))                                         ;  Open box icon with minus added during generation. 
 '(pretty-speedbar-book '("\uf02d"))                                              ;  Book icon used for documentation available. 
 '(pretty-speedbar-mail '("\uf0e0"))                                              ;  Envelope icon.
 '(pretty-speedbar-info '("\uf05a"))                                              ;  Info icon.
 '(pretty-speedbar-tags '("\uf02c"))                                              ;  Tags icon used for plus and minus tags generation. 
 '(pretty-speedbar-tag '("\uf02b"))                                               ;  Single tag icon. Most frequent tag icon.
 )

;;;;; set base colour scheme for pretty-speedbar.
(setq pretty-speedbar-icon-fill info-theme-light-white                            ; Fill color for all non-folder icons. white: #FFFFFF
      pretty-speedbar-icon-stroke info-theme-dark-red                             ; Stroke color for all non-folder icons. light grey: #DCDCDC
      pretty-speedbar-icon-folder-fill info-theme-dark-red                        ; Fill color for all folder icons: purple (fuchsia?): #D9B3FF
      pretty-speedbar-icon-folder-stroke info-theme-dark-red                      ; Stroke color for all folder icons: deep magenta: #CC00CC
      pretty-speedbar-about-fill info-theme-dark-red                              ; Fill color for all icons placed to the right of the file name, including checks and locks. lighter gray: #EFEFEF
      pretty-speedbar-about-stroke info-theme-light-white                         ; Stroke color for all icons placed to the right of the file name, including checks and locks.
      pretty-speedbar-signs-fill info-theme-light-white)                          ; Fill color for plus and minus signs used on non-folder icons. darkblue/magenta: #594968

;;;;; Customise the speedbar faces. 
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

;;; Hooks
;;  -----

(add-hook 'speedbar-mode-hook
          (lambda ()
            (visual-line-mode 0)                                                  ; Disable word wrapping in speedbar if you always enable it globally.
            (setq-local truncate-lines t)                                         ; Ensure lines do not wrap

            (text-scale-adjust -0.25)                                             ; Change speedbar's text size.  May need to alter the icon size if you change size.

            ;; Adjust horizontal scrolling behaviour
            (setq-local auto-hscroll-mode 'current-line)                          ; Horizontal scroll on the current line
            (setq-local hscroll-margin 0)                                         ; No margin for horizontal scrolling

            ;; Bind the toggle function to the '.' key in speedbar mode
            (define-key speedbar-mode-map "." 'my-speedbar/toggle-filter)))



;;; Key-maps
;;  -------- 
;; set up key-bindings for `quick-buffers' and `info' (files is already f)
(keymap-set
 speedbar-mode-map
 "b" #'(lambda () (interactive)
         (my-speedbar/switch-speedbar-view "quick buffers")))

(keymap-set
 speedbar-mode-map
 "i" #'(lambda () (interactive)
         (my-speedbar/switch-speedbar-view  "Info")))

(add-hook 'speedbar-reconfigure-keymaps-hook
          (lambda ()
            "Hook function to add custom key bindings to Speedbar's mode map.
This runs whenever Speedbar keymaps are regenerated, ensuring the
binding persists across mode changes."
            (define-key speedbar-mode-map
                        (kbd "v") #'my-speedbar/open-vterm-in-dir)))

;; Bind 'h' & 'w' & 'o' in Speedbar file mode map.
;; Note that speedbar-mode-map is a generic speedbar keymap and
;; speedbar-file-key-map is a keymap specific to the file view mode. 
(with-eval-after-load 'speedbar
  (define-key speedbar-file-key-map (kbd "w") #'my-speedbar/go-workspace)
  (define-key speedbar-file-key-map (kbd "h") #'my-speedbar/go-home)
  (define-key speedbar-file-key-map (kbd "o") #'my-speedbar/open-in-file-explorer)
  )


(global-set-key (kbd "C-c s") 'my-speedbar/toggle)                                ; Bind `my-speedbar/toggle' to "C-c s" for convenience

(provide 'speedbar-support)
;;; speedbar-support.el ends here

;; LocalWords:  FFFFFF shellscript fnl sp Makefile Lua JVM html makefile toml
;; LocalWords:  php cljs lua SCCS minibuffer tooltips propertized VCS
