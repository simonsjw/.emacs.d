;;; elisp-packages.el --- packages to wrangle e-lisp -*- lexical-binding: t -*-

;; Copyright (C) 2025
;; SPDX-License-Identifier: MIT

;; Author: Simon Watson

;;; Commentary:

;; Packages to provide base libraries extending Emacs functionality.

;;; Code:

;;;; dash.el: A modern list API for Emacs. No 'cl required.
(use-package dash)

;;;; The long lost Emacs string manipulation library.
(use-package s)

;; (use-package pkg-info)

(use-package jump)


;;;; package to process and display alerts.
;; https://github.com/spegoraro/org-alert
(use-package alert)

(provide 'elisp-packages)
;;; elisp-packages.el ends here.
