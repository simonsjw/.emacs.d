;;; project-support.el --- project support for the crafted setup   -*- lexical-binding: t; -*-

;; Copyright (C) 2022
;; SPDX-License-Identifier: MIT

;; Author: System Crafters Community
;; Keywords: project.el, projects

;;; Commentary:

;; This package provides project support and sets up the project.el package.

;;; Code:

;;; Packages phase

(use-package consult-project-extra
  :bind
  (("C-c p f" . consult-project-extra-find)
   ("C-c p o" . consult-project-extra-find-other-window)))

;;; Configuration phase


(require 'consult-project-extra)


;; (defun my-project/add-projects-from-csv (csv-file)
;;   "Add projects to Projectile from a CSV-FILE path.

;; The first column of the CSV contains the project paths."
;;   (interactive "fCSV File: ")
;;   (with-temp-buffer
;;     (insert-file-contents csv-file)
;;     (forward-line 1)                                                              ; Skip the header line
;;     (while (not (eobp))
;;       (let* ((line (buffer-substring-no-properties
;;                     (line-beginning-position) (line-end-position)))
;;              (fields (split-string line ","))
;;              (project-path (car fields)))
;;         (setq project-path                                                        ; Remove quotes around the path
;;               (replace-regexp-in-string "\"" "" project-path))
;;         (message "Processing path: %s" project-path)                              ; Debug: Print the current path
;;         (when (and project-path (file-directory-p project-path))
;;           (with-eval-after-load 'projectile                                       ; Ensure Projectile is loaded before calling its functions
;;             (if (projectile-project-p project-path)
;;                 (message "Skipping known project: %s" project-path)
;;               (progn
;;                 (projectile-add-known-project project-path)
;;                 (message "Added project: %s" project-path)))))
;;         (forward-line 1)))))






;; Call this function with the path to your CSV file
;; (let ((REPO_LIST (getenv "REPO_LIST")))
;;   (my/add-projects-from-csv REPO_LIST))

(provide 'project-support)
;;; project-support.el ends here

                                                                                  ; LocalWords:  simon
                                                                                  ; LocalWords:  emacs
