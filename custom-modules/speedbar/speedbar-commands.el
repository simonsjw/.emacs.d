;;; speedbar-commands.el --- Interactive Speedbar commands -*- lexical-binding: t; -*-

;; Copyright (C) 2026 Simon Watson
;; SPDX-License-Identifier: MIT

;; Author: Simon Watson

;;; Commentary:
;; All user-facing interactive functions for Speedbar.

;;; Code:

(require 'speedbar)
(require 'logging-config)

(defun my-speedbar/set-speedbar-directory-to-file-path (file-path &optional pin)
  "Set the speedbar directory to FILE-PATH and refresh it.
With prefix argument or PIN non-nil, also pin the directory."
  (interactive "DDirectory: \nP")
  (if pin
      (my-speedbar/set-speedbar-directory-and-pin file-path)
    (let ((expanded-path (expand-file-name file-path)))
      (when (file-directory-p expanded-path)
        (setq default-directory expanded-path)
        (speedbar-refresh)
        (message "speedbar directory set to %s" expanded-path)))))

(defun my-speedbar/set-speedbar-directory-and-pin (directory &optional quiet)
  "Set speedbar's directory to DIRECTORY and automatically pin it.
This is the central function used by project switching commands."
  (interactive "DDirectory: ")
  (let ((expanded (expand-file-name directory)))
    (when (file-directory-p expanded)
      (setq default-directory expanded)
      (speedbar-refresh)
      (setq my-speedbar/protect-directory-clicks-p t)
      (setq my-speedbar/pinned-directory expanded)
      (unless quiet
        (message "🔒 Speedbar set and pinned to project root: %s" expanded))
      expanded)))

(defun my-speedbar/toggle ()
  "Toggle Speedbar (sr-speedbar for IDE frames, regular speedbar otherwise).
Automatically enables directory protection for IDE frames."
  (interactive)
  (let ((my-selected-frame-name (frame-parameter nil 'name)))
    (if (string-prefix-p "IDE:" my-selected-frame-name)
        (progn
          (log/debug :fn 'my-speedbar/toggle
                     :msg "Frame is an IDE - use sr-speedbar.")
          (setq my-speedbar/protect-directory-clicks-p t)
          (when my-speedbar/pinned-directory
            (message "🔒 IDE frame: protection active (pinned to %s)"
                     my-speedbar/pinned-directory))
          (let ((top-left-window
                 (car (sort (window-list)
                            (lambda (w1 w2)
                              (let ((e1 (window-edges w1))
                                    (e2 (window-edges w2)))
                                (or (< (nth 1 e1) (nth 1 e2))
                                    (and (= (nth 1 e1) (nth 1 e2))
                                         (< (nth 0 e1) (nth 0 e2))))))))))
            (select-window top-left-window))
          (sr-speedbar-toggle))
      (progn
        (log/debug :fn 'my-speedbar/toggle
                   :msg "Frame is not an IDE - use speedbar.")
        (speedbar)))))

(defun my-speedbar/open-vterm-in-dir ()
  "Open a vterm session in the directory under the cursor in Speedbar."
  (interactive)
  (let* ((dir (speedbar-line-directory))
         (buf-name (concat "Vterm: "
                           (file-name-nondirectory (directory-file-name dir)))))
    (if dir
        (let ((default-directory dir))
          (vterm buf-name))
      (error "No directory selected in Speedbar"))))

(defun my-speedbar/open-in-file-explorer ()
  "Open the current directory or file in GNOME Files (Nautilus)."
  (interactive)
  (let ((path (speedbar-line-directory)))
    (when path
      (start-process "xdg-open" nil "xdg-open" path))))

;; Override for correct width reporting with sr-speedbar
(defun speedbar-frame-width ()
  "Return the width of the sr-speedbar window, or a default value."
  (if (and (boundp 'sr-speedbar-window) sr-speedbar-window)
      (window-width sr-speedbar-window)
    30))

;; Filter toggle (dotfiles)
(setq my-speedbar/speedbar-filter-state t)

(defun my-speedbar/toggle-filter ()
  "Toggle the visibility of dotfiles in speedbar."
  (interactive)
  (setq my-speedbar/speedbar-filter-state (not my-speedbar/speedbar-filter-state))
  (if my-speedbar/speedbar-filter-state
      (progn
        (setq speedbar-directory-unshown-regexp
              "^\\(\\.[^/.].*\\|_[^/]*\\|CVS\\|RCS\\|SCCS\\)$")
        (setq speedbar-file-unshown-regexp
              "^\\(\\.[^/]*\\|CVS\\|RCS\\|SCCS\\)$"))
    (progn
      (setq speedbar-directory-unshown-regexp "^\\.$")
      (setq speedbar-file-unshown-regexp "^$")))
  (speedbar-refresh))

(defun my-speedbar/switch-speedbar-view (speedbar-view)
  "Temporarily switch to another Speedbar expansion list (e.g. \"quick buffers\")."
  (interactive)
  (speedbar-change-initial-expansion-list speedbar-view))

(defun my-speedbar/go-workspace ()
  "Switch Speedbar to the workspace directory and automatically pin it.

This command checks that Speedbar is active in file mode on an appropriate
frame before calling the internal setter with the hardcoded workspace
path '/mnt/HDD04_WDD_08TB/workspace/'.  No arguments.  Useful for quick project
root locking in a specific environment."
  (interactive)
  (when (and (bound-and-true-p speedbar-frame)
             (eq speedbar-frame (selected-frame))
             (eq speedbar-buffer (current-buffer))
             (string-equal speedbar-initial-expansion-list-name "files"))
    (my-speedbar/set-speedbar-directory-and-pin
     "/mnt/HDD04_WDD_08TB/workspace/")))

(defun my-speedbar/go-home ()
  "Switch Speedbar to home directory and automatically pin it.  

Similar guard conditions as `my-speedbar/go-workspace' before pinning to `~/'.  No arguments."
  (interactive)
  (when (and (bound-and-true-p speedbar-frame)
             (eq speedbar-frame (selected-frame))
             (eq speedbar-buffer (current-buffer))
             (string-equal speedbar-initial-expansion-list-name "files"))
    (my-speedbar/set-speedbar-directory-and-pin (expand-file-name "~/"))))


(provide 'speedbar-commands)
;;; speedbar-commands.el ends here
