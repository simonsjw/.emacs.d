;;; lang-lisp.el --- Lisp development configuration -*- lexical-binding: t; -*-

;; Local Variables:
;; outline-regexp:  ';;;+'
;; outline-start:  ';;'
;; outline-level: my-outline-mode/outline-level
;; End:

;; Copyright (C) 2022
;; SPDX-License-Identifier: MIT

;; Author: System Crafters Community

;;; Commentary:

;; Configuration for the Lisp family of languages, including Common
;; Lisp, Clojure, Scheme, and Racket.

;; For Common Lisp, configure SLY and a few related packages.
;;    An implementation of CL will need to be installed, examples are:
;;    * CLISP (GNU Common Lisp)q
;;    * CMUCL (Carnegie-Mellon Common Lisp)
;;    * SBCL (Steel-Bank Common Lisp)

;; For Clojure, configure cider, clj-refactor

;; For Scheme and Racket, configure geiser.
;;   Out of the box, geiser already supports some scheme
;;   implementations.  However, there are several modules which can be
;;   added to geiser for specific implementations:
;;   * geiser-chez
;;   * geiser-chibi
;;   * geiser-chicken
;;   * geiser-gambitg
;;   * geiser-gauche
;;   * geiser-guile
;;   * geiser-kawa
;;   * geiser-mit
;;   * geiser-racket
;;   * geiser-stklos


;;; Requirements: 
(declare-function aggressive-indent-mode "aggressive-indent-mode")
(declare-function my-outline-mode/outline-level "ui-config")

