;;; custom-lang-lisp.el --- Lisp development configuration -*- lexical-binding: t; -*-

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

(require 'custom-system-tools)
(require 'straight)  ;; If `straight-use-package` is part of another package
(require 'eldoc)
(require 'yasnippet)
(require 'yasnippet-snippets)

;; Emacs Lisp
;; https://codeberg.org/ideasman42/emacs-elisp-autofmt
(straight-use-package 'elisp-autofmt)

;; Common Lisp
(straight-use-package 'sly)
(straight-use-package 'sly-asdf)
(straight-use-package 'sly-quicklisp)
(straight-use-package 'sly-repl-ansi-color)

;; Clojure
(straight-use-package 'cider)
(straight-use-package 'clj-refactor)
(straight-use-package 'clojure-mode)
(straight-use-package 'flycheck-clojure)

;; Scheme and Racket
(straight-use-package 'geiser)
(straight-use-package 'geiser-guile)
(straight-use-package 'geiser-racket)

;;; Code:

;; Global defaults
;;(require 'eldoc)


(defun elisp-flymake-byte-compile-with-packages (report-fn &rest _args)
  "A Flymake backend for elisp byte compilation.
Spawn an Emacs process that byte-compiles a file representing the
current buffer state and calls REPORT-FN when done."
  (when elisp-flymake--byte-compile-process
    (when (process-live-p elisp-flymake--byte-compile-process)
      (kill-process elisp-flymake--byte-compile-process)))
  (let ((temp-file (make-temp-file "elisp-flymake-byte-compile"))
        (source-buffer (current-buffer))
        (coding-system-for-write 'utf-8-unix)
        (coding-system-for-read 'utf-8))
    (save-restriction
      (widen)
      (write-region (point-min) (point-max) temp-file nil 'nomessage))
    (let* ((output-buffer (generate-new-buffer " *elisp-flymake-byte-compile*")))
      (setq
       elisp-flymake--byte-compile-process
       (make-process
        :name "elisp-flymake-byte-compile"
        :buffer output-buffer
        :command `(,(expand-file-name invocation-name invocation-directory)
                   "-Q"
                   "--batch"
                   ;; "--eval" "(setq load-prefer-newer t)" ; for testing
                   ,@(mapcan (lambda (path) (list "-L" path))
                             elisp-flymake-byte-compile-load-path)
                   "-f" "package-initialize"
                   "-f" "elisp-flymake--batch-compile-for-flymake"
                   ,temp-file)
        :connection-type 'pipe
        :sentinel
        (lambda (proc _event)
          (unless (process-live-p proc)
            (unwind-protect
                (cond
                 ((not (and (buffer-live-p source-buffer)
                            (eq proc (with-current-buffer source-buffer
                                       elisp-flymake--byte-compile-process))))
                  (flymake-log :warning
                               "byte-compile process %s obsolete" proc))
                 ((zerop (process-exit-status proc))
                  (elisp-flymake--byte-compile-done report-fn
                                                    source-buffer
                                                    output-buffer))
                 (t
                  (funcall report-fn
                           :panic
                           :explanation
                           (format "byte-compile process %s died" proc))))
              (ignore-errors (delete-file temp-file))
              (kill-buffer output-buffer))))
        :stderr " *stderr of elisp-flymake-byte-compile*"
        :noquery t)))))


;; aggressive indent is already activated for any prog-mode. 
;; aggressive-indent-mode for all lisp modes
;;(when (locate-library "aggressive-indent")
;;  (add-hook 'lisp-mode-hook #'aggressive-indent-mode)
;;  (add-hook 'clojure-mode-hook #'aggressive-indent-mode)
;;  (add-hook 'scheme-mode-hook #'aggressive-indent-mode))

;;; Emacs lisp
(defun my/emacs-lisp-mode-setup ()
  "Custom setup for `emacs-lisp-mode`."
  ;; You will probably want to tweak this variable, it determines how
  ;; quickly the completion prompt provides LSP suggestions when
  ;; typing. Be careful if you set it to 0 in a large project!
  (customize-set-variable 'corfu-auto-delay 0.25)

  ;; set up the autoformatting.
  (require 'elisp-autofmt)

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

  ;; Enable Ielm
  ;;(projectile-run-ielm)


  ;;; IDE layout
  ;;  ----------
  ;; set preferred buffer width
  (my-programming-mode/set-fill-column-indicator 79)


  ;;; IDE functionality map
  ;;  ---------------------
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
  ;;  --------------
  ;; list errors in buffer
  (keymap-set
   emacs-lisp-mode-map "C-c e b" #'flymake-show-buffer-diagnostics)
  ;; list errors in mini-buffer
  (keymap-set emacs-lisp-mode-map "C-c e m" #'consult-flymake)
  ;; formatting errors (not applicable)
  ;; na
  ;; go to next error
  (keymap-set emacs-lisp-mode-map "C-c e n" #'flymake-goto-next-error)
  ;; go to previous error.
  (keymap-set emacs-lisp-mode-map "C-c e p" #'flymake-goto-prev-error)


  ;;; variable/function references
  ;;  ----------------------------
  ;; xref-find-definitions
  (keymap-set emacs-lisp-mode-map "M-." #'xref-find-definitions)
  ;; xref-find-references
  (keymap-set emacs-lisp-mode-map "M-r" #'xref-find-references)
  ;; xref-find-assignments
  ;; na

  ;; add-missing-dependencies
  ;; na

  ;;; Project settings
  ;; ----------------
  ;; switch projects
  (keymap-set emacs-lisp-mode-map "C-c p p" #'consult-projectile)
  ;; list errors in project
  (keymap-set
   emacs-lisp-mode-map "C-c e p" #'flymake-show-project-diagnostics)

  ;; Find all references to the symbol in the current project.
  (keymap-set emacs-lisp-mode-map "C-c p ?" #'projectile-find-references)

  ;; The below function is for use in writing and debugging elisp.
  (defun my/debug (msg)
    "Use this function in elisp code to trigger a debug statement with
a message telling you which statement you are at."
    (message "At %s" msg)
    (debug)))

;;(add-hook 'python-ts-mode-hook #'my/python-start-or-switch-to-shell)
(add-hook 'emacs-lisp-mode-hook #'my/emacs-lisp-mode-setup)
;; ensure that the custom function in init.el is used for flymake to debug
;; Emacs lisp.
(add-hook 'emacs-lisp-mode-hook
          (lambda ()
            (setq-local flymake-diagnostic-functions
                        '(elisp-flymake-byte-compile-with-packages))))

;;; Common Lisp

(with-eval-after-load 'sly
  ;; Uncomment and update if you need to set the path to an
  ;; implementation of common lisp. This would be needed only if you
  ;; have multiple instances of common lisp installed, for example,
  ;; both CLISP and SBCL. In this case, we are assuming SBCL.
  ;; (setq inferior-lisp-program "/usr/bin/sbcl")
  (require 'sly-quicklisp "sly-quicklisp" :no-error)
  (require 'sly-repl-ansi-color "sly-repl-ansi-color" :no-error)
  (require 'sly-asdf "sly-asdf" :no-error))

(when (locate-library "sly")
  (add-hook 'lisp-mode-hook #'sly-editing-mode))

;;; Clojure
(with-eval-after-load "clojure-mode"
  (require 'cider "cider" :no-error)
  (require 'clj-refactor "clj-refactor" :no-error)

  (defun crafted-lisp-load-clojure-refactor ()
    "Load `clj-refactor' toooling and fix keybinding conflicts with cider."
    (when (locate-library "clj-refactor")
      (clj-refactor-mode 1)
      ;; keybindings mentioned on clj-refactor github page
      ;; conflict with cider, use this by default as it does
      ;; not conflict and is a better mnemonic
      (cljr-add-keybindings-with-prefix "C-c r")))
  (add-hook 'clojure-mode-hook #'crafted-lisp-load-clojure-refactor)

  (with-eval-after-load "flycheck"
    (flycheck-clojure-setup)))

;;; Scheme and Racket
;; The default is "scheme" which is used by cmuscheme, xscheme and
;; chez (at least). We are configuring guile, so use the apporpriate
;; command for that implementation.
(customize-set-variable 'scheme-program-name "guile")

(require 'custom-logging-config)


(provide 'custom-lang-lisp)
;;; custom-lang-lisp.el ends here
