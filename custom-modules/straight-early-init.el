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
;;(require 'early-init)

(defvar bootstrap-version)
(let ((bootstrap-file
       (expand-file-name "straight/repos/straight.el/bootstrap.el" straight-base-dir))
      (bootstrap-version 6))
  (unless (file-exists-p bootstrap-file)
    (with-current-buffer
        (url-retrieve-synchronously
         "https://raw.githubusercontent.com/radian-software/straight.el/develop/install.el"
         'silent 'inhibit-cookies)
      (goto-char (point-max))
      (eval-print-last-sexp)))
  (load bootstrap-file nil 'nomessage))




;; Configure crafted-emacs to use straight as package manager.
;; See `(info "(crafted-emacs)Using alternate package managers")'

;; (setq crafted-package-system 'straight)
;; (setq crafted-package-installer #'straight-use-package)
;; (setq crafted-package-installed-predicate #'straight--installed-p)

(provide 'straight-early-init)
;;; straight-early-init.el ends here