(require 'system-tools)
(require 'eldoc)
(require 'yasnippet)
(require 'yasnippet-snippets)
(require 'eldoc)

;;; Packages:

;;;; Emacs Lisp
;; https://codeberg.org/ideasman42/emacs-elisp-autofmt
;; (use-package elisp-autofmt)


;;;; Common Lisp
(use-package sly)
(use-package sly-asdf)
(use-package sly-quicklisp)
(use-package sly-repl-ansi-color)

;;;; Clojure
(use-package cider)
(use-package clj-refactor)
(use-package clojure-mode)
(use-package flycheck-clojure)

;;;; Scheme and Racket
(use-package geiser)
(use-package geiser-guile)
(use-package geiser-racket)

;;; Code:

;;;; Emacs lisp
(defun my-lang/elisp-mode-setup ()
  "Custom setup for `emacs-lisp-mode`."
  ;; You will probably want to tweak this variable, it determines how
  ;; quickly the completion prompt provides LSP suggestions when
  ;; typing. Be careful if you set it to 0 in a large project!
  (customize-set-variable 'corfu-auto-delay 0.25)

  ;; set up the autoformatting.
  ;;(require 'elisp-autofmt)
  ;;(elisp-autofmt-buffer)

  ;; enable Checkdoc.
  (checkdoc-minor-mode)

  ;; Enable Yasnippets.
  (yas-reload-all)
  (yas-minor-mode)

  ;; Enable aggressive-indenting.
  (aggressive-indent-mode t)

  ;; Enable flymake-mode
  (flymake-mode t)
  ;; show diagnostics.
  ;;(flymake-show-buffer-diagnostics)


;;;;; IDE layout

  ;; Provide a function to set the fill column indicator.
  ;; This has a default of 80 but can be set on a per mode basis.
  ;; Set the preferred fill column indicator for the mode and activate it.
  
  (setq display-fill-column-indicator-column 80)                                  ; comment indicator column visual prompt
  (setq fill-column  80)                                                          ; Column beyond which line wrapping occurs if it is activated. 
  (setq comment-fill-column 260)                                                  ; Column to use for 'comment-indent'. If nil, use 'fill-column' instead. 
  (setq comment-column 82)                                                        ; Column to indent right-margin comments to. 
  (display-fill-column-indicator-mode 1)                                          ; show the visual prompt. 

;;;;;; Set up outline

  ;; Set up customizations for outline-minor-mode.
  (setq-local outline-minor-mode-use-buttons 'in-margins)                         ; Show buttons
  (setq-local outline-blank-line t)                                               ; Blank line before headers
  (setq-local outline-minor-mode-highlight 'override)                                     ; Font-lock outlines
  
  (setq-local outline-regexp "^[[:space:]]*;;;+")                                              ; Match `;;;`
  (setq-local outline-start ";;")                                                 ; Start marker
  (setq-local outline-level #'my-outline-mode/outline-level)                      ; Custom level function
  (outline-minor-mode 1)                                                          ; Use outline-minor-mode

;;;;; IDE functionality map

  ;; compiling the code (Not applicable)
  ;; (keymap-set python-ts-mode-map "C-c C-c C-u" #)
  (keymap-set emacs-lisp-mode-map "C-c c f" #'elisp-byte-compile-file)

  ;;compile buffer but don't write
  (keymap-set emacs-lisp-mode-map "C-c c b" #'elisp-byte-compile-buffer)

  ;; debugging the code tbc
  (keymap-set emacs-lisp-mode-map "C-c C-c C-k" #'edebug-defun)

  ;; checking the documentation
  ;; checkdoc

  ;; document thing at point:
  (keymap-set emacs-lisp-mode-map "C-c C-c C-r" #'eldoc)

  ;; testing (tbd)
  ;; (keymap-set python-ts-mode-map "C-c C-c C-t"
  ;; #'projectile-test-project)

  ;; running the code
  (keymap-set emacs-lisp-mode-map "C-c r b" #'eval-buffer)

  ;; run an inferior elisp process
  (keymap-set emacs-lisp-mode-map "C-c r p" #'ielm)

  ;; formatting
  (keymap-set emacs-lisp-mode-map "C-c C-f" #'elisp-autofmt-buffer)

  ;; fix whitespace
  (keymap-set emacs-lisp-mode-map "C-c C-w" #'whitespace-cleanup)

  ;;; Errors/linting

  ;; list errors in buffer
  (keymap-set emacs-lisp-mode-map "C-c e b" #'flymake-show-buffer-diagnostics)
  ;; list errors in mini-buffer
  (keymap-set emacs-lisp-mode-map "C-c e m" #'consult-flymake)
  ;; list errors in project
  (keymap-set
   emacs-lisp-mode-map "C-c e p" #'flymake-show-project-diagnostics)
  ;; formatting errors (not applicable)
  ;; na
  ;; go to next error
  (keymap-set emacs-lisp-mode-map "C-c e n" #'flymake-goto-next-error)
  ;; go to previous error.
  (keymap-set emacs-lisp-mode-map "C-c e p" #'flymake-goto-prev-error)


  ;;; variable/function references

  ;; xref-find-definitions
  (keymap-set emacs-lisp-mode-map "M-." #'xref-find-definitions)
  ;; xref-find-references
  (keymap-set emacs-lisp-mode-map "M-r" #'xref-find-references)
  ;; xref-find-assignments
  ;; na

  ;; add-missing-dependencies
  ;; na


  ;; The below function is for use in writing and debugging elisp.
  (defun my/debug (msg)
    "Use this function in elisp code to trigger a debug statement with
a message telling you which statement you are at."
    (message "At %s" msg)
    (debug)))

;;(add-hook 'python-ts-mode-hook #'my/python-start-or-switch-to-shell)
(add-hook 'emacs-lisp-mode-hook #'my-lang/elisp-mode-setup)
;; ensure that the custom function in init.el is used for flymake to debug
;; Emacs lisp.
;; (add-hook 'emacs-lisp-mode-hook
;;           (lambda ()
;;             (setq-local flymake-diagnostic-functions
;;                         '(elisp-flymake-byte-compile-with-packages))))

;;; Common Lisp

(with-eval-after-load 'sly
  ;; Uncomment and update if you need to set the path to an
  ;; implementation of common lisp. This would be needed only if you
  ;; have multiple instances of common lisp installed, for example,
  ;; both CLISP and SBCL. In this case, we are assuming SBCL.
  ;; (setq inferior-lisp-program "/usr/bin/sbcl")
  (require 'sly-quicklisp "sly-quicklisp" :no-error)
  (require 'sly-repl-ansi-color "sly-repl-ansi-color" :no-error)
  (require 'sly-asdf "sly-asdf" :no-error)

  (defun my-lang/sly-mode-setup()
    (sly-editing-mode))

  (add-hook 'lisp-mode-hook #'my-lang/sly-mode-setup))
    

;;; Clojure
(with-eval-after-load "clojure-mode"
  (require 'cider "cider" :no-error)
  (require 'clj-refactor "clj-refactor" :no-error)

  (defun my-lang/clojure-mode-setup ()
    "Load `clj-refactor' toooling and fix keybinding conflicts with cider."
    (when (locate-library "clj-refactor")
      (clj-refactor-mode 1)
      ;; keybindings mentioned on clj-refactor github page
      ;; conflict with cider, use this by default as it does
      ;; not conflict and is a better mnemonic
      (cljr-add-keybindings-with-prefix "C-c r")))
  (add-hook 'clojure-mode-hook #'my-lang/clojure-mode-setup)

  (with-eval-after-load "flycheck"
    (flycheck-clojure-setup)))

;;; Scheme and Racket
;; The default is "scheme" which is used by cmuscheme, xscheme and
;; chez (at least). We are configuring guile, so use the apporpriate
;; command for that implementation.
(customize-set-variable 'scheme-program-name "guile")


(provide 'lang-lisp)
;;; lang-lisp.el ends here

                                                                                  ; LocalWords:  codeberg ui
