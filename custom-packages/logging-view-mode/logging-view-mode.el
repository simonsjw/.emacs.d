;;; logging-view-mode.el --- Major mode for viewing log files -*- lexical-binding: t; -*-

;; Author: Simon Watson
;; Version: 1.8  ; Updated for seconds-only timestamps
;; Keywords: logs, tools

;;; Commentary:

;; A major mode for viewing and interacting with log files.
;; Features:
;; - Syntax highlighting for log components (timestamp-based with multi-line support).
;; - Interactive mode line buttons to filter log types.
;; - Now supports *Warnings* and *Messages* buffers with adjusted font-locking and filters.

;;; Code:

;; Define custom faces (unchanged, assuming your theme vars are defined)
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

(defface logging-view-logtype-fatal-face
  `((t (:foreground ,info-theme-flat-red :weight bold :underline t)))  ; New for FATAL/EMERGENCY
  "Face for FATAL/EMERGENCY log type."
  :group 'logging-view)

(defface logging-view-location-face
  `((t (:foreground ,info-theme-magenta)))
  "Face for log location/origin."
  :group 'logging-view)

(defface logging-view-message-face
  `((t (:foreground ,info-theme-light-blue)))
  "Face for log messages."
  :group 'logging-view)

(defface logging-view-obj-face
  `((t (:foreground ,info-theme-light-orange)))
  "Face for log objects."
  :group 'logging-view)

;; Font-lock keywords with adjusted regex for seconds-only format
;; Format: [YYYY-MM-DD HH:MM:SS; LEVEL; origin] message[; Obj: obj]
;; - Optional ; Obj: obj (multi-line until next entry)
;; - LEVEL: INFO/WARN/ERR/DEBUG/FATAL (FATAL for :emergency)
(defvar logging-view-font-lock-keywords
  (let* ((entry-regex
          (concat
           "^\\(\\[\\)"
           "\\([0-9]\\{4\\}-[0-9]\\{2\\}-[0-9]\\{2\\} [0-9]\\{2\\}:[0-9]\\{2\\}:[0-9]\\{2\\}\\)"
           "\\(; \\)"
           "\\(INFO\\|emergency\\|error\\|warning\\|debug\\)"
           "\\(; \\)"
           "\\([^\]]+\\)"
           "\\(]\\) "
           "\\(\\([^;]*\\)\\|\\(;[^ ]*\\)|\\(; [^O]*\\)\\|\\(; O[^b]*\\)\\|\\(; Ob[^j]*\\)\\)"
           "\\(.*\\)")))
    `((,entry-regex
       (1 nil)                                                                    ; Opening bracket
       (2 'logging-view-timestamp-face)                                           ; timestamp
       (3 nil)                                                                    ; semi-colon
       (4 (cond                                                                   ; log level
           ((string-equal (match-string 3) "INFO")
            'logging-view-logtype-info-face)
           ((string-equal (match-string 3) "warning")
            'logging-view-logtype-warning-face)
           ((string-equal (match-string 3) "error")
            'logging-view-logtype-error-face)
           ((string-equal (match-string 3) "emergency")
            'logging-view-logtype-error-face)
           ((string-equal (match-string 3) "debug")
            'logging-view-logtype-debug-face)))
       (5 nil)                                                                    ; semi-colon
       (6 'logging-view-location-face)                                            ; Origin
       (7 nil)                                                                    ; Close brackets
       (8 'logging-view-message-face prepend)                                     ; log message
       (9 'logging-view-obj-face prepend)))))                                    ; Any payload.

;; Buffer-local variables for filters and overlays (unchanged)
(defvar-local logging-view-active-filters (make-hash-table :test 'equal)
  "Hash table storing active log type filters.")

(defvar-local logging-view-overlays nil
  "List of overlays used to hide filtered log entries.")

;; Toggle filter (unchanged)
(defun logging-view-toggle-filter (logtype)
  "Toggle the filter for LOGTYPE."
  (interactive)
  (if (gethash logtype logging-view-active-filters)
      (remhash logtype logging-view-active-filters)
    (puthash logtype t logging-view-active-filters))
  (logging-view-apply-filters)
  (logging-view-update-modeline))

;; Apply filters using overlays with adjusted start-regex (seconds only)
(defun logging-view-apply-filters ()
  "Apply log type filters to the buffer using overlays."
  (save-excursion
    (remove-overlays (point-min) (point-max) 'logging-view t)
    (setq logging-view-overlays nil)
    (goto-char (point-min))
    (let
        ((start-regex
          "^\\[[0-9]\\{4\\}-[0-9]\\{2\\}-[0-9]\\{2\\} [0-9]\\{2\\}:[0-9]\\{2\\}:[0-9]\\{2\\}; \\(INFO\\|emergency\\|error\\|warning\\|debug\\);"))
      (while (re-search-forward start-regex nil t)
        (let ((entry-start (match-beginning 0))
              (logtype (match-string 1)))
          ;; Find end: next timestamp or EOF
          (if (re-search-forward start-regex nil t)
              (progn
                (goto-char (match-beginning 0))
                (beginning-of-line))
            (goto-char (point-max)))
          (let ((entry-end (point)))
            ;; Apply overlay if filtered out (active-filters means "show only these")
            (unless (or (hash-table-empty-p logging-view-active-filters)
                        (gethash logtype logging-view-active-filters))
              (let ((ov (make-overlay entry-start entry-end)))
                (overlay-put ov 'invisible t)
                (overlay-put ov 'logging-view t)
                (push ov logging-view-overlays)))))))))

;; Update mode line with conditional buttons (hide irrelevant based on buffer)
(defun logging-view-update-modeline ()
  "Update the mode line buttons based on active filters."
  (setq-local mode-line-format
              (list
               " LogView: "
               (logging-view-create-button "emergency")
               " "
               (logging-view-create-button "error")
               " "
               (logging-view-create-button "warning")
               " "
               (logging-view-create-button "debug")
               " "
               (logging-view-create-button "INFO"))))

;; Create mode line button (adjusted for FATAL face)
(defun logging-view-create-button (logtype)
  "Create a mode line button for LOGTYPE."
  (let* ((active (gethash logtype logging-view-active-filters))
         (buffer (current-buffer)))
    (concat
     (propertize (concat " " logtype " ")
                 'face (cond
                        ((string-equal logtype "INFO")
                         'logging-view-logtype-info-face)
                        ((string-equal logtype "warning")
                         'logging-view-logtype-warning-face)
                        ((string-equal logtype "error")
                         'logging-view-logtype-error-face)
                        ((string-equal logtype "emergency")
                         'logging-view-logtype-error-face)  ; Reuse error face
                        ((string-equal logtype "debug")
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

;; Define the major mode
(define-derived-mode logging-view-mode special-mode "LogView"
  "Major mode for viewing logs in *Warnings* and *Messages*."
  ;; Inherit from special-mode for read-only behavior
  (setq buffer-read-only t)
  ;; Initialize buffer-local variables
  (setq logging-view-active-filters (make-hash-table :test 'equal))
  (setq logging-view-overlays nil)
  ;; Set font-lock
  (setq font-lock-defaults '(logging-view-font-lock-keywords))
  ;; Default face for unmatched text (e.g., non-log lines in *Messages*)
  (set (make-local-variable 'face-remapping-alist)
       '((font-lock-string-face logging-view-obj-face)))
  ;; Setup
  (logging-view-initialize-modeline)
  (logging-view-apply-filters)
  (add-hook 'after-change-functions #'logging-view-after-change-function nil t))

;; Clean up (unchanged)
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
