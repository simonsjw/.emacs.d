;;; project-support.el --- project support for the crafted setup   -*- lexical-binding: t; -*-

;; Copyright (C) 2022
;; SPDX-License-Identifier: MIT

;; Author: System Crafters Community
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

;;; Code:

;; my-project/load-parent-directories
;; my-project/scan-workspaces
;; my-project/save-parent-directories
;; my-project/add-parent-directory
;; my-project/remove-parent-directory



(setq xref-search-program 'ripgrep)
(customize-set-variable
 'xref-search-program 'ripgrep
 "use ripgrep over grep to search for things since is very fast.")

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
            (log/info :fn 'my-project/scan-workspaces
                      :msg "Scanning directory:"
                      :obj absolute-parent-dir)
            (project-remember-projects-under absolute-parent-dir 1)))             ; Add the directories to the load-path.
        my-project/workspace-list)

  )




(defun my-project/save-workspace-directories ()
  "Save the current value of `my-project/workspace-list' to file.

The file uses Emacs' project list format."
  (with-temp-file my-project/workspace-list-file
    (insert ";;; -*- lisp-data -*-\n")
    (insert (format "%S" my-project/workspace-list))))



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



;;; Project level dictionary
;; The project dictionary functionality provides a seamless way to configure
;; and persist a project-specific Aspell personal dictionary for spell-checking
;; in Emacs, particularly in programming modes, ensuring that technical terms
;; and jargon are recognised without polluting the global user dictionary. At
;; its core, the `my-prog-mode/set-project-dictionary' function orchestrates the
;; process by identifying the project root, locating or creating a
;; `.aspell.en.pws' file there, and setting the ispell-personal-dictionary
;; variable accordingly; it either copies the user's global dictionary from
;; their Emacs directory if the project file is absent, or merges any missing
;; words from the global dictionary into the existing project one using
;; `my-project/merge-aspell-dicts', which relies on `my-project/read-aspell-info' to parse both
;; files into structured data (including language, encoding, and word lists)
;; and `my-project/write-aspell' to rewrite the updated project file with sorted, unique
;; words. Simultaneously, it updates or creates the project's `.dir-locals.el'
;; file via `my-project/modify-dir-locals' to embed the dictionary setting for all
;; modes, preserving existing content and applying the changes immediately to
;; the current session. This integration delivers per-project spell-checking
;; customisation that inherits global words, enhances reproducibility across
;; Emacs sessions, and supports collaborative workflows by keeping
;; project-specific vocabulary localised and easily shareable.

(defun my-project/read-aspell-info (file)
  "Read Aspell personal dictionary FILE and return plist.

The plist will include :lang, :encoding, :words.
Assumes standard .pws format."
  (with-temp-buffer
    (insert-file-contents file)
    (goto-char (point-min))
    (let* ((header (string-trim (buffer-substring-no-properties
                                 (line-beginning-position)
                                 (line-end-position))))
           (parts (split-string header))
           (lang (nth 2 parts))
           (encoding (if (> (length parts) 4) (nth 4 parts) nil))
           (words nil))
      (forward-line 1)
      (while (not (eobp))
        (let ((word (string-trim (buffer-substring-no-properties
                                  (line-beginning-position)
                                  (line-end-position)))))
          (unless (string-empty-p word)
            (push word words)))
        (forward-line 1))
      (list :lang lang :encoding encoding :words (nreverse words)))))

(defun my-project/write-aspell (file lang encoding words)
  "Write WORDS to Aspell personal dictionary FILE with LANG and optional ENCODING.
Sorts words alphabetically and updates header count."
  (with-temp-file file
    (insert (format "personal_ws-1.1 %s %d%s\n"
                    lang
                    (length words)
                    (if encoding (concat " " encoding) "")))
    (dolist (word (sort words #'string<))
      (insert word "\n"))))

(defun my-project/merge-aspell-dicts (user-dict project-dict)
  "Merge words from USER-DICT into PROJECT-DICT, adding missing ones uniquely."
  (let* ((user-info (my-project/read-aspell-info user-dict))
         (project-info (my-project/read-aspell-info project-dict))
         (all-words (cl-union (plist-get user-info :words)
                              (plist-get project-info :words)
                              :test #'string=)))
    (my-project/write-aspell project-dict
                             (plist-get project-info :lang)
                             (plist-get project-info :encoding)
                             all-words)))

(defun my-project/modify-dir-locals (dir-locals-file project-dict)
  "Modify DIR-LOCALS-FILE to include `ispell-personal-dictionary'.

