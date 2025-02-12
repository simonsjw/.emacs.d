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

(defvar log-ts-mode-syntax-table
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
  "Syntax table for `log-ts-mode'.")

;; Define custom faces
(defface log-ts-timestamp-face
  '((t (:foreground "cyan")))
  "Face for log timestamps."
  :group 'log-view)

(defface log-ts-loglevel-info-face
  '((t (:foreground "green" :weight bold)))
  "Face for INFO log type."
  :group 'log-view)

(defface log-ts-loglevel-warning-face
  '((t (:foreground "yellow" :weight bold)))
  "Face for WARNING log type."
  :group 'log-view)

(defface log-ts-loglevel-error-face
  '((t (:foreground "red" :weight bold)))
  "Face for ERROR log type."
  :group 'log-view)

(defface log-ts-loglevel-debug-face
  '((t (:foreground "blue" :weight bold)))
  "Face for DEBUG log type."
  :group 'log-view)

(defface log-ts-location-face
  '((t (:foreground "magenta")))
  "Face for log location."
  :group 'log-view)

(defface log-ts-message-face
  '((t (:foreground "white")))
  "Face for log messages."
  :group 'log-view)

(defface log-ts-object-face
  '((t (:foreground "orange")))
  "Face for log objects."
  :group 'log-view)


;; Define buffer-local variables for filters and overlays
(defvar-local log-view-active-filters (make-hash-table :test 'equal)
  "Hash table storing active log type filters.")

(defvar-local log-view-overlays nil
  "List of overlays used to hide filtered log entries.")

(defvar-local log-ts-font-lock-settings nil
  "Font lock object defined using tree-sit grammar.")

;; Define font-lock settings using the built-in Emacs 29+ treesit API
(setq log-ts-font-lock-settings
      (treesit-font-lock-rules
       :language 'log
       :feature 'timestamps
       '((timestamp) @log-ts-timestamp-face)

       :feature 'loglevel
       '((loglevel) @log-ts-loglevel-info-face
         (:match "INFO" @log-ts-loglevel-info-face)
         (:match "WARNING" @log-ts-loglevel-warning-face)
         (:match "ERROR" @log-ts-loglevel-error-face)
         (:match "DEBUG" @log-ts-loglevel-debug-face))

       :feature 'location
       '((location) @log-ts-location-face)

       :feature 'message
       '((message) @log-ts-message-face)

       :feature 'object
       '((object) @log-ts-object-face)))


;; Toggle filter function
(defun log-view-toggle-filter (logtype)
  "Toggle the filter for LOGTYPE."
  (interactive)
  (if (gethash logtype log-view-active-filters)
      (remhash logtype log-view-active-filters)
    (puthash logtype t log-view-active-filters))
  (log-view-apply-filters)
  (log-view-update-modeline))

;; Apply filters to buffer using overlays
(defun log-view-apply-filters ()
  "Apply log type filters using Tree-sitter."
  (when (treesit-ready-p 'log)
    (save-excursion
      (remove-overlays (point-min) (point-max) 'log-view t)
      (setq log-view-overlays nil)
      (goto-char (point-min))
      (let ((entries (treesit-query-capture 'log '((log_entry) @entry))))
        (dolist (entry entries)
          (let* ((node (cdr entry))
                 (entry-start (treesit-node-start node))
                 (entry-end (treesit-node-end node))
                 (logtype-node (car (treesit-query-capture 'log '((loglevel) @logtype) node)))
                 (logtype (treesit-node-text logtype-node)))
            (unless (or (hash-table-empty-p log-view-active-filters)
                        (gethash logtype log-view-active-filters))
              (let ((ov (make-overlay entry-start entry-end)))
                (overlay-put ov 'invisible t)
                (overlay-put ov 'log-view t)
                (push ov log-view-overlays)))))))))


;; Update mode line
(defun log-view-update-modeline ()
  "Update the mode line buttons based on active filters."
  (setq-local mode-line-format
              (list
               " LogView: "
               (log-view-create-button "INFO")
               " "
               (log-view-create-button "WARNING")
               " "
               (log-view-create-button "ERROR")
               " "
               (log-view-create-button "DEBUG")
               " "
               (log-view-active-filters-string))))


(defun log-view-active-filters-string ()
  "Return a string showing active log type filters in the mode line."
  (let ((active-filters (hash-table-keys log-view-active-filters)))
    (if (null active-filters)
        "[Filters: None]"
      (format "[Filters: %s]" (string-join active-filters ", ")))))



;; Create mode line button using propertize with correct buffer capture
(defun log-view-create-button (logtype)
  "Create a mode line button for LOGTYPE with active/inactive state indication."
  (let* ((active (gethash logtype log-view-active-filters))
         (buffer (current-buffer)))
    (concat
     (propertize (concat " " logtype " ")
                 'face (if active
                           '(bold :foreground "white" :background "red")
                         (cond
                          ((string-equal logtype "INFO") 'log-view-logtype-info-face)
                          ((string-equal logtype "WARNING") 'log-view-logtype-warning-face)
                          ((string-equal logtype "ERROR") 'log-view-logtype-error-face)
                          ((string-equal logtype "DEBUG") 'log-view-logtype-debug-face)))
                 'help-echo (concat "Toggle " logtype " logs")
                 'mouse-face 'mode-line-highlight
                 'local-map (let ((map (make-sparse-keymap)))
                              (define-key map [mode-line mouse-1]
                                          `(lambda ()
                                             (interactive)
                                             (with-current-buffer ,buffer
                                               (log-view-toggle-filter ,logtype))))
                              map)))))

;; Initialize modeline
(defun log-view-initialize-modeline ()
  "Initialise the mode line with filter buttons."
  (log-view-update-modeline))

;; ;; Handle buffer changes to update overlays dynamically
(defun log-view-after-change-function (beg end len)
  "Function to handle buffer change and update overlays.
BEG, END, and LEN are the standard parameters for `after-change-functions`."
  ;; Re-apply filters to ensure new entries are handled
  (log-view-apply-filters))


(define-derived-mode log-ts-mode prog-mode "Log-ts"
  "Major mode for viewing log files using Tree-sitter (Emacs built-in)."
  :syntax-table log-ts-mode-syntax-table
  (when (treesit-ready-p 'log)
    (setq-local major-mode 'log-ts-mode)     ;; added in debugging
    (setq-local treesit-font-lock-settings log-ts-font-lock-settings)
    (treesit-major-mode-setup))
    )


;; Define the major mode
(define-derived-mode log-view-mode fundamental-mode "LogView"
  "Major mode for viewing log files."
  (setq font-lock-defaults '(log-view-font-lock-keywords))
  (setq buffer-read-only t)
  ;; Initialize buffer-local variables
  (setq log-view-active-filters (make-hash-table :test 'equal))
  (setq log-view-overlays nil)
  ;; Initialize modeline
  (log-view-initialize-modeline)
  ;; Apply initial filters
  (log-view-apply-filters)
  ;; Add hook to handle buffer changes
  (add-hook 'after-change-functions #'log-view-after-change-function nil t))

;; Clean up overlays and hooks when exiting the mode
(defun log-view-exit-mode ()
  "Clean up overlays and hooks when exiting `log-view-mode`."
  (remove-overlays (point-min) (point-max) 'log-view t)
  (setq log-view-overlays nil)
  (remove-hook 'after-change-functions #'log-view-after-change-function t)
  ;; Reset mode line
  (force-mode-line-update))

(add-hook 'kill-buffer-hook #'log-view-exit-mode nil t)

(add-to-list 'auto-mode-alist '("\\.log\\'" . log-ts-mode))

;; Provide the feature
(provide 'log-ts-mode)
;;; log-ts-mode.el ends here.

                                                                                  ; LocalWords:  puthash
                                                                                  ; LocalWords:  logtype
                                                                                  ; LocalWords:  remhash
                                                                                  ; LocalWords:  gethash
                                                                                  ; LocalWords:  subr
