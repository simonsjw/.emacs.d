;;; project-support.el --- project support for the crafted setup   -*- lexical-binding: t; -*-

;; Copyright (C) 2022
;; SPDX-License-Identifier: MIT

;; Author: Simon Watson
;; Keywords: project.el, projects

;;; Commentary:

;; This package provides project support and sets up the project.el package.

;;; Packages phase:

(require 'path-support)
(require 'logging-config)
(log/debug :fn 'project-support
           :msg "Starting load of the project-support module."
           :obj t)

(use-package consult-project-extra
  :bind
  (("C-c p f" . consult-project-extra-find)
   ("C-c p o" . consult-project-extra-find-other-window)))

(require 'consult-project-extra)

(use-package project-view
  :load-path my-paths/project-view
  :ensure nil)         ; local package – never try ELPA/MELPA/straight

;;; Code:


(setq xref-search-program 'ripgrep)
(customize-set-variable
 'xref-search-program 'ripgrep
 "use ripgrep over grep to search for things since is very fast.")



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

### Behaviour:
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
                                  "--strip-components=2"
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

(log/debug :fn 'project-support
           :msg "Ending load of the project-support module."
           :obj t)

(provide 'project-support)
;;; project-support.el ends here

;; LocalWords:  simon emacs mapc WDD  dotfiles workspaces backend
