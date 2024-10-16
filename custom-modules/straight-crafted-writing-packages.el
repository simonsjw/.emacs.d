;;;; straight-crafted-writing-packages.el --- Packages used for writing  -*- lexical-binding: t; -*-

;; Copyright (C) 2023
;; SPDX-License-Identifier: MIT

;; Author: System Crafters Community

;;; Commentary:

;; Packages used for writing different kinds of documents.

;;; Code:
(require 'straight)

;; Markdown support
(straight-use-package
 '(markdown-mode :type git
                 :flavor melpa
                 :host github
                 :repo "jrblevin/markdown-mode"))

;; lint markdown in flymake if markdownlint-cli is installed. 
(straight-use-package
 '(flymake-markdownlint :type git
                        :flavor melpa
                        :host github
                        :repo "shaohme/flymake-markdownlint"))

(straight-use-package
 '(pandoc-mode :type git
               :flavor melpa
               :host github
               :repo "joostkremers/pandoc-mode"))

(straight-use-package
 '(olivetti :type git
            :flavor melpa
            :host github
            :repo "rnkn/olivetti"))

;; PDF support
(straight-use-package
 '(pdf-tools :type git
             :flavor melpa
             :files (:defaults "README"
                               ("build" "Makefile")
                               ("build" "server")
                               "pdf-tools-pkg.el")
             :host github
             :repo "vedang/pdf-tools"))
 
;; LaTeX support - uses Auctex
;; only install and load auctex when the latex executable is found,
;; otherwise it crashes when loading
(when (executable-find "latex")
  (straight-use-package
   '(auctex :type git
            :host github
            :repo "emacs-straight/auctex"
            :files ("*" (:exclude ".git")))))
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
  (straight-use-package
   '(auctex-latexmk :type git
                    :flavor melpa
                    :host github
                    :repo "emacsmirror/auctex-latexmk")))

(require 'custom-logging-config)


(provide 'straight-crafted-writing-packages)
;;; straight-crafted-writing-packages.el ends here
