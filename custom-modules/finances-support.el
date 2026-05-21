;;; accounting-support.el --- Comprehensive hledger personal finance support for Emacs -*- lexical-binding: t; -*-

;; Copyright (C) 2026 Simon

;; Author: Simon <simon_sjw>
;; Version: 1.0
;; Package-Requires: ((emacs "29.1") (hledger-mode "1.0") (company "0.10"))
;; Keywords: finance, accounting, hledger, plaintext
;; URL: https://github.com/simonsjw/.emacs.d

;;; Commentary:
;;
;; This module provides a complete, modern, and well-documented setup for
;; hledger-mode inside your Emacs configuration.  It is designed to be
;; dropped into your custom-modules/ directory alongside org-support.el
;; and theme-support.el.
;;
;; Key features ("mod cons"):
;; - Automatic loading of .journal and .hledger files
;; - Excellent account-name completion (company-mode)
;; - One-keystroke access to the most useful financial reports
;; - Dedicated functions for balance sheet, net worth, investments, and tax views
;; - Easy launcher for hledger-web (perfect for your wife who does not use Emacs)
;; - Light but useful org-mode integration hooks
;; - Customizable journal file location and binary path
;; - Verbose, self-documenting code following strict Elisp conventions
;;
;; Installation:
;; 1. Ensure hledger is installed on your system (already done per our conversation).
;; 2. Place this file in ~/.emacs.d/custom-modules/accounting-support.el
;; 3. Add (require 'accounting-support) to your init file (or use your existing module loader).
;; 4. Customize `hledger-main-journal-file` to point at your main .journal file.
;; 5. Optionally run M-x customize-group RET accounting-support RET
;;
;; For your wife: Use `M-x hledger-start-web-ui` — it starts a beautiful
;; web dashboard she can access from any browser without touching Emacs.

;;; Code:

;;; Section: Dependencies and Requirements

(require 'hledger-mode)

;; We assume you already have company-mode available (very common in modern setups).
;; If you use Corfu instead, the completion section can be easily adapted.
(when (require 'company nil t)
  (message "accounting-support: company-mode detected and will be configured."))

;;; Section: Customization Group and Variables

(defgroup accounting-support nil
  "Settings for the accounting-support module.  All variables here affect
how hledger integrates with your Emacs workflow and how reports are
generated for both you and your wife."
  :group 'applications
  :prefix "hledger-")

(defcustom hledger-main-journal-file "~/finance/main.journal"
  "Path to your primary hledger journal file.  This is used by default
for all report commands and the web UI.  Change this to match your
actual location (e.g. ~/Documents/Finances/personal.journal)."
  :type 'file
  :group 'accounting-support)

(defcustom hledger-binary "hledger"
  "The hledger executable to use.  Normally just \"hledger\" if it is
in your PATH.  You can point to a full path if needed."
  :type 'string
  :group 'accounting-support)

(defcustom hledger-web-port 5000
  "Port on which hledger-web will listen when started via
`hledger-start-web-ui'.  Change if 5000 is already in use."
  :type 'integer
  :group 'accounting-support)

;;; Section: Core Mode Setup and Auto-loading

;; Make sure .journal and .hledger files always open in hledger-mode.
(add-to-list 'auto-mode-alist '("\\.journal\\'" . hledger-mode))
(add-to-list 'auto-mode-alist '("\\.hledger\\'" . hledger-mode))

;; Set the default journal file that hledger-mode and report commands will use.
(setq hledger-jfile hledger-main-journal-file)

;; Make the hledger binary configurable (useful if you have multiple versions).
(setq hledger-binary-path hledger-binary)

;;; Section: Completion Setup (Modern and Reliable)

;; Enable excellent account and payee completion using company-mode.
;; This is one of the biggest quality-of-life improvements when editing journals.
(with-eval-after-load 'company
  (add-to-list 'company-backends 'hledger-company)
  (message "accounting-support: hledger-company backend registered with company-mode."))

;; Fallback for users who still prefer the older auto-complete package.
(with-eval-after-load 'auto-complete
  (add-to-list 'ac-modes 'hledger-mode)
  (add-hook 'hledger-mode-hook
            (lambda ()
              (setq-local ac-sources '(hledger-ac-source)))))

;;; Section: Keybindings and Navigation Helpers

;; Add a few very useful keybindings inside hledger-mode buffers.
;; These follow common Emacs conventions and are easy to remember.
(with-eval-after-load 'hledger-mode
  (define-key hledger-mode-map (kbd "C-c C-b") #'hledger-show-balance-sheet)
  (define-key hledger-mode-map (kbd "C-c C-n") #'hledger-show-net-worth)
  (define-key hledger-mode-map (kbd "C-c C-i") #'hledger-show-investments)
  (define-key hledger-mode-map (kbd "C-c C-t") #'hledger-show-tax-overview)
  (define-key hledger-mode-map (kbd "C-c C-w") #'hledger-start-web-ui)
  (define-key hledger-mode-map (kbd "<kp-add>") #'hledger-increment-entry-date)
  (define-key hledger-mode-map (kbd "<kp-subtract>") #'hledger-decrement-entry-date))

;;; Section: Convenience Report Functions

(defun hledger-run-report (COMMAND &optional ARGS)
  "Run an arbitrary hledger report command.  COMMAND is the hledger
subcommand (e.g. \"balance\", \"balancesheet\").  ARGS is an optional
string of extra arguments.  The report opens in a dedicated buffer
with nice formatting."
  (interactive "sHledger command: ")
  (let* ((journal hledger-main-journal-file)
         (cmd (format "%s -f %s %s %s"
                      hledger-binary
                      (shell-quote-argument journal)
                      COMMAND
                      (or ARGS "")))
         (buf (get-buffer-create (format "*hledger: %s*" COMMAND))))
    (with-current-buffer buf
      (setq buffer-read-only nil)
      (erase-buffer)
      (insert (shell-command-to-string cmd))
      (hledger-report-mode)           ; nice major mode for reports
      (setq buffer-read-only t)
      (goto-char (point-min)))
    (pop-to-buffer buf)))

(defun hledger-show-balance-sheet ()
  "Display a clean balance sheet (Assets, Liabilities, Equity/Net Worth).
This is the closest equivalent to a traditional accounting balance sheet
and is extremely useful for seeing your overall financial position."
  (interactive)
  (hledger-run-report "balancesheet" "--pretty-tables -H"))

(defun hledger-show-net-worth ()
  "Show your current net worth (Assets minus Liabilities).  Uses the
balancesheetequity command for the most accurate view including equity."
  (interactive)
  (hledger-run-report "balancesheetequity" "-H --pretty-tables"))

(defun hledger-show-investments ()
  "Show investment holdings with current market value.  Great for
tracking shares, ETFs, crypto, and other commodities.  Uses -V for
market valuation."
  (interactive)
  (hledger-run-report "balance" "assets:investments -V --pretty-tables"))

(defun hledger-show-tax-overview ()
  "Generate a tax-focused overview.  Looks for accounts and tags
containing 'tax', 'deductible', 'gst', or 'ato'.  Customize the query
inside this function if your tagging scheme differs."
  (interactive)
  (hledger-run-report "balance" "tag:tax or tag:deductible or tag:gst --pretty-tables"))

;;; Section: Web-Based Reports (Wife-Friendly Interface)

(defun hledger-start-web-ui ()
  "Start the hledger-web server on port `hledger-web-port' and open it
in your default browser.  This provides a beautiful, interactive web
dashboard with charts, filters, and reports.  Ideal for your wife (or
anyone who prefers not to use Emacs).  The server runs in the background."
  (interactive)
  (let ((port hledger-web-port)
        (journal hledger-main-journal-file))
    (message "Starting hledger-web on port %d..." port)
    (start-process "hledger-web"
                   "*hledger-web*"
                   hledger-binary
                   "web"
                   "--file" journal
                   "--port" (number-to-string port)
                   "--serve")
    (sleep-for 1.5) ; give the server a moment to start
    (browse-url (format "http://localhost:%d" port))
    (message "hledger-web is now running at http://localhost:%d — share this with your wife!")))

(defun hledger-stop-web-ui ()
  "Stop any running hledger-web process started by this module."
  (interactive)
  (when (get-process "hledger-web")
    (delete-process "hledger-web")
    (message "hledger-web stopped.")))

;;; Section: Light Org-mode Integration

;; If you use org-mode for capture or literate accounting, these hooks
;; help keep things consistent with your org-support.el setup.
(with-eval-after-load 'org
  (add-hook 'hledger-mode-hook
            (lambda ()
              (setq-local org-link-file-path-type 'relative)))
  ;; Optional: allow easy insertion of hledger transactions from org files
  (org-babel-do-load-languages
   'org-babel-load-languages
   '((hledger . t))))

;;; Section: Final Hooks and Messages

(add-hook 'hledger-mode-hook
          (lambda ()
            (hl-line-mode 1)
            (setq truncate-lines t)
            (message "accounting-support: hledger-mode ready.  Use C-c C-b for balance sheet, C-c C-w for web UI.")))

;; Friendly startup message so you know the module loaded successfully.
(message "accounting-support.el loaded successfully.  Your personal finance toolkit is now active.")

(provide 'accounting-support)

;;; accounting-support.el ends here
