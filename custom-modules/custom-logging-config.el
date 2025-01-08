;;; custom-logging-config.el --- Emacs logging configuration -*- lexical-binding: t; -*-

;; Copyright (C) 2023
;; SPDX-License-Identifier: MIT

;; Author: Simon Watson

;;; Commentary:

;; Set up logging in Emacs.


;;; Code:


;; Avoid errors from large objects being converted to strings.
(customize-set-variable
 'print-length 500
 "Set the maximum length of list to print before abbreviating.")


;; Implement basic logging in Emacs.
;; set up logging
;; --------------

;; set up log path.

(defconst log/init-log
  (expand-file-name "init.log" user-emacs-directory)
  "The path to the log file used when loading Emacs.")

;; define log levels.
(defconst log/lvl-FATAL (list :idx 0 :lvl "FATAL") "The FATAL log level.")
(defconst log/lvl-ERR   (list :idx 1 :lvl "ERR")   "The ERR log level.")
(defconst log/lvl-WARN  (list :idx 2 :lvl "WARN")  "The WARN log level.")
(defconst log/lvl-DEBUG (list :idx 3 :lvl "DEBUG") "The DEBUG log level.")
(defconst log/lvl-INFO  (list :idx 4 :lvl "INFO")  "The INFO log level.")

;; define logging events to be used.
(defconst log/type-function-message       0
  "Log ad-hoc messages using `message'.")

(defconst log/type-special-form-provide   1
  "Log use of the special form `provide'.
Logging this helps understand which modules are being loaded.")

(defconst log/type-macro-use-package      2
  "Log use of the `use-package' macro.")

(defconst log/type-special-form-defconst  3
  "Log use of the special form `defconst'.")

(defconst log/type-special-form-defvar    4
  "Log use of the special form `defvar'.")


(defvar
  log/settings
  (list
   :lvl '(log/lvl-FATAL
          log/lvl-ERR
          log/lvl-WARN
          ;; log/lvl-DEBUG
          ;; log/lvl-INFO
          )
   :targets '(
              ;; log/type-function-message 
              ;; log/type-special-form-provide
              log/type-macro-use-package 
              log/type-special-form-defconst
              ;; log/type-special-form-defvar
	      ))
  "Define the object used for storing log settings.
These include events and the level of event to be logged.")


