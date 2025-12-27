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

(provide 'elisp-packages)
;;; elisp-packages.el ends here.
