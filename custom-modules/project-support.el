;;; project-support.el --- project support for the crafted setup   -*- lexical-binding: t; -*-

;; Copyright (C) 2022
;; SPDX-License-Identifier: MIT

;; Author: System Crafters Community
;; Keywords: project.el, projects

;;; Commentary:

;; This package provides project support and sets up the project.el package.



;;; Packages phase:

(use-package consult-project-extra
  :bind
  (("C-c p f" . consult-project-extra-find)
   ("C-c p o" . consult-project-extra-find-other-window)))

(require 'consult-project-extra)

;;; Code:

;; my-project/load-parent-directories
;; my-project/scan-workspaces
;; my-project/save-parent-directories
;; my-project/add-parent-directory
;; my-project/remove-parent-directory


;; (defun project-remember-projects-under (dir &optional recursive)
;;   "Index all projects below a directory DIR.
;; If RECURSIVE is non-nil, recurse into all subdirectories to find
;; more projects.  After finishing, a message is printed summarizing
;; the progress.  The function returns the number of detected
;; projects."
;;   (interactive "DDirectory: \nP")
;;   (project--ensure-read-project-list)

;;   (message "%s" recursive)
;;   (let ((dirs (if recursive
;;                   (directory-files-recursively dir "" t)
;;                 (directory-files dir t)))
;;         (known (make-hash-table :size (* 2 (length project--list))
;;                                 :test #'equal))
;;         (count 0))
;;     (dolist (project (mapcar #'car project--list))
;;       (puthash project t known))
;;     (message "subdirs: %s" dirs)
;;     (dolist (subdir dirs)
;;       (when-let (((file-directory-p subdir))
;;                  (project (project--find-in-directory subdir))
;;                  (project-root (project-root project))
;;                  ((not (gethash project-root known))))
;;         (message "project: %s:"( project-root project))
;;         (project-remember-project project t)
;;         (puthash project-root t known)
;;         (message "Found %s..." project-root)
;;         (setq count (1+ count))))
;;     (if (zerop count)
;;         (message "No projects were found")
;;       (project--write-project-list)
;;       (message "%d project%s were found"
;;                count (if (= count 1) "" "s")))
;;     count))



(defun my-project/load-workspace-directories ()
  "Load `my-project/workspace-list' from the stored file."
  (let* ((workspaces-file my-project/workspace-list-file)
         (workspaces-list (when (file-exists-p workspaces-file)
                            (with-temp-buffer
                              (insert-file-contents workspaces-file)
                              (read (current-buffer))))))

    (setq my-project/workspace-list workspaces-list)))


(defun my-project/scan-workspaces ()
  "Interactively scan for new projects.

The list of directories in `my-project/workspace-list' will be scanned
recursively for projects."
  (interactive)
  
  (mapc (lambda (parent-dir)
          (let ((absolute-parent-dir (file-truename (car parent-dir))))
            ;; Process the directory string here.
            (message "Scanning directory: %s" absolute-parent-dir)
            (project-remember-projects-under absolute-parent-dir 1)))             ; Add the directories to the load-path.
        my-project/workspace-list)

  )


(defun my-project/save-workspace-directories ()
  "Save the current value of `my-project/workspace-list' to file.

The file uses Emacs' project list format."
  (with-temp-file my-project/workspace-list-file
    (insert ";;; -*- lisp-data -*-\n")
    (insert (format "%S" my-project/workspace-list))))


;; (defun my-project/save-workspace-directories ()
;;   "Save `my-project/workspace-list` to `old_project_paths.el`,
;; ensuring a distinct, cumulative set of paths over time."
;;   (let* ((workspace-file "~/.emacs.d/var/projects/old_project_paths.el")
;;          (existing-data (when (file-exists-p workspace-file)
;;                           (with-temp-buffer
;;                             (insert-file-contents workspace-file)
;;                             (read (current-buffer)))))
;;          ;; Ensure it's a proper list-of-lists format
;;          (existing-paths (if (and existing-data (listp existing-data))
;;                              existing-data
;;                            '()))
;;          ;; Convert current workspace list to list-of-lists format
;;          (new-paths (mapcar #'list my-project/workspace-list))
;;          ;; Merge and deduplicate
;;          (updated-paths (delete-dups (append existing-paths new-paths))))

;;     ;; Save back to file
;;     (with-temp-file workspace-file
;;       (insert ";;; -*- lisp-data -*-\n")
;;       (insert (format "%S" updated-paths)))

;;     (message "Saved workspace directories. Total: %d" (length updated-paths))))



(defun my-project/add-workspace-directory (dir)
  "Add DIR as a project directory in Emacs' expected format."
  (interactive "DDirectory: ")
  (let ((expanded-dir (expand-file-name dir)))
    (unless (member (list expanded-dir) my-project/workspace-list)
      (setq my-project/workspace-list
            (append my-project/workspace-list (list (list expanded-dir)))))
    (my-project/save-workspace-directories)
    (message "Added workspace directory: %s" expanded-dir)))


(defun my-project/remove-workspace-directory (dir)
  "Remove DIR from `my-project/workspace-list'."
  (interactive "sDirectory to remove: ")
  (let ((expanded-dir (expand-file-name dir)))
    (setq my-project/workspace-directories
          (remove (list expanded-dir) my-project/workspace-directories))
    (my-project/save-workspace-directories)
    (message "Removed workspace directory: %s" expanded-dir)))



;;; Configuration phase


;; Load the parent directory paths.
;; Paths project-list-file and my-project/workspace-list-file set in
;; path-support.el.
(my-project/load-workspace-directories)

;; (project-remember-projects-under DIR &optional RECURSIVE)
;; (project-remember-project PR &optional NO-WRITE)


;; (expand-file-name "/mnt/HDD04_WDD_08TB/workspace/")

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
                                                                                  ; LocalWords:  mapc
                                                                                  ; LocalWords:  WDD
                                                                                  ; LocalWords:  dotfiles
