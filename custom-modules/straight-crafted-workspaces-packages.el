;;; straight-crafted-workspaces-packages.el --- Workspaces configuration  -*- lexical-binding: t; -*-

;; Copyright (C) 2022
;; SPDX-License-Identifier: MIT

;; Author: System Crafters Community
;; Keywords: project, workspace

;;; Commentary:

;;; Code:

;;; packages
;; (straight-use-package 'tabspaces)
;;; emacs-purpose
;; support for assigning a purpose to windows in emacs. 
(straight-use-package   
 '(emacs-purpose :type git :host github :repo "bmag/emacs-purpose"))

(provide 'straight-crafted-workspaces-packages)
;;; straight-crafted-workspaces-packages.el ends here
