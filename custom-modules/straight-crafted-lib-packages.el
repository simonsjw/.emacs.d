;;; crafted-crafted-lib-packages.el -*- lexical-binding: t; -*-

;; Copyright (C) 2022
;; SPDX-License-Identifier: MIT

;; Author: System Crafters Community

;;; Commentary:

;; Packages to provide base libraries extending emacs functionality.

;;; Code:

;; dash.el: A modern list API for Emacs. No 'cl required.
(use-package dash
  :straight (:type git :host github :repo "magnars/dash.el"))

;; The long lost Emacs string manipulation library.
(use-package s
  :straight (:type git :host github :repo "magnars/s.el"))

;; (use-package pkg-info
;;   :straight (:type git
;;                    :flavor melpa
;;                    :host github
;;                    :repo "emacsorphanage/pkg-info"))

(use-package jump
  :straight (:type git :host github :repo "eschulte/jump.el"))

(provide 'straight-crafted-lib-packages)
;;; straight-crafted-lib-packages.el ends here
