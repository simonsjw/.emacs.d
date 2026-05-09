;;; flymake-config.el --- Configure Flymake -*- lexical-binding: t; -*-

;; Copyright (C) 2023
;; SPDX-License-Identifier: MIT

;; Author: System Crafters Community

;;; Commentary:

;; Flymake configuration.

;;; Code:
(require 'path-support)
(require 'logging-config)
(log/debug :fn 'flymake-config
           :msg "Starting load of the flymake-config module."
           :obj t)

;; flymake configuration
;; ---------------------
(use-package flymake
  :custom
  (flymake-mode-line-lighter "ERR")
  ;;(flymake-mode-line-format
  ;; (flymake-mode-line-title flymake-mode-line-exception                         ; deleted " " from first position after bracket.
  ;;  flymake-mode-line-counters))
  (flymake-no-changes-timeout 1.0)
  (flymake-start-on-flymake-mode t)
  (flymake-start-on-save-buffer t)
  (flymake-fringe-indicator-position 'right-fringe)
  :config
  (remove-hook 'flymake-diagnostic-functions 'flymake-proc-legacy-flymake))


;; Customizable variables
;; ----------------------
;; Customization variables used for the configuration of the Flymake user
;; interface.

;; flymake-mode-line-lighter
;;     The name of the mode. Defaults to ‘Flymake’.


;; flymake-mode-line-format
;;     Format to use for the Flymake mode line indicator.
;; DEFAULT:
;; (" " flymake-mode-line-title flymake-mode-line-exception
;;  flymake-mode-line-counters)


;; flymake-mode-line-counter-format
;;     mode line construct for formatting Flymake diagnostic counters inside
;;     the Flymake mode line indicator.
;; DEFAULT:
;; ("[" flymake-mode-line-error-counter flymake-mode-line-warning-counter
;;  flymake-mode-line-note-counter "]")


;; flymake-no-changes-timeout
;;     If any changes are made to the buffer, syntax check is automatically
;;     started after this many seconds, unless the user makes another change,
;;     which resets the timer.
;; DEFAULT:
;; 0.5


;; flymake-start-on-flymake-mode
;;     A boolean flag indicating whether to start syntax check immediately
;;     after enabling flymake-mode.
;; DEFAULT:
;; t


;; flymake-start-on-save-buffer
;;     A boolean flag indicating whether to start syntax check after saving
;;     the buffer.
;; DEFAULT:
;; t


;; flymake-error
;;     A custom face for highlighting regions for which an error has been
;;     reported.
;; DEFAULT:
;; (flymake-double-exclamation-mark compilation-error)
;; CURRENT VALUE:
;; (flymake-double-exclamation-mark modus-themes-prominent-error)


;; flymake-warning
;;     A custom face for highlighting regions for which a warning has been
;;     reported.


;; flymake-note
;;     A custom face for highlighting regions for which a note has been
;;     reported.


;; flymake-error-bitmap
;;     A bitmap used in the fringe to mark lines for which an error has been
;;     reported.
;; DEFAULT:
;; (flymake-double-exclamation-mark compilation-error)
;; CURRENT VALUE:
;; (flymake-double-exclamation-mark modus-themes-prominent-error)


;; flymake-warning-bitmap
;;     A bitmap used in the fringe to mark lines for which a warning has been
;;     reported.
;; DEFAULT:
;; (exclamation-mark compilation-warning)
;; CURRENT VALUE:
;; (exclamation-mark modus-themes-prominent-warning)


;; flymake-fringe-indicator-position
;;     Which fringe (if any) should show the warning/error bitmaps.
;; The value can be nil (do not use indicators),
;; `left-fringe’ or `right-fringe’.
;; CURRENT VALUE:
;; right-fringe

;; flymake-wrap-around
;;     If non-nil, moving to errors with flymake-goto-next-error and
;;     flymake-goto-prev-error wraps around buffer boundaries.
;; DEFAULT:
;; t
;; CURRENT VALUE:
;; t

;; Ensure that wrapped flymake diagnostics messages begin at the
;; start of the message column and do not cover the prior columns.
;; This hook is for the single-file diagnostics buffer.
(add-hook 'flymake-diagnostics-buffer-mode-hook
          (lambda ()
            (setq wrap-prefix "                            ")
            (visual-line-mode t)))

;; Same wrapping for the *project* diagnostics buffer (new in Emacs 29+).
(add-hook 'flymake-project-diagnostics-mode-hook
          (lambda ()
            (setq wrap-prefix "                                                      ")
            (visual-line-mode t)))

(defun my-flymake/show-project-diagnostics ()
  "Show a list of Flymake diagnostics for the current project.

If no project can be detected (via `project-current'), fall back to the
current directory (`default-directory') and emit a warning message.
This ensures the project-level view always has a root to work from."
  (interactive)
  (let* ((prj (project-current))
         (root (if prj
                   (project-root prj)
                 (let ((dir default-directory))
                   (message "Warning: No project directory known — using current directory %s instead." dir)
                   dir)))
         (buffer (flymake--project-diagnostics-buffer root)))
    (with-current-buffer buffer
      (flymake-project-diagnostics-mode)
      (when prj
        (setq-local flymake--project-diagnostic-list-project prj))
      (revert-buffer)
      (display-buffer (current-buffer)))))

;; Optional helper: preload all project files so that project diagnostics
;; can see diagnostics from every file (Flymake only runs on visited buffers).
;; Since your projects are small (a few dozen files), this is feasible.
;; Run it once per session or before calling `my-flymake/show-project-diagnostics'.
(defun my-flymake/preload-project-for-diagnostics (&optional auto-show-delay)
  "Visit every file in the current project and ensure `flymake-mode' is enabled.

This populates `flymake-show-project-diagnostics' (and any custom project
diagnostic views) with results from the entire project.

AUTO-SHOW-DELAY: if non-nil, automatically run
`flymake-show-project-diagnostics' after this many seconds (default 4).
Set to nil to disable auto-show.

Only use for small projects (a few dozen files).  Large projects will be slow
and will keep many buffers alive in the background."
  (interactive "P")
  (let* ((prj (project-current t))
         (files (project-files prj))
         (count (length files))
         (done 0)
         (errors 0)
         (delay (if (numberp auto-show-delay) auto-show-delay 4)))
    (message "Preloading %d project files for Flymake..." count)
    (dolist (file files)
      (condition-case err
          (let ((buf (find-file-noselect file)))
            (with-current-buffer buf
              (unless (bound-and-true-p flymake-mode)
                (flymake-mode 1))
              (flymake-start))
            (setq done (1+ done)))
        (error
         (setq errors (1+ errors))
         (message "Warning: failed to preload %s: %s" file (error-message-string err))))
      (when (= (mod done 10) 0)           ; occasional progress update
        (message "Preloaded %d/%d files (%.0f%%)..." done count
                 (* 100.0 (/ done (float count))))))
    (message "Preload complete: %d succeeded, %d errors. %s"
             done errors
             (if (and delay (> delay 0))
                 (format "Project diagnostics will appear in ~%ds." delay)
               "Run `flymake-show-project-diagnostics' (or your wrapper) when ready."))
    (when (and delay (> delay 0))
      (run-with-timer delay nil #'flymake-show-project-diagnostics))))

;; Keybindings
(with-eval-after-load "prog-mode"
  (keymap-set prog-mode-map "C-c e n" #'flymake-goto-next-error)
  (keymap-set prog-mode-map "C-c e p" #'flymake-goto-prev-error)
  (keymap-set python-ts-mode-map "C-c e p" #'my-flymake/show-project-diagnostics)
  (keymap-set prog-mode-map "C-c e o" #'my-flymake/preload-project-for-diagnostics)
  )

(log/debug :fn 'flymake-config
           :msg "Finishing load of the flymake-config module."
           :obj t)

(provide 'flymake-config)
;;; flymake-config.el ends here
