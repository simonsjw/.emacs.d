;;; custom-system-objects.el --- useful objects for emacs -*- mode: emacs-lisp; lexical-binding: t; -*-

;;; License
;; Copyright (C) 2022
;; SPDX-License-Identifier: MIT

;; Author: Simon Watson

;;; Commentary:

;; This module contains code to 'grease the wheels' in delivering functionality
;; for the Emacs Lisp object model. It is similar to `custom-system-tools' but
;; here the focus is on functionality to access and use Emacs lisp objects
;; rather than the deployment of those objects to achieve higher level tasks.
;;
;; As a rule of thumb - if the functionality relies on additional modules
;; then it is probably at home here in `custom-system-objects'. 
;; 
;; Perhaps the division into these two modules isn't always straightforward.
;; In those cases, consult these docs!


;;; Code:

(require 'custom-logging-config)
(require 'ispell)
(require 'dired)

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Hash table management
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

;; utility for creating a hash table.
(defun my-hash-tools/define-hash-table
    (table-name cons-list &optional idx-name item-name)
  "Define a hash table and populate it with records.
  
TABLE-NAME is the name of the hash table to be created.
CONS-LIST is a list of cons cells, where the car of each cons cell is the index
and the cdr is a list of item data.
IDX-NAME and ITEM-NAME are optional names for the hash table columns.
If not supplied, the default names `idx' and `item' are used."
  (let ((idx-column (or idx-name :idx))
        (item-column (or item-name :item)))
    (set table-name (make-hash-table :test 'equal))
    (dolist (log cons-list)
      (let ((idx (car log))
            (item (cdr log)))
        (puthash idx
                 (list idx-column idx item-column (cadr item) :active nil)
                 (symbol-value table-name))))))

;; end of hash table management
;; ---------------------------

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Frame management
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
(defun my-frame-tools/delete-frame-by-name (frame-name)
  "Delete a frame by its name FRAME-NAME."
  (interactive "sEnter frame name to delete: ")  ; Prompt for frame name
  (let ((found nil))  ; Track if we found the frame
    (dolist (frame (frame-list))
      (when (string= (frame-parameter frame 'name) frame-name)
        (delete-frame frame)
        (setq found t)
        (message "Deleted frame named '%s'." frame-name)))
    (unless found
      (message "No frame named '%s' found." frame-name))))


(defun my-frame-tools/set-current-frame-name (name)
  "Set the name of the current frame to NAME."
  (interactive "sEnter new frame name: ")  ; Prompt for the frame name interactively
  (set-frame-name name))


(defun my-frame-tools/close-all-windows-except-first (&optional frame)
  "Close all windows in FRAME except the first window.
If FRAME is nil, use the current frame."
  (let* ((target-frame (or frame (selected-frame)))
         (first-window (frame-first-window target-frame)))
    (select-window first-window) ; Select the first window
    (with-selected-frame target-frame
      (delete-other-windows)))) ; Close all other windows


;; end of Frame management
;; ---------------------------

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Window management
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
(defun my-window-tools/list-window-names ()
  "List all windows and their names."
  (interactive)
  (let ((output-buffer (get-buffer-create "*Window Names*")))  ; Create or get the buffer
    (with-current-buffer output-buffer
      (erase-buffer)  ; Clear the previous contents
      (insert "List of all window names:\n\n"))
    (walk-windows
     (lambda (w)
       (let ((name (window-parameter w 'name)))
         (with-current-buffer output-buffer
           (insert (format "Window: %s, name: %s\n" w
                           (or name "unnamed"))))))
     nil 'visible)
    (display-buffer output-buffer)))

(defun my-window-tools/find-window-by-name (name)
  "Find the window with the 'Name' parameter equal to NAME."
  (let ((found-window nil))
    (walk-windows
     (lambda (window)
       (when (equal (window-parameter window 'name) name)
         (setq found-window window)))
     nil t)
    found-window))

(defun my-window-tools/list-window-tags (window)
  "List all tags (parameters) for the given WINDOW."
  (let ((params (window-parameters window)))
    (mapcar (lambda (param)
              (message "Tag: %s, Value: %s" (car param) (cdr param)))
            params)))

;; end of Window management
;; ---------------------------

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; BUFFER management
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Define the customizable variable at the top level
(defcustom my-buffer-attributes nil
  "The attributes associated with the buffer."
  :local t
  :type '(alist :key-type symbol :value-type sexp)
  :group 'my-system-objects)


(defun my-buffer-tools/set-buffer-attribute (buffer attribute value)
  "Set an ATTRIBUTE with VALUE for the given BUFFER."
  (with-current-buffer buffer
    (setq my-buffer-attributes
          (assoc-delete-all attribute my-buffer-attributes))
    (add-to-list 'my-buffer-attributes (cons attribute value))))

(defun my-buffer-tools/get-buffer-attribute (buffer attribute)
  "Given a BUFFER, get the value of ATTRIBUTE for it."
  (with-current-buffer buffer
    (cdr (assoc attribute my-buffer-attributes))))

(defun my-buffer-tools/get-window-with-tag (tag)
  "Get a window by its tag.
Used with my-buffer-tools/display-given-buffer to provide functionality to
my-buffer-tools/display-buffer-by-name-and-tag"
  (catch 'window
    (dolist (win (window-list))
      (when (equal (window-parameter win 'tag) tag)
        (throw 'window win)))
    nil))


;;; TOOLS FOR THE FILE SYSTEM
;;  -------------------------
;; Function to ensure directory exists
(defun my-on-disk-tools/ensure-directory-exists (dir)
  "Ensure the directory DIR exists, create it if it does not."
  (unless (file-directory-p dir)
    (message "creating %s" dir)
    (make-directory dir t)))

;; ---end of TOOLS FOR THE FILE SYSTEM---

(provide 'custom-system-objects)
;;; custom-system-objects.el ends here

                                        ; LocalWords:  LISTB
