;;; logging-view-mode.el --- Major mode for viewing log files -*- lexical-binding: t; -*-

;; Author: Simon Watson
;; Version: 1.4
;; Keywords: logs, tools
;; URL: tbc

;;; Commentary:

;; A major mode for viewing and interacting with log files.
;; Features:
;; - Syntax highlighting for log components.
;; - Interactive mode line buttons to filter log types.

;;; Code:

;; Define custom faces
(defface logging-view-timestamp-face
  `((t (:foreground ,info-theme-flat-green)))
  "Face for log timestamps."
  :group 'logging-view)

(defface logging-view-logtype-info-face
  `((t (:foreground ,info-theme-faded-lime :weight bold)))
  "Face for INFO log type."
  :group 'logging-view)

(defface logging-view-logtype-warning-face
  `((t (:foreground ,info-theme-flat-yellow :weight bold)))
  "Face for WARNING log type."
  :group 'logging-view)

(defface logging-view-logtype-error-face
  `((t (:foreground ,info-theme-flat-red :weight bold)))
  "Face for ERROR log type."
  :group 'logging-view)

(defface logging-view-logtype-debug-face
  `((t (:foreground ,info-theme-flat-blue :weight bold)))
  "Face for DEBUG log type."
  :group 'logging-view)

(defface logging-view-location-face
  `((t (:foreground ,info-theme-magenta)))
  "Face for log location."
  :group 'logging-view)

(defface logging-view-message-face
  `((t (:foreground ,info-theme-light-blue)))
  "Face for log messages."
  :group 'logging-view)

(defface logging-view-obj-face
  `((t (:foreground ,info-theme-light-orange)))
  "Face for log objects."
  :group 'logging-view)


;; Define font-lock keywords
;; "\\[\\([0-9]\\{4\\}-[0-9]\\{2\\}-[0-9]\\{2\\} [0-9]\\{2\\}:[0-9]\\{2\\}:[0-9]\\{2\\}\\.[0-9]\\{6\\}\\)"
(defvar logging-view-font-lock-keywords
  (let* (
         ;; Define regex patterns for each component
         (timestamp-regex
          (concat "\\[\\([0-9]\\{4\\}-[0-9]\\{2\\}-[0-9]\\{2\\} "
                  "[0-9]\\{2\\}:[0-9]\\{2\\}:[0-9]\\{2\\}\\.[0-9]\\{6\\}\\)"))
         (logtype-regex "; \\(INFO\\|WARNING\\|ERROR\\|DEBUG\\);")
         (location-regex "; \\([^]]+\\)\\]")
         (message-regex "\\]\\(.*?\\);")
         (obj-regex ";\\([^;]+\\);"))
    `(
      (,timestamp-regex 1 'logging-view-timestamp-face)
      (,logtype-regex 1
                      (cond
                       ((string-equal (match-string 1) "INFO")
                        'logging-view-logtype-info-face)
                       ((string-equal (match-string 1) "WARNING")
                        'logging-view-logtype-warning-face)
                       ((string-equal (match-string 1) "ERROR")
                        'logging-view-logtype-error-face)
                       ((string-equal (match-string 1) "DEBUG")
                        'logging-view-logtype-debug-face)))
      (,location-regex 1 'logging-view-location-face)
      (,message-regex 1 'logging-view-message-face)
      (,obj-regex 1 'logging-view-obj-face)
      )))

;; Define buffer-local variables for filters and overlays
(defvar-local logging-view-active-filters (make-hash-table :test 'equal)
  "Hash table storing active log type filters.")

(defvar-local logging-view-overlays nil
  "List of overlays used to hide filtered log entries.")

;; Toggle filter function
(defun logging-view-toggle-filter (logtype)
  "Toggle the filter for LOGTYPE."
  (interactive)
  (if (gethash logtype logging-view-active-filters)
      (remhash logtype logging-view-active-filters)
    (puthash logtype t logging-view-active-filters))
  (logging-view-apply-filters)
  (logging-view-update-modeline))

;; Apply filters to buffer using overlays
(defun logging-view-apply-filters ()
  "Apply log type filters to the buffer using overlays."
  (save-excursion
    (remove-overlays (point-min) (point-max) 'logging-view t)                     ; Remove existing log entry overlays
    (setq logging-view-overlays nil)                                              ; Reset the overlay list
    (goto-char (point-min))
    (let ((start-regex "^\\[[0-9]\\{4\\}-[0-9]\\{2\\}-[0-9]\\{2\\} [0-9]\\{2\\}:[0-9]\\{2\\}:[0-9]\\{2\\}\\.[0-9]\\{6\\}; \\(INFO\\|WARNING\\|ERROR\\|DEBUG\\); \\([^]]+\\)\\]"))
      (while (re-search-forward start-regex nil t)
        (let ((entry-start (match-beginning 0))
              (logtype (match-string 1)))
          ;; Find the end of the current log entry
          (if (re-search-forward start-regex nil t)
              (let ((entry-end (match-beginning 0)))
                (goto-char entry-end))
            ;; If no next entry, set end to end of buffer
            (goto-char (point-max)))
          (let ((entry-end (point)))
            ;; Adjust entry-end to include the final newline if present
            (when (and (> entry-end entry-start)
                       (eq (char-before entry-end) ?\n))
              (setq entry-end (1+ entry-end)))
            ;; Decide whether to hide or show the entry
            (unless (or (hash-table-empty-p logging-view-active-filters)
                        (gethash logtype logging-view-active-filters))
              (let ((ov (make-overlay entry-start entry-end)))
                (overlay-put ov 'invisible t)
                (overlay-put ov 'logging-view t)                                  ; Tag to identify the overlay
                (push ov logging-view-overlays)))))))))

;; Update mode line
(defun logging-view-update-modeline ()
  "Update the mode line buttons based on active filters."
  (setq-local mode-line-format
              (list
               " LogView: "
               (logging-view-create-button "INFO")
               " "
               (logging-view-create-button "WARNING")
               " "
               (logging-view-create-button "ERROR")
               " "
               (logging-view-create-button "DEBUG"))))

;; Create mode line button using propertize with correct buffer capture
(defun logging-view-create-button (logtype)
  "Create a mode line button for LOGTYPE."
  (let* ((active (gethash logtype logging-view-active-filters))
         (buffer (current-buffer)))                                               ; Capture the current buffer
    (concat
     (propertize (concat " " logtype " ")
                 'face (cond
                        ((string-equal logtype "INFO")
                         'logging-view-logtype-info-face)
                        ((string-equal logtype "WARNING")
                         'logging-view-logtype-warning-face)
                        ((string-equal logtype "ERROR")
                         'logging-view-logtype-error-face)
                        ((string-equal logtype "DEBUG")
                         'logging-view-logtype-debug-face))
                 'help-echo (concat "Toggle " logtype " logs")
                 'mouse-face 'mode-line-highlight
                 'local-map (let ((map (make-sparse-keymap)))
                              (define-key map [mode-line mouse-1]
                                          `(lambda ()
                                             (interactive)
                                             (with-current-buffer ,buffer
                                               (logging-view-toggle-filter
                                                ,logtype))))
                              map)
                 'cursor 'pointer)
     ;; Visual indicator for active filters
     (when active
       (propertize "*"
                   'face '(:foreground "white" :background "red"))))))

