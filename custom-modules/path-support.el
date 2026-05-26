;;; path-support.el --- Path configuration for Emacs (with no-littering)  -*- lexical-binding: t; -*-

;; Copyright (C) 2024 Simon Watson
;; SPDX-License-Identifier: MIT

;; Author: Simon Watson

;;; Commentary:

;; Single source of truth for ALL Emacs paths.
;; Loaded exactly once from early-init.el.
;; We fully replicate the useful parts of no-littering here so there is zero dependency
;; on the package for any path logic.

;;; Code:



(defvar envvar/SYSTEM_NAME
  (or (getenv "MY_NAME") "INFODYNAMICS")
  "The name of the system on which we are currently running Emacs.")

;; === NO-LITTERING paths + PACKAGE SETUP (all early) ===

(defvar no-littering-var-directory
  (expand-file-name (concat "var/" envvar/SYSTEM_NAME "/")
                    user-emacs-directory))

(defvar no-littering-etc-directory
  (expand-file-name (concat "etc/" envvar/SYSTEM_NAME "/")
                    user-emacs-directory))

;;; Early safety check
(unless (and no-littering-var-directory no-littering-etc-directory)
  (warn "no-littering-var-directory and/or no-littering-etc-directory were not set in early-init.el"))



;; set up the info directory.
(defconst custom-info-dir
  (expand-file-name "docs/" user-emacs-directory)
  "Directory containing custom Info documentation files.")

