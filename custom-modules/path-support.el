;;; path-support.el --- path configuration for emacs  -*- lexical-binding: t; -*-

;; Copyright (C) 2024
;; SPDX-License-Identifier: MIT

;; Author: Simon Watson

;;; Commentary:

;; configure the paths used by Emacs.
;; We use the no-littering package to keep things neat.

;;; Declarations and imports.
(defvar no-littering-var-directory 'uninitialized
  "`no-littering-var-directory' set in init.el before this module runs.")
(when (eq no-littering-var-directory 'uninitialized)
  (warn
   "no-littering-var-directory is not set. Please ensure it is set in init.el"))

(defvar no-littering-etc-directory 'uninitialized
  "`no-littering-etc-directory' set in init.el before this module runs.")
(when (eq no-littering-etc-directory 'uninitialized)
  (warn
   "no-littering-etc-directory is not set. Please ensure it is set in init.el"))


(defvar my-paths/eln-cache)
(defvar epg-gpg-program)
(defvar custom-info-dir)
(defvar custom-packages-dir)
(defvar undo-tree-history-directory-alist)
(defvar auto-save-dir)
(defvar backup-dir)
(defvar org-preview-latex-image-directory)
(defvar save-sql-history-dir)

(defvar project-templates-archive nil
  "Path to the project templates archive file.")

(defvar yasnippets-directory-personal)
(defvar yasnippets-directory-default)
(defvar yasnippets-directory-yasmate)
(defvar yas-snippet-dirs)

;; (defvar bookmark-default-file)
;; (defvar bmkp-desktop-default-directory)

(defvar dape-default-breakpoints-file)

(defvar org-directory)
(defvar org-contacts-directory)
(defvar org-roam-directory)
(defvar org-roam-dailies-directory)
(defvar org-agenda-files)

(defvar org-contacts-files nil
  "Load the path to each file in the contacts directory.")

;; Notes file for org capture.
(defvar org-default-notes-file nil
  "Path to the Emacs notes file for org notes functionality.")

;; I include the built in diary functionality in the Org-mode setup
(defvar diary-file nil
  "Path to the Emacs diary file for built in diary functionality.")


(defvar my-paths/desktop-layout-folder nil
  "Folder containing `window-tree' specifications for UI layouts.")

(defvar my-paths/q-load-balancer-folder)
;;(defvar my-paths/rainbow-mode)
(defvar my-paths/systemd-mode)
(defvar my-paths/logging-view-mode)

(defvar my-paths/ispell-word-replacement)
(defvar ispell-personal-dictionary)


;;; Packages:


;;; Code:

;; this function is take from TOOLS FOR THE FILE SYSTEM in system-tools.
;; It is reproduced here so custom-path-support can be loaded without
;; dependencies.

(defun my-on-disk-tools/ensure-directory-exists (dir)
  "Ensure the directory DIR exists, create it if it does not."
  (unless (file-directory-p dir)
    (message "creating %s" dir)
    (make-directory dir t)))

;;;; no-littering
;;   ------------
;; no-littering package is central to the directory organisation in this
;; setup
(message
 "no-littering var directory set: %s" no-littering-var-directory)
(message
 "no-littering etc directory set: %s" no-littering-etc-directory)

;;;; Emacs internal Directory
;;   -----------------------

;; set up my eln-cache.
(setq my-paths/eln-cache
      (expand-file-name "eln-cache/" no-littering-etc-directory))
(my-on-disk-tools/ensure-directory-exists my-paths/eln-cache)

;; set a path to local custom packages.
(setq custom-packages-dir
      (expand-file-name "custom-packages/" user-emacs-directory))

(add-to-list 'load-path custom-packages-dir)

;; set a path to local custom modules.
(setq custom-modules-dir
      (expand-file-name "custom-modules/" user-emacs-directory))

(add-to-list 'load-path custom-modules-dir)

;; set a path to local custom modules.
(setq custom-system-tools-dir
      (expand-file-name "custom-modules/system-tools/" user-emacs-directory))

(add-to-list 'load-path custom-system-tools-dir)

;; set a path to local custom modules.
(setq custom-prog-mode-dir
      (expand-file-name "custom-modules/prog-mode/" user-emacs-directory))

(add-to-list 'load-path custom-prog-mode-dir)

;; set a path to custom documentation to be searchable with `info'.
(setq custom-info-dir
      (expand-file-name "docs" user-emacs-directory))

(add-to-list 'load-path custom-info-dir)

;;(log/debug :fn 'init
;;           :msg "Current load-path:"
;;           :obj (format "%s" load-path))


;;;; custom.el
(defvar custom-file nil "Set location of custom.el.")
(setq custom-file
      (expand-file-name "custom.el" no-littering-etc-directory))


;;;; GPG application
;;   ---------------
;; (setq epg-gpg-program "/usr/bin/gpg")

;; Automatically create the auto-save and backup directories if they don't
;; exist

;; Define the path to the undo-tree cache.
(setq undo-tree-history-directory-alist
      `(("." . ,(expand-file-name "undo" no-littering-var-directory))))

(setq auto-save-dir
      (expand-file-name "auto-save/" no-littering-var-directory))
(my-on-disk-tools/ensure-directory-exists auto-save-dir)

(setq backup-dir
      (expand-file-name "backups/" no-littering-var-directory))
(my-on-disk-tools/ensure-directory-exists backup-dir)

(setq org-preview-latex-image-directory
      (expand-file-name ".cache_latex/" no-littering-var-directory))
(my-on-disk-tools/ensure-directory-exists org-preview-latex-image-directory)

(setq save-sql-history-dir
      (expand-file-name "sql-history/" no-littering-var-directory))
(my-on-disk-tools/ensure-directory-exists save-sql-history-dir)


;; Use customize-set-variable to set the directory for backup files
(setq backup-directory-alist `(("." . ,backup-dir)))

;; Use customize-set-variable to set the directory for auto-save files
(setq auto-save-file-name-transforms `((".*" ,auto-save-dir t)))

;; Set the tree-sitter load paths.
;;(note treesit-extra-load-path is set in early-init.el)

;; (defvar treesit-load-path '())
;; (defvar treesit-extra-load-path nil)
;; (add-to-list 'treesit-load-path  (expand-file-name "~/.emacs.d/tree-sitter/"))
;; (add-to-list 'treesit-extra-load-path  (expand-file-name "~/.emacs.d/tree-sitter/"))


;;;; Bookmark+
;;   ---------
;; The location of the default bookmark desktop directory bmkp is set under
;;     no-littering-var-directory
;; the variable files for bookmark+ (and bookmark) are in bmkp.
;; bmkp-desktop-default-directory is set to bmkp/desktops
;;     - this is where desktop bookmarks are stored.
;; bmkp-bmenu-state-file is set to bmkp/emacs-bmk-bmenu-state.el
;;     - this is where the current state of the list-bookmark buffer is stored.
;; bookmark-default-file is set to bmkp/bookmark-default.bmk
;;     - this is the default location for bookmark files.
(with-eval-after-load 'bookmark+

  ;; Set the default location of bookmarks.
  (setq bmkp-current-bookmark-file
        (expand-file-name
         "bmkp/bookmark-default.bmk" no-littering-var-directory))
  
  ;; Set the default location of bookmarks.
  (setq bookmark-default-file
        (expand-file-name
         "bmkp/bookmark-default.bmk" no-littering-var-directory))
  
  ;; Set the location of the default bookmark desktop directory.
  (setq
   bmkp-desktop-default-directory
   (expand-file-name "bmkp/desktops" no-littering-var-directory))
  
  ;; ensure the desktop file exists.
  (my-on-disk-tools/ensure-directory-exists
   bmkp-desktop-default-directory)
  
  (setq bmkp-bmenu-state-file
        (expand-file-name
         "bmkp/emacs-bmk-bmenu-state.el" no-littering-var-directory))
  )



;;;; UI configuration
;;   ----------------
;; note this is different to the bookmark desktop.
(setq my-paths/desktop-layout-folder
      (expand-file-name
       "desktop-layout/" no-littering-var-directory))


;;;; Yasnippet directories
;;   ---------------------
;; (no-littering only sets the yasnippet personal directory automatically)
(with-eval-after-load 'yasnippet
  (progn
    (setq yasnippets-directory-personal
          (expand-file-name "yasnippet/snippets/"
                            no-littering-var-directory))
    (setq yasnippets-directory-default
          (expand-file-name
           "yasnippet-snippets-1.0/snippets/"
           package-user-dir))
    (setq yasnippets-directory-yasmate
          (expand-file-name
           "yasnippet/yasmate/snippets/" no-littering-var-directory))

    ;; set the list of the yasnippet directories.
    ;; no-littering only sets up a link to an empty
    ;; directory under etc.
    (setq yas-snippet-dirs
          `(,yasnippets-directory-personal
            ,yasnippets-directory-default
            ,yasnippets-directory-yasmate)))

  ;; ensure the yasnippet directories exist.
  (my-on-disk-tools/ensure-directory-exists yasnippets-directory-personal)
  (my-on-disk-tools/ensure-directory-exists yasnippets-directory-yasmate))

;;;; Projects.el
;;   -----------
;; Set the location of the project template archive.
(setq project-templates-archive
      (expand-file-name "var/project-templates.tar.xz" user-emacs-directory))

;; Set location of saved project paths and master work-spaces containing
;; multiple projects.

(setq project-list-file
      (expand-file-name "projects/project-list.el" no-littering-var-directory))
(setq my-project/workspace-list-file
      (expand-file-name "projects/workspace-list.el" no-littering-var-directory))
(my-on-disk-tools/ensure-directory-exists
 (expand-file-name "projects/" no-littering-var-directory))


;;;; Spreadsheet
;;   -----------
(setq my-paths/spreadsheet-dir
      (expand-file-name "spreadsheet" no-littering-var-directory))
(my-on-disk-tools/ensure-directory-exists my-paths/spreadsheet-dir)

;;;; language servers

;; LaTeX lsp bin
(setq lsp-bin-texlab
      (expand-file-name
       "lang-servers/texlab/target/release/texlab" no-littering-etc-directory))
;;;; Dape
;;   ----
;; Set the location of the adapters.
(setq dape-adapter-dir
      (expand-file-name "dape/adapters/" no-littering-etc-directory))

;; Set the location of the bash adapter. (note - etc not var)
(setq dape-adapter-directory-bash
      (expand-file-name "dape/adapters/bash-debug" no-littering-etc-directory))

(my-on-disk-tools/ensure-directory-exists dape-adapter-directory-bash)

;; Set location of saved breakpoints (note - var not etc)
(setq dape-default-breakpoints-file
      (expand-file-name "dape/dape-breakpoints" no-littering-var-directory))

(my-on-disk-tools/ensure-directory-exists
 (expand-file-name "dape" no-littering-var-directory))

;;;; Org Mode
;;   --------
(setq org-directory "~/Documents/org") ; Path to org data.

(setq org-contacts-directory                                                      ; Path to the Emacs contacts file for org contacts functionality.
      (expand-file-name  "contacts/" org-directory))

(customize-set-variable
 'org-contacts-files
 (directory-files-recursively org-contacts-directory "\\.org$")
 "Load the path to each file in the contacts directory. ")

;; Notes file for org capture.
(setq org-default-notes-file
      (expand-file-name "notes/notes.org" org-directory))

;; I include the built in diary functionality in the Org-mode setup
(setq diary-file (expand-file-name "emacsDiary/diary" org-directory))

;; put all of org under org-roam.
(setq org-roam-directory (expand-file-name "org-roam/" org-directory))
;;(setq org-roam-dailies-directory (expand-file-name "daily" org-directory))

;; Automatically include all Org files in a directory
;; (setq org-agenda-files (list "~/Documents/org/work.org"
;;                              "~/Documents/org/home.org"x
;;                              "~/Documents/org/projects/"))
(setq org-agenda-files
      (directory-files-recursively
       (concat org-directory "/agenda") "\\.org$"))

;; Using Org with Latex
;; --------------------
;; This needs a cache set up to store any rendered latex shown in org.
;; Here we set up that directory.
;; Set the path for Org LaTeX preview images
(defvar
  org-preview-latex-image-directory
  (expand-file-name ".cache_latex/" no-littering-etc-directory)
  "Path for the directory used to cache latex images.")


;;;; Dictionary settings
;;   -------------------
;; Set up dictionary paths (also specified in defaults-config.el)
(setq ispell-personal-dictionary
      (expand-file-name ".aspell.en.pws" user-emacs-directory))

(setq my-paths/ispell-word-replacement
      (expand-file-name ".aspell.en.prepl" user-emacs-directory))

(setq save-sql-history-dir
      (expand-file-name "sql-history/" no-littering-var-directory))


;; keep the pretty-speedbar-icons in the icon stash.
;; (defvar pretty-speedbar-icons-dir
;;   (expand-file-name
;;    (concat user-emacs-directory "etc/images/pretty-speedbar-icons/"))
;;   "Store pretty-speedbar-icons in the etc/images/pretty-speedbar-icons folder.

;; This is located in the user's default Emacs directory.")
;; (setq pretty-speedbar-icons-dir
;;       (expand-file-name
;;        (concat user-emacs-directory "etc/images/pretty-speedbar-icons/")))


;; define a path to the object-memory-tree custom package.
(setq my-paths/memory-object-tree-folder
      (concat user-emacs-directory "custom-packages/memory-object-tree/"))

;; define a path to the combobulate custom package
(setq my-paths/combobulate
      (concat user-emacs-directory "custom-packages/combobulate/"))

;; define a path to the q custom package
(setq my-paths/q-load-balancer-folder
      (concat user-emacs-directory "custom-packages/q-loadbalancer/"))

;; define a path to the rainbow-mode custom package
;; (setq my-paths/rainbow-mode
;;       (concat user-emacs-directory "custom-packages/rainbow-mode/"))

;; define a path to the systemd-mode custom package
(setq my-paths/systemd-mode
      (concat user-emacs-directory "custom-packages/systemd-mode/"))

;; define a path to the logging-view-mode custom package
(setq my-paths/logging-view-mode
      (concat user-emacs-directory "custom-packages/logging-view-mode/"))

;; define a path to the logging-view-mode custom package
(setq my-paths/log-ts-mode
      (concat user-emacs-directory "custom-packages/log-ts-mode/"))

;; paths to exclude from recentf (base and shortcut).
(setq recentf-exclude
      '(
        "^~/sync/primary/dotfiles/emacs/\\.emacs\\.d/init\\.log"
        "^~/sync/primary/dotfiles/emacs/\\.emacs\\.d/$"
        "^~/sync/primary/dotfiles/emacs/\\.emacs\\.d/conf\\.org$"

        "^~/\\.emacs\\.d/init\\.log"
        "^~/\\.emacs\\.d/$"
        "^~/\\.emacs\\.d/conf\\.org$"))

;; set global variables for 'special files'.
(defconst my-paths/default-config-file
  (expand-file-name "conf.org" user-emacs-directory)
  "Path to the literate config file.")

(defconst my-paths/default-log-file
  (expand-file-name "init.log" user-emacs-directory)
  "Path to the init log file.")


(provide 'path-support)
;;; path-support.el ends here

;; LocalWords:  pws prepl systemd combobulate
;; LocalWords:  recentf
;; LocalWords:  loadbalancer
;; LocalWords:  Dape emacs init
;; LocalWords:  bmk
