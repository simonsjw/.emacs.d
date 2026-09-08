;;; lang-web.el --- apache-mode, robots-txt-mode, and web-mode. -*- lexical-binding: t; -*-

;; Copyright (C) 2026 Simon Watson
;; SPDX-License-Identifier: MIT

;; Author: Simon Watson

;;; Commentary:

;; Language module for web-related modes: Apache config,
;; robots.txt, and `web-mode'.  Completion uses CAPF / Corfu, not
;; company-mode.
;;
;; Map:
;;   Feature:    lang-web
;;   Load-after: path-support logging-config
;;   Load-phase: lang
;;   Keymaps:    none
;;   Docs:       docs/lang-web.org
;;   OS:         none

;;; Code:

;;; Packages phase
(require 'path-support)
(require 'logging-config)
(log/debug :fn 'lang-web
           :msg "Starting load of the lang-web module."
           :obj t)

(use-package apache-mode)                                                         ; apache-mode: Emacs major mode for editing Apache HTTP Server configuration files.
(use-package robots-txt-mode)                                                     ; Emacs major mode for editing robots.txt. This mode supports well-known extension by Google and RFC Draft.
(use-package web-mode)                                                            ; format multiple modes in the same buffer; (HTML, javascript, php etc)

;;; Configuration phase

;; set up web mode
(require 'web-mode)
(add-to-list 'auto-mode-alist '("\\.phtml\\'" . web-mode))
(add-to-list 'auto-mode-alist '("\\.tpl\\.php\\'" . web-mode))
(add-to-list 'auto-mode-alist '("\\.[agj]sp\\'" . web-mode))
(add-to-list 'auto-mode-alist '("\\.as[cp]x\\'" . web-mode))
(add-to-list 'auto-mode-alist '("\\.erb\\'" . web-mode))
(add-to-list 'auto-mode-alist '("\\.mustache\\'" . web-mode))
(add-to-list 'auto-mode-alist '("\\.djhtml\\'" . web-mode))


(log/debug :fn 'lang-web
           :msg "Finishing load of the lang-web module."
           :obj t)

(provide 'lang-web)
;;; lang-web.el ends here
