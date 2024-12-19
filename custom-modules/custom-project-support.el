;;; custom-project-support.el --- project support for the crafted setup   -*- lexical-binding: t; -*-

;; Copyright (C) 2022
;; SPDX-License-Identifier: MIT

;; Author: System Crafters Community
;; Keywords: projectile, projects

;;; Commentary:

;; This package adds additional project support and the setup of the projectile package.

;; code:

;;; Packages phase
(use-package projectile
  :config
  (projectile-mode +1)
  (define-key
   projectile-mode-map (kbd "C-c p") 'projectile-command-map))

(use-package consult-projectile)
(use-package ibuffer-projectile)

;;; Configuration phase

(require 'projectile)
(require 'consult-projectile)
(require 'ibuffer-projectile)

(setq projectile-mode-line-function    ;; set the modeline entry for projectile.
 '(lambda () (format " proj[%s]" (projectile-project-name))))
                          
(setq projectile-auto-discover nil)    ;; do not scan the search path everytime emacs starts.
(setq projectile-enable-caching t)     ;; save results from project searches across sessions.
(projectile-mode +1)                   ;; switch on projectile mode.


(defun my/ensure-and-switch-to-project (project-root)
  "Ensure PROJECT-ROOT is a known project and switch to it."
  (interactive "DProject Root: ")
  (projectile-add-known-project project-root)
  (projectile-switch-project project-root))

        
(defun my/add-projects-from-csv (csv-file)
  "Add projects to Projectile from a CSV-FILE path.

The first column of the CSV contains the project paths."
  (interactive "fCSV File: ")
  (with-temp-buffer
    (insert-file-contents csv-file)
    ;; Skip the header line
    (forward-line 1)
    (while (not (eobp))
      (let* ((line (buffer-substring-no-properties
                    (line-beginning-position) (line-end-position)))
             (fields (split-string line ","))
             (project-path (car fields)))
        ;; Remove quotes around the path
        (setq project-path
              (replace-regexp-in-string "\"" "" project-path))
        ;; Debug: Print the current path
        (message "Processing path: %s" project-path)
        (when (and project-path (file-directory-p project-path))
          ;; Ensure Projectile is loaded before calling its functions
          (with-eval-after-load 'projectile
            (if (projectile-project-p project-path)
                (message "Skipping known project: %s" project-path)
              (progn
                (projectile-add-known-project project-path)
                (message "Added project: %s" project-path)))))
        (forward-line 1)))))


;; enhance ibuffer with ibuffer-projectile-default-group-name if it is
;; available.
(when (require 'ibuffer-projectile nil :noerror)

  (defun crafted-ide-enhance-ibuffer-with-ibuffer-project ()
    "Set up integration for `ibuffer' with `ibuffer-projectile'."
    (setq ibuffer-filter-groups (ibuffer-projectile-generate-filter-groups))
    (unless (eq ibuffer-sorting-mode 'project-name)
      (ibuffer-do-sort-by-project-name)))
  (add-hook 'ibuffer-hook #'crafted-ide-enhance-ibuffer-with-ibuffer-project))


;; Call this function with the path to your CSV file
;; (let ((REPO_LIST (getenv "REPO_LIST")))
;;   (my/add-projects-from-csv REPO_LIST))

;;; Shortcut keys
;; Define projectile command keys map. 
(define-key projectile-mode-map (kbd "C-c p") 'projectile-command-map)

(provide 'custom-project-support)
;;; custom-project-support.el ends here
