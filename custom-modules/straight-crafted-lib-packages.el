;;; crafted-crafted-lib-packages.el -*- lexical-binding: t; -*-

;; Copyright (C) 2022
;; SPDX-License-Identifier: MIT

;; Author: System Crafters Community

;;; Commentary:

;; Packages to provide base libraries extending emacs functionality.

;;; Code:

;; dash.el: A modern list API for Emacs. No 'cl required.
(use-package dash)

;; The long lost Emacs string manipulation library.
(use-package s)

;; (use-package pkg-info)

(use-package jump)

(provide 'straight-crafted-lib-packages)
;;; straight-crafted-lib-packages.el ends here
