;;; custom-no-littering-config.el --- no littering config  -*- lexical-binding: t; -*-

;; Copyright (C) 2022
;; SPDX-License-Identifier: MIT

;; Author: System Crafters Community

;;; Commentary:

;; configure the no-littering package. 

;;; Code:
(straight-use-package 'no-littering)
(require 'no-littering)


;; Use the `MY_NAME` environment variable to set machine specific
;; locations for use with no littering. 
(let ((my-name (getenv "MY_NAME")))
  (when my-name
    ;; Update `no-littering-var-directory` to include the `MY_NAME` value as a subdirectory
    (setq no-littering-var-directory (expand-file-name (concat "var/" my-name "/") user-emacs-directory))))

(let ((my-name (getenv "MY_NAME")))
  (when my-name
    ;; Update `no-littering-etc-directory` to include the `MY_NAME` value as a subdirectory
    (setq no-littering-var-directory (expand-file-name (concat "etc/" my-name "/") user-emacs-directory))))

;;; Using Org with Latex
;;  --------------------
;; This needs a cache set up to store any rendered latex shown in org.
;; Here we set up that directory. 
;; Set the path for Org LaTeX preview images
(setq org-preview-latex-image-directory 
      (expand-file-name ".cache_latex/" no-littering-var-directory))

;; Now check if the directory exists and create it if it does not
(let ((latex-cache-dir (expand-file-name org-preview-latex-image-directory)))
  (unless (file-exists-p latex-cache-dir)
    (make-directory latex-cache-dir t)))


;; elpa
(customize-set-variable 'package-user-dir (expand-file-name "elpa/" no-littering-etc-directory))

;; gnupg
(customize-set-variable 'package-gnupghome-dir (expand-file-name "gnupg" no-littering-etc-directory))

;; eln-cache ALREADY DONE.
;;(add-to-list 'native-comp-eln-load-path (expand-file-name "eln-cache/" no-littering-etc-directory))

;; Set the backuplocation using built in emacs functionality.
;; https://www.gnu.org/software/emacs/manual/html_node/emacs/Backup.html
(customize-set-variable 'backup-directory-alist `(("." . ,(expand-file-name "backups/" no-littering-var-directory))))
	
;; custom.el
(customize-set-variable 'custom-file 
	(no-littering-expand-etc-file-name "custom.el"))

;; projectile     
(customize-set-variable 'projectile-known-projects-file 
                        (expand-file-name "projectile/projectile-bookmarks.eld" no-littering-var-directory))
;; update the original project.el version of this list. (variable used in startup)
(customize-set-variable 'project-list-file
                        (expand-file-name "projectile/projectile-bookmarks.eld" no-littering-var-directory))

(customize-set-variable 'lsp-session-file 
                        (expand-file-name ".lsp-session-v1" no-littering-var-directory))

;; savehist
(customize-set-variable 'savehist-file 
	(expand-file-name "savehist" no-littering-var-directory))
	
;; Autosave
(customize-set-variable 'auto-save-file-name-transforms
	`((".*" ,(expand-file-name "auto-save/" no-littering-var-directory) t)))

;; Anaconda mode for python. 	
(customize-set-variable 'anaconda-mode-installation-directory
 	(expand-file-name "anaconda-mode/" no-littering-var-directory))

;;; Recent Files
;; Don't store visits to these files in the recent file history
(require 'recentf)
;; recent files (recentf)
;; https://www.emacswiki.org/emacs/RecentFiles
(customize-set-variable 'recentf-save-file 
	(recentf-expand-file-name (expand-file-name ".recentf" no-littering-var-directory)))

;; Don't record files opened in the etc and var directories in recent file lists. 
(add-to-list 'recentf-exclude
	(recentf-expand-file-name no-littering-var-directory))

(require 'custom-logging-config)

(provide 'custom-no-littering-support)
;;; custom-no-littering-support.el ends here
