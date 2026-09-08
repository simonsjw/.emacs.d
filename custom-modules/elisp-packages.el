;;; elisp-packages.el --- Bootstrap dash, s, and jump. -*- lexical-binding: t; -*-

;; Copyright (C) 2026 Simon Watson
;; SPDX-License-Identifier: MIT

;; Author: Simon Watson

;;; Commentary:

;; Bootstrap third-party Elisp libraries used across the tree:
;; `dash', `s', and `jump'.  Keep these three; do not remove them as a
;; drive-by cleanup.  Load from `init.el' after `logging-config'.
;;
;; Map:
;;   Feature:    elisp-packages
;;   Load-after: path-support logging-config
;;   Load-phase: bootstrap
;;   Keymaps:    none
;;   Docs:       docs/elisp-packages.org
;;   OS:         none

;;; Code:

(require 'path-support)
(require 'logging-config)
(log/debug :fn 'elisp-packages
           :msg "Starting load of the elisp-packages module."
           :obj t)

;;;; dash.el: A modern list API for Emacs. No 'cl required.
(use-package dash)

;;;; The long lost Emacs string manipulation library.
(use-package s)

;; (use-package pkg-info)

(use-package jump)
(log/debug :fn 'elisp-packages
           :msg "Finishing load of the elisp-packages module."
           :obj t)

(provide 'elisp-packages)
;;; elisp-packages.el ends here.
