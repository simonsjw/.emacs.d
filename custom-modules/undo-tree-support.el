;;; undo-tree-support.el --- better undo-tree in emacs -*- lexical-binding: t; -*-

;; Copyright (C) 2022
;; SPDX-License-Identifier: MIT

;; Author: System Crafters Community

;;; Commentary:

;; Get quality undo-tree support in Emacs.



;;; Packages:

(require 'system-tools)
(require 'path-support)
(require 'logging-config)
(log/debug :fn 'undo-tree-support
           :msg "Starting load of the undo-tree-support module."
           :obj t)

;; Undo-tree package
;; https://gitlab.com/tsc25/undo-tree/-/blob/master/undo-tree.el
(use-package undo-tree
  :delight)

(require 'undo-tree)

;;; Code:
(global-undo-tree-mode)


;;;; Customisation:
;; Define the undo-tree customization group
(defgroup undo-tree nil
  "Customization group for undo-tree."
  :group 'convenience
  :prefix "undo-tree-")

;; Define the undo-tree-show-minibuffer-help custom variable
(defcustom undo-tree-show-minibuffer-help t
  "Show a quick reference to the most important `undo-tree-mode' commands.

shown in the mini-buffer when the undo-tree buffer is active."
  :type 'boolean
  :group 'undo-tree)



;; Enable timestamps in the undo-tree visualizer
(setq undo-tree-visualizer-timestamps t)
;; Enable diffs in the undo-tree visualizer
(setq undo-tree-visualizer-diff t)


;; Define the undo-tree-auto-save-history custom variable
(defcustom undo-tree-auto-save-history t
  "Automatically save undo history to a file.

  (the path for the save history is defined in custom-path-support.el)
Note: Requires Emacs version 24.3 or higher."
  :type 'boolean
  :group 'undo-tree)

;; restore undo-tree history for buffer: 
;;    `undo-tree-load-history` (command)
;; (not done by default)

;; manually save undo history to file for buffer when
;; undo-tree-auto-save-history is not t:
;;    `undo-tree-save-history` 




;;; Compressing undo history
;; Undo history files cannot grow beyond the maximum undo tree size, which is
;; limited by undo-limit, undo-strong-limit and undo-outer-limit.
;; Nevertheless, undo history files can grow quite large.
;; If you want to automatically compress undo history, add the following
;; advice to your .emacs file (replacing ".gz" with the filename extension of
;; your favourite compression algorithm):

(defadvice undo-tree-make-history-save-file-name
    (after undo-tree activate)
  (setq ad-return-value (concat ad-return-value ".gz")))


(log/debug :fn 'undo-tree-support
           :msg "Finishing load of the undo-tree-support module."
           :obj t)

(provide 'undo-tree-support)
;;; undo-tree-support.el ends here
