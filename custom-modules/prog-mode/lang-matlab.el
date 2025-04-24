;;; lang-matlab.el --- python support for the crafted setup   -*- lexical-binding: t; -*-

;;; Commentary:

;; A starter config for editing Matlab code.
;;
;; Prerequisites:
;;
;; - Matlab installation.


;;; Package phase
(use-package matlab-mode)



;;; Code:

(declare-function matlab-shell "matlab-mode")

(declare-function yas-minor-mode "yasnippet")
;;(declare-function treesit-fold-mode "treesit-fold")
;;(declare-function treesit-fold-indicators-mode "treesit-fold")

(declare-function my-outline-mode/outline-level "ui-config")

;;; Configuration phase


;;;; settings for matlab-mode.
(defun my-lang/matlab-mode-setup ()
  "Central function to hook into `python-mode' for python functionality."
  (message
   "[%s ; DEBUG; my-lang/matlab-mode-setup]starting loading the defun ; ;"
   (current-time-string))


   ;;;;; Set up outline

  ;; Set up customisations for outline-minor-mode.
  (setq-local outline-minor-mode-use-buttons 'in-margins)                         ; Show buttons
  (setq-local outline-blank-line t)                                               ; Blank line before headers
  (setq-local outline-minor-mode-highlight t)                                     ; Font-lock outlines
  (setq-local outline-regexp "^[[:space:]]*%%+")                                  ; Match `##' and more.
  (setq-local outline-start "%")                                                  ; Start marker
  (setq-local outline-level #'my-outline-mode/outline-level)                      ; Custom level function
  (outline-minor-mode 1)                                                          ; Use outline-minor-mode

   ;;;;; Folding

  ;; Set the fringe mode for python-ts-mode folding.
  (set-fringe-mode '(12 . 12))
  
  ;; Enable treesit-fold-mode
  ;; (treesit-fold-mode 1)
  ;; Enable treesit-fold-indicators-mode
  ;; (treesit-fold-indicators-mode 1)

  ;; You will probably want to tweak this variable, it determines how
  ;; quickly the completion prompt provides LSP suggestions when
  ;; typing. Be careful if you set it to 0 in a large project!
  (customize-set-variable 'corfu-auto-delay 0.25)

  ;; Enable Anaconda mode for Python code navigation and documentation
  ;; (anaconda-mode)

  ;; Do not enable blacken mode for automatic code formatting
  ;; (blacken-mode)

  ;; Enable isort for Python import sorting
  ;; (python-isort-on-save-mode)

  ;; Enable Ya-snippets.
  (yas-minor-mode)

  ;;;;; IDE layout
  
  ;; Provide a function to set the fill column indicator.
  ;; This has a default of 80 but can be set on a per mode basis.
  ;; Set the preferred fill column indicator for the mode and activate it.
  
  (setq display-fill-column-indicator-column 88)                                  ; comment inde
  (setq fill-column 88)                                                           ; Column beyond which line wrapping occurs if it is activated.
  (setq comment-fill-column 250)                                                  ; Column to use for wrapping comment lines.
  (setq comment-column 90)                                                        ; Column to indent right-margin comments to.

  (display-fill-column-indicator-mode 1)                                          ; show the buffer line width.

  ;;(matlab-shell)                                                                  ; ensure matlab is running.

  ;; Note that pycodestyle is set via file in directory specified by
  ;; export XDG_CONFIG_HOME="/home/simon/.emacs.d/etc/config/"
  ;; called pycodestyle with the following content:
  ;; [pycodestyle]
  ;; max-line-length = 88

  ;;;;; IDE functionality map
  
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
  ;; (keymap-set python-ts-mode-map "C-c r b" #'eval-buffer)

  ;; ;; run an inferior python process
  ;; (keymap-set python-ts-mode-map "C-c r p" #'run-python)

  ;; ;; formatting
  ;; ;; (keymap-set python-ts-mode-map "C-c C-f b" #'blacken-buffer)
  ;; ;;  (keymap-set python-ts-mode-map "C-c C-f r" #'blacken-buffer)

  ;;  ;;;;; Errors/linting

  ;; ;; list errors in buffer
  ;; (keymap-set python-ts-mode-map "C-c e b" #'flymake-show-buffer-diagnostics)
  ;; ;; list errors in minibuffer
  ;; (keymap-set python-ts-mode-map "C-c e m" #'consult-flymake)
  ;; ;; list errors in project
  ;; (keymap-set
  ;;  python-ts-mode-map "C-c e p" #'flymake-show-project-diagnostics)
  ;; ;; formatting errors (not applicable)
  ;; ;; (keymap-set python-ts-mode-map "C-c C-n" )
  ;; ;; go to next error
  ;; (keymap-set python-ts-mode-map "C-c e n" #'flymake-goto-next-error)
  ;; ;; go to previous error.
  ;; (keymap-set python-ts-mode-map "C-c e l" #'flymake-goto-prev-error)

  ;;  ;;;;; Variable/function references

  ;; ;; xref-find-definitions
  ;; ;; (keymap-set python-ts-mode-map "M-." #'anaconda-mode-find-definitions)
  ;; ;; xref-find-references
  ;; ;;  (keymap-set python-ts-mode-map "M-r" #'anaconda-mode-find-references)
  ;; ;; xref-find-assignments
  ;; ;;  (keymap-set python-ts-mode-map "M-=" #'anaconda-mode-find-assignments)

  ;;  ;;;;; add-missing-dependencies
  
  ;; (keymap-set python-ts-mode-map "C-c i f" #'python-fix-imports)
  
  (message
   "[%s ; DEBUG; my-lang/matlab-mode-setup]finished loading the defun ; ;"
   (current-time-string)))

;; associate .m file with the matlab-mode (major mode)
(add-to-list 'auto-mode-alist '("\\.m$" . matlab-mode))

;; setup matlab-shell (assumes that matlab is in the PATH).
(setq matlab-shell-command "matlab")
(setq matlab-shell-command-switches (list "-nodesktop"))

;; linting Matlab code. 
;; setup mlint for warnings and errors highlighting
;;(add-to-list 'mlint-programs "/usr/local/MATLAB/R2024b/bin/glnxa64/mlint")        ; add mlint program for linux

(setq matlab-show-mlint-warnings t)                                               ; show linting warnings by default.

;; finally, ensure that any non-standard shebangs are covered. This overrides
;; interpreter-mode-alist. The difference is that interpreter-mode-alist
;; matches strictly the interpreter at the end of the shebang. Magic-mode-alist
;; can match any regular expression against the first line in a file.
(add-to-list 'magic-mode-alist
             '((lambda ()
                 (looking-at "^#!.*matlab")) . matlab-mode))

;; hooks:
(add-hook 'matlab-mode-hook #'my-lang/matlab-mode-setup)

(provide 'lang-matlab)
;;; lang-matlab.el ends here

;; LocalWords:  pyvenv isort numpydoc el CONDA WORKON ENV serviceEnv lang keymap
;; LocalWords:  eldoc defun minibuffer pycodestyle pycomplete gitlab melpa maci
;; LocalWords:  pythonic dape yasnippet debugpy adapter customisations ui macOS
;; LocalWords:  matlab nodesktop mlint linux glnxa
