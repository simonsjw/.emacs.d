;;; custom-path-support.el - path configuration for emacs  -*- lexical-binding: t; -*-

;; Copyright (C) 2022
;; SPDX-License-Identifier: MIT

;; Author: System Crafters Community

;;; Commentary:

;; configure the paths used by Emacs.
;; We use the no-littering package to keep things neat.

;;; Declarations and imports.
(defvar no-littering-var-directory)
(defvar no-littering-etc-directory)

(defvar custom-info-dir)
(defvar undo-tree-history-directory-alist)
(defvar auto-save-dir)
(defvar backup-dir)
(defvar org-preview-latex-image-directory)
(defvar save-sql-history-dir)

(defvar yasnippets-directory-personal)
(defvar yasnippets-directory-default)
(defvar yasnippets-directory-yasmate)
(defvar yas-snippet-dirs)

(defvar projectile-project-search-path)

(defvar bookmark-default-file)
(defvar bmkp-desktop-default-directory)

(defvar org-directory)
(defvar org-contacts-directory)
(defvar org-roam-directory)
(defvar org-roam-dailies-directory)
(defvar org-agenda-files)
(defvar recentf-exclude)

(defvar org-contacts-files nil
  "Load the path to each file in the contacts directory. ")

;; Notes file for org capture. 
(defvar org-default-notes-file nil
  "Path to the Emacs notes file for org notes functionality.")

;; I include the built in diary functionality in the Org-mode setup
(defvar diary-file nil
  "Path to the Emacs diary file for built in diary functionality.")

(defvar ispell-replacement-dictionary)
(defvar ispell-personal-dictionary)

(declare-function
 my-on-disk-tools/ensure-directory-exists custom-system-tools)

(declare-function  recentf-expand-file-name recentf)

;;; Packages:

(use-package no-littering
  :straight (:type git
                   :flavor melpa
                   :host github
                   :repo "emacscollective/no-littering"))




;;; Code:

(message
 "no-littering var directory set: %s" no-littering-var-directory)
(message
 "no-ilttering etc directory set: %s" no-littering-etc-directory)


;; set a path to custom documentation to be searchable with `info'.
(setq custom-info-dir (expand-file-name "docs/dir"  user-emacs-directory))

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
;; (add-to-list 'load-path
;;              (concat straight-base-dir "straight/" straight-build-dir "/"
;;                      "tree-sitter-langs/bin/"))


;; Bookmark+
;; ---------
;; These all need to be applied after the bookmark+ library is loaded.

(with-eval-after-load 'bookmark+

  ;; Set the location of the default bookmark directory.

  (setq
   bmkp-desktop-default-directory
   (expand-file-name "bmkp/desktops" no-littering-var-directory))

  ;; Set the location of the default bookmark file.

  (setq
   bookmark-default-file
   (expand-file-name
    "bmkp/desktops/IDE" no-littering-var-directory))
  )

(my-on-disk-tools/ensure-directory-exists
 (expand-file-name "bmkp/desktops" no-littering-var-directory))

;; Yasnippet directories
;; ---------------------
;; (no-littering only sets the yasnippet personal directory automatically)
(with-eval-after-load 'yasnippet
  (progn
    (setq yasnippets-directory-personal
          (expand-file-name "yasnippet/snippets/"
                            no-littering-var-directory))
    (setq yasnippets-directory-default
          (expand-file-name
           "straight/build/yasnippet-snippets/snippets/"
           no-littering-etc-directory))
    (setq yasnippets-directory-yasmate
          (expand-file-name
           "yasnippet/yasmate/snippets/" no-littering-var-directory))

    ;; set the list of the yasnippet directories.
    ;; no-littering only sets up a link to an empty
    ;; directory under etc.
    (setq yas-snippet-dirs
          `(,(expand-file-name
              "yasnippet/snippets/"
              no-littering-var-directory)
            ,(expand-file-name
              "straight/build/yasnippet-snippets/snippets/"
              no-littering-etc-directory)
            ,(expand-file-name
              "yasnippet/yasmate/snippets/" ;; the yasmate collection
              no-littering-var-directory)))))

;; ensure the yasnippet directories exist.
(my-on-disk-tools/ensure-directory-exists
 (expand-file-name "yasnippet/snippets/" no-littering-var-directory))
(my-on-disk-tools/ensure-directory-exists
 (expand-file-name
  "straight/build/yasnippet-snippets/snippets/"
  no-littering-etc-directory))
(my-on-disk-tools/ensure-directory-exists
 (expand-file-name
  "yasnippet/yasmate/snippets/" no-littering-var-directory))

;;; Get Projectile search paths from the environmental variable
;; PROJECTILE_PATHS. If it is not set, default to ~/.

;; A typical example is:
;; export PROJECTILE_PATHS="/home/simon/Downloads/github:5,/home/simon/sync/primary/Adventures:5,/home/simon/sync/primary/dotfiles:5,/mnt/HDD04_WDD_08TB/workspace:7"
;; This searches the locations recursively to a maximum of 5
;; directories deep (apart from workspace, which searches 7 deep.)


(setq
 projectile-project-search-path
 (if (getenv "PROJECTILE_PATHS")
     (mapcar (lambda (path-depth-pair)
               (let ((parts (split-string path-depth-pair ":")))
                 (cons (car parts) (string-to-number (cadr parts)))))
             (split-string (getenv "PROJECTILE_PATHS") ","))
   ;; Default search path if the environment variable is not set
   '(("~/" . 3))))

;; Org Mode
;; --------
(setq org-directory "~/Documents/org") ; Path to org data.

(setq org-contacts-directory ; Path to the Emacs contacts file for org contacts functionality.
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
(setq org-roam-directory org-directory)
(setq org-roam-dailies-directory "daily/")
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


;; Set up dictionary paths
(setq ispell-replacement-dictionary
      (expand-file-name ".aspell.en.prepl" user-emacs-directory))
(setq ispell-personal-dictionary
      (expand-file-name ".aspell.en.pws" user-emacs-directory))


(setq save-sql-history-dir
       (expand-file-name "sql-history/" no-littering-var-directory))
(setq save-sql-history-dir
      (expand-file-name "sql-history/" no-littering-var-directory))

;; keep the pretty-speedbar-icons in the icon stash. 
;;(with-eval-after-load 'pretty-speedbar-icons
;; (defconst pretty-speedbar-icons-dir
;;   (expand-file-name
;;    (concat user-emacs-directory "etc/images/pretty-speedbar-icons/"))
;; "Store pretty-speedbar-icons in the etc/images/pretty-speedbar-icons folder. This is located in the user's default Emacs directory.") 
;;)


;;; Recent Files
;; Don't store visits to these files in the recent file history
;; https://www.emacswiki.org/emacs/RecentFiles

;; Don't record files opened in the etc and var directories in recent file lists.
(add-to-list 'recentf-exclude
             (recentf-expand-file-name no-littering-var-directory))

(add-to-list 'recentf-exclude
             (recentf-expand-file-name
              "~/sync/primary/dotfiles/emacs/.emacs.d/"))

(add-to-list 'recentf-exclude
             (recentf-expand-file-name "~/.emacs.d/conf.org"))


(provide 'custom-path-support)
;;; custom-path-support.el ends here
