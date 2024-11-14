;;; custom-project-overview.el --- Project Overview in Emacs -*- lexical-binding: t; -*-

;; Author: Your Name
;; Version: 1.0
;; Package-Requires: ((emacs "26.1") (projectile "2.0.0") (magit "3.0.0"))
;; Keywords: project, git, management
;; URL: https://your-repository-url

;;; Commentary:

;; This Emacs package provides a project overview that displays information
;; about your projects, such as Git status, last edit times, and allows
;; batch operations like pushing or pulling from remotes.

;;; Code:

(require 'tabulated-list)
(require 'projectile)
(require 'magit)

;; **1. Define a New Major Mode for the Project Overview**

;; We create a derived mode from `tabulated-list-mode` to display our projects in a table.

(define-derived-mode custom-project-overview/mode tabulated-list-mode "Projects"
  "Major mode for displaying an overview of projects.

\\<custom-project-overview/mode-map>
Press \\[custom-project-overview/refresh] to refresh the list.
Press \\[custom-project-overview/push] to push marked projects.
Press \\[custom-project-overview/pull] to pull marked projects."
  ;; Define the columns: Name, Last Edit, Git Status, etc.
  (setq tabulated-list-format
        [("Name" 30 t)                 ; Project name
         ("Last Edit" 20 t)            ; Last modification time
         ("Git Status" 20 t)           ; Git status summary
         ("Remote Status" 20 t)        ; Remote repository status
         ("Size" 10 t)                 ; Project size
         ("Last Commit Msg" 50 t)      ; Last commit message
         ("Last Commit Date" 20 t)])   ; Last commit date
  ;; Set padding between rows
  (setq tabulated-list-padding 2)
  ;; Initialize the header
  (tabulated-list-init-header))

;; **2. Function to Calculate Project Directory Size**

(defun custom-project-overview/project-directory-size (dir)
  "Calculate the total size of directory DIR, excluding symbolic links."
  (let ((size 0))
    (dolist (file (directory-files-recursively dir ".*" t))
      (unless (file-symlink-p file)
        (setq size (+ size (file-attribute-size (file-attributes file))))))
    size))

;; **3. Function to Refresh the Project Overview List**

(defun custom-project-overview/refresh ()
  "Refresh the list of projects in the project overview buffer."
  (interactive)
  ;; Build the entries for `tabulated-list-entries`
  (setq tabulated-list-entries
        (mapcar (lambda (project)
                  ;; Set the default directory to the project path
                  (let* ((default-directory project)
                         ;; Get the project name
                         (name (file-name-nondirectory
                                (directory-file-name project)))
                         ;; Get the last modification time of the project directory
                         (last-edit (format-time-string
                                     "%Y-%m-%d %H:%M"
                                     (nth 5 (file-attributes
                                             (directory-file-name project)))))
                         ;; Get the Git status (short format)
                         (git-status (string-trim
                                      (shell-command-to-string
                                       "git status --short")))
                         ;; Get the remote repository URL, if any
                         (remote-status (magit-get "remote" "origin" "url"))
                         ;; Calculate the project size in human-readable format
                         (size (file-size-human-readable
                                (custom-project-overview/project-directory-size project)))
                         ;; Get the last commit message
                         (last-commit-msg (string-trim
                                           (magit-git-string
                                            "log" "-1" "--pretty=%B")))
                         ;; Get the last commit date
                         (last-commit-date (magit-git-string
                                            "log" "-1" "--pretty=%ci")))
                    ;; Create the entry for the table
                    (list project
                          (vector name last-edit git-status remote-status
                                  size last-commit-msg last-commit-date))))
                ;; Get the list of relevant known projects from Projectile
                (projectile-relevant-known-projects)))
  ;; Refresh the table display
  (tabulated-list-print t))

;; **4. Entry Point Function to Open the Project Overview**

(defun custom-project-overview/open ()
  "Open the project overview buffer."
  (interactive)
  (let ((buffer (get-buffer-create "*Project Overview*")))
    (with-current-buffer buffer
      ;; Activate our custom major mode
      (custom-project-overview/mode)
      ;; Refresh the project list
      (custom-project-overview/refresh))
    ;; Switch to the project overview buffer
    (switch-to-buffer buffer)))

;; **5. Key Bindings for Actions in the Project Overview Mode**

;; Define key bindings for common actions within our mode
(define-key custom-project-overview/mode-map (kbd "g") 'custom-project-overview/refresh)
(define-key custom-project-overview/mode-map (kbd "P") 'custom-project-overview/push)
(define-key custom-project-overview/mode-map (kbd "F") 'custom-project-overview/pull)
(define-key custom-project-overview/mode-map (kbd "m") 'tabulated-list-mark)
(define-key custom-project-overview/mode-map (kbd "u") 'tabulated-list-unmark)

;; **6. Function to Get Marked Projects**

(defun custom-project-overview/get-marked-projects ()
  "Retrieve a list of projects that have been marked by the user."
  (let ((projects '()))
    (save-excursion
      ;; Iterate over each line in the table
      (goto-char (point-min))
      (while (not (eobp))
        ;; If the current line is marked, add its project to the list
        (when (eq (char-after) ?*)
          (let ((project (tabulated-list-get-id)))
            (push project projects)))
        (forward-line 1)))
    projects))

;; **7. Function to Push Changes to Remotes**

(defun custom-project-overview/push ()
  "Push changes to the remote repositories of the marked projects."
  (interactive)
  (dolist (project (custom-project-overview/get-marked-projects))
    (let ((default-directory project))
      (if (magit-git-repo-p)
          (progn
            ;; Push to the current branch's push-remote
            (magit-push-current-to-pushremote nil)
            (message "Pushed %s" project))
        (message "Not a Git repository: %s" project)))))

;; **8. Function to Pull Changes from Remotes**

(defun custom-project-overview/pull ()
  "Pull changes from the remote repositories of the marked projects."
  (interactive)
  (dolist (project (custom-project-overview/get-marked-projects))
    (let ((default-directory project))
      (if (magit-git-repo-p)
          (progn
            ;; Pull from the current branch's upstream
            (magit-pull-from-upstream nil)
            (message "Pulled %s" project))
        (message "Not a Git repository: %s" project)))))

;; **9. Provide the Feature**

;; This statement makes the feature 'custom-project-overview' available for
;; `require` in other files.
(provide 'custom-project-overview)

;;; custom-project-overview.el ends here
