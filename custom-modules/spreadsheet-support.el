;;; spreadsheet-support.el --- Spreadsheet configuration -*- mode: emacs-lisp; mode: outline-minor; lexical-binding: t; -*-

;;; License
;; Copyright (C) 2022
;; SPDX-License-Identifier: MIT

;; Author: Erik Lundstedt, System Crafters Community

;;; Commentary:

;; configure a spreadsheet like buffer.

;;; Code:
(use-package ses)
;; (use-package ses
;;   :ensure nil  ; Built-in, no need to install
;;   :defer t     ; Load only when needed (e.g., on .ses file open)
;;   :hook (ses-mode . my-ses/ses-mode-hook)
;;   :custom
;;   (ses-jump-cell-name-function #'upcase)  ; Default: uppercase cell names for jumps
;;   (ses-jump-prefix-function #'ses-jump-prefix-numeric)  ; Interpret prefix args as row/column numbers
;;   :config
;;   (defun my-ses/ses-mode-hook ()
;;     "Custom hook for SES mode: Define local printers if needed.
;; This runs on SES buffer activation, ensuring printers are available
;; without overriding globals.
;; Prioritises efficiency by checking read-only status."
;;     (when (and (eq major-mode 'ses-mode)
;;                display-line-numbers
;;                ses--cells))  ; Ensure SES data structures are initialised.

;;     ))


(defun my-ses/create-new-ses (file-path)
  "Create and save a new SES spreadsheet at FILE-PATH.

This is a helper function for `my-open-or-create-spreadsheet` to
initialize a new SES spreadsheet.

Args:
  file-path (string): Full path where the new spreadsheet will be saved.

Returns:
  buffer: The buffer containing the new spreadsheet."
  (find-file file-path)                                                           ; Create buffer for new file
  (ses-mode)                                                                      ; Activate SES mode
  ;; (ses-new)                             ; Initialize new SES spreadsheet
  ;; (save-buffer)                         ; Save the new file
                                                                                  ; Ensure SES buffer is narrowed after mode activation.
  ;;(ses-setup)
  (let ((orig-buf (current-buffer)))
    (switch-to-buffer (get-buffer-create "*scratch*"))
    (switch-to-buffer orig-buf)
    (redisplay t))
  (ses-renarrow-buffer))                                                               ; Return the buffer

(defun my-ses/adjust-headers-for-line-numbers ()
  "Adjust SES column headers to align when line numbers are enabled.

Line numbers move the worksheet content right - the column headers need
adjusting for this.  The function here calculates the offset from line number
width and repositions headers accordingly."
  (when (and (eq major-mode 'ses-mode)
             display-line-numbers)
    (let* ((max-lines (count-lines (point-min) (point-max)))
           (num-width (length (number-to-string max-lines)))
           (offset (* num-width (frame-char-width))))
      ;; Adjust SES column header positions
      (save-excursion
        (goto-char (point-min))
        (while (looking-at "^[A-Z]+")
          (put-text-property (point) (1+ (point))
                             'display `(space . (:width ,offset)))
          (forward-line 1))))))

(defun my-ses/force-refresh-via-window-switch ()
  "Force refresh of current SES buffer by briefly switching windows.
This simulates user action of clicking out and back in, triggering redisplay.
Variables:
- orig-win: The originally selected window.
Output: None (side-effect: buffer redisplay).
Flow: Save current window, select next, then restore original."
  (interactive)
  (let ((orig-win (selected-window)))  ; Save current window
    (select-window (next-window))      ; Switch to next window in list
    (select-window orig-win)))         ; Switch back to original

(defun my-ses/jump-to-ses-and-back ()
  "Briefly switch to the 'spreadsheet.ses' buffer and back to original.
This triggers redisplay in the 'spreadsheet.ses' buffer by activating it
momentarily, which may resolve display artefacts in SES mode.
Variables:
- orig-buffer: The originally current buffer.
Output: None (side-effect: buffer switch and potential redisplay).
Flow: Save current buffer, switch to 'spreadsheet.ses', then restore original."
  (interactive)
  (let ((orig-buffer (current-buffer)))  ; Save current buffer
    (when (get-buffer "spreadsheet.ses")  ; Check if target buffer exists
      (switch-to-buffer "spreadsheet.ses")  ; Switch to SES buffer
      (switch-to-buffer orig-buffer))))  ; Switch back to original

;; Hook this function to run after SES mode starts and line numbers are enabled
;;(add-hook 'ses-mode-hook #'my-ses/adjust-headers-for-line-numbers)
;;(add-hook 'window-configuration-change-hook
;;          #'my-ses/adjust-headers-for-line-numbers)

(provide 'spreadsheet-support)
;;; spreadsheet-support.el ends here
