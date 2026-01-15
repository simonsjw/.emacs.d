;;; server-support.el --- server support -*- lexical-binding: t; -*-

;; Copyright (C) 2025
;; SPDX-License-Identifier: MIT

;; Author: Simon Watson
;; Keywords: emacs server

;;; Commentary:

;; This package handles the setup of the Emacs server.

;;; library imports:
;;     (none)

;;; Package phase

;;; Code:

;; start the server if its not already running.
;; To shutdown the server use the below: 
;;   M-x server-edit
;;   C-x C-c
(unless (require 'server nil t)
  (message "Warning: Failed to load 'server' library. Server mode not started.")
  (server-start))

(defun my-server/display-simple-frame (buffer)
  "Display server BUFFER in a new, simple frame.

Avoid creation of an IDE layout or custom window management.
This creates a single-window frame, bypasses category assignment, and ensures
isolation from IDE frames."
  (let* ((frame-params '((UI-TYPE . nil)                                          ; No IDE tag
                         (custom-window-management . nil)                         ; Disable custom management
                         (name . "Simple File Frame")                             ; Optional: Name for easy identification
                         (width . 120)                                            ; Optional: Customize size
                         (height . 40)))
         (frame (make-frame frame-params))
         (switch-to-buffer-obey-display-actions nil))                             ; Temporarily disable to bypass display-buffer advice/categories
    (select-frame frame)
    (switch-to-buffer buffer)
    (delete-other-windows)                                                        ; Ensure single window in the frame
    frame)
  
  (dolist (face '(window-divider ;; remove the window dividers - this must be done after the instance has been created (ui-config.el is ignored for --daemon)
                  window-divider-first-pixel
                  window-divider-last-pixel))
    (face-spec-reset-face face)
    (set-face-foreground face (face-attribute 'default :background)))
  (set-face-background 'fringe (face-attribute 'default :background))
  )

(setq server-window #'my-server/display-simple-frame)

(provide 'server-support)
;;; server-support.el ends here


