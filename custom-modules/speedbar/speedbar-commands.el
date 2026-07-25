;;; speedbar-commands.el --- Interactive Speedbar commands (updated for new pinning) -*- lexical-binding: t; -*-

;; Copyright (C) 2026 Simon Watson
;; SPDX-License-Identifier: MIT

;; Author: Simon Watson

;;; Commentary:
;; User-facing interactive commands for Speedbar.
;; Updated to work with the new dynamic MY-SPEEDBAR/PIN-PROJECT-ROOT model.
;;
;; Note on manual root commands:
;; Functions like `my-speedbar/set-speedbar-directory-and-pin`, `my-speedbar/go-workspace`
;; and `my-speedbar/go-home` are retained as **explicit manual overrides**.
;; They jump to a specific root and enable pinning. They are still useful
;; even in the new dynamic model (e.g. for quickly locking to workspace or home).

;;; Code:

(require 'speedbar)
(require 'logging-config)

(defun my-speedbar/set-speedbar-directory-to-file-path (FILE-PATH &optional PIN)
  "Set the Speedbar directory to FILE-PATH and refresh it.

FILE-PATH is the directory path (string).
With prefix argument or PIN non-nil, also enable project pinning
(MY-SPEEDBAR/PIN-PROJECT-ROOT set to t)."
  (interactive "DDirectory: \nP")
  (let ((expanded-path (expand-file-name FILE-PATH)))
    (when (file-directory-p expanded-path)
      (setq default-directory expanded-path)
      (speedbar-refresh)
      (when PIN
        (setq my-speedbar/pin-project-root t)
        (setq my-speedbar/file-tree-root default-directory))
      (message "Speedbar directory set to %s" expanded-path))))

(defun my-speedbar/set-speedbar-directory-and-pin (DIRECTORY &optional QUIET)
  "Set Speedbar's directory to DIRECTORY and enable project pinning.

DIRECTORY is the target directory path (string).
This is an explicit manual override that sets MY-SPEEDBAR/PIN-PROJECT-ROOT to t.
Useful for quickly locking Speedbar to a specific project root."
  (interactive "DDirectory: ")
  (let ((expanded (expand-file-name DIRECTORY)))
    (when (file-directory-p expanded)
      (setq default-directory expanded)
      (speedbar-refresh)
      (setq my-speedbar/pin-project-root t)
      (setq my-speedbar/file-tree-root default-directory)
      (unless QUIET
        (message "🔒 Speedbar set and pinned to project root: %s" expanded))
      expanded)))

(defun my-speedbar/toggle ()
  "Toggle Speedbar (sr-speedbar for IDE frames, regular speedbar otherwise).
Automatically enables project pinning (MY-SPEEDBAR/PIN-PROJECT-ROOT = t)
for IDE frames."
  (interactive)
  (let ((my-selected-frame-name (frame-parameter nil 'name)))
    (if (string-prefix-p "IDE:" my-selected-frame-name)
        (progn
          (log/debug :fn 'my-speedbar/toggle
                     :msg "Frame is an IDE - use sr-speedbar.")
          (setq my-speedbar/pin-project-root t)
          (when my-speedbar/file-tree-root
            (message "🔒 IDE frame: pinning active (root: %s)"
                     my-speedbar/file-tree-root))
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
  "Toggle the visibility of dotfiles in Speedbar."
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

(defun my-speedbar/switch-speedbar-view (SPEEDBAR-VIEW)
  "Temporarily switch to another Speedbar expansion list (e.g. \"quick buffers\").

SPEEDBAR-VIEW is the name of the desired expansion list (string)."
  (interactive)
  (speedbar-change-initial-expansion-list SPEEDBAR-VIEW))

(defun my-speedbar/go-workspace ()
  "Switch Speedbar to the workspace directory and enable project pinning.

Checks that Speedbar is active in file view before pinning to the workspace path.
This is an explicit manual override that sets MY-SPEEDBAR/PIN-PROJECT-ROOT to t."
  (interactive)
  (when (and (bound-and-true-p speedbar-frame)
             (eq speedbar-frame (selected-frame))
             (eq speedbar-buffer (current-buffer))
             (string-equal speedbar-initial-expansion-list-name "files"))
    (my-speedbar/set-speedbar-directory-and-pin
     "/mnt/HDD04_WDD_08TB/workspace/")))

(defun my-speedbar/go-home ()
  "Switch Speedbar to home directory and enable project pinning.

Similar guard conditions as `my-speedbar/go-workspace' before pinning to `~/'.
This is an explicit manual override that sets MY-SPEEDBAR/PIN-PROJECT-ROOT to t."
  (interactive)
  (when (and (bound-and-true-p speedbar-frame)
             (eq speedbar-frame (selected-frame))
             (eq speedbar-buffer (current-buffer))
             (string-equal speedbar-initial-expansion-list-name "files"))
    (my-speedbar/set-speedbar-directory-and-pin (expand-file-name "~/"))))

(provide 'speedbar-commands)
;;; speedbar-commands.el ends here