;; Define the log types with default values in a hash table
(defvar log/log-table (make-hash-table :test 'equal)
  "A hash table of log settings and active status.")
;; Retrieve targets from log/settings
(let ((targets (plist-get log/settings :targets))
      (log-definitions
       (list
        (cons 'log/type-function-message 
              '(log/type-function-message "message"))        ; TODO: fix! suspect the issue is that the logging function uses message. 
        (cons 'log/type-special-form-provide
              '(log/type-special-form-provide "provide"))
        (cons 'log/type-macro-use-package
              '(log/type-macro-use-package "use-package"))
        (cons 'log/type-special-form-defconst
              '(log/type-special-form-defconst "defconst"))  ; TODO: setup 
        (cons 'log/type-special-form-defvar
              '(log/type-special-form-defvar "defvar")))))   ; TODO: setup 
  (dolist (log log-definitions)
    (let* ((symbol (car log))
           (idx (symbol-value symbol))
           (item (cdr log))
           (active (if (member symbol targets) t nil)))
      (puthash idx
               (list :idx (symbol-name symbol)
                     :item-type (cadr item)
                     :active active)
               log/log-table))))

(defun log/initialize-log-table ()
  "Initialise :active status based on :targets in `log/settings'.
This allows selection of the kind of logging objects to record.
use like this:
   (log/initialize-log-table)"
  (let ((targets (plist-get log/settings :targets)))
    (maphash (lambda (idx value)
               (let ((symbol-name (intern (plist-get value :idx))))
                 (puthash idx
                          (plist-put value
                                     :active
                                     (if (member symbol-name targets) t nil))
                          log/log-table)))
             log/log-table)))

(defun log/get-log-type-by-index (idx)
  "Get the log type properties for the given index IDX.
Example usage:
 (log/get-log-type-by-index log/type-adhoc-log)
 - Returns
   (:idx \"log/type-adhoc-log\" :item-type \"log-message\" :active t)
 (get-log-type-by-index log/type-special-form-provision)
 - Returns
   (:idx \"type-special-form-provide\" :item-type \"provide\" :active nil)"
  (gethash idx log/log-table))


(defun log/current-time ()
  "Return the current time as a string with microsecond precision."
  (let*
      (
       (now (current-time))
       (seconds (float-time now))                       ; Get time in seconds (float).
       (microseconds
        (truncate (* (mod seconds 1) 1000000)))         ; get microseconds
       (time-in-seconds
        (format-time-string "%Y-%m-%d %H:%M:%S" now)))  ; Get the standard time
    (format "%s.%06d"  time-in-seconds microseconds)))  ; Add microseconds

(defun log/write-to-file (message log-file)
  "Write a log to file, creating or appending as necessary.

This function mirrors \"my/append-to-file\" and is defined so logging can be
set up without loading dependencies.
  MESSAGE:    A string to be appended to the file (string).
  LOG-FILE:  A path to a file (string)"
  (with-temp-buffer
    (insert message "\n")
    (append-to-file (point-min) (point-max) log-file)))

(defun log/logger (&rest args)
  "Base logger function for the session.

Note that any object passed will be converted to a string and truncated at no
more than the number of characters in \"print-length\".
If the object is a string, it will not be truncated and any formatting symbols
contained (\\n for example) will be respected in the print to file.

  ARGS:
  LOGFILE:  The file-path for the log (symbol).
  LVL:      The logging level (symbol).
  FN:       The function being logged (symbol).
  MSG:      The log message (string).
  OBJ:      An object to be recorded.

  RETURNS:
  nil"
  (let ((logFile (plist-get args :logFile))
        (lvl (plist-get args :lvl))
        (fn (plist-get args :fn))
        (msg (plist-get args :msg))
        (obj (plist-get args :obj)))

    (log/write-to-file
     (format
      "[%s; %s; %s] %s; %s;"
        (log/current-time)
        (plist-get lvl :lvl)
        (symbol-name fn)
        msg
        (prin1-to-string obj))
  logFile)))

;; Define the log levels used in the system.
(defun log/fatal (&rest args)
  "Function to log a message at log-level `FATAL.
ARGS:
   FN:       The function being logged (symbol).
   MSG:      The log message (string).
   OBJ:      An object to be recorded."
  (let ((fn (plist-get args :fn))
        (msg (plist-get args :msg))
        (obj (plist-get args :obj)))
    (log/logger
     :logFile log/init-log :fn fn :msg msg :obj obj
     :lvl log/lvl-FATAL)))

(defun log/error (&rest args)
  "Function to log a message at log-level `ERROR.
ARGS:
   FN:       The function being logged (symbol).
   MSG:      The log message (string).
   OBJ:      An object to be recorded."
  (let ((fn (plist-get args :fn))
        (msg (plist-get args :msg))
        (obj (plist-get args :obj)))
    (log/logger
     :logFile log/init-log :fn fn :msg msg :obj obj
     :lvl log/lvl-ERR)))

(defun log/warn (&rest args)
  "Function to log a message at log-level `WARN.
ARGS:
   FN:       The function being logged (symbol).
   MSG:      The log message (string).
   OBJ:      An object to be recorded."
  (let ((fn (plist-get args :fn))
        (msg (plist-get args :msg))
        (obj (plist-get args :obj)))
    (log/logger
     :logFile log/init-log :fn fn :msg msg :obj obj
     :lvl log/lvl-WARN)))

(defun log/debug (&rest args)
  "Function to log a message at log-level `DEBUG.
ARGS:
   FN:       The function being logged (symbol).
   MSG:      The log message (string).
   OBJ:      An object to be recorded."
  (let ((fn (plist-get args :fn))
        (msg (plist-get args :msg))
        (obj (plist-get args :obj)))
    (log/logger
     :logFile log/init-log :fn fn :msg msg :obj obj
     :lvl log/lvl-DEBUG)))

(defun log/info (&rest args)
  "Function to log a message at log-level `INFO.
ARGS:
   FN:       The function being logged (symbol).
   MSG:      The log message (string).
   OBJ:      An object to be recorded."
  (let ((fn (plist-get args :fn))
        (msg (plist-get args :msg))
        (obj (plist-get args :obj)))
    (log/logger
     :logFile log/init-log :fn fn :msg msg :obj obj
     :lvl log/lvl-INFO)))


(provide 'custom-logging-config)
;;; custom-logging-config.el ends here
