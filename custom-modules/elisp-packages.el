;;; elisp-packages.el --- packages to wrangle e-lisp -*- lexical-binding: t -*-

;; Copyright (C) 2025
;; SPDX-License-Identifier: MIT

;; Author: Simon Watson

;;; Commentary:

;; Packages to provide base libraries extending Emacs functionality.

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
