;;; ide-config.el --- Provide IDE-like features -*- lexical-binding: t; -*-

;; Copyright (C) 2025
;; SPDX-License-Identifier: MIT

;; Author: Simon Watson

;;; Commentary:
;; A selection of packages to provide functionality for the UI.

;; Eglot has been built-in since Emacs 29.
(require 'path-support)
(require 'logging-config)
(log/debug :fn 'ide-config
           :msg "Starting load of the ide-config module."
           :obj t)


;; whichkey is now built in.
(use-package which-key
  :delight
  :ensure nil
  :config
  (setq which-key-lighter "")
  (which-key-mode))

;; editorconfig is a cross-editor/ide configuration tool to control
;; indentation, spaces vs tabs, etc.
(use-package editorconfig)
;; a minor mode to always keep your code indented while editing blocks of code.
(use-package aggressive-indent
  :delight)
;; Jump to the definition of a function. Works using oldskool
;; rgrep type approaches. (No fancy tree-sitter here!)
;; https://github.com/jacktasia/dumb-jump
(use-package dumb-jump)
;; Get some yasnippets installed.
;; https://github.com/AndreaCrotti/yasnippet-snippets
(use-package yasnippet-snippets)


;;; Code:

;; (require 'eglot)
(require 'consult)
(require 'embark)

(require 'editorconfig)
(require 'aggressive-indent)

(declare-function consult-eglot-embark-mode "consult-eglot-embark")
(declare-function eldoc-box-hover-mode "eldoc-box-hover-mode")

;;;; eglot setup

(with-eval-after-load 'eglot
  (with-eval-after-load 'embark
    (use-package consult-eglot)
    (with-eval-after-load 'consult-eglot
      (use-package consult-eglot-embark)
      (require 'consult-eglot-embark)
      (consult-eglot-embark-mode)))

  ;; Assuming python-ts-mode is the major mode for Python files
  ;; use basepyright for the language server.

  ;; Remove any existing configuration for python modes
  (setq eglot-server-programs
        (assq-delete-all 'python-mode eglot-server-programs))
  
  (setq eglot-server-programs
        (assq-delete-all 'python-ts-mode eglot-server-programs))

  ;; we are using pyrefly rather than basedpyright.
  ;; ---------------------------------------------
  ;; (add-to-list
  ;;  'eglot-server-programs
  ;;  '((python-mode python-ts-mode) . ("basedpyright-langserver" "--stdio")))

  (add-to-list
   'eglot-server-programs
   '((python-ts-mode python-mode) . ("pyrefly" "lsp")))

  (add-to-list 'eglot-server-programs `(LaTeX-mode . (,lsp-bin-texlab)))
  
  ;; If bash-language-server is installed, configure Eglot LSP for Bash
  (when (executable-find "bash-language-server")
    (add-to-list
     'eglot-server-programs
     '((bash-mode bash-ts-mode) . ("bash-language-server" "start"))))



  ;; +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
  ;; Documentation/help setup
  ;; -----------
  ;; use eldoc-box-hover-mode.
  ;;(add-hook 'eglot-managed-mode-hook #'eldoc-box-hover-at-point-mode)

  ;; the below stops eldoc-box showing up if not explicitly requested.
  ;; (add-to-list 'eglot-ignored-server-capabilites :hoverProvider)
  ;; (add-hook 'after-save-hook 'eglot-format)
  )


;;;; editorconfig setup
;;   ------------------
;; turn on editorconfig if it is available
(when (require 'editorconfig nil :noerror)
  (add-hook 'prog-mode-hook #'editorconfig-mode))


;;; Key bindings
(log/debug :fn 'ide-config
           :msg "Finishing the load of the ide-config module."
           :obj t)


(provide 'ide-config)
;;; ide-config.el ends here

