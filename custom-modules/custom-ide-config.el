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


;; ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
;; eglot setup
;; -----------

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
  (add-to-list 'eglot-server-programs
               '((python-mode python-ts-mode)
                 "basedpyright-langserver" "--stdio"))


  ;; ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
  ;; Documentation/help setup
  ;; -----------
  ;; use eldoc-box-hover-mode.
  (add-hook 'eglot-managed-mode-hook #'eldoc-box-hover-at-point-mode)

  ;; the below stops eldoc-box showing up if not explicitly requested.
  (add-to-list 'eglot-ignored-server-capabilites :hoverProvider)
  ;; (add-hook 'after-save-hook 'eglot-format)
  )

;; ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
;; TAB control for comments
;; -----------

(defun my-ide/tab-for-comments ()
  "Enhanced TAB behavior for handling comments.

Runs `comment-indent` when the cursor is on a line with a comment.
Otherwise, delegates to the default TAB behavior for the active mode."
  (interactive)
  (if (save-excursion
        (let ((line-end (line-end-position)))
          (comment-search-forward line-end t)))
      ;; If a comment is found on this line, use `comment-indent`
      (comment-indent)
    ;; Otherwise, fall back to the default TAB command
    (let ((command (key-binding (kbd "TAB"))))
      (if (and command (not (eq command 'my-tab-adaptive)))
          (call-interactively command)
        (indent-for-tab-command)))))


;; Apply this function to specific modes or globally if desired
(defun my-ide/tab-for-comments-setup ()
  "Set up enhanced TAB behavior for programming modes."
  (local-set-key (kbd "TAB") 'my-ide/tab-for-comments))

;;(add-hook 'prog-mode-hook #'my-ide/tab-for-comments-setup)

;; ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
;; editorconfig setup.
;; -----------

;; turn on editorconfig if it is available
(when (require 'editorconfig nil :noerror)
  (add-hook 'prog-mode-hook #'editorconfig-mode))


(provide 'custom-ide-config)
;;; custom-ide-config.el ends here


                                                                                  ; LocalWords:  eglot dape ide cEnter basepyright
