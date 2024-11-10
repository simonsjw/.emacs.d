;;; custom-init-config.el --- Crafted Emacs initial configuration  -*- lexical-binding: t; -*-

;; Copyright (C) 2023
;; SPDX-License-Identifier: MIT

;; Author: System Crafters Community

;;; Commentary:

;; Perform some initialization for use by Crafted Emacs modules among
;; other things.
;;; declarations and imports.
(defvar Info-directory-list)
(declare-function info-initialize "info")

;;; Code:

;; Use this file to find the project root where you cloned
;; `crafted-emacs' and use that as the value for the
;; `crafted-emacs-home' value which is needed by a few modules,
;; including the template below used for writing Crafted Emacs
;; modules.

;;(require 'info)

(defgroup custom-init '()
  "Initialization configuration for Crafted Emacs."
  :tag "Custom Init"
  :group 'custom)


;; If the source file is newer than the compiled file, load it instead
;; of the compiled version.
(customize-set-variable 'load-prefer-newer t)

;; Add the custom Emacs documentation to the info nodes
;; (let ((custom-info-dir (expand-file-name "docs/dir"  user-emacs-directory)))
;;   (when (file-exists-p custom-info-dir)
;;     (require 'info)
;;     (info-initialize)
;;     (push (file-name-directory custom-info-dir) Info-directory-list)))

;; Ensure Info paths are set up correctly, and add custom docs
(require 'info)
;; Only initialize Info directories once
(unless Info-directory-list
  (info-initialize))
;; Define and add custom directory
(let ((custom-info-dir (expand-file-name "docs" user-emacs-directory)))
  (when (file-directory-p custom-info-dir)
    (add-to-list 'Info-directory-list custom-info-dir)))

(provide 'custom-init-config)
;;; custom-init-config.el ends here
