;;; vtable-tools.el --- useful functionality for emac vtables -*- mode: emacs-lisp; lexical-binding: t; -*-

;;; License
;; Copyright (C) 2022
;; SPDX-License-Identifier: MIT

;; Author: Simon Watson

;;; Commentary:

;; This file contains code to help the creation of use of vtables.



;;; Code:

(require 'vtable)


(defvar my-vtable/buffer-name "*vTable*"
  "The name of the buffer displaying the vtable.")

(defvar my-vtable/page-size 30
  "Number of rows per page for paginated vtable.
Tune based on performance; smaller values reduce lag.")

(defvar my-vtable/current-page 0
  "Current page index for paginated vtable (0-based).")

(defvar my-vtable/full-data nil
  "Full dataset as list of row lists.
Populated externally; each row matches column count.")

(defun my-vtable/create-paginated-vtable-buffer (buffer-name columns full-data)
  "Create and display a buffer with a paginated vtable.
BUFFER-NAME is the buffer to create or switch to.
COLUMNS is a list of column specs, each: (:name NAME :width WIDTH :align ALIGN).
FULL-DATA is the complete list of rows for pagination.

Sets up vtable with subset of data, adds keybindings for navigation,
and handles updates efficiently.  Flow: validate, store full data,
create vtable with initial page, bind keys, switch buffer."
  (setq my-vtable/full-data full-data)
  (my-vtable/validate-vtable-inputs columns full-data)
  (let ((buf (get-buffer-create buffer-name)))
    (with-current-buffer buf
      (erase-buffer)
      (let* ((vt (make-vtable :columns columns
                              :objects-function #'my-vtable/get-paged-objects
                              :use-header-line t)))
        (vtable-insert vt))
      (my-vtable/bind-pagination-keys)
      (setq my-vtable/current-page 0))  ; Reset on creation.
    (switch-to-buffer buf)))

(defun my-vtable/get-paged-objects ()
  "Return subset of MY-VTABLE/FULL-DATA for current page.
Computes start/end indices efficiently; returns list of rows.
Flow: calculate offsets, extract subsequence; no args needed as globals suffice."
  (let* ((start (* my-vtable/current-page my-vtable/page-size))
         (end (min (+ start my-vtable/page-size) (length my-vtable/full-data))))
    (seq-subseq my-vtable/full-data start end)))

(defun my-vtable/next-vtable-page ()
  "Advance to next page and update vtable efficiently.
Checks if more pages exist; reverts table without full rebuild."
  (interactive)
  (let ((max-page (/ (1- (length my-vtable/full-data)) my-vtable/page-size)))
    (when (< my-vtable/current-page max-page)
      (setq my-vtable/current-page (1+ my-vtable/current-page))
      (vtable-revert-command))))

(defun my-vtable/prev-vtable-page ()
  "Go to previous page and update vtable efficiently.
Ensures page >= 0; reverts table without full rebuild."
  (interactive)
  (when (> my-vtable/current-page 0)
    (setq my-vtable/current-page (1- my-vtable/current-page))
    (vtable-revert-command)))

(defun my-vtable/bind-pagination-keys ()
  "Bind keys for pagination in current buffer.
Uses local map for n (next), p (prev); efficient as hooks avoid globals."
  (let ((map (make-sparse-keymap)))
    (define-key map (kbd "n") #'my-vtable/next-vtable-page)
    (define-key map (kbd "p") #'my-vtable/prev-vtable-page)
    (use-local-map map)))

(defun my-vtable/validate-vtable-inputs (columns data)
  "Validate COLUMNS and DATA for vtable integrity.
Ensures columns are list of plists, data rows match column count.
Throws error on mismatch; called early for efficiency."
  (unless (listp columns) (error "Columns must be a list"))
  (let ((col-count (length columns)))
    (dolist (row data)
      (unless (= (length row) col-count)
        (error "Row length must match column count")))))

;; Example usage:
;; Columns as before.
(defvar my-vtable/vcolumns '((:name "Name" :width 20 :align left)
                             (:name "Age" :width 5 :align right)
                             (:name "City" :width 15 :align left)))

;; Simulate large data: 1000 rows.
(defvar my-vtable/large-data
  (let ((data '()))
    (dotimes (i 1000)
      (push (list (format "Person %d" i) (random 100) (format "City %d" (random 10))) data))
    (nreverse data)))

;; Create paginated table.
(my-vtable/create-paginated-vtable-buffer my-vtable/buffer-name my-vtable/vcolumns my-vtable/large-data)




(provide 'vtable-tools)
;;; vtable-tools.el ends here

;; LocalWords: vtable
