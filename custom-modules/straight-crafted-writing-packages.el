;;;; straight-crafted-writing-packages.el --- Packages used for writing  -*- lexical-binding: t; -*-

;; Copyright (C) 2023
;; SPDX-License-Identifier: MIT

;; Author: System Crafters Community

;;; Commentary:

;; Packages used for writing different kinds of documents.

;;; Code:
(require 'straight)

;; Markdown support
(use-package markdown-mode
  :straight (:type git
                   :flavor melpa
                   :host github
                   :repo "jrblevin/markdown-mode"))

;; lint markdown in flymake if markdownlint-cli is installed. 
(use-package flymake-markdownlint 
  :straight (:type git
                   :flavor melpa
                   :host github
                   :repo "shaohme/flymake-markdownlint"))

(use-package pandoc-mode 
  :straight (:type git
                   :flavor melpa
                   :host github
                   :repo "joostkremers/pandoc-mode"))

(use-package olivetti
  :straight (:type git
                   :flavor melpa
                   :host github
                   :repo "rnkn/olivetti"))

;; PDF support
(use-package pdf-tools
  :straight (:type git
                   :flavor melpa
                   :host github
                   :repo "vedang/pdf-tools")
  :config
  (pdf-tools-install))
 
;; LaTeX support - uses Auctex
;; only install and load auctex when the latex executable is found,
;; otherwise it crashes when loading
(when (executable-find "latex")
  (use-package auctex
    :straight (:type git
                     :host github
                     :repo "emacs-straight/auctex")))
;; Install the auctex-latexmk package when the latex and latexmk
;; executable are found.
;;
;; This package contains a bug which might make it crash during loading
;; (with a bug related to tex-buf) on newer systems.
;;
;; If you encounter the bug, you should uninstall this package, then
;; you can install a fix (not on melpa) with the following recipe,
;; and the configuration in this file will still work
;;
;; (N.B. the recipe is for straight.el, but can be modified for use with Emacs
;;       29 package-vc, quelpa.el, or other \"from source\" package
;;       managers.)
;;
;; '(auctex-latexmk :fetcher git :host github :repo \"wang1zhen/auctex-latexmk\")
(when (and (executable-find "latex")
           (executable-find "latexmk"))
  (use-package auctex-latexmk
    :straight (:type git
                     :flavor melpa
                     :host github
                     :repo "emacsmirror/auctex-latexmk")))

(use-package citar
  :straight(:type git
                  :flavor melpa
                  :files (:defaults
                          (:exclude "citar-embark.el")
                          "citar-pkg.el")
                  :host github
                  :repo "emacs-citar/citar")
  :custom
  (citar-bibliography (list (getenv "BIB_HOME")))  ;; Wrap in `list` to ensure it's a list
  :hook
  (LaTeX-mode . citar-capf-setup)
  (org-mode . citar-capf-setup))

(use-package citar-embark
  :straight (:type git
                   :flavor melpa
                   :files ("citar-embark.el" "citar-embark-pkg.el")
                   :host github :repo "emacs-citar/citar")
  :after citar embark
  :no-require
  :config (citar-embark-mode))

(provide 'straight-crafted-writing-packages)
;;; straight-crafted-writing-packages.el ends here
