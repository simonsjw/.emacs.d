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
Does not alter other .dir-locals.el content."
  (interactive)
  (let* ((project-root (or (project-root (project-current))
                           (user-error "No project detected")))
         (dir-locals-file (expand-file-name ".dir-locals.el" project-root))
         (project-dict (expand-file-name ".aspell.en.pws" project-root))
         (user-dict (expand-file-name ".aspell.en.pws" user-emacs-directory))
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

;; Common logic (e.g., path formatting, grouping projects by workspaces,
;; canonical path resolution) is extracted into separate functions.
;; Duplicated code between `my-project-list' and
;; `my-project/visualise-projects' is minimized by sharing utilities. The
;; tabulated-list-mode display now includes all Git info columns (fixing the
;; original mismatch between format and vector length). Error handling and
;; checks for required variables are consistent.


;; Fixes applied:
;; - Dynamically construct the format string using nested `format' calls, e.g.,
;;   (format (format "%%-%ds" width) value).
;;   Built format strings for headers and lines accordingly.
;; - excludes :path, which is handled separately).
;; - Adjusted padding for project paths (indented by 2 spaces) to fit within
;;   :path width.
;; - Use left-aligned columns using %%-%ds for better readability.
;; - Ensured consistent handling for non-Git projects with fallback "-" in
;;   columns.

;; Assumptions:
;; - `project--list' and `my-project/workspace-list' are defined elsewhere
;;   (e.g., via project.el customisation).
;; - Projects and workspaces are directory paths.
;; - Only Git backend is supported via VC, but extensible if needed.
;; - Clicking or RET on a project path invokes `project-switch-project'.

(defvar my-project/format-max-path-length 60
  "Maximum length for path display before truncation.")

(defvar my-project/format-max-remote-length 50
  "Maximum length for remote URL display before truncation.")

(defvar my-project/column-widths
  '(:path 65 :backend 10 :branch 15 :status 10 :upstream 20 :commit 15
          :remote 65 :stash 20)
  "Plist of column widths for text-based project display.")

(defun my-project/format-path (path)
  "Format the PATH for display,

This function truncates any path if longer than
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
                            (if (boundp 'my-project/workspace-list)               ; Check if custom workspace list variable is bound.
                                nil
                              (my-project/load-workspace-directories))            ; If not bound, use `my-project/workspace-list' to load it.
                            (mapcar #'car my-project/workspace-list)))            ; Extract the car (first element) of each item, assuming it's a list of cons or lists where car is the path.
         (projects-orig (if (boundp 'project--list)                               ; Check if project.el's project list is bound.
                            (mapcar #'car project--list)                          ; Extract car (path) from each project entry.
                          nil))                                                   ; If not, set to nil.
         (workspace-pairs
          (my-project/get-canonical-pairs (or workspaces-orig '())))              ; Convert workspace paths to (original . canonical) pairs, using empty list if nil.
         (project-pairs                                                           ;
          (my-project/get-canonical-pairs (or projects-orig '())))                ; Similarly for projects.
         (project-groups (make-hash-table :test 'equal))                          ; Create a hash table with string keys (original workspaces) using equal for comparison.
         (ungrouped-projects nil))                                                ; Initialise list for projects without matching workspaces.
    (unless (or workspaces-orig projects-orig)                                    ; If both originals are nil or empty.
      (user-error "No workspaces or projects available to display"))              ; Signal an error to the user.
    ;; Initialize hash table with empty lists for each workspace.
    (dolist (ws-orig workspaces-orig)                                             ; Loop over each original workspace path.
      (puthash ws-orig nil project-groups))                                       ; Insert key with empty list value.
    ;; Group projects under the deepest matching workspace.
    (dolist (proj-pair project-pairs)                                             ; Loop over each project pair.
      (let* ((proj-canon (cdr proj-pair))                                         ; Extract canonical project path.
             (matching-ws nil))                                                   ; Initialise list for matching workspace pairs.
        (dolist (ws-pair workspace-pairs)                                         ; Loop over workspace pairs.
          (when (string-prefix-p (cdr ws-pair) proj-canon)                        ; Check if workspace canonical is prefix of project canonical.
            (push ws-pair matching-ws)))                                          ; If yes, add to matching list.
        (if matching-ws                                                           ; If there are matches.
            (let* ((best-ws-pair (car
                                  (sort matching-ws
                                        (lambda (a b) (> (length (cdr a))
                                                         (length (cdr b)))))))    ; Sort matches by canonical length descending, take first (longest/deepest).
                   (best-ws-orig (car best-ws-pair)))                             ; Get original path of best workspace.
              (puthash best-ws-orig
                       (cons proj-pair (gethash best-ws-orig project-groups))
                       project-groups))                                           ; Prepend project pair to the list for that workspace.
          (push proj-pair ungrouped-projects))))                                  ; If no match, add to ungrouped.
    ;; Sort projects within each group and ungrouped list alphabetically by
    ;; original path.
    (dolist (ws-orig workspaces-orig)                                             ; Loop over workspaces again.
      (puthash ws-orig (sort (gethash ws-orig project-groups)                     ; Get current list, sort it.
                             (lambda (a b) (string< (car a) (car b))))            ; Compare original paths (cars) lexicographically.
               project-groups))                                                   ; Update hash table with sorted list.
    (setq ungrouped-projects
          (sort ungrouped-projects (lambda (a b) (string< (car a) (car b)))))     ; Sort ungrouped list similarly.
    (cons project-groups ungrouped-projects)))                                    ; Return cons of hash table and ungrouped list.

(defun my-project/git-repo-info (dir)
  "Return a property list (plist) of Git repository information for DIR.

Default to nil if DIR is not a Git repo.

This function queries the Git repository at DIR using Emacs' built-in Version
Control (VC) functions.  It gathers details like branch, status, upstream,
commit hash, remote URL, and stash presence.  Errors during Git commands are
caught and messaged, returning nil.

Arguments:
- DIR: A string representing the directory path to check.

Returns:
- A plist with keys :backend (always 'Git if repo), :branch, :status ('clean'
  or 'dirty'), :upstream, :commit (short hash), :remote (origin URL),
  :stash (status string).
- nil if not a Git repo or on error.

Handles empty outputs and fatal errors from Git by providing fallback values
like 'no commits' or 'none'."
  (let ((default-directory (file-truename (expand-file-name dir))))               ; Set default-directory to the true, expanded path of DIR to run commands there.
    (when (eq (vc-responsible-backend default-directory) 'Git)                    ; Check if VC backend for this dir is Git; if not, return nil implicitly.
      (condition-case err                                                         ; Catch any errors during the following block.
          (let* ((branch
                  (string-trim
                   (or
                    (vc-git--run-command-string nil
                                                "rev-parse"
                                                "--abbrev-ref"
                                                "HEAD")
                    "")))                                                         ; Run git rev-parse to get branch name, trim, fallback to empty.
                 (status-output
                  (vc-git--run-command-string nil
                                              "status" "--porcelain"))            ; Run git status in porcelain format for easy parsing.
                 (status
                  (if (string-empty-p (or status-output ""))
                      "clean" "dirty"))                                           ; Determine if repo is clean (no changes) or dirty.
                 (upstream
                  (string-trim
                   (or (vc-git--run-command-string
                        nil
                        "rev-parse"
                        "--abbrev-ref"
                        "--symbolic-full-name"
                        "@{upstream}")
                       "")))                                                      ; Get upstream branch name.
                 (commit
                  (string-trim
                   (or (vc-git--run-command-string
                        nil "rev-parse" "--short" "HEAD")
                       "")))                                                      ; Get short commit hash of HEAD.
                 (remote
                  (string-trim
                   (or (vc-git--run-command-string
                        nil "remote" "get-url" "origin")
                       "")))                                                      ; Get URL of origin remote.
                 (stash-output
                  (vc-git--run-command-string nil "stash" "list"))                ; List stashes.
                 (stash
                  (if (string-empty-p (or stash-output ""))
                      "Nothing stashed" "Stashed changes exist")))                ; Determine if stashes exist.
            (list :backend 'Git                                                   ; Start building the plist with backend.
                  :branch (if (string-empty-p branch) "no commits" branch)        ; Fallback if no branch.
                  :status status                                                  ; Clean or dirty.
                  :upstream (if (or
                                 (string-empty-p upstream)
                                 (string-match-p "fatal" upstream))
                                "none" upstream)                                  ; Handle no upstream or errors.
                  :commit (if (string-empty-p commit) "no commits" commit)        ; Fallback if no commits.
                  :remote (if (or
                               (string-empty-p remote)
                               (string-match-p "fatal" remote))
                              "no remote" remote)                                 ; Handle no remote or errors.
                  :stash stash))                                                  ; Stash status.
        (error (message "Error getting Git info for %s: %s"
                        dir (error-message-string err))                           ; On error, message the issue.
               nil)))))                                                           ; Return nil on error.


(defun my-project/visualise-projects ()
  "Display a navigable list of projects grouped by workspaces.

The list is displayed in a plain-text buffer with Git information.

This interactive function organizes and displays Emacs projects (sourced from
 `project--list') grouped under workspaces (from `my-project/workspace-list').
It creates or switches to the buffer \"*Organized Projects*\", populates it
with a header, grouped and ungrouped project entries, and enables navigation
modes.  Each project path is interactive: pressing RET or clicking `mouse-1'
invokes `project-switch-project' on the project's canonical path.

The display includes:
- Workspace names (formatted paths).
- Project paths (indented, formatted, propertized for interactivity).
- Git information columns: Backend, Branch, Status, Upstream, Commit,
  Remote (truncated if long), Stash.
- \"Other Projects\" section for ungrouped projects.
- Fallback \"-\" for non-Git projects or missing info.

Paths are formatted using `my-project/format-path' (truncating long paths).
Remotes use `my-project/format-remote'.
Git info is fetched via `my-project/git-repo-info'.
Grouping uses `my-project/get-grouped-projects'.

The buffer is set to read-only with `view-mode' for easy navigation
 (q to quit, n/p for lines). `tab-line-mode' is enabled for tabbed interface.

No arguments. Called interactively via M-x or bound key.

Depends on:
- `my-project/get-grouped-projects', `my-project/format-path',
  `my-project/format-remote', `my-project/git-repo-info',
  `my-project/column-widths'.
- Emacs packages: project.el, vc-git.

Errors if no projects or workspaces available
 (via `my-project/get-grouped-projects')."
  (interactive)                                                                   ; Mark this function as callable via M-x or key bindings.
  (let* ((grouped (my-project/get-grouped-projects))                              ; Call grouping function to get cons of hash table and ungrouped list.
         (project-groups (car grouped))                                           ; Extract hash table of grouped projects (workspace -> list of pairs).
         (ungrouped-projects (cdr grouped))                                       ; Extract list of ungrouped project pairs.
         (col-widths my-project/column-widths)                                    ; Get column widths plist for formatting.
         (header-fmt (concat (format "%%-%ds" (plist-get col-widths :path))       ; Build format string for header: left-aligned with widths.
                             (format "%%-%ds" (plist-get col-widths :backend))
                             (format "%%-%ds" (plist-get col-widths :branch))
                             (format "%%-%ds" (plist-get col-widths :status))
                             (format "%%-%ds" (plist-get col-widths :upstream))
                             (format "%%-%ds" (plist-get col-widths :commit))
                             (format "%%-%ds" (plist-get col-widths :remote))
                             (format "%%-%ds" (plist-get col-widths :stash))
                             "\n"))
         (line-fmt (concat (format "%%-%ds" (plist-get col-widths :backend))      ; Build format string for Git info columns (excludes path).
                           (format "%%-%ds" (plist-get col-widths :branch))
                           (format "%%-%ds" (plist-get col-widths :status))
                           (format "%%-%ds" (plist-get col-widths :upstream))
                           (format "%%-%ds" (plist-get col-widths :commit))
                           (format "%%-%ds" (plist-get col-widths :remote))
                           (format "%%-%ds" (plist-get col-widths :stash))))
         (propertize-project                                                      ; Define lambda to add text properties and keymap to project path text.
          (lambda (display-text canonical-path)
            (propertize display-text                                              ; Apply properties to the display text.
                        'project-path canonical-path                              ; Store canonical path for later retrieval.
                        'mouse-face 'highlight                                    ; Highlight on mouse hover.
                        'help-echo "RET or click: Switch to this project"         ; Tooltip text.
                        'keymap
                        (let ((map (make-sparse-keymap)))                         ; Create a new keymap.
                          (define-key
                           map (kbd "RET")                                        ; Bind RET key.
                           (lambda () (interactive)                               ; Lambda for RET: interactive to allow command execution.
                             (project-switch-project
                              (get-text-property (point) 'project-path))))        ; Switch to project using property at point.
                          (define-key
                           map [mouse-1]                                          ; Bind mouse-1 click.
                           (lambda (event) (interactive "e")                      ; Lambda with event arg, interactive with "e" for event.
                             (project-switch-project
                              (get-text-property (point) 'project-path))))        ; Switch using property.
                          map)))))                                                ; Return the keymap.
    ;; Create or switch to buffer and clear it.
    (switch-to-buffer (get-buffer-create "*Organized Projects*"))                 ; Switch to or create the named buffer.
    (erase-buffer)                                                                ; Clear all content in the buffer.
    ;; Insert header row.
    (insert (format header-fmt "Path" "Backend" "Branch" "Status" "Upstream"
                    "Commit" "Remote" "Stash"))                                   ; Insert formatted header labels.
    (insert (make-string (+ (plist-get col-widths :path)                          ; Create a separator line of dashes.
                            (plist-get col-widths :backend)
                            (plist-get col-widths :branch)
                            (plist-get col-widths :status)
                            (plist-get col-widths :upstream)
                            (plist-get col-widths :commit)
                            (plist-get col-widths :remote)
                            (plist-get col-widths :stash)) ?-))
    (insert "\n")                                                                 ; Newline after separator.
    ;; Insert grouped projects.
    (dolist (ws-orig (sort (hash-table-keys project-groups) #'string<))           ; Loop over sorted workspace original paths (alphabetical).
      (insert (format "%s\n" (my-project/format-path ws-orig)))                   ; Insert formatted workspace name followed by newline.
      (dolist (proj-pair (gethash ws-orig project-groups))                        ; Loop over project pairs for this workspace.
        (let* ((proj-orig (car proj-pair))                                        ; Extract original project path.
               (proj-canon (cdr proj-pair))                                       ; Extract canonical project path.
               (info (my-project/git-repo-info proj-canon))                       ; Get Git info plist for the project.
               (display-path
                (format (format "  %%-%ds" (- (plist-get col-widths :path) 2))    ; Format indented path, left-aligned, adjusted for indent.
                        (my-project/format-path proj-orig))))
          (insert (concat                                                         ; Build and insert the line string.
                   (funcall propertize-project display-path proj-canon)           ; Propertized path text.
                   (if info                                                       ; If Git info available.
                       (format line-fmt                                           ; Format Git columns.
                               (plist-get info :backend)
                               (plist-get info :branch)
                               (plist-get info :status)
                               (plist-get info :upstream)
                               (plist-get info :commit)
                               (my-project/format-remote
                                (plist-get info :remote))
                               (plist-get info :stash))
                     (format line-fmt "-" "-" "-" "-" "-" "-" "-"))               ; Fallback dashes.
                   "\n"))))                                                       ; Newline at end.
      (insert "\n"))                                                              ; Extra newline after group.
    ;; Insert ungrouped projects.
    (insert "Other Projects\n")                                                   ; Insert section header.
    (dolist (proj-pair ungrouped-projects)                                        ; Loop over ungrouped pairs.
      (let* ((proj-orig (car proj-pair))                                          ; Original path.
             (proj-canon (cdr proj-pair))                                         ; Canonical path.
             (info (my-project/git-repo-info proj-canon))                         ; Git info.
             (display-path
              (format
               (format "  %%-%ds" (- (plist-get col-widths :path) 2))             ; Formatted indented path.
               (my-project/format-path proj-orig))))
        (insert (concat                                                           ; Build and insert line.
                 (funcall propertize-project display-path proj-canon)             ; Propertized path.
                 (if info                                                         ; If info.
                     (format line-fmt                                             ; Format Git info.
                             (plist-get info :backend)
                             (plist-get info :branch)
                             (plist-get info :status)
                             (plist-get info :upstream)
                             (plist-get info :commit)
                             (my-project/format-remote
                              (plist-get info :remote))
                             (plist-get info :stash))
                   (format line-fmt "-" "-" "-" "-" "-" "-" "-"))                 ; Fallback.
                 "\n"))))                                                         ; Newline.
    (goto-char (point-min))                                                       ; Move cursor to buffer start.
    (view-mode 1)                                                                 ; Enable view-mode (read-only, navigation keys).
    (tab-line-mode 1)))                                                           ; Enable tab-line-mode for tabs if supported.


;; (make-vtable
;;  :columns `(
;;             (:name "Path"
;;                    :width (plist-get col-widths :path)
;;                    )
;;             (:name "Status"
;;                    :width (plist-get col-widths :status)
;;                    )
;;             (:name "Commit"
;;                    :width (plist-get col-widths :commit)
;;                    )
;;             (:name "Branch"
;;                    :width (plist-get col-widths :branch)
;;                    )
;;             (:name "Upstream"
;;                    :width (plist-get col-widths :upstream)
;;                    )
;;             (:name "Remote"
;;                    :width (plist-get col-widths :remote)
;;                    )
;;             (:name "Stash"
;;                    :width (plist-get col-widths :stash)
;;                    )
;;             (:name "Backend"
;;                    :width (plist-get col-widths :backend)
;;                    )
;;             )

;;  :objects '(("Foo" 1034)
;;             ("Gazonk" 45))

;;  :objects-function (lambda ()
;;                      (project-switch-project "/tmp/" t ".jpg'"))
;;  :getter
;;  ;; If given, this is a function that should return the values to use in the table,
;;  ;; and will be called once for each element in the table (unless overridden by a column getter function).
;;  ;;   Function: getter object index table
;;  ;;   For a simple object (like a sequence), this function will typically just
;;  ;;   return the element corresponding to the column index (zero-based), but
;;  ;;   the function can do any computation it wants. If it’s more convenient to
;;  ;;   write the function based on column names rather than the column index,
;;  ;;   the vtable-column function can be used to map from index to name.
;;  :separator-width 2
;;  )
;; (make-vtable
;;  :columns `(( :name "Thumb" :width "500px"
;;               :displayer
;;               ,(lambda (value max-width table)
;;                  (propertize "*" 'display
;;                              (create-image value nil nil
;;                                            :max-width max-width))))
;;             (:name "Size" :width 10
;;                    :formatter file-size-human-readable)
;;             (:name "Time" :width 10 :primary ascend)
;;             "Name")
;;  :objects-function (lambda ()
;;                      (directory-files "/tmp/" t "\\\\.jpg\\\\'"))
;;  :actions '("RET" find-file)
;;  :getter (lambda (object column table)
;;            (pcase (vtable-column table column)
;;              ("Name" (file-name-nondirectory object))
;;              ("Thumb" object)
;;              ("Size" (file-attribute-size (file-attributes object)))
;;              ("Time" (format-time-string
;;                       \"%F\" (file-attribute-modification-time
;;                             (file-attributes object))))))
;;  :separator-width 5
;;  :keymap (define-keymap
;;            "q" #'kill-buffer))

(provide 'project-support)
;;; project-support.el ends here

;; LocalWords:  simon emacs mapc WDD  dotfiles workspaces backend
