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

(use-package sr-speedbar)
(use-package pretty-speedbar)

;; Local memory-object-tree package
(add-to-list 'load-path my-paths/memory-object-tree-folder)
(use-package memory-object-tree
  :ensure nil
  :demand t)

;; ----------------------------------------------------------------------
;; Re-entrant pretty-speedbar setup (called from my-visual/apply-all-customisations)
;; ----------------------------------------------------------------------
(defun my-speedbar/setup-pretty-icons ()
  "Set up pretty-speedbar colours, sizes, and icons.
Purpose:
  Re-applied on every new frame so icons appear correctly in daemon + client frames.
  Historical note: pre-2026 setups failed here because pretty-speedbar ran only once at load."
  (setq pretty-speedbar-icon-size 20
        pretty-speedbar-font "Symbols Nerd Font Mono")

  ;; Icon glyphs (your existing choices)
  (setq pretty-speedbar-folder '("\uf07b" t)
        pretty-speedbar-folder-open '("\uf07c" t)
        pretty-speedbar-blank-page '("\uf15b")
        pretty-speedbar-page '("\uf15c")
        pretty-speedbar-box-closed '("\uebb4")
        pretty-speedbar-box-open '("\uebb5")
        pretty-speedbar-book '("\uf02d")
        pretty-speedbar-mail '("\uf0e0")
        pretty-speedbar-info '("\uf05a")
        pretty-speedbar-tags '("\uf02c")
        pretty-speedbar-tag '("\uf02b"))

  ;; Colours (use your info-theme variables — defined in theme-support)
  (setq pretty-speedbar-icon-fill info-theme-light-white
        pretty-speedbar-icon-stroke info-theme-dark-red
        pretty-speedbar-icon-folder-fill info-theme-dark-red
        pretty-speedbar-icon-folder-stroke info-theme-dark-red
        pretty-speedbar-about-fill info-theme-dark-red
        pretty-speedbar-about-stroke info-theme-light-white
        pretty-speedbar-signs-fill info-theme-light-white)

  (when (fboundp 'pretty-speedbar-generate)
    (pretty-speedbar-generate))

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
  "Set speedbar to FILE-PATH and refresh."
  (interactive "DDirectory: ")
  (let ((expanded (expand-file-name file-path)))
    (when (file-directory-p expanded)
      (setq default-directory expanded)
      (speedbar-refresh)
      (log/info :fn 'my-speedbar/set-speedbar-directory-to-file-path
                :msg "Speedbar directory set."
                :obj expanded)
      )))

(defun my-speedbar/toggle ()
  "Toggle sr-speedbar in IDE frames, plain speedbar otherwise."
  (interactive)
  (if (string-prefix-p "IDE:" (frame-parameter nil 'name))
      (progn
        (select-window (car (sort (window-list) (lambda (w1 w2)
                                                  (let ((e1 (window-edges w1))
                                                        (e2 (window-edges w2)))
                                                    (or (< (nth 1 e1) (nth 1 e2))
                                                        (and (= (nth 1 e1) (nth 1 e2))
                                                             (< (nth 0 e1) (nth 0 e2)))))))))
        (sr-speedbar-toggle))
    (speedbar)))

(defun my-speedbar/toggle-filter ()
  "Toggle visibility of dotfiles in speedbar."
  (interactive)
  (setq my-speedbar/speedbar-filter-state (not my-speedbar/speedbar-filter-state))
  (if my-speedbar/speedbar-filter-state
      (setq speedbar-directory-unshown-regexp "^\\(\\.[^/.].*\\|_[^/]*\\|CVS\\|RCS\\|SCCS\\)$"
            speedbar-file-unshown-regexp "^\\(\\.[^/]*\\|CVS\\|RCS\\|SCCS\\)$")
    (setq speedbar-directory-unshown-regexp "^\\.$"
          speedbar-file-unshown-regexp "^$"))
  (speedbar-refresh))


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
              
(provide 'speedbar-support)
;;; speedbar-support.el ends here
