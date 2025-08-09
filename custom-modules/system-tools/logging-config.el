;;; logging-config.el --- Emacs logging using built-in warnings/messages -*- lexical-binding: t; -*-

;; Copyright (C) 2023-2025
;; SPDX-License-Identifier: MIT

;; Author: Simon Watson (refactored with Grok's advice)

;;; Commentary:

;; Logging system using Emacs's native `warnings.el' and `message'.
;; - Uses built-in levels:
;;    :emergency (fatal),
;;    :error,
;;    :warning,
;;    :debug (via `display-warning'),
;;    :info (via `message').
;; - Provides separate logging functions (`log/fatal', `log/error', etc.)
;;    for clarity and consistency.
;; - Enriches logs with timestamp (seconds), origin (function name),
;;    and optional objects.
;; - Saves `*Warnings*' buffer to `init.log' on Emacs exit for persistence.
;; - Displays `load-history' in `*Load-History*' buffer with `logging-view-mode'.
;; - Integrates with `logging-view-mode.el' for viewing `*Warnings*',
;;   `*Messages*', and `*Load-History*'.

;;;; Key Changes and Rationale

;; Simplified Logger: Routes logs to `display-warning'
;;    (for :emergency, :error, :warning, :debug) or `message' (for :info),
;;    leveraging Emacs's built-in systems instead of custom logging tables.
;; Timestamps: Uses `format-time-string' for seconds-resolution timestamps
;;    (e.g., "2025-07-30 12:34:56").  Added via `warning-prefix-function' for
;;    warnings and manually prepended for `message'.
;; Object Handling: Uses `prin1-to-string' for objects, appended to messages,
;;    with truncation controlled by `print-length`.
;; File Persistence: Saves `*Warnings*' to `init.log' on exit via
;;    `kill-emacs-hook'.  Optionally, `*Messages*' could be saved similarly.
;; Viewing: Applies `logging-view-mode' to `*Warnings*' via `special-mode-hook'
;;    for font-locking (timestamp, level, origin, message, object) and
;;    mode-line filter buttons.
;; Removed: Custom timestamp function (replaced with `format-time-string'),
;;    direct file writes (replaced with buffer-based saving), and custom log
;;    table (replaced with native warning levels).

;;;; How to Use Warnings/Messages in Elisp Code

;;;;;; INFO-LEVEL LOGGING
;; Use `log/info' or `message' for non-critical information.  Logs to
;; `*Messages*' and echo area.
;; Example 1: Simple Info Logging
;; (defun my-custom-function (arg)
;;   "Log info messages."
;;   (log/info :fn 'my-custom-function :msg (format "Processing arg: %s" arg)))
;;   ;; Or directly:
;;   (message "Processing arg: %s" arg)
;; Output:
;; "[2025-07-30 12:34:56; INFO; my-custom-function] Processing arg: foo"
;; With objects:
;; (log/info :fn 'my-custom-function :msg "Details" :obj (list :key "value"))
;; Output:
;; "[2025-07-30 12:34:56; INFO; my-custom-function] Details; Obj: (:key \"value\")"

;; Example 2: Enriched Info Logging
;; For custom formatting, wrap `message':
;; (defun my-log-info (msg &rest args)
;;   "Log with timestamp and origin."
;;   (message "[%s; INFO; %s] %s"
;;            (Format-time-string "%Y-%m-%d %H:%M:%S")
;;            (cadr (backtrace-frame 2))
;;            (apply #'format msg args)))
;; Usage: (my-log-info "Details: %s" obj)

;;;;;; WARNING/DEBUG LOGGING
;; Use `log/warn', `log/debug', or `warn'/`display-warning' for suspicious or
;; debugging info. Logs to `*Warnings*'.
;; Example 3:
;; (log/warn :fn 'my-function :msg (format "Suspicious input: %s" input))
;; Or:
;; (warn "Suspicious input: %s" input)
;; Output: "[2025-07-30 12:34:56; WARNING; my-function] Suspicious input: foo"

;;;;;; ERROR/EMERGENCY LOGGING
;; Use `log/error` or `log/fatal` for errors or critical issues. Logs to
;;    `*Warnings*', with `:emergency' triggering a ding.
;; Example 4:
;; (log/error :fn 'my-function :msg (format "Invalid input: %s" input))
;; Or:
;; (display-warning 'emacs "Invalid input: %s" input :error)
;; Example 5:
;; (log/fatal :fn 'my-function :msg "Critical failure" :obj err)
;; Output:
;;    "[2025-07-30 12:34:56; EMERGENCY; my-function] Critical failure; Obj: error"

;;;;;; INTEGRATED LOGGING
;; Use `display-warning' for leveled logs in custom code. Supports categories
;;    for suppression.
;; Example 6:
;; (defun my-error-prone-function (input)
;;   "Log errors/warnings using warnings."
;;   (condition-case err
;;       (progn
;;         (if (not (stringp input))
;;             (log/error :fn 'my-error-prone-function
;;                        :msg (format "Invalid input: %s" input))
;;           (log/warn :fn 'my-error-prone-function
;;                     :msg (format "Suspicious input: %s" input)))
;;         (log/debug :fn 'my-error-prone-function
;;                    :msg "Debug info"
;;                    :obj (list :input input)))
;;     (error
;;      (log/fatal :fn 'my-error-prone-function
;;                 :msg (format "Fatal error: %s" (error-message-string err))))))
;; Output in `*Warnings*':
;; "[2025-07-30 12:34:56; ERR; my-error-prone-function] Invalid input: foo"
;; Suppression: (add-to-list 'warning-suppress-types '(my-category)) to hide
;; display but log.

;;;; Best Practices
;; - Call logging functions directly:
;;      e.g., `(log/debug :fn 'my-fn :msg "Debug" :obj var).
;; - Suppress logs: Use `warning-suppress-types' for display,
;;      `warning-suppress-log-types' for complete suppression.
;; - Control visibility: Set `warning-minimum-level' (display) and
;;      `warning-minimum-log-level' (logging).
;; - Objects: Convert to strings with `prin1-to-string' to avoid errors.
;; - Init-Time: Logs work during initialisation;
;;    `*Messages*' captures most info logs.
;; - Testing: Set `warning-minimum-log-level' to `:debug' for verbose output.
;; - Performance: Avoid excessive logging in performance-critical paths.

;;;; Advanced Usage
;; - Categories: Use symbols/lists (e.g., `(emacs init)`) for suppression via
;;      `warning-suppress-log-types'.
;; - Viewing: `*Warnings*` auto-pops for high levels; `logging-view-mode'
;;      adds highlighting and filters.
;; - Persistence: `*Warnings*' saved to `init.log` on exit; extend to
;;      `*Messages*' if needed.
;; - Customisation: Adjust `logging-view-mode' font-locking or filters for
;;      specific needs.

;;; Code:

(require 'warnings)  ; For display-warning and customizations.

;; Define log path for optional file save.
(defconst log/init-log
  (expand-file-name "init.log" user-emacs-directory)
  "Path to save warnings log (appended on exit).")

(defvar log/inhibit-message-format nil
  "Non-nil to skip custom message formatting.")

;; Custom prefix for warnings: Add timestamp (seconds) and origin.
(defun log/warning-prefix (level level-info)
  "Enrich warnings with timestamp and origin."
  (let* ((ts (format-time-string "%Y-%m-%d %H:%M:%S"))  ; Seconds resolution.
         (origin-frame (backtrace-frame 5))  ; Skip internal warn frames.
         (origin (or (cadr origin-frame) "unknown")))
    (insert (format "[%s; %s; %s] " ts (symbol-name level) origin)))
  level-info)

(setq warning-prefix-function #'log/warning-prefix)

;; Optional: Add :info to warning-levels if you prefer warnings over message for info.
;; Uncomment to enable:
;; (add-to-list 'warning-levels '(:info "Info%s: " nil))

;; Logging functions: Direct calls to display-warning or message.
(defun log/fatal (&rest args)
  "Log at :emergency (fatal) using display-warning."
  (let* ((fn (or (plist-get args :fn) "unknown"))
         (msg (plist-get args :msg))
         (obj (plist-get args :obj))
         (full-msg
          (format
           "%s%s" msg (if obj (format "; Obj: %s" (prin1-to-string obj)) ""))))
    (display-warning 'emacs full-msg :emergency)))

(defun log/error (&rest args)
  "Log at :error using display-warning."
  (let* ((fn (or (plist-get args :fn) "unknown"))
         (msg (plist-get args :msg))
         (obj (plist-get args :obj))
         (full-msg
          (format
           "%s%s" msg (if obj (format "; Obj: %s" (prin1-to-string obj)) ""))))
    (display-warning 'emacs full-msg :error)))

(defun log/warn (&rest args)
  "Log at :warning using display-warning."
  (let* ((fn (or (plist-get args :fn) "unknown"))
         (msg (plist-get args :msg))
         (obj (plist-get args :obj))
         (full-msg
          (format
           "%s%s" msg (if obj (format "; Obj: %s" (prin1-to-string obj)) ""))))
    (display-warning 'emacs full-msg :warning)))

(defun log/debug (&rest args)
  "Log at :debug using display-warning."
  (let* ((fn (or (plist-get args :fn) "unknown"))
         (msg (plist-get args :msg))
         (obj (plist-get args :obj))
         (full-msg
          (format
           "%s%s" msg (if obj (format "; Obj: %s" (prin1-to-string obj)) ""))))
    (display-warning 'emacs full-msg :debug)))

(defun log/info (&rest args)
  "Log at :info using message."
  (let* ((fn (or (plist-get args :fn) "unknown"))
         (msg (plist-get args :msg))
         (obj (plist-get args :obj))
         (full-msg
          (format
           "%s%s" msg (if obj (format "; Obj: %s" (prin1-to-string obj))
                        "; Obj: t"))))
    (let ((log/inhibit-message-format t))  ; Bind to t.
      (message "[%s; INFO; %s] %s"
               (format-time-string "%Y-%m-%d %H:%M:%S")
               fn full-msg))))

;; Advise events to log automatically.
(defvar log/targets '(message provide use-package defconst defvar)
  "Events to log; customize to enable/disable.")


(advice-add 'message :around
            (lambda (orig-fun format-string &rest args)
              "Format system messages like [timestamp; INFO; (emacs)] msg; Obj: t."
              (if (or log/inhibit-message-format (not format-string))  ; Handle nil format-string.
                  (apply orig-fun format-string args)
                (let ((msg (apply #'format format-string args)))
                  (apply orig-fun "[%s; INFO; (emacs)] %s; Obj: t"
                         (format-time-string "%Y-%m-%d %H:%M:%S")
                         msg
                         nil)))))

(advice-add 'provide :after
            (lambda (feature &rest _)
              "Log provide calls at :info."
              (when (member 'provide log/targets)
                (log/info :fn 'provide :msg (format "Provided %s" feature)))))

(advice-add 'use-package-handler/:ensure :after
            (lambda (&rest args)
              "Log use-package at :info."
              (when (member 'use-package log/targets)
                (log/info :fn 'use-package :msg (format "Using package %s" (car args))))))

;; Log defconst/defvar from load-history.
(defun log/load-history-hook (file)
  "Log defconst and defvar entries from load-history for FILE."
  (when (member 'load-history log/targets)
    (dolist (entry (assoc file load-history))
      (when (consp entry)
        (pcase entry
          (`(defconst . ,symbol)
           (log/debug :fn 'defconst :msg (format "Defined const %s in %s" symbol file)))
          (`(defvar . ,symbol)
           (log/debug :fn 'defvar :msg (format "Defined var %s in %s" symbol file))))))))

(add-hook 'after-load-functions #'log/load-history-hook)

;; Display load-history in a buffer.
(defun log/display-load-history ()
  "Display 'load-history' in *Load-History* buffer with 'logging-view-mode'."
  (interactive)
  (let ((buffer (get-buffer-create "*Load-History*")))
    (with-current-buffer buffer
      (let ((inhibit-read-only t))
        (erase-buffer)
        (dolist (file-entry load-history)
          (let ((file (car file-entry))
                (entries (cdr file-entry)))
            
            (dolist (entry entries)
              (let ((timestamp (format-time-string "%Y-%m-%d %H:%M:%S")))
                (cond
                 ((consp entry)
                  (let ((key (car entry))
                        (value (cdr entry)))
                    (insert (format "[%s; :debug; load-history] Defined %s %s in %s; Obj: t\n"
                                    timestamp
                                    (if (symbolp key) (symbol-name key) (prin1-to-string key))
                                    (if (symbolp value) (symbol-name value) (prin1-to-string value))
                                    file))))
                 (t
                  (insert (format "[%s; :debug; load-history] Used %s without defining in %s; Obj: t\n"
                                  timestamp
                                  (prin1-to-string entry)
                                  file)))
                 ))))
          )
        )
      (logging-view-mode)
      (goto-char (point-min))
      )
    (pop-to-buffer buffer)))

;; Save all log buffers to file on exit without prompting
(defun log/save-all-to-file ()
  "Save contents of *Warnings*, *Messages*, and *Load-History* to init.log, overwriting without prompt."
  (interactive)
  (let ((log-content ""))
    ;; Collect contents from each buffer if it exists
    (dolist (buf '("*Warnings*" "*Messages*" "*Load-History*"))
      (when (get-buffer buf)
        (with-current-buffer buf
          (setq log-content
                (concat log-content
                        (buffer-string)
                        "\n\n;; ---------- End of " buf " ----------\n\n")))))
    ;; Write all contents to init.log, overwriting without prompt
    (when (not (string-empty-p log-content))
      (let ((coding-system-for-write 'utf-8)) ; Ensure consistent encoding
        (write-region log-content nil log/init-log nil 'silent))))
  ;; Optional: Create a backup of init.log before overwriting
  (when (file-exists-p log/init-log)
    (copy-file log/init-log (concat log/init-log ".bak") t)))

(add-hook 'kill-emacs-hook #'log/save-all-to-file)

;; Customise warnings display/suppression.
(setq warning-minimum-level :warning
      warning-minimum-log-level :debug
      warning-suppress-log-types nil)

;; Delay adding the hook until logging-view-mode is loaded.
(with-eval-after-load 'logging-view-mode
  ;; Helper function to safely apply mode if buffer exists
  (defun log/apply-view-mode-to-buffer (buffer-name)
    "Apply logging-view-mode to BUFFER-NAME if it exists."
    (when (get-buffer buffer-name)
      (with-current-buffer buffer-name
        (unless (eq major-mode 'logging-view-mode)
          (logging-view-mode)))))

  ;; Extend the hook to cover *Messages* and *Warnings* dynamically
  (add-hook 'special-mode-hook
            (lambda ()
              (when (and (not (eq major-mode 'logging-view-mode))  ; Guard against recursion
                         (or (equal (buffer-name) "*Warnings*")
                             (equal (buffer-name) "*Messages*")))
                (logging-view-mode))))

  ;; Apply to existing buffers safely
  (log/apply-view-mode-to-buffer "*Messages*")
  (log/apply-view-mode-to-buffer "*Warnings*")
  (add-to-list 'auto-mode-alist '("\\<init\\.log\\'" . logging-view-mode)))



;;       warning-suppress-types '((emacs))  ; Example: suppress 'emacs category display.

(use-package menu-keys-support
  :ensure nil  ; Local file, not a package
  :load-path "custom-modules/")

(provide 'logging-config)
;;; logging-config.el ends here

; LocalWords:  Uncomment
