;;; vtable-tools.el --- useful functionality for emacs vtables -*- mode: emacs-lisp; lexical-binding: t; -*-

;;; License
;; Copyright (C) 2022
;; SPDX-License-Identifier: MIT

;; Author: Simon Watson

;;; Commentary:

;; This file contains code to help the creation and use of vtables.
;; It supports paginated vtables with mode-line controls for navigation.
;; Optionally, it handles multiple vtables in a single buffer using overlays
;; to track regions and per-vtable state, allowing dynamic selection based
;; on point position for updating the mode line.

;;; Code:

(require 'vtable)
(require 'cl-lib)  ; For cl-defstruct.

(cl-defstruct (my-vtable-info
               (:constructor my-vtable-make-info)
               (:copier nil))
  "Structure to hold per-vtable pagination state.
Slots:
- full-data: List of all row data.
- current-page: Integer, 0-based current page index.
- page-size: Integer, rows per page.
- vtable: The vtable object.
- overlay: Overlay over the vtable's buffer region."
  full-data
  current-page
  page-size
  vtable
  overlay)

(defvar-local my-vtable-multi-mode nil
  "Non-nil if buffer supports multiple vtables with overlays.")

(defvar-local my-vtable-list nil
  "List of my-vtable-info structs for multi-vtable buffers.")

(defvar-local my-vtable-current-info nil
  "Current selected my-vtable-info; updated in multi-mode.")

(defvar my-vtable/buffer-name "*vTable*"
  "The name of the buffer displaying the vtable.")

(defvar my-vtable/page-size 30
  "Number of rows per page for paginated vtable.
Tune based on performance; smaller values reduce lag.")

(defvar-local my-vtable/full-data nil
  "Full data for single vtable mode (buffer-local).")

(defvar-local my-vtable/current-page 0
  "Current page for single vtable mode (buffer-local).")

(defun my-vtable/create-paginated-vtable-buffer (buffer-name columns full-data &optional multi)
  "Create and display a buffer with a paginated vtable.
BUFFER-NAME is the buffer to create or switch to.
COLUMNS is a list of column specs, each: (:name NAME :width WIDTH :align ALIGN).
FULL-DATA is the complete list of rows for pagination.
Optional MULTI: if non-nil, enable multi-vtable mode (no erase, append support).

In single mode (MULTI nil): Sets up one vtable, uses buffer-wide vars.
In multi mode: Appends vtable, uses overlays and per-vtable state.
Flow: validate inputs, get/create buffer, optionally erase (single only),
set state vars (single) or multi-mode flag, create vtable with paged objects,
set current info (multi), insert it, setup overlay (multi), bind keys,
add mode-line. Switches to buffer and enables tab-line-mode."
  (my-vtable/validate-vtable-inputs columns full-data)
  (let ((buf (get-buffer-create buffer-name)))
    (with-current-buffer buf
      (unless multi (erase-buffer))  ; Single: clear; multi: append.
      (when multi (setq my-vtable-multi-mode t))
      (unless multi
        (setq-local my-vtable/full-data full-data)
        (setq-local my-vtable/current-page 0))
      (let* ((objects-fn (if multi
                             (lambda () (my-vtable/get-paged-objects
                                         (my-vtable/get-current-info)))
                           #'my-vtable/get-paged-objects-single))
             (vt (make-vtable :columns columns
                              :objects-function objects-fn
                              :use-header-line t))
             (info (my-vtable-make-info :full-data full-data
                                        :current-page 0
                                        :page-size my-vtable/page-size
                                        :vtable vt
                                        :overlay nil)))  ; Overlay later.
        (when multi (setq my-vtable-current-info info))  ; Set before insert.
        (vtable-insert vt)
        (when multi
          ;; Create overlay over vtable region, store info.
          (let ((ov (make-overlay (vtable-beginning vt) (vtable-end vt))))
            (overlay-put ov 'my-vtable-info info)
            (setf (my-vtable-info-overlay info) ov))
          (push info my-vtable-list)
          ;; Add hook to update selected on movement.
          (add-hook 'post-command-hook #'my-vtable/update-selected nil t))
        (my-vtable/bind-pagination-keys)
        ;; Append pagination controls to mode-line-format.
        (setq-local mode-line-format
                    (append mode-line-format
                            (list " " '(:eval (my-vtable/generate-mode-line)))))))
    (switch-to-buffer buf))
  (tab-line-mode t))

(defun my-vtable/add-paginated-vtable-to-buffer (buffer-name columns full-data)
  "Add another paginated vtable to an existing multi-mode buffer.
BUFFER-NAME must exist and have my-vtable-multi-mode t.
COLUMNS and FULL-DATA as in create function.
Errors if not multi-mode.
Flow: validate, switch to buffer, goto end, insert separator,
create vtable, set current info, insert vtable, create overlay,
add to list."
  (my-vtable/validate-vtable-inputs columns full-data)
  (let ((buf (get-buffer buffer-name)))
    (unless buf (error "Buffer %s does not exist" buffer-name))
    (with-current-buffer buf
      (unless my-vtable-multi-mode (error "Buffer not in multi-vtable mode"))
      (goto-char (point-max))
      (insert "\n\n")  ; Separator between vtables.
      (let* ((objects-fn (lambda () (my-vtable/get-paged-objects
                                     (my-vtable/get-current-info))))
             (vt (make-vtable :columns columns
                              :objects-function objects-fn
                              :use-header-line t))
             (info (my-vtable-make-info :full-data full-data
                                        :current-page 0
                                        :page-size my-vtable/page-size
                                        :vtable vt
                                        :overlay nil)))
        (setq my-vtable-current-info info)  ; Set before insert.
        (vtable-insert vt)
        (let ((ov (make-overlay (vtable-beginning vt) (vtable-end vt))))
          (overlay-put ov 'my-vtable-info info)
          (setf (my-vtable-info-overlay info) ov))
        (push info my-vtable-list)))))

(defun my-vtable/get-paged-objects-single ()
  "Return subset of MY-VTABLE/FULL-DATA for current page in single mode.
Computes start/end indices efficiently; returns list of rows.
Flow: calculate offsets, extract subsequence."
  (let* ((start (* my-vtable/current-page my-vtable/page-size))
         (end (min (+ start my-vtable/page-size) (length my-vtable/full-data))))
    (seq-subseq my-vtable/full-data start end)))

(defun my-vtable/get-paged-objects (info)
  "Return paged objects for given INFO struct in multi mode.
Similar to single, but uses INFO's slots.
Flow: extract from info, calculate offsets, subsequence."
  (let* ((full (my-vtable-info-full-data info))
         (page (my-vtable-info-current-page info))
         (size (my-vtable-info-page-size info))
         (start (* page size))
         (end (min (+ start size) (length full))))
    (seq-subseq full start end)))

(defun my-vtable/get-current-info ()
  "Return current my-vtable-info; depends on mode.
In multi: use my-vtable-current-info.
In single: return a temp struct from locals.
Flow: check mode, return accordingly."
  (if my-vtable-multi-mode
      my-vtable-current-info
    (my-vtable-make-info :full-data my-vtable/full-data
                         :current-page my-vtable/current-page
                         :page-size my-vtable/page-size
                         :vtable (vtable-current-table)  ; Assume single.
                         :overlay nil)))

(defun my-vtable/update-selected ()
  "Update my-vtable-current-info based on point in multi-mode.
Called via post-command-hook.
Flow: find overlays at point, get first with 'my-vtable-info,
set current; if none, keep previous or nil."
  (when my-vtable-multi-mode
    (let ((ovs (overlays-at (point)))
          found)
      (dolist (ov ovs)
        (when (overlay-get ov 'my-vtable-info)
          (setq found (overlay-get ov 'my-vtable-info))
          (cl-return)))
      (when found (setq my-vtable-current-info found)))))

(defun my-vtable/next-vtable-page ()
  "Advance to next page and update vtable efficiently.
Works for current info in either mode.
Flow: get info, calc max, increment if possible, revert vtable."
  (interactive)
  (let* ((info (my-vtable/get-current-info))
         (full (my-vtable-info-full-data info))
         (size (my-vtable-info-page-size info))
         (page (my-vtable-info-current-page info))
         (max-page (/ (1- (length full)) size)))
    (when (< page max-page)
      (setf (my-vtable-info-current-page info) (1+ page))
      (vtable-revert-command))))

(defun my-vtable/prev-vtable-page ()
  "Go to previous page and update vtable efficiently.
Works for current info in either mode.
Flow: get info, decrement if >0, revert."
  (interactive)
  (let* ((info (my-vtable/get-current-info))
         (page (my-vtable-info-current-page info)))
    (when (> page 0)
      (setf (my-vtable-info-current-page info) (1- page))
      (vtable-revert-command))))

(defun my-vtable/first-vtable-page ()
  "Jump to first page and update vtable efficiently.
Works for current info.
Flow: get info, set page 0, revert."
  (interactive)
  (let ((info (my-vtable/get-current-info)))
    (setf (my-vtable-info-current-page info) 0)
    (vtable-revert-command)))

(defun my-vtable/last-vtable-page ()
  "Jump to last page and update vtable efficiently.
Works for current info.
Flow: get info, calc max, set page, revert."
  (interactive)
  (let* ((info (my-vtable/get-current-info))
         (full (my-vtable-info-full-data info))
         (size (my-vtable-info-page-size info))
         (max-page (/ (1- (length full)) size)))
    (setf (my-vtable-info-current-page info) max-page)
    (vtable-revert-command)))

(defun my-vtable/bind-pagination-keys ()
  "Bind keys for pagination in current buffer.
Uses local map for n (next), p (prev).
Flow: create sparse map, define keys, set local map.
In multi-mode, commands dispatch to current."
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

(defun my-vtable/generate-mode-line ()
  "Generate propertized string for mode-line pagination controls.
Uses current info from mode.
Calculates current (1-based) and total pages; creates clickable elements
with keymaps for first, prev, next, last actions.
Returns formatted string like '[ |← ← N/M → →| ]'.
If no current info (multi-mode, point not in vtable), returns empty.
Flow: get info, if nil return empty; else compute, make keymaps, concat."
  (let ((info (my-vtable/get-current-info)))
    (if (null info)
        ""
      (let* ((cur (1+ (my-vtable-info-current-page info)))
             (full (my-vtable-info-full-data info))
             (size (my-vtable-info-page-size info))
             (total (1+ (/ (1- (length full)) size)))
             (page-str (format "%d/%d" cur total))
             (first-map (make-sparse-keymap))
             (prev-map (make-sparse-keymap))
             (next-map (make-sparse-keymap))
             (last-map (make-sparse-keymap)))
        ;; Define mouse-1 clicks on mode-line for each action.
        (define-key first-map [mode-line mouse-1] #'my-vtable/first-vtable-page)
        (define-key prev-map [mode-line mouse-1] #'my-vtable/prev-vtable-page)
        (define-key next-map [mode-line mouse-1] #'my-vtable/next-vtable-page)
        (define-key last-map [mode-line mouse-1] #'my-vtable/last-vtable-page)
        (concat "["
                (propertize "|◀" 'mouse-face 'mode-line-highlight 'keymap first-map)
                " "
                (propertize "◀" 'mouse-face 'mode-line-highlight 'keymap prev-map)
                " "
                page-str
                " "
                (propertize "▶" 'mouse-face 'mode-line-highlight 'keymap next-map)
                " "
                (propertize "▶|" 'mouse-face 'mode-line-highlight 'keymap last-map)
                "]")
        ))))

;; Example usage for single vtable:
;; (my-vtable/create-paginated-vtable-buffer my-vtable/buffer-name my-vtable/vcolumns my-vtable/large-data)

;; For multi: Create with multi t, then add more.
;; (my-vtable/create-paginated-vtable-buffer my-vtable/buffer-name my-vtable/vcolumns my-vtable/large-data t)
;; (my-vtable/add-paginated-vtable-to-buffer my-vtable/buffer-name my-vtable/vcolumns my-vtable/large-data)

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

(provide 'vtable-tools)
;;; vtable-tools.el ends here

;; LocalWords: vtable
