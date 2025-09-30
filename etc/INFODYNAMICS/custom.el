;;; -*- lexical-binding: t -*-
(custom-set-variables
 ;; custom-set-variables was added by Custom.
 ;; If you edit it by hand, you could mess it up, so be careful.
 ;; Your init file should contain only one such instance.
 ;; If there is more than one, they won't work right.
 '(bmkp-last-as-first-bookmark-file "~/.emacs.d/var/INFODYNAMICS/bmkp/bookmark-default.bmk")
 '(bookmark-save-flag 1)
 '(icon-preference '(symbol image text emoji))
 '(outline-minor-mode-cycle t)
 '(outline-minor-mode-highlight 'override)
 '(outline-minor-mode-prefix [3 64])
 '(outline-minor-mode-use-buttons 'in-margins)
 '(package-selected-packages
   '(aggressive-indent anaconda-mode apache-mode auctex-latexmk cape cargo
                       cargo-mode cargo-transient cdlatex citar-embark
                       clj-refactor compile-angel consult-eglot-embark
                       consult-project-extra corfu-terminal csv-mode dape
                       dashboard delight dired+ docker docker-compose-mode
                       dotenv-mode dumb-jump eldoc-box elisp-demos
                       flycheck-clojure flymake-markdownlint flymake-shellcheck
                       geiser-guile geiser-racket git-gutter git-gutter-fringe
                       git-modes google-contacts helpful ibuffer-vc imenu-list
                       info+ insert-shebang jump marginalia matlab-mode
                       nerd-icons-completion nerd-icons-corfu
                       nerd-icons-dired no-littering numpydoc olivetti orderless
                       org-alert org-appear org-contacts org-contrib
                       org-link-beautify org-pretty-tags org-roam
                       page-break-lines pandoc-mode pdf-tools pq pretty-speedbar
                       pyvenv rainbow-mode robots-txt-mode ruff-format rustic
                       sly-asdf sly-quicklisp sly-repl-ansi-color sqlformat
                       sr-speedbar treesit-fold undo-tree vertico vlf vlf-mode
                       vterm web-mode yasnippet-snippets))
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
 '(project-vc-name "")
 '(safe-local-variable-values '((eval olivetti-set-width 160)))
 '(semantic-sb-info-format-tag-function 'semantic-format-tag-short-doc)
 '(ses-initial-size '(10 . 10))
 '(speedbar-add-supported-extension
   '(".cl" ".li?sp" ".lua" ".fnl" ".fennel" ".kt" ".mvn" ".gradle" ".properties"
     ".cljs?" ".sh" ".bash" ".php" ".ts" ".html?" ".css" ".less" ".scss" ".sass"
     ".py" ".p" ".q" ".k" ".rs" ".lock" "makefile" "MAKEFILE" "Makefile" ".json"
     ".yaml" ".toml" ".md" ".markdown" ".org" ".txt" "README"))
 '(speedbar-directory-button-trim-method 'trim)
 '(speedbar-directory-unshown-regexp "^\\(CVS\\|RCS\\|SCCS\\|\\.\\.*$\\)\\'")
 '(speedbar-frame-parameters
   '((minibuffer) (border-width . 4) (width . 40) (menu-bar-lines . 0)
     (tool-bar-lines . 0) (unsplittable . t) (left-fringe . 4)))
 '(speedbar-indentation-width 3)
 '(speedbar-show-unknown-files t)
 '(speedbar-smart-directory-expand-flag t)
 '(speedbar-update-flag t)
 '(speedbar-vc-do-check t)
 '(sr-speedbar-auto-refresh t)
 '(sr-speedbar-max-width 170)
 '(sr-speedbar-right-side nil)
 '(sr-speedbar-width 40 t)
 '(vlf-application 'dont-ask)
 '(vlf-tune-load-time 2.0))
(custom-set-faces
 ;; custom-set-faces was added by Custom.
 ;; If you edit it by hand, you could mess it up, so be careful.
 ;; Your init file should contain only one such instance.
 ;; If there is more than one, they won't work right.
 '(default ((t (:inherit nil :weight regular :height 100 :family "fira code"))))
 '(fixed-pitch ((t (:inherit nil :weight regular :height 100 :family "source code pro"))))
 '(fixed-pitch-serif ((t (:inherit nil :weight regular :height 100 :family "courier new"))))
 '(ibuffer-header-face ((t (:foreground "cyan" :weight bold :underline t))))
 '(speedbar-button-face ((t (:foreground "#D2D6CE"))))
 '(speedbar-directory-face ((t (:foreground "#D2D6CE"))))
 '(speedbar-file-face ((t (:foreground "#D2D6CE"))))
 '(speedbar-highlight-face ((t (:inherit 'popup-menu-selection-face))))
 '(speedbar-selected-face ((t (:foreground "gray98" :underline nil))))
 '(speedbar-separator-face ((t (:inherit 'org-level-2 :forground "#D2D6CE" :background "#1B152D"))))
 '(speedbar-tag-face ((t (:inherit 'font-lock-variable-name-face))))
 '(variable-pitch ((t (:inherit nil :weight regular :height 100 :family "times new roman")))))
