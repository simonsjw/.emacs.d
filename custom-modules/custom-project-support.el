;;; custom-project-support.el --- project support for the crafted setup   -*- lexical-binding: t; -*-

;; Copyright (C) 2022
;; SPDX-License-Identifier: MIT

;; Author: System Crafters Community
;; Keywords: projectile, projects

;;; Commentary:

;; This package adds additional project support and the setup of the projectile package.

;;; Code:

;;; Packages phase
(use-package projectile
  :config
  (projectile-mode +1)
  (define-key
   projectile-mode-map (kbd "C-c p") 'projectile-command-map))


(use-package consult-projectile)

(use-package ibuffer-projectile
  :config
  (add-to-list 'ibuffer-saved-filter-groups
               '("home"
                 ("Projectile" (projectile . t))
                 ;;   ("Projects" (filename . "/path/to/projects/"))
                 ("Agenda Files" (filename . "/home/simon/Documents/org/agenda/"))
                 ("Emacs Custom Files" (filename . "/home/simon/.emacs.d/custom-modules/"))
                 )))

;;; Configuration phase

(require 'projectile)
(require 'consult-projectile)
;;(require 'ibuffer-projectile)

;; (setq projectile-mode-line-function                                               ; set the modeline entry for projectile.
;;       '(lambda () (format " proj[%s]" (projectile-project-name))))
(setq projectile-auto-discover nil)                                               ; do not scan the search path everytime emacs starts.
(setq projectile-enable-caching t)                                                ; save results from project searches across sessions.
(projectile-mode +1)                                                              ; switch on projectile mode.


(defun my-project/ensure-and-switch-to-project (project-root)
  "Ensure PROJECT-ROOT is a known project and switch to it."
  (interactive "DProject Root: ")
  (projectile-add-known-project project-root)
  (projectile-switch-project project-root))

        
(defun my-project/add-projects-from-csv (csv-file)
  "Add projects to Projectile from a CSV-FILE path.

The first column of the CSV contains the project paths."
  (interactive "fCSV File: ")
  (with-temp-buffer
    (insert-file-contents csv-file)
    (forward-line 1)                                                              ; Skip the header line
    (while (not (eobp))
      (let* ((line (buffer-substring-no-properties
                    (line-beginning-position) (line-end-position)))
             (fields (split-string line ","))
             (project-path (car fields)))
        (setq project-path                                                        ; Remove quotes around the path
              (replace-regexp-in-string "\"" "" project-path))
        (message "Processing path: %s" project-path)                              ; Debug: Print the current path
        (when (and project-path (file-directory-p project-path))
          (with-eval-after-load 'projectile                                       ; Ensure Projectile is loaded before calling its functions
            (if (projectile-project-p project-path)
                (message "Skipping known project: %s" project-path)
              (progn
                (projectile-add-known-project project-path)
                (message "Added project: %s" project-path)))))
        (forward-line 1)))))


;; enhance ibuffer with ibuffer-projectile-default-group-name if available.
(defun my-project/ibuffer-projectile-setup ()
  "Set up integration for `ibuffer' with `ibuffer-projectile'."
  (setq ibuffer-filter-groups (ibuffer-projectile-generate-filter-groups))
  (unless (eq ibuffer-sorting-mode 'project-name)
    (ibuffer-do-sort-by-project-name)))

(when (require 'ibuffer-projectile nil :noerror)
  (add-hook 'ibuffer-hook #'my-project/ibuffer-projectile-setup))

;; Call this function with the path to your CSV file
;; (let ((REPO_LIST (getenv "REPO_LIST")))
;;   (my/add-projects-from-csv REPO_LIST))

(provide 'custom-project-support)
;;; custom-project-support.el ends here

                                                                                  ; LocalWords:  simon
                                                                                  ; LocalWords:  emacs