DIR-LOCALS-FILE will be set to PROJECT-DICT if missing.
The function reads, updates, and writes back the file while preserving structure."
  (let ((content (with-temp-buffer
                   (insert-file-contents dir-locals-file)
                   (read (current-buffer)))))
    (let ((nil-class (assoc nil content)))
      (unless (assoc 'ispell-personal-dictionary (cdr nil-class))
        (if nil-class
            (setcdr nil-class (append (cdr nil-class)
                                      `((ispell-personal-dictionary . ,project-dict))))
          (setq content (append content
                                `((nil . ((ispell-personal-dictionary . ,project-dict)))))))
        (with-temp-file dir-locals-file
          (pp content (current-buffer)))))))

(defun my-prog-mode/set-project-dictionary ()
  "Set `ispell-personal-dictionary' to a `.aspell.en.pws' in the project root.

This setting is also saved to `.dir-locals.el'.
- If .dir-locals.el exists and lacks the setting, add it and copy user dict if
  needed.
- If it exists and has the setting, merge missing words from user dict to
  project dict.
- If .dir-locals.el is new, create it with the setting and copy user dict.
Does not alter other .dir-locals.el content.

The function depends on a project dictionary template being located at
`var/INFODYNAMICS/dict_project.pws' with respect to the `user-emacs-directory'."
  (interactive)
  (let* ((project-root (or (project-root (project-current))
                           (user-error "No project detected")))
         (dir-locals-file (expand-file-name ".dir-locals.el" project-root))
         (project-dict (expand-file-name ".aspell.en.pws" project-root))
         (user-dict (expand-file-name "var/INFODYNAMICS/dict_project.pws" user-emacs-directory))
         (file-exists (file-exists-p dir-locals-file))
         (has-setting (and file-exists
                           (with-temp-buffer
                             (insert-file-contents dir-locals-file)
                             (goto-char (point-min))
                             (search-forward "ispell-personal-dictionary" nil t)))))
    (unless (file-exists-p user-dict)
      (user-error "User dictionary %s does not exist" user-dict))
    (if (file-exists-p project-dict)
        (my-project/merge-aspell-dicts user-dict project-dict)
      (copy-file user-dict project-dict))
    (if file-exists
        (unless has-setting
          (my-project/modify-dir-locals dir-locals-file project-dict))
      (with-temp-file dir-locals-file
        (insert (format "%S" `((nil . ((ispell-personal-dictionary . ,project-dict))))))))
    (dir-locals-read-from-dir project-root)
    (when (derived-mode-p 'prog-mode)
      (hack-dir-local-variables))
    (message "Project dictionary set to %s; updated %s. Run M-x normal-mode if needed."
             project-dict dir-locals-file)))


;;; my-project.el --- Modular functions for managing and displaying Emacs projects with Git info

;; COMPLETE CLEAN VERSION (2026-03-09) — FIXED FOR YOUR EMACS
;; • Each workspace group is in its own independent vtable (as requested)
;; • Bold workspace path above each table
;; • Empty line between groups
;; • NO repeated "Path Backend Branch..." bars anywhere in the buffer
;; • Column labels now appear cleanly in the buffer's header-line (standard vtable behaviour)
;; • Removed the unsupported :header keyword that caused the error
;; • Full RET / mouse-1 support to switch projects
;; • All original logic (grouping, Git info, formatting, etc.) preserved exactly

(require 'vtable)
(require 'cl-lib)

(defvar my-project/format-max-path-length 60
  "Maximum length for path display before truncation.")

(defvar my-project/format-max-remote-length 50
  "Maximum length for remote URL display before truncation.")

(defvar my-project/column-widths
  '(:path 65 :backend 10 :branch 15 :status 10 :upstream 20 :commit 15
          :remote 65 :stash 20)
  "Plist of column widths for text-based project display.")

(defvar my-project/vtable-columns
  (list
   (list :name "Path"     :width (plist-get my-project/column-widths :path)     :align 'left)
   (list :name "Backend"  :width (plist-get my-project/column-widths :backend))
   (list :name "Branch"   :width (plist-get my-project/column-widths :branch))
   (list :name "Status"   :width (plist-get my-project/column-widths :status))
   (list :name "Upstream" :width (plist-get my-project/column-widths :upstream))
   (list :name "Commit"   :width (plist-get my-project/column-widths :commit))
   (list :name "Remote"   :width (plist-get my-project/column-widths :remote))
   (list :name "Stash"    :width (plist-get my-project/column-widths :stash)))
  "Column definitions for the vtable display.")

(defun my-project/format-path (path)
  "Format the PATH for display, truncating if longer than
 `my-project/format-max-path-length'."
  (let ((l (length path)))
    (if (<= l my-project/format-max-path-length)
        path
      (concat (substring path 0 20) " ... " (substring path (- l 35) l)))))

(defun my-project/format-remote (remote)
  "Format REMOTE URL for display, truncating if longer than
 `my-project/format-max-remote-length'."
  (if (string-match-p "^\\(no remote\\|none\\|N/A\\)$" remote)
      remote
    (let ((l (length remote)))
      (if (<= l my-project/format-max-remote-length)
          remote
        (concat (substring remote 0 20) "..." (substring remote (- l 35) l))))))

(defun my-project/get-canonical-pairs (dirs)
  "Return a list of (original . canonical-directory) pairs for DIRS.
Canonical paths resolve symlinks and expand to absolute paths."
  (mapcar (lambda (orig)
            (cons orig
                  (file-name-as-directory
                   (file-truename (expand-file-name orig)))))
          dirs))

(defun my-project/get-grouped-projects ()
  "Group projects by workspace and return a cons cell.

The cons cell is (PROJECT-GROUPS . UNGROUPED-PROJECTS).

This function organizes Emacs projects (from `project--list') under workspaces
 (from `my-project/workspace-list').  It resolves paths to canonical forms to
handle symlinks and absolute paths accurately.  Projects are grouped under the
workspace with the longest matching prefix (deepest nesting).  Ungrouped
projects are those without any matching workspace.

Returns:
- PROJECT-GROUPS: A hash table where keys are original workspace paths
  (strings), and values are lists of project pairs
  (original-path . canonical-path), sorted alphabetically by original path.
- UNGROUPED-PROJECTS: A list of project pairs not matching any workspace, sorted
  alphabetically by original path.

Handles cases where `my-project/workspace-list' or `project--list' are unbound
or empty by signaling a user-error if neither provides data.

Depends on `my-project/get-canonical-pairs' to create (original . canonical)
pairs."
  (let* ((workspaces-orig (progn
                            (if (boundp 'my-project/workspace-list)
                                nil
                              (my-project/load-workspace-directories))
                            (mapcar #'car my-project/workspace-list)))
         (projects-orig (if (boundp 'project--list)
                            (mapcar #'car project--list)
                          nil))
         (workspace-pairs
          (my-project/get-canonical-pairs (or workspaces-orig '())))
         (project-pairs
          (my-project/get-canonical-pairs (or projects-orig '())))
         (project-groups (make-hash-table :test 'equal))
         (ungrouped-projects nil))
    (unless (or workspaces-orig projects-orig)
      (user-error "No workspaces or projects available to display"))
    (dolist (ws-orig workspaces-orig)
      (puthash ws-orig nil project-groups))
    (dolist (proj-pair project-pairs)
      (let* ((proj-canon (cdr proj-pair))
             (matching-ws nil))
        (dolist (ws-pair workspace-pairs)
          (when (string-prefix-p (cdr ws-pair) proj-canon)
            (push ws-pair matching-ws)))
        (if matching-ws
            (let* ((best-ws-pair (car
                                  (sort matching-ws
                                        (lambda (a b) (> (length (cdr a))
                                                         (length (cdr b)))))))
                   (best-ws-orig (car best-ws-pair)))
              (puthash best-ws-orig
                       (cons proj-pair (gethash best-ws-orig project-groups))
                       project-groups))
          (push proj-pair ungrouped-projects))))
    (dolist (ws-orig workspaces-orig)
      (puthash ws-orig (sort (gethash ws-orig project-groups)
                             (lambda (a b) (string< (car a) (car b))))
               project-groups))
    (setq ungrouped-projects
          (sort ungrouped-projects (lambda (a b) (string< (car a) (car b)))))
    (cons project-groups ungrouped-projects)))

(defun my-project/git-repo-info (dir)
  "Return a property list (plist) of Git repository information for DIR.

Default to nil if DIR is not a Git repo."
  (let ((default-directory (file-truename (expand-file-name dir))))
    (when (eq (vc-responsible-backend default-directory) 'Git)
      (condition-case err
          (let* ((branch
                  (string-trim
                   (or (vc-git--run-command-string nil "rev-parse" "--abbrev-ref" "HEAD") "")))
                 (status-output
                  (vc-git--run-command-string nil "status" "--porcelain"))
                 (status
                  (if (string-empty-p (or status-output "")) "clean" "dirty"))
                 (upstream
                  (string-trim
                   (or (vc-git--run-command-string
                        nil "rev-parse" "--abbrev-ref" "--symbolic-full-name" "@{upstream}") "")))
                 (commit
                  (string-trim
                   (or (vc-git--run-command-string nil "rev-parse" "--short" "HEAD") "")))
                 (remote
                  (string-trim
                   (or (vc-git--run-command-string nil "remote" "get-url" "origin") "")))
                 (stash-output
                  (vc-git--run-command-string nil "stash" "list"))
                 (stash
                  (if (string-empty-p (or stash-output "")) "Nothing stashed" "Stashed changes exist")))
            (list :backend 'Git
                  :branch (if (string-empty-p branch) "no commits" branch)
                  :status status
                  :upstream (if (or (string-empty-p upstream) (string-match-p "fatal" upstream)) "none" upstream)
                  :commit (if (string-empty-p commit) "no commits" commit)
                  :remote (if (or (string-empty-p remote) (string-match-p "fatal" remote)) "no remote" remote)
                  :stash stash))
        (error (message "Error getting Git info for %s: %s" dir (error-message-string err))
               nil)))))

(defun my-project--make-row (proj-pair)
  "Create a vtable row object from a (original . canonical) PROJ-PAIR."
  (let ((orig (car proj-pair))
        (canon (cdr proj-pair)))
    (list :original orig
          :canonical canon
          :info (my-project/git-repo-info canon))))

(defun my-project--vtable-getter (row column vtable)
  "Extract the value for COLUMN from ROW for the vtable."
  (let ((info (plist-get row :info))
        (col-name (vtable-column vtable column)))
    (pcase col-name
      ("Path"     (format "  %s" (my-project/format-path (plist-get row :original))))
      ("Backend"  (if info (or (plist-get info :backend) "-") "-"))
      ("Branch"   (if info (or (plist-get info :branch) "no commits") "-"))
      ("Status"   (if info (or (plist-get info :status) "-") "-"))
      ("Upstream" (if info (or (plist-get info :upstream) "none") "-"))
      ("Commit"   (if info (or (plist-get info :commit) "no commits") "-"))
      ("Remote"   (if info (my-project/format-remote (or (plist-get info :remote) "no remote")) "-"))
      ("Stash"    (if info (or (plist-get info :stash) "Nothing stashed") "-"))
      (_ "-"))))

(defun my-project--switch-to-project (row)
  "Switch to the project using the canonical path stored in the vtable ROW."
  (when-let ((path (plist-get row :canonical)))
    (project-switch-project path)))

(defun my-project/visualise-projects ()
  "Display a navigable list of projects grouped by workspaces using vtable.

Exactly as requested:
- Each project group is in its own independent vtable
- Workspace path (bold) appears above each table
- Empty line between groups
- NO column headers in the buffer body (labels now appear cleanly in the header-line)"
  (interactive)
  (let* ((grouped (my-project/get-grouped-projects))
         (project-groups (car grouped))
         (ungrouped-projects (cdr grouped)))

    (switch-to-buffer (get-buffer-create "*Organized Projects*"))
    (erase-buffer)

    (cl-labels ((insert-group (title projects)
                  (when projects
                    (insert (propertize (format "%s\n" title) 'face 'bold))
                    (insert "\n")
                    (make-vtable
                     :columns my-project/vtable-columns
                     :objects (mapcar #'my-project--make-row projects)
                     :getter #'my-project--vtable-getter
                     :use-header-line t          ; ← This removes repeated headers from the body
                     :actions '("RET" my-project--switch-to-project
                                "<mouse-1>" my-project--switch-to-project))
                    (insert "\n\n"))))
      ;; Grouped workspaces
      (dolist (ws-orig (sort (hash-table-keys project-groups) #'string<))
        (insert-group (my-project/format-path ws-orig)
                      (gethash ws-orig project-groups)))

      ;; Ungrouped projects
      (insert-group "Other Projects" ungrouped-projects))

    (goto-char (point-min))
    (view-mode 1)
    (tab-line-mode 1)))


(log/debug :fn 'project-support
           :msg "Ending load of the project-support module."
           :obj t)

(provide 'project-support)
;;; project-support.el ends here

;; LocalWords:  simon emacs mapc WDD  dotfiles workspaces backend
