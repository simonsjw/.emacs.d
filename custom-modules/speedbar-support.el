;;; speedbar-support.el --- Speedbar configuration -*- lexical-binding: t; -*-

;; Copyright (C) 2026 Simon Watson
;; SPDX-License-Identifier: MIT

;; Author: Simon Watson
;; Keywords: speedbar sr-speedbar file-tree pretty-icons

;;; Commentary:

;; Modern daemon-aware speedbar setup (2026 best practice).
;; • All icon/colour setup is re-entrant via my-speedbar/setup-pretty-icons.
;; • Icons are guaranteed to appear on emacsclient -c frames.
;; • No early graphical assumptions at load time.
;; • Efficiency first: minimal code, single refresh, full docstrings.

;;; Code:
(require 'path-support)
(require 'logging-config)
(log/debug :fn 'speedbar-support
           :msg "Starting load of the speedbar-support module."
           :obj t)

(use-package sr-speedbar)

(use-package pretty-speedbar
  :load-path my-paths/pretty-speedbar
  :ensure nil          ; local package – never try ELPA/MELPA/straight
  :demand t            ; load immediately (best for Speedbar)
  :custom
  (ezimage-use-images t)
  (speedbar-use-images t)
  :config
  ;; Generate icons on first run (or if they’re missing)
  (unless (file-exists-p (expand-file-name "pretty-folder.svg"
                                           pretty-speedbar-icons-dir))
    (pretty-speedbar-reload)))

;; Local memory-object-tree package
;; (add-to-list 'load-path my-paths/memory-object-tree-folder)
;; (use-package memory-object-tree
;;   :ensure nil
;;   :demand t)

;; ----------------------------------------------------------------------
;; Re-entrant pretty-speedbar setup (called from my-visual/apply-all-customisations)
;; ----------------------------------------------------------------------
(defun my-speedbar/setup-pretty-icons ()
  "Set up pretty-speedbar colours, sizes, and icons.
Purpose:
  Re-applied on every new frame so icons appear correctly in daemon + client frames.
  Historical note: pre-2026 setups failed here because pretty-speedbar ran only once at load."
  (require 'pretty-speedbar)
  (setq pretty-speedbar-icon-size 20
        pretty-speedbar-font "Symbols Nerd Font Mono")

  ;; Icon glyphs (your existing choices)
  (setq pretty-speedbar-folder '("\uf07b" t)                                      ;  Closed folder icon.
        pretty-speedbar-folder-open '("\uf07c" t)                                 ;  Open folder icon.
        pretty-speedbar-blank-page '("\uf15b")                                    ;  Used for plus and minus file icons.
        pretty-speedbar-page '("\uf15c")                                          ;  Default file icon.
        pretty-speedbar-box-closed '("\uebb4")                                    ;  Closed box icon with plus added during generation.
        pretty-speedbar-box-open '("\uebb5" )                                     ;  Open box icon with minus added during generation.
        pretty-speedbar-book '("\uf02d")                                          ;  Book icon used for documentation available.
        pretty-speedbar-mail '("\uf0e0")                                          ;  Envelope icon.
        pretty-speedbar-info '("\uf05a")                                          ;  Info icon.
        pretty-speedbar-tags '("\uf02c")                                          ;  Tags icon used for plus and minus tags generation. 
        pretty-speedbar-tag '("\uf02b"))                                          ;  Single tag icon. Most frequent tag icon.
  

  ;; Colours (use your info-theme variables — defined in theme-support)
  (setq pretty-speedbar-icon-fill info-theme-light-white
        pretty-speedbar-icon-stroke info-theme-dark-red
        pretty-speedbar-icon-folder-fill info-theme-dark-red
        pretty-speedbar-icon-folder-stroke info-theme-dark-red
        pretty-speedbar-about-fill info-theme-dark-red
        pretty-speedbar-about-stroke info-theme-light-white
        pretty-speedbar-signs-fill info-theme-light-white)

  (when (fboundp 'pretty-speedbar-generate)
    (pretty-speedbar-generate) )

  (log/info :fn 'my-speedbar/setup-pretty-icons
            :msg "Pretty icons & colours applied."
            :obj nil)
  )

;; ----------------------------------------------------------------------
;; Core speedbar customisations (all daemon-safe)
;; ----------------------------------------------------------------------
(custom-set-variables
 '(speedbar-indentation-width 3)
 '(speedbar-directory-button-trim-method 'trim)
 '(speedbar-update-flag t)
 '(semantic-sb-info-format-tag-function 'semantic-format-tag-short-doc)
 '(speedbar-vc-do-check t)
 '(speedbar-show-unknown-files t)
 '(speedbar-smart-directory-expand-flag t)
 '(speedbar-directory-unshown-regexp "^\\(CVS\\|RCS\\|SCCS\\|\\.\\.*$\\)\\'")
 '(speedbar-add-supported-extension
   '(".cl" ".li?sp" ".lua" ".fnl" ".fennel" ".kt" ".mvn" ".gradle" ".properties"
     ".cljs?" ".sh" ".bash" ".php" ".ts" ".html?" ".css" ".less" ".scss" ".sass"
     ".py" ".p" ".q" ".k" ".rs" ".lock" "makefile" "MAKEFILE" "Makefile"
     ".json" ".yaml" ".toml" ".md" ".markdown" ".org" ".txt" "README"))
 '(sr-speedbar-auto-refresh t)
 '(sr-speedbar-max-width 170)
 '(sr-speedbar-width 40)
 '(sr-speedbar-right-side nil))

;; Faces (kept minimal — colours now handled via theme)
(custom-set-faces
 `(speedbar-button-face ((t (:foreground ,info-theme-white-grey))))
 `(speedbar-directory-face ((t (:foreground ,info-theme-white-grey))))
 `(speedbar-file-face ((t (:foreground ,info-theme-white-grey))))
 '(speedbar-selected-face ((t (:foreground "gray98" :underline nil))))
 `(speedbar-highlight-face ((t (:inherit 'popup-menu-selection-face))))
 `(speedbar-tag-face ((t (:inherit 'font-lock-variable-name-face))))
 `(speedbar-separator-face ((t (:inherit 'org-level-2
                                         :foreground ,info-theme-white-grey
                                         :background ,info-theme-dark-blue)))))

;; ----------------------------------------------------------------------
;; Functions
;; ----------------------------------------------------------------------
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

;; Variable to hold the state of the filter in speedbar.  t or nil.
;; used in `my-speedbar/toggle-filter'.
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
        ;; Hide dot files, directories beginning with "_", and specific VCS
        ;; directories but always show the `..' file.
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





;; ----------------------------------------------------------------------
;; Hooks & keymaps (all re-entrant)
;; ----------------------------------------------------------------------
(add-hook 'speedbar-mode-hook
          (lambda ()
            (visual-line-mode 0)
            (setq-local truncate-lines t)
            (text-scale-adjust -0.25)
            (setq-local auto-hscroll-mode 'current-line)
            (setq-local hscroll-margin 0)
            (define-key speedbar-mode-map "." #'my-speedbar/toggle-filter)))

(with-eval-after-load 'speedbar
  (define-key speedbar-file-key-map (kbd "w") #'my-speedbar/go-workspace)
  (define-key speedbar-file-key-map (kbd "h") #'my-speedbar/go-home)
  (define-key speedbar-file-key-map (kbd "o") #'my-speedbar/open-in-file-explorer)
  (define-key speedbar-mode-map "b" (lambda () (interactive) (my-speedbar/switch-speedbar-view "quick buffers")))
  (define-key speedbar-mode-map "i" (lambda () (interactive) (my-speedbar/switch-speedbar-view "Info")))
  (define-key speedbar-mode-map "v" #'my-speedbar/open-vterm-in-dir))

(global-set-key (kbd "C-c s") #'my-speedbar/toggle)

;; ----------------------------------------------------------------------
;; Safe icon regeneration when speedbar buffer is actually ready
;; ----------------------------------------------------------------------
(add-hook 'speedbar-mode-hook
          (lambda ()
            (when (fboundp 'my-speedbar/setup-pretty-icons)
              (my-speedbar/setup-pretty-icons))
            (when (fboundp 'speedbar-refresh)
              (speedbar-refresh))
            (message "[INFO; speedbar] Icons regenerated via speedbar-mode-hook")))

(with-eval-after-load 'sr-speedbar
  (add-hook 'sr-speedbar-after-toggle-hook
            (lambda ()
              (when (fboundp 'my-speedbar/setup-pretty-icons)
                (my-speedbar/setup-pretty-icons))
              (when (fboundp 'sr-speedbar-refresh)
                (sr-speedbar-refresh))
              (message "[INFO; speedbar] Icons regenerated after sr-speedbar toggle"))))

(log/debug :fn 'speedbar-support
           :msg "Ending load of the speedbar-support module."
           :obj t)

(provide 'speedbar-support)
;;; speedbar-support.el ends here
