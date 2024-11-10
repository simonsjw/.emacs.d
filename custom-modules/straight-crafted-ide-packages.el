;;; straight-crafted-ide-packages.el --- packages for IDE functionality -*- lexical-binding: t; -*-

;; Copyright (C) 2023
;; SPDX-License-Identifier: MIT

;; Author: System Crafters Community

;;; Commentary:
;; A selection of packages to provide functionality for the UI.

;; Eglot has been built-in since Emacs 29.

;;; Code:

(use-package which-key
  :straight (:type git
                   :flavor melpa
                   :host github :repo "justbur/emacs-which-key")
  :config
  (which-key-mode))

;; editorconfig is a cross-editor/ide configuration tool to control
;; indentation, spaces vs tabs, etc.
(use-package editorconfig
  :delight
  :straight (:type git
                   :flavor melpa
                   :host github
                   :repo "editorconfig/editorconfig-emacs"))

;; a minor mode to always keep your code indented while editing blocks of code.
(use-package aggressive-indent
  :straight (:type git
                   :flavor melpa
                   :host github
                   :repo "Malabarba/aggressive-indent-mode"))

;; Jump to the definition of a function. Works using oldskool
;; rgrep type approaches. (No fancy tree-sitter here!)
;; https://github.com/jacktasia/dumb-jump
(use-package dumb-jump
  :straight (:type git
                   :flavor melpa
                   :host github
                   :repo "jacktasia/dumb-jump"))

;; Get some yasnippets installed.
;; https://github.com/AndreaCrotti/yasnippet-snippets
(use-package yasnippet-snippets
  :straight (:type git
                   :flavor melpa
                   :files ("*.el" "snippets" ".nosearch"
                           "yasnippet-snippets-pkg.el")
                   :host github
                   :repo "AndreaCrotti/yasnippet-snippets"))

(use-package persistent-scratch
  :straight (:type git
                   :flavor melpa
                   :host github
                   :repo "Fanael/persistent-scratch"))

(provide 'straight-crafted-ide-packages)
;;; straight-crafted-ide-packages.el ends here

                                        ; LocalWords:  dape cwd fn gud