(with-eval-after-load 'info
  (info-initialize)
  (when (and custom-info-dir (file-directory-p custom-info-dir))
    (add-to-list 'Info-additional-directory-list custom-info-dir)))


;;;
;; Local helper (dependency-free)
(defun my-on-disk-tools/ensure-directory-exists (dir)
  "Ensure the directory DIR exists, creating it (and parents) if needed."
  (unless (file-directory-p dir)
    (message "Creating directory: %s" dir)
    (make-directory dir t)))

;; === ALL PATHS AS defconst (value + rich docstring in one place) ===

;;;

;; **** eln-cache set in early-init.el
(defconst my-paths/eln-cache
  (expand-file-name "eln-cache/" no-littering-etc-directory)
  "Path for the folder for the eln compile cache.")

(defconst my-paths/desktop-layout-folder
  (expand-file-name "desktop-layout/" no-littering-var-directory)
  "Folder storing desktop layouts for the IDE (uses `window-tree' output).")

(defconst my-paths/spreadsheet-dir
  (expand-file-name "spreadsheet/" no-littering-var-directory)
  "Folder for storing spreadsheet (.ses) templates.")

(defconst my-paths/ispell-word-replacement
  (expand-file-name ".aspell.en.prepl" user-emacs-directory)
  "Personal ispell prepl file: list of words and their automatic replacements.")

(defconst my-paths/memory-object-tree-folder
  (locate-user-emacs-file "custom-packages/memory-object-tree/")
  "Project to show objects in memory under various languages (similar to a file explorer).")

(defconst my-paths/project-view
  (locate-user-emacs-file "custom-packages/project-view/")
  "Project to show multiple projects and workspaces with git status with vc integration.")

(defconst my-paths/speedbar-support
  (expand-file-name "custom-modules/speedbar/" user-emacs-directory)
  "Directory containing speedbar functionality support.")

(defconst my-paths/pretty-speedbar
  (locate-user-emacs-file "custom-packages/pretty-speedbar/")
  "Update of pretty-speedbar to work correctly with emacsclient.")

(defconst my-paths/q-load-balancer-folder
  (locate-user-emacs-file "custom-packages/q-loadbalancer/")
  "Project to set up a full KDB/Q load balancer directly inside Emacs.")

(defconst my-paths/org-modern-indent-folder
  (locate-user-emacs-file "custom-packages/org-modern-indent/")
  "Project to use org-modern-indent in  Emacs.")

(defconst my-paths/systemd-mode
  (locate-user-emacs-file "custom-packages/systemd-mode/")
  "systemD font-locking and keywords — minor local update to fix loading issue.")

(defconst my-paths/logging-view-mode
  (locate-user-emacs-file "custom-packages/logging-view-mode/")
  "Font-locking and useful filters for a custom logging mode.")

(defconst my-paths/log-ts-mode
  (locate-user-emacs-file "custom-packages/log-ts-mode/")
  "New logging mode project (treesitter-based version of logging-view-mode).")

(defconst my-paths/ts-lang-repo
  (expand-file-name "tree-sitter/" user-emacs-directory)
  "Home of the Tree-sitter language specifications.")

(defconst my-paths/default-config-file
  (expand-file-name "conf.org" user-emacs-directory)
  "Path to conf.org — the literate code file used to generate early-init.el and init.el.")

(defconst my-paths/default-log-file
  (expand-file-name "init.log" user-emacs-directory)
  "Path to the Emacs initialization log file.")

;; Standard/third-party paths (original names kept)
(defconst custom-packages-dir
  (expand-file-name "custom-packages/" user-emacs-directory)
  "Directory containing manually installed / git-submodule packages.")

(defconst custom-modules-dir
  (expand-file-name "custom-modules/" user-emacs-directory)
  "Directory containing my custom Emacs Lisp modules.")

(defconst custom-system-tools-dir
  (expand-file-name "custom-modules/system-tools/" user-emacs-directory)
  "Directory containing system-related custom modules.")

(defconst custom-prog-mode-dir
  (expand-file-name "custom-modules/prog-mode/" user-emacs-directory)
  "Directory containing programming-mode custom modules.")

(defconst custom-file
  (expand-file-name "custom.el" no-littering-etc-directory)
  "Location of custom.el (set here so it is available extremely early).")

(defconst undo-tree-history-directory-alist
  `(("." . ,(expand-file-name "undo/" no-littering-var-directory)))
  "Alist for undo-tree history files.")

(defconst auto-save-dir
  (expand-file-name "auto-save/" no-littering-var-directory)
  "Directory for auto-save files.")

(defconst backup-dir
  (expand-file-name "backups/" no-littering-var-directory)
  "Directory for backup files.")

(defconst org-preview-latex-image-directory
  (expand-file-name "latex-preview/" no-littering-var-directory)
  "Directory used to cache LaTeX preview images in Org buffers.")

(defconst save-sql-history-dir
  (expand-file-name "sql-history/" no-littering-var-directory)
  "Directory for SQL history files.")

(defconst project-templates-archive
  (expand-file-name "var/project-templates.tar.xz" user-emacs-directory)
  "Path to the project templates archive file.")

(defconst project-list-file
  (expand-file-name "projects/project-list.el" no-littering-var-directory)
  "Location of the project-list.el file used by project.el.")

(defconst project-view/workspace-list-file
  (expand-file-name "projects/workspace-list.el" no-littering-var-directory)
  "Location of my custom workspace list.")

(defconst lsp-bin-texlab
  (expand-file-name "lang-servers/texlab/target/release/texlab" no-littering-etc-directory)
  "Path to the texlab language-server binary.")

(defconst dape-adapter-dir
  (expand-file-name "dape/adapters/" no-littering-etc-directory)
  "Directory containing Dape debug adapters.")

(defconst dape-adapter-directory-bash
  (expand-file-name "dape/adapters/bash-debug/" no-littering-etc-directory)
  "Directory for the bash debug adapter.")

(defconst dape-default-breakpoints-file
  (expand-file-name "dape/dape-breakpoints.eld" no-littering-var-directory)
  "Location of the default Dape debugger breakpoints file.")

(defconst org-directory "~/Documents/org"
  "Root directory for all Org-mode files.")

(defconst org-contacts-directory
  (expand-file-name "contacts/" org-directory)
  "Path to the Emacs contacts directory for org-contacts functionality.")

(defconst org-roam-directory
  (expand-file-name "org-roam/" org-directory)
  "Root directory for Org-roam (all Org data lives under org-directory).")

(defconst org-default-notes-file
  (expand-file-name "notes/notes.org" org-directory)
  "Path to the Emacs notes file for org-capture functionality.")

(defconst org-default-inbox-file
  (expand-file-name "inbox.org" org-directory)
  "Path to the org-journal for Emacs.")

(defconst org-default-journal-file
  (expand-file-name "journal/journal.org" org-directory)
  "Path to the org-journal for Emacs.")

(defconst diary-file
  (expand-file-name "emacsDiary/diary" org-directory)
  "Path to the Emacs diary file (integrated with Org).")

(defconst pretty-speedbar-icons-dir
  (locate-user-emacs-file "etc/images/pretty-speedbar-icons/")
  "Directory containing icons for the pretty-speedbar package.")

;; Cleanups for a perfectly tidy ~/.emacs.d root
(defconst recentf-save-file
  (expand-file-name "recentf-save.el" no-littering-var-directory)
  "Location of the recent-files list (recentf-save.el).")

(defconst savehist-file
  (expand-file-name "savehist.el" no-littering-var-directory)
  "Location of the savehist (minibuffer/command history) file.")

(defconst package-user-dir
  (expand-file-name "elpa/" no-littering-var-directory)
  "Directory where ELPA/MELPA packages are installed.")

(defconst org-roam-db-location
  (expand-file-name "org/org-roam.db" no-littering-var-directory)
  "Location of the Org-roam SQLite database.")

(defconst org-id-locations-file
  (expand-file-name "org/org-id-locations.el" no-littering-var-directory)
  "Location of the Org-roam locations tracker.")



;; === Paths that no-littering would set automatically (now explicit) ===

(defconst abbrev-file-name
  (expand-file-name "abbrev.el" no-littering-etc-directory)
  "Location of abbrev definitions (auto-saved word expansions).")

(defconst auto-save-list-file-prefix
  (expand-file-name "auto-save-list/.saves-" no-littering-var-directory)
  "Prefix for auto-save-list session files.
Creates the folder under var/INFODYNAMICS/.")

(defconst eshell-directory-name
  (expand-file-name "eshell/" no-littering-var-directory)
  "Directory for Eshell history, aliases, and other data.")

(defconst server-auth-dir
  (expand-file-name "server/auth/" no-littering-var-directory)
  "Directory for Emacs server authentication files.")

(defconst tramp-persistency-file-name
  (expand-file-name "tramp/persistency.el" no-littering-var-directory)
  "Location of Tramp connection persistency file.")

(defconst url-configuration-directory
  (expand-file-name "url/" no-littering-var-directory)
  "Directory for URL package configuration, cookies, and history.")

(defconst url-cookie-file
  (expand-file-name "url/cookies.el" no-littering-var-directory)
  "Location of URL cookies file.")

(defconst url-history-file
  (expand-file-name "url/history.el" no-littering-var-directory)
  "Location of URL history file.")

;; Yasnippet placeholders (set inside with-eval-after-load)
(defconst yasnippets-directory-personal nil
  "Personal yasnippet directory (set after yasnippet loads).")
(defconst yasnippets-directory-default nil)
(defconst yasnippets-directory-yasmate nil)
(defconst yas-snippet-dirs nil
  "List of directories YASnippet searches for templates.")



;; === Path setup & directory creation ===
(message "no-littering var directory set: %s" no-littering-var-directory)
(message "no-littering etc directory set: %s" no-littering-etc-directory)

;; Ensure main no-littering directories
(dolist
    (dir
     (list
      no-littering-var-directory
      no-littering-etc-directory
      )
     )
  (my-on-disk-tools/ensure-directory-exists dir))

;; Ensure all writeable directories (including the new ones)
(dolist (dir (list my-paths/eln-cache
                   auto-save-dir
                   backup-dir
                   org-preview-latex-image-directory
                   save-sql-history-dir
                   my-paths/desktop-layout-folder
                   my-paths/spreadsheet-dir
                   dape-adapter-directory-bash
                   (expand-file-name "dape/" no-littering-var-directory)
                   (expand-file-name "projects/" no-littering-var-directory)
                   package-user-dir
                   (expand-file-name "auto-save-list/" no-littering-var-directory)
                   (expand-file-name "auto-save/sessions/" no-littering-var-directory)
                   eshell-directory-name
                   server-auth-dir
                   (expand-file-name "tramp/" no-littering-var-directory)
                   url-configuration-directory))
  (my-on-disk-tools/ensure-directory-exists dir))


;; Load paths
(add-to-list 'load-path custom-packages-dir)
(add-to-list 'load-path custom-modules-dir)
(add-to-list 'load-path custom-system-tools-dir)
(add-to-list 'load-path custom-prog-mode-dir)


;;;
;; Custom Info docs — deferred until info.el is loaded (
;; fixes the void-variable error)
(with-eval-after-load 'info
  (add-to-list 'Info-additional-directory-list custom-info-dir))

;; Backup & auto-save settings
(setq backup-directory-alist `(("." . ,backup-dir)))
(setq auto-save-file-name-transforms `((".*" ,auto-save-dir t)))

;; Recentf / savehist / ELPA
(setq recentf-save-file recentf-save-file)
(setq savehist-file savehist-file)

;; Bookmark+
(with-eval-after-load 'bookmark+
  (setq bmkp-current-bookmark-file
        (expand-file-name "bmkp/bookmark-default.bmk" no-littering-var-directory))
  (setq bookmark-default-file bmkp-current-bookmark-file)
  (setq bmkp-desktop-default-directory
        (expand-file-name "bmkp/desktops/" no-littering-var-directory))
  (my-on-disk-tools/ensure-directory-exists bmkp-desktop-default-directory)
  (setq bmkp-bmenu-state-file
        (expand-file-name "bmkp/emacs-bmk-bmenu-state.el" no-littering-var-directory)))

;; Yasnippet
(with-eval-after-load 'yasnippet
  (setq yasnippets-directory-personal
        (expand-file-name "yasnippet/snippets/" no-littering-var-directory))
  (setq yasnippets-directory-default
        (expand-file-name "yasnippet-snippets-1.0/snippets/" package-user-dir))
  (setq yasnippets-directory-yasmate
        (expand-file-name "yasnippet/yasmate/snippets/" no-littering-var-directory))
  (setq yas-snippet-dirs
        (list yasnippets-directory-personal
              yasnippets-directory-default
              yasnippets-directory-yasmate))
  (my-on-disk-tools/ensure-directory-exists yasnippets-directory-personal)
  (my-on-disk-tools/ensure-directory-exists yasnippets-directory-yasmate))

;; Org Mode dynamic lists

;;;
(setq org-contacts-files
      (directory-files-recursively org-contacts-directory "\\.org$"))
(setq org-agenda-files
      (directory-files-recursively (concat org-directory "/agenda") "\\.org$"))

(message "✅ path-support.el loaded successfully — all paths defined (including former no-littering auto-paths)")

(provide 'path-support)
;;; path-support.el ends here
