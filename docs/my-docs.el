;;; my-docs.el --- Export this tree's Org docs to Info. -*- lexical-binding: t; -*-

;; Copyright (C) 2026 Simon Watson
;; SPDX-License-Identifier: MIT

;; Author: Simon Watson
;; Historical credit: System Crafters Community crafted-docs.el

;;; Commentary:

;; Export helpers for this Emacs configuration's documentation under
;; `docs/'.  Load from a clean Emacs session so Texinfo output does
;; not pick up session-local settings.
;;
;; From `docs/':
;;   make docs
;;   emacs -Q --script my-docs.el -f my-docs-export-info
;;
;; Or load interactively and run `my-docs-export'.
;;
;; Map:
;;   Feature:    my-docs
;;   Load-after: none
;;   Load-phase: docs
;;   Keymaps:    none
;;   Docs:       docs/CONTRIBUTING.org
;;   OS:         make emacs texinfo

;;; Code:

(require 'ox-texinfo)

;;;; Public variables
;;   ----------------

(defvar my-docs-directory (expand-file-name "docs/" user-emacs-directory)
  "Directory containing this tree's Org documentation.")

(defvar my-docs-export-use-user-emacs-directory nil
  "When non-nil, look for documentation under `user-emacs-directory'.
Used by `my-docs-export' when no directory argument is given.")

;;;; Export
;;   ------

(defun my-docs-export-info ()
  "Export `emacs-config.info' from `emacs-config.org' in the current directory.
Remove the intermediate `.texi' file written by `org-texinfo-export-to-info'."
  (with-current-buffer (find-file "./emacs-config.org")
    (org-texinfo-export-to-info))
  (when (file-exists-p "./emacs-config.texi")
    (delete-file "./emacs-config.texi"))
  (message "Generated emacs-config.info file"))

(defun my-docs-export--sentinel (proc event)
  "Sentinel for `my-docs-export' providing customized message feedback.
PROC is unused.  EVENT contains the standard event-text from
`make-process'."
  (cond ((string-match-p "finished" event)
         (message "Emacs: docs export finished"))
        ((string-match-p "exited.*" event)
         (message "Emacs docs export %s.  See *my-docs-export* buffer for more information"
                  event))))

(defun my-docs-export (&optional my-docs-directory)
  "Export `emacs-config.info' in a separate Emacs session.
MY-DOCS-DIRECTORY is the `docs/' folder.  When omitted, use the
current directory if `my-docs.el' is present, else `docs/' under
`user-emacs-directory' when
`my-docs-export-use-user-emacs-directory' is non-nil, else prompt
with `read-directory-name'.

This does not use make; it runs Emacs as a separate process.
Export output is written to the `*my-docs-export*' buffer."
  (interactive
   (list
    (cond ((file-exists-p "./my-docs.el") ".")
          ((and my-docs-export-use-user-emacs-directory
                (boundp 'user-emacs-directory)
                (file-directory-p user-emacs-directory))
           (expand-file-name "docs/" user-emacs-directory))
          (t (read-directory-name "Emacs docs directory: ")))))
  (unless (executable-find "emacs")
    (user-error "Emacs is not in PATH"))
  (let ((docs-directory (expand-file-name my-docs-directory))
        (docs-script (expand-file-name "my-docs.el" my-docs-directory)))
    (if (file-exists-p docs-script)
        (make-process :name "my-docs-export"
                      :buffer "*my-docs-export*"
                      :command (list "emacs"
                                     "-Q" "--script" "my-docs.el"
                                     "--chdir" docs-directory
                                     "--funcall" "my-docs-export-info")
                      :sentinel #'my-docs-export--sentinel)
      (user-error "Directory %s is not this tree's docs directory"
                  docs-directory))))

(provide 'my-docs)
;;; my-docs.el ends here
