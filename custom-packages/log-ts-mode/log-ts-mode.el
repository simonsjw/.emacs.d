;;; log-ts-mode.el --- Major mode for viewing log files -*- lexical-binding: t; -*-

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

(require 'treesit)

(declare-function hash-table-keys "subr-x")
(declare-function hash-table-empty-p "subr-x")

(defvar logging-ts-mode-syntax-table
  (let ((st (make-syntax-table)))
    (modify-syntax-entry ?\; "." st)                                              ; Treat semicolons as punctuation
    (modify-syntax-entry ?\[ "." st)
    (modify-syntax-entry ?\] "." st)
    (modify-syntax-entry ?\( "." st)
    (modify-syntax-entry ?\) "." st)
    (modify-syntax-entry ?\{ "." st)
    (modify-syntax-entry ?\} "." st)
    (modify-syntax-entry ?\< "." st)
    (modify-syntax-entry ?\> "." st)
    st)
  "Syntax table for `logging-ts-mode'.")

;; Define custom faces
(defface logging-ts-timestamp-face
  '((t (:foreground "cyan")))
  "Face for log timestamps."
  :group 'logging-view)

(defface logging-ts-loglevel-info-face
  '((t (:foreground "green" :weight bold)))
  "Face for INFO log type."
  :group 'logging-view)

(defface logging-ts-loglevel-warning-face
  '((t (:foreground "yellow" :weight bold)))
  "Face for WARNING log type."
  :group 'logging-view)

(defface logging-ts-loglevel-error-face
  '((t (:foreground "red" :weight bold)))
  "Face for ERROR log type."
  :group 'logging-view)

(defface logging-ts-loglevel-debug-face
  '((t (:foreground "blue" :weight bold)))
  "Face for DEBUG log type."
  :group 'logging-view)

(defface logging-ts-location-face
  '((t (:foreground "magenta")))
  "Face for log location."
  :group 'logging-view)

(defface logging-ts-message-face
  '((t (:foreground "white")))
  "Face for log messages."
  :group 'logging-view)

(defface logging-ts-object-face
  '((t (:foreground "orange")))
  "Face for log objects."
  :group 'logging-view)


;; Define buffer-local variables for filters and overlays
(defvar-local logging-view-active-filters (make-hash-table :test 'equal)
  "Hash table storing active log type filters.")

(defvar-local logging-view-overlays nil
  "List of overlays used to hide filtered log entries.")

(defvar-local logging-ts-font-lock-settings nil
  "Font lock object defined using tree-sit grammar.")

;; Define font-lock settings using the built-in Emacs 29+ treesit API
(setq logging-ts-font-lock-settings
      (treesit-font-lock-rules
       :language 'log
       :feature 'timestamps
       '((timestamp) @logging-ts-timestamp-face)

       :feature 'loglevel
       '((loglevel) @logging-ts-loglevel-info-face
         (:match "INFO" @logging-ts-loglevel-info-face)
         (:match "WARNING" @logging-ts-loglevel-warning-face)
         (:match "ERROR" @logging-ts-loglevel-error-face)
         (:match "DEBUG" @logging-ts-loglevel-debug-face))

       :feature 'location
       '((location) @logging-ts-location-face)

       :feature 'message
       '((message) @logging-ts-message-face)

       :feature 'object
       '((object) @logging-ts-object-face)))


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
  "Apply log type filters using Tree-sitter."
  (when (treesit-ready-p 'log)
    (save-excursion
      (remove-overlays (point-min) (point-max) 'logging-view t)
      (setq logging-view-overlays nil)
      (goto-char (point-min))
      (let ((entries (treesit-query-capture 'log '((log_entry) @entry))))
        (dolist (entry entries)
          (let* ((node (cdr entry))
                 (entry-start (treesit-node-start node))
                 (entry-end (treesit-node-end node))
                 (logtype-node (car (treesit-query-capture 'log '((loglevel) @logtype) node)))
                 (logtype (treesit-node-text logtype-node)))
            (unless (or (hash-table-empty-p logging-view-active-filters)
                        (gethash logtype logging-view-active-filters))
              (let ((ov (make-overlay entry-start entry-end)))
                (overlay-put ov 'invisible t)
                (overlay-put ov 'logging-view t)
                (push ov logging-view-overlays)))))))))

;; (defun logging-view-apply-filters ()
;;   "Apply log type filters to the buffer using overlays."
;;   (save-excursion
;;     (remove-overlays (point-min) (point-max) 'logging-view t) ; Remove existing log entry overlays
;;     (setq logging-view-overlays nil) ; Reset the overlay list
;;     (goto-char (point-min))
;;     (let (
;;           (start-regex
;;            (concat "^\\["
;;                    "[0-9]\\{4\\}-[0-9]\\{2\\}-[0-9]\\{2\\}"
;;                    " "
;;                    "[0-9]\\{2\\}"
;;                    ":"
;;                    "[0-9]\\{2\\}"":""[0-9]\\{2\\}\\"
;;                    "."
;;                    "[0-9]\\{6\\}"
;;                    "; "
;;                    "\\(INFO\\|WARNING\\|ERROR\\|DEBUG\\)"
;;                    "; "
;;                    "\\([^]]+\\)"
;;                    "\\]")
;;            ))
;;       (while (re-search-forward start-regex nil t)
;;         (let ((entry-start (match-beginning 0))
;;               (logtype (match-string 1)))
;;           ;; Find the end of the current log entry
;;           (if (re-search-forward start-regex nil t)
;;               (let ((entry-end (match-beginning 0)))
;;                 (goto-char entry-end))
;;             ;; If no next entry, set end to end of buffer
;;             (goto-char (point-max)))
;;           (let ((entry-end (point)))
;;             ;; Adjust entry-end to include the final newline if present
;;             (when (and (> entry-end entry-start)
;;                        (eq (char-before entry-end) ?\n))
;;               (setq entry-end (1+ entry-end)))
;;             ;; Decide whether to hide or show the entry
;;             (unless (or (hash-table-empty-p logging-view-active-filters)
;;                         (gethash logtype logging-view-active-filters))
;;               (let ((ov (make-overlay entry-start entry-end)))
;;                 (overlay-put ov 'invisible t)
;;                 (overlay-put ov 'logging-view t) ; Tag to identify the overlay
;;                 (push ov logging-view-overlays)))))))))

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
               (logging-view-create-button "DEBUG")
               " "
               (logging-view-active-filters-string))))


(defun logging-view-active-filters-string ()
  "Return a string showing active log type filters in the mode line."
  (let ((active-filters (hash-table-keys logging-view-active-filters)))
    (if (null active-filters)
        "[Filters: None]"
      (format "[Filters: %s]" (string-join active-filters ", ")))))



;; Create mode line button using propertize with correct buffer capture
(defun logging-view-create-button (logtype)
  "Create a mode line button for LOGTYPE with active/inactive state indication."
  (let* ((active (gethash logtype logging-view-active-filters))
         (buffer (current-buffer)))
    (concat
     (propertize (concat " " logtype " ")
                 'face (if active
                           '(bold :foreground "white" :background "red")
                         (cond
                          ((string-equal logtype "INFO") 'logging-view-logtype-info-face)
                          ((string-equal logtype "WARNING") 'logging-view-logtype-warning-face)
                          ((string-equal logtype "ERROR") 'logging-view-logtype-error-face)
                          ((string-equal logtype "DEBUG") 'logging-view-logtype-debug-face)))
                 'help-echo (concat "Toggle " logtype " logs")
                 'mouse-face 'mode-line-highlight
                 'local-map (let ((map (make-sparse-keymap)))
                              (define-key map [mode-line mouse-1]
                                          `(lambda ()
                                             (interactive)
                                             (with-current-buffer ,buffer
                                               (logging-view-toggle-filter ,logtype))))
                              map)))))

;; (defun logging-view-create-button (logtype)
;;   "Create a mode line button for LOGTYPE."
;;   (let* ((active (gethash logtype logging-view-active-filters))
;;          (buffer (current-buffer))) ; Capture the current buffer
;;     (concat
;;      (propertize (concat " " logtype " ")
;;                  'face (cond
;;                         ((string-equal logtype "INFO") 'logging-view-logtype-info-face)
;;                         ((string-equal logtype "WARNING") 'logging-view-logtype-warning-face)
;;                         ((string-equal logtype "ERROR") 'logging-view-logtype-error-face)
;;                         ((string-equal logtype "DEBUG") 'logging-view-logtype-debug-face))
;;                  'help-echo (concat "Toggle " logtype " logs")
;;                  'mouse-face 'mode-line-highlight
;;                  'local-map (let ((map (make-sparse-keymap)))
;;                               (define-key map [mode-line mouse-1]
;;                                           `(lambda ()
;;                                              (interactive)
;;                                              (with-current-buffer ,buffer
;;                                                (logging-view-toggle-filter ,logtype))))
;;                               map)
;;                  'cursor 'pointer)
;;      ;; Visual indicator for active filters
;;      (when active (propertize "*" 'face '(:foreground "white" :background "red"))))))

;; Initialize modeline
(defun logging-view-initialize-modeline ()
  "Initialise the mode line with filter buttons."
  (logging-view-update-modeline))

;; ;; Handle buffer changes to update overlays dynamically
(defun logging-view-after-change-function (beg end len)
  "Function to handle buffer change and update overlays.
BEG, END, and LEN are the standard parameters for `after-change-functions`."
  ;; Re-apply filters to ensure new entries are handled
  (logging-view-apply-filters))


(define-derived-mode logging-ts-mode prog-mode "Logging-TS"
  "Major mode for viewing log files using Tree-sitter (Emacs built-in)."
  :syntax-table logging-ts-mode-syntax-table
  (when (treesit-ready-p 'log)
    (setq-local treesit-font-lock-settings logging-ts-font-lock-settings)
    (treesit-major-mode-setup)))


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

(add-to-list 'auto-mode-alist '("\\.log\\'" . logging-ts-mode))

;; Provide the feature
(provide 'log-ts-mode)
;;; log-ts-mode.el ends here.

                                                                                  ; LocalWords:  puthash
                                                                                  ; LocalWords:  logtype
                                                                                  ; LocalWords:  remhash
                                                                                  ; LocalWords:  gethash
                                                                                  ; LocalWords:  subr
