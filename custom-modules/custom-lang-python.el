;;; custom-lang-python.el --- python support for the crafted setup   -*- lexical-binding: t; -*-

;;; Commentary:

;; A starter config for editing Python code.
;;
;; This configuration provides syntax highlighting via tree sitter
;; (with python-ts-mode), LSP code completion via Eglot and Corfu, and
;; some helpful keybindings for python tooling.
;;
;; Prerequisites:
;;
;; - Emacs with Tree Sitter installed (this comes with Emacs 29).
;;
;; - A Python language server (e.g. pyls or pyright).

;; Python development environment configuration.  Several python
;; packages can be installed with `pip'.  Many of these are needed by
;; the Emacs packages used in this configuration.

;; * autopep8      -- automatically formats python code to conform to
;;                    PEP 8 style guide
;; * black         -- uncompromising code formatter
;; * flake8        -- style guide enforcement
;; * importmagic   -- automatically add, remove, manage imports
;; * ipython       -- interactive python shell
;; * yapf          -- formatter for python code

;; Emacs packages to support python development:
;; * anaconda      -- code navigation, documentation and completion
;; * blacken       -- buffer formatting on save using black
;;                    (need to pip install black)
;; * eglot         -- language server integration
;;                    (need to pip install pyright)
;; * numpydoc      -- python doc templates, uses `yasnippets'
;; * pythonic      -- utility packages for running python in different
;;                    environments (dependency of anaconda)
;; * pyvenv        -- virtualenv wrapper


