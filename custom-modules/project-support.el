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


;; the path to the templates archive should already be set in
;; custom-path-support.el as below.  It is commented out here so we know if
;; there are any issues with that process.
;; (defvar project-templates-archive
;;   (expand-file-name "~/.emacs.d/var/project-templates.tar.xz")
;;   "Path to the project templates archive file.")

(defun my-project/template-name-list ()
  "Return a list of folders in the `project-templates-archive.tar.zx' archive.
Each of these folders is a coding language so this can be used to select
folders to be used as the basis for initialising a code repo."
  (let* (
         (string-list
          (split-string
           (shell-command-to-string
            (format "tar -tf %s" project-templates-archive)) "\n" t))
         (result nil)
         )
    (dolist (str string-list)
      (when (string-match "^[^/]+/\\([^/]+\\)/" str)
        (let ((match (match-string 1 str)))
          (unless (member match result)
            (push match result)))))
    (nreverse result)))


(defun my-project/create-project-from-template (&optional template parent-dir project-name)
  "Create a new project from a template in the archive.

This function can be called programmatically with optional arguments or
interactively with prompts for user input.

### Arguments:
- TEMPLATE (optional): A string specifying the name of the template folder in
  the archive (e.g., 'latex', 'python').  If not provided, the user is prompted
  to select one.
- PARENT-DIR (optional): A string specifying the directory where the new project
  directory will be created.  If not provided, the user is prompted to specify
  it.
- PROJECT-NAME (optional): A string specifying the name of the new project
  directory.  If not provided, the user is prompted to enter it.

### Behavior:
1. Extracts the specified template from the archive to PARENT-DIR/PROJECT-NAME.
2. Initializes a Git repository in the new project directory.
3. Provides feedback via messages or errors if something goes wrong.

When called interactively, it prompts for all required inputs using a completion
interface for templates and standard directory/string prompts."
  (interactive
   (let* (
          ;; Retrieve the list of templates from the archive
          (output (shell-command-to-string
                   (format "tar -tf %s" project-templates-archive)))
          (lines (split-string output "\n" t))
          ;; Filter lines to get top-level directories (templates) ending "/"
          (template-names (my-project/template-name-list))
          ;; Prompt user to select a template with completion
          (selected-template
           (completing-read "Select template: " template-names nil t))
          ;; Prompt user for the parent directory
          (parent-dir
           (read-directory-name "Parent directory for new project: "))
          ;; Prompt user for the project name
          (project-name (read-string "Project name: ")))
     ;; Return the interactively collected values as a list
     (list selected-template parent-dir project-name)))

  ;; --- Validate the archive existence ---
  (unless (file-exists-p project-templates-archive)
    (error "Archive file %s does not exist" project-templates-archive))

  ;; --- Retrieve available templates for validation ---
  (let* ((output
          (shell-command-to-string
           (format "tar -tf %s" project-templates-archive)))
         (lines (split-string output "\n" t))
         (template-names
          (cl-loop for line in lines
                   if (and (string-suffix-p "/" line)
                           (not (string-match "/" (substring line 0 -1))))
                   collect (substring line 0 -1))))

    ;; --- Set parent-dir and project-name if not provided ---
    (unless parent-dir
      (setq parent-dir (nth 1 (interactive))))
    (unless project-name
      (setq project-name (nth 2 (interactive))))

    ;; --- Construct the full project directory path ---
    (let ((project-dir (expand-file-name project-name parent-dir)))
      ;; Check if the project directory already exists to avoid overwriting
      (when (file-exists-p project-dir)
        (error "Directory %s already exists" project-dir))

      ;; Create the project directory (with parents if needed)
      (make-directory project-dir t)

      ;; --- Extract the template from the archive ---
      (let ((status (call-process "tar" nil nil nil
                                  "--xz" "-xf" project-templates-archive
                                  "-C" project-dir
                                  "--strip-components=2"                          ; strip the project-templates folder and the project type folder. 
                                  (concat "project-templates/" template "/"))))
        (unless (zerop status)
          (error "Failed to extract template: tar exited with status %d"
                 status)))

      ;; --- Initialize a Git repository in the new project directory ---
      (let ((status (call-process "git" nil nil nil "init" project-dir)))
        (unless (zerop status)
          (error
           "Failed to initialize git repository: git exited with status %d"
           status)))

      ;; --- Notify the user of success ---
      (message "Project %s created successfully in %s."
               project-name parent-dir))))


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