;; Initialize modeline
(defun logging-view-initialize-modeline ()
  "Initialize the mode line with filter buttons."
  (logging-view-update-modeline))

;; Handle buffer changes to update overlays dynamically
(defun logging-view-after-change-function (beg end len)
  "Function to handle buffer changes and update overlays.
BEG, END, and LEN are the standard parameters for `after-change-functions`."
  ;; Re-apply filters to ensure new entries are handled
  (logging-view-apply-filters))

;; Define the major mode
(define-derived-mode logging-view-mode fundamental-mode "LogView"
  "Major mode for viewing log files."
  (setq font-lock-defaults '(logging-view-font-lock-keywords))
  (setq buffer-read-only t)
  ;; Initialize buffer-local variables
  (setq logging-view-active-filters (make-hash-table :test 'equal))
  (setq logging-view-overlays nil)
  ;; Initialize modeline
  (logging-view-initialize-modeline)
  ;; Apply initial filters
  (logging-view-apply-filters)
  ;; Add hook to handle buffer changes
  (add-hook 'after-change-functions #'logging-view-after-change-function nil t))

;; Clean up overlays and hooks when exiting the mode
(defun logging-view-exit-mode ()
  "Clean up overlays and hooks when exiting `logging-view-mode`."
  (remove-overlays (point-min) (point-max) 'logging-view t)
  (setq logging-view-overlays nil)
  (remove-hook 'after-change-functions #'logging-view-after-change-function t)
  ;; Reset mode line
  (force-mode-line-update))

(add-hook 'kill-buffer-hook #'logging-view-exit-mode nil t)

;; Provide the feature
(provide 'logging-view-mode)

;;; logging-view-mode.el ends here