;;; Packages phase
(require 'eglot)
;; (require 'major-mode-hydra)


(defvar dape-configs)                                                             ; list of configs by language for the debugger.
(defvar py-comment-fill-column)
(defvar py-docstring-fill-column)
(defvar python-indent-offset)
(defvar pyvenv-virtual-env-name)
(defvar python-shell-interpreter)
(defvar python-ts-mode-map)

(declare-function reformatter-define "reformatter")
(declare-function yas-minor-mode "yasnippet")
(declare-function treesit-fold-mode "treesit-fold")
(declare-function treesit-fold-indicators-mode "treesit-fold")
(declare-function pyvenv-activate pyvenv)

(declare-function python-shell-switch-to-shell "python")
(declare-function python-shell-send-buffer "python")
(declare-function python-shell-send-region "python")
(declare-function python-shell-send-string "python")
(declare-function python-shell-get-process "python")
(declare-function python-shell-restart "python")
(declare-function python-shell-send-defun "python")


(declare-function consult-flymake "consult-flymake")
(declare-function consult-projectile "consult-projectile")

(declare-function projectile-find-references "projectile")

(declare-function anaconda-mode-find-definitions "anaconda-mode")
(declare-function anaconda-mode-find-references "anaconda-mode")
(declare-function anaconda-mode-find-assignments "anaconda-mode")
(declare-function anaconda-mode-show-doc "anaconda-mode")

(declare-function eldoc-box-hover-mode "eldoc-box")

;; (use-package python-mode
;;   :straight (:type git
;;                    :flavor melpa
;;                    :files ("python-mode.el"
;;                            ("completion"
;;                             "completion/pycomplete.*")
;;                            "python-mode-pkg.el")
;;                    :host gitlab
;;                    :repo "python-mode-devs/python-mode"))

(use-package pythonic)
(use-package pyvenv)
(use-package anaconda-mode)
(use-package numpydoc)

;; Although this setup uses the tree sitter mode (python-ts-mode) for
;; Python language buffers, we still want to have the official
;; python-mode around so we can use its various commands.
;;(straight-use-package 'python-mode)

;;(setq major-mode-remap-alist
;;     '((python-mode . python-ts-mode)))

;;; Code:
(defun my-lang-python/remove-anaconda-paths (path-list)
  "Remove any Anaconda-related paths from PATH-LIST."
  (cl-remove-if (lambda (path)     ; changed from remove-if
                  (let ((conda-home (getenv "CONDA_PREFIX")))
                    (string-prefix-p (concat conda-home "/") path)))
                path-list))

(defun my-lang-python/update-python-path ()
  "Dynamically update Emacs the path to python in `exec-path' and PATH.

This function removes any Anaconda-related paths from `exec-path' and
PATH, then adds the path of the currently activated Python
environment.
This ensures that `exec-path' and PATH only contain the path for the
active environment."

  ;; Retrieve the name of the currently activated virtual environment.
  (let ((env-name pyvenv-virtual-env-name))
    (when env-name  ;; Check if an environment is actually activated.
      ;; Get the WORKON_HOME environment variable
      (let ((workon-home (getenv "WORKON_HOME")))
        ;; Check if WORKON_HOME is set
        (if workon-home
            ;; Construct the path to the 'bin' directory of the
            ;; activated environment.
            (let ((env-path (concat workon-home "/" env-name "/bin")))
              ;; Update exec-path and PATH with new environment path.
              (setq exec-path (append (list env-path) exec-path))
              (setenv "PATH" (concat env-path ":" (getenv "PATH"))))
          (message "WORKON_HOME environment variable is not set")))

      ;; Reconnect Eglot if it is running
      ;; (let ((server (eglot-current-server)))
      ;;   (when server
      ;;     (eglot-reconnect server)))
      )))


(defun my-lang-python/start-or-switch-to-python-shell ()
  "Start a python process or switch to an existing one."
  (unless (python-shell-get-process)
    (run-python python-shell-interpreter t))
  (python-shell-switch-to-shell))

;;; Configuration phase

;; These defaults for python home environment are set
;; in serviceEnv.txt.
;; "CONDA_PREFIX"
;; "CONDA_DEFAULT_ENV"
;; "WORKON_HOME"

;; ensure custom settings are loaded.
(when (and custom-file (file-exists-p custom-file))
  (load custom-file nil :nomessage))


;; Now ensure that pyvenv is pointing at the 'base' environment.
;; To access the other environments in the env folder, pyvenv will
;; source the directories in WORKON_HOME.
(let ((conda-home (getenv "CONDA_PREFIX")))
  (pyvenv-activate conda-home))

;; Make sure that files with the suffix .p are recognised as python
;; files.

(add-to-list 'auto-mode-alist '("\\.p\\'" . python-ts-mode))
(add-to-list 'auto-mode-alist '("\\.py\\'" . python-ts-mode))

;; settings for python-mode.
(defun my-lang-python/python-mode-setup ()
  "Central function to hook into `python-mode' for python functionality."
  (message
   "[%s ; DEBUG; my-lang-python/python-mode-setup]starting loading the defun ; ;"
   (current-time-string))

  (require 'projectile)
  (require 'treesit-fold)
  (require 'eldoc)
  (require 'pythonic)
  (require 'anaconda-mode)
  (require 'numpydoc)
  (require 'pyvenv)
  (require 'eldoc-box)
  (require 'dape)
  (require 'reformatter)

  ;; enable eldoc-mode.
  (eldoc-mode 1)
  
  ;; start up Eglot in this mode.
  (eglot-ensure)

  ;; enable python anaconda env management.
  (pyvenv-mode)
  
  (my-lang-python/update-python-path)
  
  ;; switch on hover at point mode.
  ;;(eldoc-box-hover-at-point-mode nil)
  ;;(eldoc-box-help-at-point)

  (reformatter-define python-format
    :program "ruff"
    :args '("format")
    :lighter " PF")  ; remove ref on modeline.

  ;;;;;; Set up outline
  ;;     --------------
  ;; Set up customizations for outline-minor-mode.
  (setq-local outline-minor-mode-use-buttons 'in-margins)                         ; Show buttons
  (setq-local outline-blank-line t)                                               ; Blank line before headers
  (setq-local outline-minor-mode-highlight t)                                     ; Font-lock outlines
  (setq-local outline-regexp "##+")                                              ; Match `;;;`
  (setq-local outline-start "#")                                                 ; Start marker
  (setq-local outline-level #'my-outline-mode/outline-level)                      ; Custom level function
  (outline-minor-mode 1)                                                          ; Use outline-minor-mode


  ;;;;;; Folding
  ;;     -------
  ;; Set the fringe mode for python-ts-mode folding.
  (set-fringe-mode '(12 . 12))
  ;; Enable ts-fold-mode
  (treesit-fold-mode 1)
  ;; Enable treesit-fold-indicators-mode
  (treesit-fold-indicators-mode 1)


  ;; You will probably want to tweak this variable, it determines how
  ;; quickly the completion prompt provides LSP suggestions when
  ;; typing. Be careful if you set it to 0 in a large project!
  (customize-set-variable 'corfu-auto-delay 0.25)

  ;; Enable Anaconda mode for Python code navigation and documentation
  ;;(anaconda-mode)

  ;; Do not enable blacken mode for automatic code formatting
  ;; (blacken-mode)

  ;; Enable isort for Python import sorting
  ;;(python-isort-on-save-mode)

  ;; Enable Ya-snippets.
  (yas-minor-mode)

  ;; Add my/update-python-path function to pyvenv activation.
  (add-hook 'pyvenv-post-activate-hooks 'my-lang-python/update-python-path)

  ;;; IDE layout
  ;;  ----------
  ;; Provide a function to set the fill column indicator.
  ;; This has a default of 80 but can be set on a per mode basis.
  ;; Set the preferred fill column indicator for the mode and activate it.
  
  (setq display-fill-column-indicator-column 88)                                  ; comment inde
  (setq fill-column 88)                                                           ; Column beyond which line wrapping occurs if it is activated.
  (setq comment-fill-column 270)                                                  ; Colujmn to use for 'comment-indent'. If nil, use 'fill-column' instead.
  (setq py-comment-fill-column 270)
  (setq comment-column 90)                                                        ; Column to indent right-margin comments to.
  (setq py-docstring-fill-column 88)                                              ; Set docstrings to have same fill column as code.
  (setq python-indent-offset 4)                                                   ; Set the indent for python mode.

  (display-fill-column-indicator-mode 1)                                          ; show the buffer line width.

  (dape-active-mode)                                                              ; ensure dape mode is active.

  ;; Note that pycodestyle is set via file in directory specified by
  ;; export XDG_CONFIG_HOME="/home/simon/.emacs.d/etc/config/"
  ;; called pycodestyle with the following content:
  ;; [pycodestyle]
  ;; max-line-length = 88

  ;; Start python interpreter
  ;;  (my-lang-python/start-or-switch-to-python-shell)

  ;; ---------------------
  ;; IDE functionality map
  ;; ---------------------

  ;; compiling the code (Not applicable)
  ;; (keymap-set python-ts-mode-map "C-c C-c C-u" #)

  ;; debugging the code tbc
  ;; (keymap-set python-ts-mode-map "C-c C-c C-k" #)

  ;; document thing at point:
  ;; (keymap-set python-ts-mode-map "C-c C-c C-r" #'eldoc)
  ;;  (keymap-set python-ts-mode-map "M-?" #'anaconda-mode-show-doc)
  ;; testing (tbd)
  ;; (keymap-set python-ts-mode-map "C-c C-c C-t"
  ;; #'projectile-test-project)

  ;; running the code
  (keymap-set python-ts-mode-map "C-c r b" #'eval-buffer)

  ;; run an inferior python process
  (keymap-set python-ts-mode-map "C-c r p" #'run-python)

  ;; formatting
  ;; (keymap-set python-ts-mode-map "C-c C-f b" #'blacken-buffer)
  ;;  (keymap-set python-ts-mode-map "C-c C-f r" #'blacken-buffer)

  ;; Errors/linting
  ;; --------------
  ;; list errors in buffer
  (keymap-set python-ts-mode-map "C-c e b" #'flymake-show-buffer-diagnostics)
  ;; list errors in minibuffer
  (keymap-set python-ts-mode-map "C-c e m" #'consult-flymake)
  ;; formatting errors (not applicable)
  ;; (keymap-set python-ts-mode-map "C-c C-n" )
  ;; go to next error
  (keymap-set python-ts-mode-map "C-c e n" #'flymake-goto-next-error)
  ;; go to previous error.
  (keymap-set python-ts-mode-map "C-c e p" #'flymake-goto-prev-error)


  ;; variable/function references
  ;; ----------------------------
  ;; xref-find-definitions
  ;; (keymap-set python-ts-mode-map "M-." #'anaconda-mode-find-definitions)
  ;; xref-find-references
  ;;  (keymap-set python-ts-mode-map "M-r" #'anaconda-mode-find-references)
  ;; xref-find-assignments
  ;;  (keymap-set python-ts-mode-map "M-=" #'anaconda-mode-find-assignments)


  ;; add-missing-dependencies
  (keymap-set python-ts-mode-map "C-c i f" #'python-fix-imports)
  

  ;; "Test"
  ;; (("t" ert "prompt")
  ;;  ("T" (ert t) "all")
  ;;  ("F" (ert :failed) "failed"))))

  (message
   "[%s ; DEBUG; my-lang-python/python-mode-setup]finished loading the defun ; ;"
   (current-time-string)))

(add-hook 'python-ts-mode-hook #'my-lang-python/python-mode-setup)

(provide 'custom-lang-python)
;;; custom-lang-python.el ends here

                                                                                  ; LocalWords:  pyvenv isort numpydoc el CONDA WORKON ENV serviceEnv lang keymap
                                                                                  ; LocalWords:  eldoc defun minibuffer pycodestyle pycomplete gitlab melpa
                                                                                  ; LocalWords:  pythonic dape yasnippet debugpy adapter
