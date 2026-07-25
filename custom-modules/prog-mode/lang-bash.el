;;; lang-bash.el --- Language support for Bash scripting -*- lexical-binding: t; -*-

;;; Commentary:

;; A config for editing Bash scripts with:
;; - Enhanced syntax highlighting via bash-ts-mode (Tree-sitter)
;; - LSP code completion via Eglot (if bash-language-server is available and Eglot configured)
;; - On-the-fly syntax checking with Flymake (using shellcheck)
;;
;; Prerequisites:
;; - Emacs >= 29 with built-in Tree-sitter support
;; - bash-language-server (npm i -g bash-language-server)
;; - shellcheck


;;; Code:
(require 'path-support)
(require 'logging-config)
(log/debug :fn 'lang-bash
           :msg "Starting load of the lang-bash module."
           :obj t)
;; Always ensure flymake-shellcheck is loaded as a fallback
(use-package flymake-shellcheck
  :ensure t)

(defun my-lang/format-bash-script-with-shfmt ()
  "Format the current Bash script using shfmt."
  (interactive)
  (let ((buffer (current-buffer))
        (point (point)))
    (shell-command-on-region (point-min) (point-max) "shfmt" buffer t)
    (goto-char point)))


(defun my-lang/bash-mode-setup ()
  "Setup function for `bash-ts-mode`."

  ;; set up dape to work with the

  (require 'dape)

  ;; Use Eglot if bash-language-server is available
  (if (executable-find "bash-language-server")
      (eglot-ensure)
    (progn
      (flymake-mode)
      (flymake-shellcheck-load)))

;;;;; Set up outline

  ;; Set up customisations for outline-minor-mode.
  (setq-local outline-minor-mode-use-buttons 'in-margins)                         ; Show buttons
  (setq-local outline-blank-line t)                                               ; Blank line before headers
  (setq-local outline-minor-mode-highlight t)                                     ; Font-lock outlines
  (setq-local outline-regexp "##+")                                               ; Match `##`
  (setq-local outline-start "#")                                                  ; Start marker
  (setq-local outline-level #'my-outline-mode/outline-level)                      ; Custom level function
  (outline-minor-mode 1)                                                          ; Use outline-minor-mode

;;;;; Folding

  ;; Set the fringe mode for python-ts-mode folding.
  (set-fringe-mode '(12 . 12))

  ;; Enable treesit-fold-mode
  (treesit-fold-mode 1)
  ;; Enable treesit-fold-indicators-mode
  (treesit-fold-indicators-mode 1)


  ;; You will probably want to tweak this variable, it determines how
  ;; quickly the completion prompt provides LSP suggestions when
  ;; typing. Be careful if you set it to 0 in a large project!
  (customize-set-variable 'corfu-auto-delay 0.25)

  ;; Enable Ya-snippets.
  (yas-minor-mode 1)

;;;;; IDE layout

  ;; Provide a function to set the fill column indicator.
  ;; This has a default of 80 but can be set on a per mode basis.
  ;; Set the preferred fill column indicator for the mode and activate it.

  (setq display-fill-column-indicator-column 88)                                  ; comment indent
  (setq fill-column 88)                                                           ; Column beyond which line wrapping occurs if it is activated.
  (setq comment-fill-column 250)                                                  ; Column to use for wrapping comment lines.
  (setq comment-column 90)                                                        ; Column to indent right-margin comments to.

  (display-fill-column-indicator-mode 1)                                          ; show the buffer line width.

  (dape-active-mode)                                                              ; ensure dape mode is active.


;;;;; IDE functionality map

  ;; checking the code
  ;; (keymap-set bash-ts-mode-map "C-c C-c C-k" #'rust-check)

  ;; testing
  ;;  (keymap-set bash-ts-mode-map "C-c C-c C-t" #'rust-test)

  ;; running the code
  ;; (keymap-set bash-ts-mode-map "C-c C-c C-r" #'rust-run)

  ;; linting

  ;;  formatting
  (keymap-set bash-ts-mode-map "C-c C-f" #'my-lang/format-bash-script-with-shfmt)

  ;; list all errors

  ;; formatting errors
  ;; (keymap-set bash-ts-mode-map "C-c C-n" #'rust-goto-format-problem)

  ;; lsp-execute-code-action
  ;; - run when lsp-ui displays code action at the top of the sideline

  ;; xref-find-definitions

  ;; xref-find-references

;;;;; Errors/linting
  ;; list errors in buffer
  (keymap-set bash-ts-mode-map "C-c e b" #'flymake-show-buffer-diagnostics)
  ;; list errors in minibuffer
  (keymap-set bash-ts-mode-map "C-c e m" #'consult-flymake)
  ;; list errors in project
  (keymap-set
   bash-ts-mode-map "C-c e p" #'flymake-show-project-diagnostics)
  ;; formatting errors (not applicable)
  ;; (keymap-set bash-ts-mode-map "C-c C-n" )
  ;; go to next error
  (keymap-set bash-ts-mode-map "C-c e n" #'flymake-goto-next-error)
  ;; go to previous error.
  (keymap-set bash-ts-mode-map "C-c e l" #'flymake-goto-prev-error)

;;;;; Variable/function references
  ;; xref-find-definitions
  ;; (keymap-set bash-ts-mode-map "M-." #'anaconda-mode-find-definitions)
  ;; xref-find-references
  ;;  (keymap-set bash-ts-mode-map "M-r" #'anaconda-mode-find-references)
  ;; xref-find-assignments
  ;;  (keymap-set bash-ts-mode-map "M-=" #'anaconda-mode-find-assignments)


  (message
   "[%s ; DEBUG; my-lang/bash-mode-setup]finished loading the defun ; ;"
   (current-time-string)))

(add-hook 'bash-ts-mode-hook 'my-lang/bash-mode-setup)


;; set mode by file extension.
(add-to-list 'auto-mode-alist '("\\.sh\\'" . bash-ts-mode))
(add-to-list 'auto-mode-alist '("\\.bashrc\\'" . bash-ts-mode))

;; if a shebang is included in the file, choose mode by the implied interpreter,
;; Note that this overrides any file extension map.
(add-to-list 'interpreter-mode-alist '("bash" . bash-ts-mode))


;; finally, ensure that any non-standard shebangs are covered. This overrides
;; interpreter-mode-alist. The difference is that interpreter-mode-alist
;; matches strictly the interpreter at the end of the shebang. Magic-mode-alist
;; can match any regular expression against the first line in a file.
(add-to-list 'magic-mode-alist
             '((lambda ()
                 (looking-at "^#!.*\\(bash\\|sh\\)")) . bash-ts-mode))

(log/debug :fn 'lang-bash
           :msg "Finishing load of the lang-bash module."
           :obj t)

(provide 'lang-bash)
;;; lang-bash.el ends here



                                                                                  ; LocalWords:  Treesit
