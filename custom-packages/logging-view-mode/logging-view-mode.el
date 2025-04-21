;;; logging-view-mode.el --- Major mode for viewing log files -*- lexical-binding: t; -*-

;; Author: Simon Watson
;; Version: 1.7
;; Keywords: logs, tools
;; URL: tbc

;;; Commentary:

;; A major mode for viewing and interacting with log files.
;; Features:
;; - Syntax highlighting for log components
;;       (timestamp-based with multi-line support).
;; - Interactive mode line buttons to filter log types.

;;; Code:

;; Define custom faces (unchanged)
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

;; Define font-lock keywords with improved timestamp detection
(defvar logging-view-font-lock-keywords
  (let* ((entry-regex
          (concat
           "^\\(\\[\\)"                                                           ; Group 1: Opening bracket (unformatted)
           "\\([0-9]\\{4\\}-[0-9]\\{2\\}-[0-9]\\{2\\} "
           "[0-9]\\{2\\}:[0-9]\\{2\\}:[0-9]\\{2\\}\\.[0-9]\\{6\\}\\); "           ; Group 2: Timestamp
           "\\(INFO\\|WARNING\\|ERROR\\|DEBUG\\); "                               ; Group 3: Log type
           "\\([^]]+\\)\\]"                                                       ; Group 4: Location
           "\\([^;]+\\);"                                                         ; Group 5: Message (up to first ;)
           "\\(.*\\(?:\n\\(?:[^[]\\|\\]\\).*\\)*\\)"                              ; Group 6: Object (until next timestamp)
           "\\(;\\)"                                                              ; Group 7: Trailing semicolon
           ))
         ;; Stricter timestamp detection: must start with [YYYY-MM-DD
         (next-timestamp "^\\[[0-9]\\{4\\}-[0-9]\\{2\\}-[0-9]\\{2\\} "))
    `((,entry-regex
       (1 nil)                                                                    ; Opening bracket: no face (white)
       (2 'logging-view-timestamp-face)                                           ; Timestamp
       (3 (cond
           ((string-equal (match-string 3) "INFO")
            'logging-view-logtype-info-face)
           ((string-equal (match-string 3) "WARNING")
            'logging-view-logtype-warning-face)
           ((string-equal (match-string 3) "ERROR")
            'logging-view-logtype-error-face)
           ((string-equal (match-string 3) "DEBUG")
            'logging-view-logtype-debug-face)))
       (4 'logging-view-location-face)  ; Location
       (5 'logging-view-message-face prepend)  ; Message
       (6 'logging-view-obj-face prepend)  ; Object
       (7 nil)  ; Trailing semicolon: no face (white)
       ))))

;; Define buffer-local variables for filters and overlays
(defvar-local logging-view-active-filters (make-hash-table :test 'equal)
  "Hash table storing active log type filters.")

(defvar-local logging-view-overlays nil
  "List of overlays used to hide filtered log entries.")

;; Toggle filter function (unchanged)
(defun logging-view-toggle-filter (logtype)
  "Toggle the filter for LOGTYPE."
  (interactive)
  (if (gethash logtype logging-view-active-filters)
      (remhash logtype logging-view-active-filters)
    (puthash logtype t logging-view-active-filters))
  (logging-view-apply-filters)
  (logging-view-update-modeline))

;; Apply filters to buffer using overlays with improved timestamp detection
(defun logging-view-apply-filters ()
  "Apply log type filters to the buffer using overlays."
  (save-excursion
    (remove-overlays (point-min) (point-max) 'logging-view t)
    (setq logging-view-overlays nil)
    (goto-char (point-min))
    ;; Stricter timestamp detection: must start with [YYYY-MM-DD
    (let ((start-regex "^\\[[0-9]\\{4\\}-[0-9]\\{2\\}-[0-9]\\{2\\} [0-9]\\{2\\}:[0-9]\\{2\\}:[0-9]\\{2\\}\\.[0-9]\\{6\\}; \\(INFO\\|WARNING\\|ERROR\\|DEBUG\\);"))
      (while (re-search-forward start-regex nil t)
        (let ((entry-start (match-beginning 0))
              (logtype (match-string 1)))
          ;; Find the end of the current log entry (next timestamp or buffer end)
          (if (re-search-forward start-regex nil t)
              (progn
                (goto-char (match-beginning 0))
                (beginning-of-line))
            (goto-char (point-max)))
          (let ((entry-end (point)))
            ;; Apply overlay if filtered
            (unless (or (hash-table-empty-p logging-view-active-filters)
                        (gethash logtype logging-view-active-filters))
              (let ((ov (make-overlay entry-start entry-end)))
                (overlay-put ov 'invisible t)
                (overlay-put ov 'logging-view t)
                (push ov logging-view-overlays)))))))))

;; Update mode line (unchanged)
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

;; Create mode line button (unchanged)
(defun logging-view-create-button (logtype)
  "Create a mode line button for LOGTYPE."
  (let* ((active (gethash logtype logging-view-active-filters))
         (buffer (current-buffer)))
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
                 'local-map
                 (let ((map (make-sparse-keymap)))
                   (define-key map [mode-line mouse-1]
                               `(lambda ()
                                  (interactive)
                                  (with-current-buffer ,buffer
                                    (logging-view-toggle-filter ,logtype))))
                   map)
                 'cursor 'pointer)
     (when active
       (propertize "*" 'face '(:foreground "white" :background "red"))))))

;; Initialize modeline (unchanged)
(defun logging-view-initialize-modeline ()
  "Initialize the mode line with filter buttons."
  (logging-view-update-modeline))

;; Handle buffer changes (unchanged)
(defun logging-view-after-change-function (beg end len)
  "Function to handle buffer changes and update overlays."
  (logging-view-apply-filters))

;; Define the major mode with format detection
(define-derived-mode logging-view-mode fundamental-mode "LogView"
  "Major mode for viewing log files."
  
  (setq buffer-read-only t)
  
  ;; Initialize buffer-local variables
  (setq logging-view-active-filters (make-hash-table :test 'equal))
  (setq logging-view-overlays nil)
  
  ;; Check first character to determine format (JSON support TBD)
  (goto-char (point-min))
  (if (eq (char-after) ?{)

      ;; JSON: use JSON based formatting
      (message "JSON logging detected - support coming in step 2!")
    
    ;; Non-JSON: Use timestamp-based parsing
    
    ;; if a part of the buffer falls back on a default face, it is because the
    ;; regexp font-lock matching limits have been reached. That is only likely
    ;; for the text in the Object portion of the buffer so we default all text
    ;; to that.
    (set (make-local-variable 'face-remapping-alist)
         '((font-lock-string-face logging-view-obj-face)))
    
    (setq font-lock-defaults '(logging-view-font-lock-keywords))
    
    (logging-view-initialize-modeline)
    (logging-view-apply-filters)
    (add-hook
     'after-change-functions #'logging-view-after-change-function nil t)))

;; Clean up overlays and hooks (unchanged)
(defun logging-view-exit-mode ()
  "Clean up overlays and hooks when exiting `logging-view-mode`."
  (remove-overlays (point-min) (point-max) 'logging-view t)
  (setq logging-view-overlays nil)
  (remove-hook 'after-change-functions #'logging-view-after-change-function t)
  (force-mode-line-update))

(add-hook 'kill-buffer-hook #'logging-view-exit-mode nil t)

;; Provide the feature
(provide 'logging-view-mode)

;;; logging-view-mode.el ends here
