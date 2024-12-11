;;; straight-crafted-ide-packages.el --- packages for IDE functionality -*- lexical-binding: t; -*-

;; Copyright (C) 2023
;; SPDX-License-Identifier: MIT

;; Author: System Crafters Community

;;; Commentary:
;; A selection of packages to provide functionality for the UI.

;; Eglot has been built-in since Emacs 29.

;;; Code:

(use-package which-key
  :config
  (which-key-mode))

;; use packages for formatting code without lsp/eglot.
(use-package reformatter)

;; use ruff for python formatting.
(use-package ruff-format)

;; editorconfig is a cross-editor/ide configuration tool to control
;; indentation, spaces vs tabs, etc.
(use-package editorconfig)
;; a minor mode to always keep your code indented while editing blocks of code.
(use-package aggressive-indent)
;; Jump to the definition of a function. Works using oldskool
;; rgrep type approaches. (No fancy tree-sitter here!)
;; https://github.com/jacktasia/dumb-jump
(use-package dumb-jump)
;; Get some yasnippets installed.
;; https://github.com/AndreaCrotti/yasnippet-snippets
(use-package yasnippet-snippets)

(provide 'straight-crafted-ide-packages)
;;; straight-crafted-ide-packages.el ends here

                                        ; LocalWords:  dape cwd fn gud
