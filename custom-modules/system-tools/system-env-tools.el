;;; system-env-tools.el --- Env, hash, and string helpers. -*- lexical-binding: t; -*-

;; Copyright (C) 2026 Simon Watson
;; SPDX-License-Identifier: MIT

;; Author: Simon Watson

;;; Commentary:

;; Piece of `system-tools': environment snapshots, hash-table
;; helpers, and string utilities.  Required by the loader, not from
;; `init.el' directly.
;;
;; Map:
;;   Feature:    system-env-tools
;;   Load-after: path-support logging-config
;;   Load-phase: bootstrap
;;   Keymaps:    none
;;   Docs:       docs/system-env-tools.org
;;   OS:         none

;;; Code:

(require 'path-support)
(require 'logging-config)
(log/debug :fn 'system-env-tools
           :msg "Starting load of the system-env-tools module."
           :obj t)

(require 'cl-lib)

;;;; Environmental variable tools
(defun my-env-tools/exec-path-from-shell-report (&optional variables)
  "Return a report of which environment variables are missing or empty.

VARIABLES defaults to `exec-path-from-shell-variables'.
The return value is a plist suitable for logging with :obj.

Example usage:

  (log/debug :fn 'defaults-config
             :msg \"Environment variable status after exec-path-from-shell\"
             :obj (my/exec-path-from-shell-report))"
  (let* ((vars (or variables exec-path-from-shell-variables))
         (missing '())
         (empty '())
         (present '()))
    (dolist (var vars)
      (let ((val (getenv var)))
        (cond
         ((null val)   (push var missing))
         ((string-empty-p val) (push var empty))
         (t            (push (cons var val) present)))))
    (list :missing (nreverse missing)
          :empty   (nreverse empty)
          :present (length present)   ; just a count to keep the log readable
          :total   (length vars))))


(defun my-env-tools/exec-path-from-shell-report-full (&optional variables)
  "Get full environmental variable values (optionally only those in VARIABLES).

This function is similar `my-env-tools/exec-path-from-shell-report' but also
returns the present values.  Use in debugging."
  (let* ((vars (or variables exec-path-from-shell-variables))
         (missing '())
         (empty '())
         (present '()))
    (dolist (var vars)
      (let ((val (getenv var)))
        (cond
         ((null val)           (push var missing))
         ((string-empty-p val) (push var empty))
         (t                    (push (cons var val) present)))))
    (list :missing (nreverse missing)
          :empty   (nreverse empty)
          :present (nreverse present)
          :total   (length vars))))

;; end of environmental variable tools.
;; ---------------------------


;;;; Hash table management

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


;;;; String processing

(defun my-strings/ensure-directory-path (path)
  "Ensure the directory PATH ends with a '/'."
  (if (string-suffix-p "/" path)
      path
    (concat path "/")))

(defun my-strings/current-time-with-milliseconds ()
  "Return the current time as a string with millisecond precision."
  (let*
      ((now (current-time))
       (seconds
        (float-time now))                                                         ; Get the time as a floating-point number
       (milliseconds
        (truncate
         (mod (* seconds 1) 1000)  ))                                             ; Extract milliseconds
       (time-in-seconds
        (format-time-string
         "%Y-%m-%d %H:%M:%S" now)))                                               ; Get the standard time
    (format "%s.%03d"
            time-in-seconds                                                       ; Get the formatted time
            milliseconds)))                                                       ; Add milliseconds


(defun my-strings/human-readable-file-sizes-to-bytes (string)
  "Convert a human-readable file size so it is expressed in units of bytes.

The original number and the output are encoded as STRING..
This is the companion of `my-strings/bytes-to-human-readable-file-sizes', a
function which converts a given amount of bytes into a human readable size as
a STRING."
  (interactive)
  (cond
   ((string-suffix-p "G" string t)
    (* 1000000000
       (string-to-number (substring string 0 (- (length string) 1)))))
   ((string-suffix-p "M" string t)
    (* 1000000
       (string-to-number (substring string 0 (- (length string) 1)))))
   ((string-suffix-p "K" string t)
    (* 1000
       (string-to-number (substring string 0 (- (length string) 1)))))
   (t
    (string-to-number string )))
  )


(cl-defun my-strings/number-to-human-readable-string (number &optional (sigfigs 4) (prec 2) (strlength -1))
  "Convert NUMBER to human-readable string.

The NUMBER will have SIGFIGS significant figures to a precision of PREC if it is
small enough to fit in the allowed significant figures.

If STRLENGTH is a positive number, then white-space will be used to ensure a cc
minimum of that length string is returned with a letter at the end for large
numbers or else a space so the units column is aligned."
  (interactive)
  (let ((result
         (cond
          ((> number 1000000000) (format "%10.1fG" (/ number 1000000000.0)))
          ((> number 100000000) (format "%10.0fM" (/ number 1000000.0)))
          ((> number 1000000) (format "%10.1fM" (/ number 1000000.0)))
          ((> number 100000) (format "%10.0fk" (/ number 1000.0)))
          ((> number 1000) (format "%10.1fk" (/ number 1000.0)))
          (t (format "%10f" number))))) ;; Raw number case
    (if (= (length result) 10)
        (concat result " ")                                                       ; Append space to make length 11
      result)))                                                                   ; Otherwise, return as is


(defun my-strings/bytes-to-human-readable-file-sizes (bytes)
  "Convert number of BYTES to human-readable file size.
Ensures the result is always of length 5 by adding a space if no unit is
present."
  (interactive)
  (let ((result
         (cond
          ((> bytes 1000000000) (format "%5.1fG" (/ bytes 1000000000.0)))
          ((> bytes 100000000) (format "%5.0fM" (/ bytes 1000000.0)))
          ((> bytes 1000000) (format "%5.1fM" (/ bytes 1000000.0)))
          ((> bytes 100000) (format "%5.0fk" (/ bytes 1000.0)))
          ((> bytes 1000) (format "%5.1fk" (/ bytes 1000.0)))
          (t (format "%4d" bytes))))) ;; Raw bytes case
    (if (= (length result) 4)
        (concat " "  result)                                                      ; Append space to make length 11
      result)))                                                                   ; Otherwise, return as is


;; end of String processing
;; ---------------------------

(log/debug :fn 'system-env-tools
           :msg "Finishing load of the system-env-tools module."
           :obj t)

(provide 'system-env-tools)
;;; system-env-tools.el ends here
