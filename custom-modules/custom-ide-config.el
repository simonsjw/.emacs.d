;;; custom-ide-config.el --- Provide IDE-like features -*- lexical-binding: t; -*-

;; Copyright (C) 2023
;; SPDX-License-Identifier: MIT

;; Author: System Crafters Community

;;; Commentary:

;; Eglot configuration.

;; Suggested additional keybindings
;; (with-eval-after-load "prog-mode"
;;   (keymap-set prog-mode-map "C-c e n" #'flymake-goto-next-error)
;;   (keymap-set prog-mode-map "C-c e p" #'flymake-goto-prev-error))

;;; Code:

(require 'straight)
(require 'eglot)
(require 'consult)
(require 'embark)

(require 'editorconfig)
(require 'aggressive-indent)

(declare-function consult-eglot-embark-mode "consult-eglot-embark")
(declare-function eldoc-box-hover-mode "eldoc-box-hover-mode")




;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;; eglot setup ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

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

  ;; Add the new configuration explicitly for python modes
  ;; (add-to-list 'eglot-server-programs
  ;;              '((python-mode python-ts-mode)
  ;;                "basedpyright-langserver" "--stdio"))

  ;; (add-to-list 'eglot-server-programs '(python-ts-mode . ("ruff" "server")))
  ;;  (add-hook 'python-ts-mode 'eglot-ensure)
  (add-to-list 'eglot-server-programs
               '(python-ts-mode . ("basedpyright-langserver" "--stdio")))
  


  ;; +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
  ;; Documentation/help setup
  ;; -----------
  ;; use eldoc-box-hover-mode.
  (add-hook 'eglot-managed-mode-hook #'eldoc-box-hover-at-point-mode)

  ;; the below stops eldoc-box showing up if not explicitly requested.
  (add-to-list 'eglot-ignored-server-capabilites :hoverProvider)
  ;; (add-hook 'after-save-hook 'eglot-format)
  )


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;:
;;;;;;;;;;;;;;;;;;;;;;;;;;;;; editorconfig setup. ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;:
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;:


;; turn on editorconfig if it is available
(when (require 'editorconfig nil :noerror)
  (add-hook 'prog-mode-hook #'editorconfig-mode))


(provide 'custom-ide-config)
;;; custom-ide-config.el ends here


                                                                                  ; LocalWords:  eglot dape ide cEnter basepyright
