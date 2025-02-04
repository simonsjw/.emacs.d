(custom-set-variables
 ;; custom-set-variables was added by Custom.
 ;; If you edit it by hand, you could mess it up, so be careful.
 ;; Your init file should contain only one such instance.
 ;; If there is more than one, they won't work right.
 '(bmkp-last-as-first-bookmark-file
   "/home/simon/.emacs.d/var/INFODYNAMICS/bmkp/current-bookmark.el")
 '(icon-preference '(symbol image text emoji))
 '(outline-minor-mode-cycle t)
 '(outline-minor-mode-highlight 'override)
 '(outline-minor-mode-prefix [3 64])
 '(outline-minor-mode-use-buttons 'in-margins)
 '(package-selected-packages
   '(aggressive-indent anaconda-mode apache-mode auctex-latexmk
                       auto-compile bookmark+ cape cargo cargo-mode
                       cargo-transient citar-embark clj-refactor
                       consult-eglot-embark consult-project-extra
                       corfu-terminal csv-mode dape dashboard dired+
                       docker docker-compose-mode dumb-jump eldoc-box
                       elisp-demos flycheck-clojure
                       flymake-markdownlint flymake-shellcheck
                       geiser-guile geiser-racket git-modes
                       google-contacts helpful ibuffer-vc imenu-list
                       info+ jump marginalia modus-themes
                       nerd-icons-completion nerd-icons-corfu
                       nerd-icons-dired nerd-icons-ibuffer
                       no-littering numpydoc olivetti orderless
                       org-alert org-appear org-contacts org-contrib
                       org-link-beautify org-pretty-tags org-roam
                       page-break-lines pandoc-mode pdf-tools pq
                       pretty-speedbar pyvenv robots-txt-mode
                       ruff-format rustic sly-asdf sly-quicklisp
                       sly-repl-ansi-color sqlformat treesit-fold
                       undo-tree vertico vterm web-mode
                       yasnippet-snippets))
 '(package-vc-selected-packages
   '((treesit-fold :url
                   "https://github.com/emacs-tree-sitter/treesit-fold.git")
     (dired+ :url "https://github.com/emacsmirror/dired-plus.git")
     (info+ :url "https://github.com/emacsmirror/info-plus.git")
     (bookmark+ :url
                "https://github.com/emacsmirror/bookmark-plus.git")
     (auto-compile :url
                   "https://github.com/emacscollective/auto-compile.git")))
 '(pretty-speedbar-blank-page '(""))
 '(pretty-speedbar-book '(""))
 '(pretty-speedbar-box-closed '(""))
 '(pretty-speedbar-box-open '(""))
 '(pretty-speedbar-folder '("" t))
 '(pretty-speedbar-folder-open '("" t))
 '(pretty-speedbar-font "Symbols Nerd Font Mono")
 '(pretty-speedbar-icon-size 20)
 '(pretty-speedbar-info '(""))
 '(pretty-speedbar-mail '(""))
 '(pretty-speedbar-page '(""))
 '(pretty-speedbar-tag '(""))
 '(pretty-speedbar-tags '(""))
 '(projectile-speedbar-enable t)
 '(safe-local-variable-values '((eval olivetti-set-width 160)))
 '(semantic-sb-info-format-tag-function 'semantic-format-tag-short-doc)
 '(speedbar-add-supported-extension
   '(".cl" ".li?sp" ".lua" ".fnl" ".fennel" ".kt" ".mvn" ".gradle"
     ".properties" ".cljs?" ".sh" ".bash" ".php" ".ts" ".html?" ".css"
     ".less" ".scss" ".sass" ".py" ".p" ".q" ".k" ".rs" ".lock"
     "makefile" "MAKEFILE" "Makefile" ".json" ".yaml" ".toml" ".md"
     ".markdown" ".org" ".txt" "README"))
 '(speedbar-directory-button-trim-method 'trim)
 '(speedbar-directory-unshown-regexp "^\\(CVS\\|RCS\\|SCCS\\|\\.\\.*$\\)\\'")
 '(speedbar-indentation-width 3)
 '(speedbar-show-unknown-files t)
 '(speedbar-smart-directory-expand-flag t)
 '(speedbar-update-flag t)
 '(speedbar-use-images t)
 '(speedbar-vc-do-check t)
 '(sr-speedbar-auto-refresh t)
 '(sr-speedbar-max-width 170)
 '(sr-speedbar-right-side nil)
 '(sr-speedbar-width 40 t))
(custom-set-faces
 ;; custom-set-faces was added by Custom.
 ;; If you edit it by hand, you could mess it up, so be careful.
 ;; Your init file should contain only one such instance.
 ;; If there is more than one, they won't work right.
 '(default ((t (:inherit nil :weight regular :height 100 :family "fira code"))))
 '(cell-blank-face ((t (:background "#1B152D" :box (:line-width 1 :color "#D2D6CE")))))
 '(cell-blank-odd-face ((t (:background "#4A4F6A" :box (:line-width 1 :color "#D2D6CE")))))
 '(cell-comment-2-face ((t (:foreground "#859B00" :box (:line-width 1 :color "#D2D6CE")))))
 '(cell-comment-face ((t (:foreground "#169C05" :box (:line-width 1 :color "#D2D6CE")))))
 '(cell-cursor-face ((t (:background "#4E9A06" :foreground "#CFD400" :box (:line-width 1 :color "#D2D6CE")))))
 '(cell-default-face ((t (:foreground "#D2D6CE" :box (:line-width 1 :color "#D2D6CE")))))
 '(fixed-pitch ((t (:inherit nil :weight regular :height 100 :family "source code pro"))))
 '(fixed-pitch-serif ((t (:inherit nil :weight regular :height 100 :family "courier new"))))
 '(modus-themes-heading-0 ((t (:foreground "#D2D6CE" :weight Bold :height 150 :family "Impact"))) t)
 '(modus-themes-heading-1 ((t (:foreground "#D2D6CE" :weight Bold :height 140 :family "arial"))) t)
 '(modus-themes-heading-2 ((t (:foreground "#D2D6CE" :weight Bold :height 130 :family "arial"))) t)
 '(modus-themes-heading-3 ((t (:foreground "#D2D6CE" :weight Bold :height 120 :family "arial"))) t)
 '(modus-themes-heading-4 ((t (:foreground "#D2D6CE" :weight regular :height 120 :family "arial"))) t)
 '(modus-themes-heading-5 ((t (:foreground "#D2D6CE" :weight regular :height 80 :family "arial"))) t)
 '(speedbar-button-face ((t (:foreground "#D2D6CE"))))
 '(speedbar-directory-face ((t (:foreground "#D2D6CE"))))
 '(speedbar-file-face ((t (:foreground "#D2D6CE"))))
 '(speedbar-highlight-face ((t (:inherit 'popup-menu-selection-face))))
 '(speedbar-selected-face ((t (:foreground "gray98" :underline nil))))
 '(speedbar-separator-face ((t (:inherit 'org-level-2 :forground "#D2D6CE" :background "#1B152D"))))
 '(speedbar-tag-face ((t (:inherit 'font-lock-variable-name-face))))
 '(variable-pitch ((t (:inherit nil :weight regular :height 100 :family "times new roman")))))


