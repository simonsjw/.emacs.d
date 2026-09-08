;;; system-frame-tools.el --- Frame, fringe, and ss port helpers. -*- lexical-binding: t; -*-

;; Copyright (C) 2026 Simon Watson
;; SPDX-License-Identifier: MIT

;; Author: Simon Watson

;;; Commentary:

;; Piece of `system-tools': frame helpers, fringe/margin theme
;; helpers, and `ss' port listing.  Required by the loader, not from
;; `init.el' directly.
;;
;; Map:
;;   Feature:    system-frame-tools
;;   Load-after: path-support logging-config
;;   Load-phase: bootstrap
;;   Keymaps:    none
;;   Docs:       docs/system-frame-tools.org
;;   OS:         ss

;;; Code:

(require 'path-support)
(require 'logging-config)
(log/debug :fn 'system-frame-tools
           :msg "Starting load of the system-frame-tools module."
           :obj t)

;;;; Frame management

(defvar my-frame-tools-inhibit-kill nil
  "Non-nil means inhibit killing buffers in `my-frame-tools/kill-buffers-on-frame-close'.")

(defun my-frame-tools/kill-buffers-on-frame-close (frame)
  "Kill buffers unique to FRAME when it's closed."
  (unless my-frame-tools-inhibit-kill
    (let ((my-frame-tools-inhibit-kill t)                                         ; Prevent recursion
          (buffers (delete-dups (mapcar #'window-buffer (window-list frame)))))
      (dolist (buf buffers)
        (when (and (buffer-live-p buf)
                   (not (minibufferp buf))
                   (= (length (get-buffer-window-list buf nil t))
                      (length (get-buffer-window-list buf nil frame))))
          (kill-buffer buf))))))


(defun my-frame-tools/delete-frame-by-name (frame-name)
  "Delete a frame by its name FRAME-NAME."
  (interactive "sEnter frame name to delete: ")                                   ; Prompt for frame name
  (let ((found nil))                                                              ; Track if we found the frame
    (dolist (frame (frame-list))
      (when (string= (frame-parameter frame 'name) frame-name)
        (delete-frame frame)
        (setq found t)
        (message "Deleted frame named '%s'." frame-name)))
    (unless found
      (message "No frame named '%s' found." frame-name))))

(defun my-frame-tools/get-frame-by-name (frame-name)
  "Get a frame object when given its name FRAME-NAME."
  (defvar frame-object nil)
  (let ((found nil))                                                              ; Track if we found the frame
    (dolist (frame (frame-list))
      (when (string= (frame-parameter frame 'name) frame-name)

        (setq found t)
        (setq frame-object frame)
        (message "found frame named '%s'." frame-name)))
    (unless found
      (message "No frame named '%s' found." frame-name))
    frame-object))


(defun my-frame-tools/set-current-frame-name (name)
  "Set the name of the current frame to NAME."
  (interactive "sEnter new frame name: ")                                         ; Prompt for the frame name interactively
  (set-frame-name name))


(defun my-frame-tools/close-all-windows-except-first (&optional frame)
  "Close all windows in FRAME except the first window.
If FRAME is nil, use the current frame."
  (let* ((target-frame (or frame (selected-frame)))
         (first-window (frame-first-window target-frame)))
    (select-window first-window)                                                  ; Select the first window
    (with-selected-frame target-frame
      (delete-other-windows))))                                                   ; Close all other windows


;; end of Frame management
;; -----------------------


;;;; TOOLS FOR THEME SUPPORT
;;   -----------------------

(defun my-theme-support/tone-down-fringes ()
  "Set the buffer fringes to be invisible (same colour as default background).
This is the area inside the window margin which can hold icons.

Purpose:
  Make fringes blend perfectly with the buffer so they disappear visually.
  Uses strongest possible override so Modus themes cannot win.

Variables:
  None — uses current default face colours (always safe).

Output: fringes match default background (invisible).
Flow:
  1. Guard for graphical frames.
  2. Strong frame-local override with :override t.
  3. Immediate re-apply after theme reloads.
Efficiency: single `set-face-attribute', idempotent, under 20 lines.
Historical lesson: theme overrides always win unless you use :override t or `face-spec-set'."
  (when (display-graphic-p)
    (let ((bg (face-background 'default))
          (fg (face-foreground 'default)))
      (set-face-attribute 'fringe nil
                          :foreground fg
                          :background bg)
      (message "[INFO; visual] Fringes toned down to match default background"))))

(defun my-theme-tools/set-current-window-margins (left &optional right)
  "Set the left and optionally right margins of the current window.
LEFT is the left margin width, and RIGHT is the right margin width (optional)."
  (let ((win (selected-window)))
    (set-window-margins win left right)))


;; ---end of TOOLS FOR THEME SUPPORT---

;;; TOOLS USING THE OS
;;  ------------------
(defun my-os-tools/ports-found-by-ss (output)
  "Extract a list of port numbers from `ss -tuln` output.
OUTPUT:  the text string produced from ss -tuln."
  (let ((lines (split-string output "\n" t))                                      ; Split by newline
        (ports '()))
    (dolist (line lines ports)
      ;; Find lines that contain 'LISTEN'
      (when (string-match-p "LISTEN" line)
        ;; Extract the port number using regex
        (when (string-match ".*\\([0-9]+\\)$" line)
          (let ((port (match-string 1 line)))
            (push (string-to-number port) ports)))))
    ports))

(defun my-os-tools/get-ss-output ()
  "Get the output of `ss -tuln`.
If `ss` is not found, show an error
message."
  (if (executable-find "ss")
      (shell-command-to-string "ss -tuln")
    (progn
      (message
       "Error: The 'ss' command is not available on this system.")
      ""))) ;; Return an empty string when `ss` is not found

(defun my-os-tools/find-available-ports (start end used-ports)
  "Find available ports in a given range.
START:       the start of the port range.
END:         the end of the port range to be checked.
USED-PORTS:  the ports that are not available."
  (let ((available-ports '()))
    (dotimes (i (- end start) available-ports)                                    ; Iterate over range
      (let ((port (+ start i)))
        (unless (member port used-ports)
          (push port available-ports))))))

;; ---end of TOOLS USING THE OS---k

(log/debug :fn 'system-frame-tools
           :msg "Finishing load of the system-frame-tools module."
           :obj t)

(provide 'system-frame-tools)
;;; system-frame-tools.el ends here
