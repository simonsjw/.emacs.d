;;; logging-view-mode.el --- Major mode for viewing log files -*- lexical-binding: t; -*-

;; Author: Simon Watson
;; Version: 1.0
;; Keywords: logs, tools
;; URL: http://example.com/logging-view-mode

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

;; Function to determine LOGTYPE face
(defun logging-view-logtype-face ()
  "Return the appropriate face for the current LOGTYPE."
  (let ((logtype (match-string 2)))
    (cond
     ((string= logtype "INFO") 'logging-view-logtype-info-face)
     ((string= logtype "WARNING") 'logging-view-logtype-warning-face)
     ((string= logtype "ERROR") 'logging-view-logtype-error-face)
     ((string= logtype "DEBUG") 'logging-view-logtype-debug-face)
     (t 'default))))

;; Define font-lock keywords
(defvar logging-view-font-lock-keywords
  `(
    ;; Match the main log line structure and apply faces to each group
    ("^\\[\\([0-9-: .]+\\); \\(INFO\\|WARNING\\|ERROR\\|DEBUG\\); \\([^]]+\\)\\]\\(.*?\\);\\([^;]+\\);"
     ;; Group 1: Timestamp
     (1 'logging-view-timestamp-face)
     ;; Group 2: LOGTYPE with dynamic face
     (2 (logging-view-logtype-face))
     ;; Group 3: Location
     (3 'logging-view-location-face)
     ;; Group 4: Message
     (4 'logging-view-message-face)
     ;; Group 5: Object
     (5 'logging-view-obj-face))
    
    ;; Fallback: Match any line not matching the above structure
    ("^[^[]+.*"
     ;; Apply the Object face to the entire line, excluding any trailing ';'
     (0 (progn
          (let ((line-end (line-end-position)))
            ;; Remove Object face from trailing ';' if present
            (when (and (> line-end 0)
                       (char-equal (char-before line-end) ?\;))
              (put-text-property (1- line-end) line-end 'face nil)))
          'logging-view-obj-face)))
    )
  "Highlighting expressions for `logging-view-mode'.")





;; Define variables for filters
(defvar logging-view-active-filters (make-hash-table :test 'equal)
  "Hash table storing active log type filters.")

;; Toggle filter function
(defun logging-view-toggle-filter (logtype)
  "Toggle the filter for LOGTYPE."
  (interactive)
  (if (gethash logtype logging-view-active-filters)
      (remhash logtype logging-view-active-filters)
    (puthash logtype t logging-view-active-filters))
  (logging-view-apply-filters)
  (logging-view-update-modeline))

;; Apply filters to buffer
(defun logging-view-apply-filters ()
  "Apply log type filters to the buffer."
  (save-excursion
    (goto-char (point-min))
    (let ((inhibit-read-only t))
      (while (re-search-forward
              "^\\[\\([0-9-: .]+\\); \\(INFO\\|WARNING\\|ERROR\\|DEBUG\\); \\([^]]+\\)\\]\\(.*?\\);\\([^;]+\\);"
              nil t)
        (let ((logtype (match-string 2)))
          (if (or (not (hash-table-p logging-view-active-filters))
                  (hash-table-empty-p logging-view-active-filters)
                  (gethash logtype logging-view-active-filters))
              (progn
                (put-text-property (line-beginning-position) (line-end-position)
                                   'invisible nil))
            (put-text-property (line-beginning-position) (line-end-position)
                               'invisible t)))))))

;; Update mode line
(defun logging-view-update-modeline ()
  "Update the mode line buttons based on active filters."
  (setq mode-line-format
        (list
         " LogView: "
         (logging-view-create-button "INFO")
         " "
         (logging-view-create-button "WARNING")
         " "
         (logging-view-create-button "ERROR")
         " "
         (logging-view-create-button "DEBUG"))))

;; Create mode line button
(defun logging-view-create-button (logtype)
  "Create a mode line button for LOGTYPE."
  (propertize logtype
              'face (cond
                     ((string-equal logtype "INFO") 'logging-view-logtype-info-face)
                     ((string-equal logtype "WARNING") 'logging-view-logtype-warning-face)
                     ((string-equal logtype "ERROR") 'logging-view-logtype-error-face)
                     ((string-equal logtype "DEBUG") 'logging-view-logtype-debug-face))
              'mouse-face 'highlight
              'help-echo (concat "Toggle " logtype " logs")
              'local-map (let ((map (make-sparse-keymap)))
                           (define-key map [mouse-1]
                                       `(lambda ()
                                          (interactive)
                                          (logging-view-toggle-filter ,logtype)))
                           map)))

;; Initialise modeline
(defun logging-view-initialize-modeline ()
  "Initialize the mode line with filter buttons."
  (logging-view-update-modeline))

;; Define the major mode
(define-derived-mode logging-view-mode fundamental-mode "LogView"
  "Major mode for viewing log files."
  (setq font-lock-defaults '(logging-view-font-lock-keywords))
  (setq buffer-read-only t)
  (logging-view-initialize-modeline)
  (logging-view-apply-filters))

;; Provide the feature
(provide 'logging-view-mode)

;;; logging-view-mode.el ends here
