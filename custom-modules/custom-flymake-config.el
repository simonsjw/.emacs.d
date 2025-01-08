;;; custom-ide-config.el --- Configure Flymake -*- lexical-binding: t; -*-

;; Copyright (C) 2023
;; SPDX-License-Identifier: MIT

;; Author: System Crafters Community

;;; Commentary:

;; Flymake configuration.

;; Suggested additional keybindings
;; (with-eval-after-load "prog-mode"
;;   (keymap-set prog-mode-map "C-c e n" #'flymake-goto-next-error)
;;   (keymap-set prog-mode-map "C-c e p" #'flymake-goto-prev-error))

;;; Code:

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
(add-hook 'flymake-diagnostics-buffer-mode-hook
          (lambda ()
            (setq wrap-prefix "                            ")
            (visual-line-mode t)))                                                ; Adjust indentation size as needed

(defun my-flymake/show-project-diagnostics ()
  "Show a list of Flymake diagnostics for the current project."
  (interactive)
  (let* ((prj (project-current))
         (root (project-root prj))
         (buffer (flymake--project-diagnostics-buffer root)))
    (with-current-buffer buffer
      (flymake-project-diagnostics-mode)
      (setq-local flymake--project-diagnostic-list-project prj)
      (revert-buffer)
      (display-buffer (current-buffer)))))

;; (display-buffer (current-buffer)
;;                 `((display-buffer-reuse-window
;;                    display-buffer-at-bottom)
;;                   (window-height . fit-window-to-buffer))))))
(provide 'custom-flymake-config)
;;; custom-flymake-config.el ends here

