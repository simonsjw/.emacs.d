;;; project-support.el --- Project.el integration and project-view loader. -*- lexical-binding: t; -*-

;; Copyright (C) 2026 Simon Watson
;; SPDX-License-Identifier: MIT

;; Author: Simon Watson

;;; Commentary:

;; Built-in `project.el' integration and the loader for the local
;; `project-view' package.  Sets `xref-search-program' to ripgrep,
;; appends a transient directory fallback after VC finders, and
;; provides helpers to create a project from
;; `project-templates-archive' (defined in `path-support.el'; do not
;; reintroduce a local copy here).  Keys live in `keymaps-project.el'
;; (`C-c p').  Load from `init.el' after `logging-config'.
;;
;; The environment variable `PROJECT_PATHS' is documented in `conf.org'
;; and `docs/os-integrations.org' for a later project-view follow-up.
;; Lisp does not read it today.
;;
;; Map:
;;   Feature:    project-support
;;   Load-after: path-support logging-config
;;   Load-phase: ide
;;   Keymaps:    keymaps-project.el
;;   Docs:       docs/project-support.org
;;   OS:         ripgrep

;;; Code:

(require 'path-support)
(require 'logging-config)
(log/debug :fn 'project-support
           :msg "Starting load of the project-support module."
           :obj t)

(require 'project)

;;;; Packages
;;   --------

(use-package consult-project-extra
  :ensure t
  :bind
  (("C-c p f" . consult-project-extra-find)
   ("C-c p o" . consult-project-extra-find-other-window)))

(use-package project-view
  :load-path my-paths/project-view
  :ensure nil)

;;;; Xref search
;;   -----------

(customize-set-variable
 'xref-search-program 'ripgrep
 "Use ripgrep over grep; it is much faster on large trees.")

;;;; Transient project fallback
;;   --------------------------

(defun my-project/fallback (dir)
  "Treat DIR itself as a transient project root when no other finder succeeds.
Skip `/tmp/', `/var/tmp/', and `/proc/'.  Return `(transient . DIR)'
or nil.  Appended on `project-find-functions' so VC finders run first."
  (let ((expanded (expand-file-name dir)))
    (unless (or (string-prefix-p "/tmp/" expanded)
                (string-prefix-p "/var/tmp/" expanded)
                (string-prefix-p "/proc/" expanded))
      (cons 'transient (file-name-as-directory expanded)))))

;; Append so it only runs after `project-try-vc' (and any other
;; finders) return nil.
(add-to-list 'project-find-functions #'my-project/fallback t)

;;;; Project templates
;;   -----------------

;; `project-templates-archive' is defined in `path-support.el'.  Do
;; not add a second copy here.

(defun my-project/template-name-list ()
  "Return language folder names stored in `project-templates-archive'.
Each top-level folder under the archive is a coding-language
template that can initialise a new repo."
  (let* ((string-list
          (split-string
           (shell-command-to-string
            (format "tar -tf %s" project-templates-archive))
           "\n" t))
         (result nil))
    (dolist (str string-list)
      (when (string-match "^[^/]+/\\([^/]+\\)/" str)
        (let ((match (match-string 1 str)))
          (unless (member match result)
            (push match result)))))
    (nreverse result)))

(defun my-project/create-project-from-template (&optional template parent-dir project-name)
  "Create a new project from a template in `project-templates-archive'.
TEMPLATE is the template folder name in the archive (for example
\"latex\" or \"python\").  PARENT-DIR is the directory that will
contain the new project.  PROJECT-NAME is the new directory name.

Extract TEMPLATE into PARENT-DIR/PROJECT-NAME, run `git init', and
report success or signal an error.  Interactively, prompt for all
three arguments with completion on template names."
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


;;;; Sequential query-replace
;;   ------------------------

(defun my-project/query-replace-regexp-one-by-one (regexp to-string)
  "Query-replace REGEXP with TO-STRING one project file at a time.
Like `project-query-replace-regexp' but process files sequentially.
Open each file, run an interactive `query-replace', save if modified,
then kill the buffer before moving to the next file."
  (interactive
   (let ((args (query-replace-read-args
                "Query replace regexp in project (one file at a time)" t t)))
     (list (nth 0 args) (nth 1 args))))
  (let* ((pr (project-current t))
         (files (project-files pr))
         (case-fold-search nil))          ; keep case-sensitive like the original
    (dolist (file files)
      (when (and (file-regular-p file)
                 (not (file-symlink-p file)))
        (let ((buf (find-file-noselect file)))
          (with-current-buffer buf
            (goto-char (point-min))
            (perform-replace regexp to-string
                             t               ; query
                             t               ; regexp-flag
                             nil             ; delimited
                             nil nil
                             (point-min) (point-max))
            (when (buffer-modified-p)
              (save-buffer)))
          (kill-buffer buf)
          (message "Finished %s" file))))))

(log/debug :fn 'project-support
           :msg "Ending load of the project-support module."
           :obj t)

(provide 'project-support)
;;; project-support.el ends here
