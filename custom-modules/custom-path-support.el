;;; custom-path-support.el --- path configuration for emacs  -*- lexical-binding: t; -*-

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

(defvar epg-gpg-program)
(defvar custom-info-dir)
(defvar custom-packages-dir)
(defvar undo-tree-history-directory-alist)
(defvar auto-save-dir)
(defvar backup-dir)
(defvar org-preview-latex-image-directory)
(defvar save-sql-history-dir)

(defvar yasnippets-directory-personal)
(defvar yasnippets-directory-default)
(defvar yasnippets-directory-yasmate)
(defvar yas-snippet-dirs)

(defvar bookmark-default-file)
(defvar bmkp-desktop-default-directory)

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

(defvar my-paths/q-load-balancer-folder)
(defvar my-paths/rainbow-mode)
(defvar my-paths/systemd-mode)
(defvar my-paths/cell-mode)
(defvar my-paths/logging-view-mode)

(defvar my-paths/ispell-word-replacement)
(defvar ispell-personal-dictionary)


;;; Packages:

(use-package no-littering)

;;; Code:

;; this function is take from TOOLS FOR THE FILE SYSTEM in system-tools.
;; It is reproduced here so custom-path-support can be loaded without
;; dependencies.

(defun my-on-disk-tools/ensure-directory-exists (dir)
  "Ensure the directory DIR exists, create it if it does not."
  (unless (file-directory-p dir)
    (message "creating %s" dir)
    (make-directory dir t)))

(message
 "no-littering var directory set: %s" no-littering-var-directory)
(message
 "no-littering etc directory set: %s" no-littering-etc-directory)

;; GPG application:
;; (setq epg-gpg-program "/usr/bin/gpg")

;; set a path to local custom packages.
(setq custom-packages-dir
      (expand-file-name "custom-packages/" user-emacs-directory))

;; set a path to custom documentation to be searchable with `info'.
(setq custom-info-dir (expand-file-name "docs" user-emacs-directory))

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

;; Bookmark+
;; ---------
;; These all need to be applied after the bookmark+ library is loaded.

(with-eval-after-load 'bookmark+

  ;; Set the default location of bookmarks.
  (setq bookmark-default-file
        (expand-file-name
         "bmkp/bookmark-default.el" no-littering-var-directory))
  
  ;; Set the location of the default bookmark desktop directory.
  (setq
   bmkp-desktop-default-directory
   (expand-file-name "bmkp/desktops" no-littering-var-directory))

  (my-on-disk-tools/ensure-directory-exists
   bmkp-desktop-default-directory)
  
  (setq bmkp-bmenu-state-file
        (expand-file-name
         "bmkp/emacs-bmk-bmenu-state.el" no-littering-var-directory))
  )

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
           "package/archives/elpa/yasnippet-snippets-1.0/snippets/"
           no-littering-var-directory))
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
              "package/archives/elpa/yasnippet-snippets-1.0/snippets/"
              no-littering-etc-directory)
            ,(expand-file-name
              "yasnippet/yasmate/snippets/" ;; the yasmate collection
              no-littering-var-directory))))

  ;; ensure the yasnippet directories exist.
  (my-on-disk-tools/ensure-directory-exists yasnippets-directory-personal)
  (my-on-disk-tools/ensure-directory-exists yasnippets-directory-yasmate))

;; Dape
;; ----
;; Set location of saved breakpoints.
(setq dape-default-breakpoints-file
      (expand-file-name "dape/dape-breakpoints" no-littering-var-directory)
      )
(my-on-disk-tools/ensure-directory-exists
 (expand-file-name "dape" no-littering-var-directory)
 )

;; Org Mode
;; --------
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


;; define a path to the q custom package
(setq my-paths/q-load-balancer-folder
      (concat user-emacs-directory "custom-packages/q-loadbalancer/"))

;; define a path to the rainbow-mode custom package
(setq my-paths/rainbow-mode
      (concat user-emacs-directory "custom-packages/rainbow-mode/"))

;; define a path to the systemd-mode custom package
(setq my-paths/systemd-mode
      (concat user-emacs-directory "custom-packages/systemd-mode/"))

;; define a path to the cell-mode custom package
(setq my-paths/cell-mode
      (concat user-emacs-directory "custom-packages/cell-mode/"))

;; define a path to the logging-view-mode custom package
(setq my-paths/logging-view-mode
      (concat user-emacs-directory "custom-packages/logging-view-mode/"))

(provide 'custom-path-support)
;;; custom-path-support.el ends here

                                                                                  ; LocalWords:  pws prepl systemd
                                                                                  ; LocalWords:  recentf
                                                                                  ; LocalWords:  loadbalancer
                                                                                  ; LocalWords:  Dape
