;;; crafted-ui-packages.el --- Packages to improve the Emacs UI.  -*- lexical-binding: t; -*-
;; Copyright (C) 2022
;; SPDX-License-Identifier: MIT

;; Author: System Crafters Community

;;; Commentary:

;; Packages to configure with `crafted-ui-config.el'

;;; Code:
;;; packages

;; here we use a direct load of info+.el since use-package
;; throws up an error.
;; (load (expand-file-name
;;        "custom-packages/info+.el" user-emacs-directory))
(use-package bookmark+)
(use-package dired+)
(use-package info+)
(use-package imenu-list)
(use-package elisp-demos)

;; Get Bufler the recursive buffer grouping package
(use-package bufler)

;; docs in windows over code.
(use-package eldoc-box)

;; (straight-use-package 'tabspaces)
;; This groups whole frames under a tab as opposed to tab-line which
;; adds a tab to windows with multiple buffers.

;; Burly - save and restore desktop layouts.
(use-package burly)

(provide 'straight-crafted-ui-packages)
;;; straight-crafted-ui-packages.el ends here
