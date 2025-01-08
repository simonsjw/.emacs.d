;;; straight-early-init.el --- Bootstrap straight.el  -*- lexical-binding: t; -*-

;; Copyright (C) 2023
;; SPDX-License-Identifier: MIT

;; Author: System Crafters Community

;;; Commentary:

;; Code to bootstrap straight package manager

;;; Code:

;; configure straight.el
;; See https://github.com/radian-software/straight.el#getting-started


;; straight-base-dir set previously.
;; (require 'early-init)

(defvar straight-base-dir)

(declare-function straight-use-package "straight")

(let ((bootstrap-file
       (expand-file-name
        "straight/repos/straight.el/bootstrap.el" straight-base-dir))
      (bootstrap-version 6))
  (unless (file-exists-p bootstrap-file)
    (with-current-buffer
        (url-retrieve-synchronously
         "https://raw.githubusercontent.com/radian-software/straight.el/develop/install.el"
         'silent 'inhibit-cookies)
      (goto-char (point-max))
      (eval-print-last-sexp)))
  (load bootstrap-file nil 'nomessage))

;; Install use-package
(straight-use-package 'use-package)

;; Configure use-package to use straight.el by default
(use-package straight
  :custom
  (straight-use-package-by-default t))

;; ensure we always ensure! (with use-package)

(require 'use-package-ensure)                               ; This is equivalent to setting :ensure t
(setq use-package-always-ensure t)

(use-package auto-compile)

(provide 'straight-early-init)
;;; straight-early-init.el ends here
