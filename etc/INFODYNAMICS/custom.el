;;; -*- lexical-binding: t -*-
(custom-set-variables
 ;; custom-set-variables was added by Custom.
 ;; If you edit it by hand, you could mess it up, so be careful.
 ;; Your init file should contain only one such instance.
 ;; If there is more than one, they won't work right.
 '(bmkp-last-as-first-bookmark-file "~/.emacs.d/var/INFODYNAMICS/bmkp/bookmark-default.bmk")
 '(icon-preference '(symbol image text emoji))
 '(org-fold-catch-invisible-edits 'show-and-error nil nil "Customized with use-package org")
 '(outline-minor-mode-cycle t)
 '(outline-minor-mode-highlight 'override)
 '(outline-minor-mode-prefix [3 64])
 '(outline-minor-mode-use-buttons 'in-margins)
 '(package-selected-packages
   '(aggressive-indent aidermacs anaconda-mode apache-mode apheleia auctex-latexmk
                       breadcrumb calfw-cal calfw-org cape cargo cargo-mode
                       cargo-transient cdlatex citar-embark clj-refactor
                       combobulate compile-angel consult-eglot-embark
                       consult-project-extra corfu dape dashboard delight
                       diff-hl dired+ docker docker-compose-mode dotenv-mode
                       dumb-jump eldoc-box elisp-demos etc-sudoers-mode
                       exec-path-from-shell flycheck-clojure
                       flymake-markdownlint flymake-markdownlint-cli2
                       flymake-ruff flymake-shellcheck fringe-helper
                       geiser-guile geiser-racket git-modes git-timemachine
                       google-contacts gptel helpful hledger-mode ibuffer-vc
                       imenu-list info+ jinx jump marginalia
                       markdown-preview-mode markdown-toc matlab-mode
                       nerd-icons-completion nerd-icons-corfu nerd-icons-dired
                       no-littering numpydoc olivetti orderless org-alert
                       org-appear org-contacts org-contrib org-fancy-priorities
                       org-modern org-roam org-super-agenda page-break-lines
                       pandoc-mode pdf-tools popon pq pydoc python-pytest
                       python-view-data pyvenv qrencode rainbow-mode
                       robots-txt-mode rustic sly-asdf sly-quicklisp
                       sly-repl-ansi-color sqlformat sr-speedbar treesit-fold
                       undo-tree valign vertico visual-fill-column vlf
                       vterm-toggle web-mode web-server websocket yaml-pro
                       yasnippet-snippets))
 '(package-vc-selected-packages
   '((flymake-markdownlint-cli2 :url
                                "https://github.com/ewilderj/flymake-markdownlint-cli2.git"
                                :branch "main")))
 '(safe-local-variable-values
   '((visual-fill-column-width . 120)
     (ispell-personal-dictionary
      . "/mnt/HDD04_WDD_08TB/workspace/python/logger/.aspell.en.pws")
     (ispell-personal-dictionary
      . "/mnt/HDD04_WDD_08TB/workspace/python/ai_api/.aspell.en.pws")))
 '(semantic-sb-info-format-tag-function 'semantic-format-tag-short-doc)
 '(speedbar-add-supported-extension
   '(".cl" ".li?sp" ".lua" ".fnl" ".fennel" ".kt" ".mvn" ".gradle" ".properties"
     ".cljs?" ".sh" ".bash" ".php" ".ts" ".html?" ".css" ".less" ".scss" ".sass"
     ".py" ".p" ".q" ".k" ".rs" ".lock" "makefile" "MAKEFILE" "Makefile" ".json"
     ".yaml" ".toml" ".md" ".markdown" ".org" ".txt" "README"))
 '(speedbar-directory-button-trim-method 'trim)
 '(speedbar-directory-unshown-regexp "^\\(CVS\\|RCS\\|SCCS\\|\\.\\.*$\\)\\'")
 '(speedbar-indentation-width 3)
 '(speedbar-prefer-window t)
 '(speedbar-show-unknown-files t)
 '(speedbar-smart-directory-expand-flag t)
 '(speedbar-update-flag t)
 '(speedbar-vc-do-check t)
 '(sr-speedbar-auto-refresh t)
 '(sr-speedbar-max-width 170)
 '(sr-speedbar-right-side nil)
 '(sr-speedbar-width 40 t)
 '(vlf-application 'dont-ask)
 '(which-key-popup-type 'minibuffer nil nil "Customized with use-package which-key"))
(custom-set-faces
 ;; custom-set-faces was added by Custom.
 ;; If you edit it by hand, you could mess it up, so be careful.
 ;; Your init file should contain only one such instance.
 ;; If there is more than one, they won't work right.
 '(default ((t (:inherit nil :weight regular :height 100 :family "Noto Mono"))))
 '(fixed-pitch ((t (:inherit nil :weight regular :height 100 :family "Source Code Pro"))))
 '(fixed-pitch-serif ((t (:inherit nil :weight regular :height 100 :family "Courier New"))))
 '(ibuffer-header-face ((t (:foreground "cyan" :weight bold :underline t))))
 '(modus-themes-heading-0 ((t (:foreground "#D2D6CE" :weight Bold :height 150 :family "Impact"))) t)
 '(modus-themes-heading-1 ((t (:foreground "#D2D6CE" :weight Bold :height 140 :family "arial"))) t)
 '(modus-themes-heading-2 ((t (:foreground "#D2D6CE" :weight Bold :height 130 :family "arial"))) t)
 '(modus-themes-heading-3 ((t (:foreground "#D2D6CE" :weight Bold :height 120 :family "arial"))) t)
 '(modus-themes-heading-4 ((t (:foreground "#D2D6CE" :weight regular :height 120 :family "arial"))) t)
 '(modus-themes-heading-5 ((t (:foreground "#D2D6CE" :weight regular :height 80 :family "arial"))) t)
 '(org-table ((t :background "#2E2E2E" :inverse-video nil)))
 '(speedbar-button-face ((t (:foreground "#D2D6CE"))))
 '(speedbar-directory-face ((t (:foreground "#D2D6CE"))))
 '(speedbar-file-face ((t (:foreground "#D2D6CE"))))
 '(speedbar-highlight-face ((t (:inherit 'popup-menu-selection-face))))
 '(speedbar-selected-face ((t (:foreground "gray98" :underline nil))))
 '(speedbar-separator-face ((t (:inherit 'org-level-2 :foreground "#D2D6CE" :background "#1B152D"))))
 '(speedbar-tag-face ((t (:inherit 'font-lock-variable-name-face))))
 '(variable-pitch ((t (:inherit nil :weight regular :height 100 :family "Times New Roman")))))
