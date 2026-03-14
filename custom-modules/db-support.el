;;; db-support.el --- database support for emacs setup   -*- lexical-binding: t; -*-

;; Copyright (C) 2022
;; SPDX-License-Identifier: MIT

;; Author: System Crafters Community
;; Keywords: SQL, postgresSQL

;;; Commentary:

;; This package handles database support
;; included here:
;;    * Package phase
;;    * Code phase
;;    * Config phase
;;    * Hook phase
;;    * keymap phase

;;; Code:

(require 'path-support)
(require 'logging-config)

;;; Package phase

;; An Emacs 25 module for accessing PostgreSQL via the pq client library.
(use-package pq)

;; use pgformatter - A PostgreSQL SQL syntax beautifier that can work
;;  as a console program or as a CGI.
;; On-line demo site at http://sqlformat.darold.net/
(use-package sqlformat)

;;(require 'sqlformat)
;;(require 'pq)


;;; Code phase


(defun my-db/connect-postgres ()
  "Connect to a PostgreSQL database.

This function uses an environment variable for the password if available."
  (interactive)
  ;; Check if the environment variable is set
  (let ((password (getenv "POSTGRES_U_DC_PW")))
    (if password
        (let ((sql-postgres-password password)) ; If the environment variable is set, temporarily override the sql-password parameter
          (sql-postgres))
      (sql-postgres)))) ; If the environment variable is not set, just call sql-postgres as usual

(defun my-db/capture-sql-output ()
  "Capture the last SQL query output and put it in a  buffer *SQL Results*."
  (interactive)
                                                                                  ; Ensure we're in the *SQL* buffer
  (unless (string= (buffer-name) "*SQL: Postgres*")
    (error "This function must be run from the *SQL* buffer"))
  ;; Find the start of the last SQL output
  (search-backward-regexp "^\\-\\-\\-\\-")
  (let ((start (point)))
    ;; Find the end of the SQL output
    (search-forward-regexp "^\\(postgres\\|\\$\\) ")
    (let ((end (match-beginning 0)))
      ;; Copy the SQL output
      (copy-region-as-kill start end)
      ;; Switch to the *SQL Results* buffer, creating it if necessary
      (switch-to-buffer-other-window "*SQL Results*")
      (erase-buffer)
      ;; Paste the SQL output
      (yank))))

;; save-sql-history-dir defined in custom-path-support
(defun my-db/sql-save-history-hook ()
  "Save your SQL history between sessions."
  (let ((history-filename (concat save-sql-history-dir
                                  (symbol-name sql-product)
                                  "-history.sql")))
    (if sql-product
        (set (make-local-variable 'sql-input-ring-file-name) history-filename)
      (error "SQL history will not be saved because sql-product is nil"))))


(add-hook 'sql-interactive-mode-hook 'my-db/sql-save-history-hook)

(defun my-db/upcase-sql-keywords ()
  "Make all SQL keywords upper case."
  (interactive)
  (save-excursion
    (dolist (keywords sql-mode-postgres-font-lock-keywords)
      (goto-char (point-min))
      (while (re-search-forward (car keywords) nil t)
        (goto-char (+ 1 (match-beginning 0)))
        (when (eql font-lock-keyword-face (face-at-point))
          (backward-char)
          (upcase-word 1)
          (forward-char))))))



;;; config phase

;; configure formatting SQL wiht pg_formatter
(setq sqlformat-command 'pgformatter)

;; applied formatting:
;;    -g | --nogrouping: add a newline between statements in
;;                       transaction regroupement.
;;                       Default is to group statements.
;;    -s | --spaces size: change space indent, default 4 spaces.
(setq sqlformat-args '("-s2" "-g"))



;;; Hooks phase

;; automatically activate for files ending .sql and .qry
(add-to-list 'auto-mode-alist '("\\.sql\\'" . sql-mode))
(add-to-list 'auto-mode-alist '("\\.qry\\'" . sql-mode))


;; specify an escape character of "\" for comments in sql.
(add-hook 'sql-mode-hook
          (lambda ()
	    (modify-syntax-entry ?\\ "\\" sql-mode-syntax-table)))




;;; keymaps phase

;; C-c C-f to format the code (as usual)
;;(define-key sql-mode-map (kbd "C-c C-f") 'sqlformat)


(provide 'db-support)
;;; db-support.el ends here


; LocalWords:  formatter
