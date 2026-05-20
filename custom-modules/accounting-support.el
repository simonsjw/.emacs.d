;;; accounting-support.el --- High-level accounting tools and wife-friendly reports -*- lexical-binding: t; -*-

;; Copyright (C) 2026 Simon

;; Author: Simon <simon_sjw>
;; Version: 1.1
;; Package-Requires: ((emacs "29.1") (hledger-mode "1.0"))
;; Keywords: finance, accounting, hledger, plaintext
;; URL: https://github.com/simonsjw/.emacs.d

;;; Commentary:
;;
;; This module provides the "mod cons" for personal finance in Emacs.
;; It is designed to be loaded via the use-package expression shown above.
;;
;; Core features:
;; - Clean wrapper functions for the most useful reports (balance sheet,
;;   net worth, investments, tax overview)
;; - One-command launcher for hledger-web (perfect for your wife)
;; - Light org-mode integration hooks
;; - All functions are fully documented following strict Elisp guidelines
;;
;; The basic hledger-mode setup (auto-mode, completion, keybindings) now
;; lives in the use-package declaration for a cleaner separation of concerns.

;;; Code:

(require 'logging-config)
(log/debug :fn 'accounting-support
           :msg "Starting load of the accounting-support module."
           :obj t)



(use-package hledger-mode
  :ensure t
  :mode ("\\.journal\\'" "\\.hledger\\'" "\\.rules\\'")
  :custom
  (hledger-jfile accounting-main-journal-file)
  (hledger-binary-path "hledger")
  (hledger-show-expanded-report nil "Cleaner reports by default")
  :config
  ;; Load our custom accounting module after hledger-mode is ready
  (require 'accounting-support)

  ;; Modern completion (company-mode)
  (when (bound-and-true-p company-mode)
    (add-to-list 'company-backends 'hledger-company))

  ;; Helpful keybindings that work everywhere (not just in hledger buffers)
  (global-set-key (kbd "C-c a b") #'accounting-show-balance-sheet)
  (global-set-key (kbd "C-c a n") #'accounting-show-net-worth)
  (global-set-key (kbd "C-c a i") #'accounting-show-investments)
  (global-set-key (kbd "C-c a t") #'accounting-show-tax-overview)
  (global-set-key (kbd "C-c a w") #'accounting-start-web-ui)

  (message "accounting-support: hledger-mode fully configured via use-package."))

;;; Section: Customization Variables

(defgroup accounting-support nil
  "High-level personal finance tools built on top of hledger-mode.
These settings control report behaviour and the web dashboard used
by non-Emacs users."
  :group 'applications
  :prefix "accounting-")

(setq accounting-main-journal-file "~/Documents/org/accounting/main.journal")

(defcustom accounting-main-journal-file "~/finance/main.journal"
  "Path to your primary hledger journal file.  Set this once in your
init file or via customize.  All report functions use this by default."
  :type 'file
  :group 'accounting-support)

(defcustom accounting-web-port 5000
  "TCP port used by `accounting-start-web-ui' when launching the
hledger-web dashboard for your wife and other non-Emacs users."
  :type 'integer
  :group 'accounting-support)

;;; Section: Core Report Engine

(defun accounting-run-report (COMMAND &optional ARGS)
  "Run any hledger report command and display the result in a nicely
formatted buffer.  COMMAND is the hledger subcommand (e.g. \"balance\",
\"balancesheet\").  ARGS is an optional string of extra flags."
  (interactive "sHledger command: ")
  (let* ((journal accounting-main-journal-file)
         (cmd (format "hledger -f %s %s %s"
                      (shell-quote-argument journal)
                      COMMAND
                      (or ARGS "")))
         (buf-name (format "*accounting: %s*" COMMAND))
         (buf (get-buffer-create buf-name)))
    (with-current-buffer buf
      (setq buffer-read-only nil)
      (erase-buffer)
      (insert (shell-command-to-string cmd))
      (hledger-report-mode)
      (setq buffer-read-only t)
      (goto-char (point-min)))
    (pop-to-buffer buf)
    (message "Report generated: %s" COMMAND)))


;;; Section: CSV Import Helpers (for cashflows folder)

(defcustom accounting-cashflows-dir "~/Documents/org/accounting/cashflows/"
  "Directory containing your CBA CSV exports."
  :type 'directory
  :group 'accounting-support)

(defun accounting-import-all-csvs ()
  "Import all CSV files in `accounting-cashflows-dir' using import.rules.
Runs with --dry-run first so you can review.  Perfect for monthly updates."
  (interactive)
  (let ((default-directory accounting-cashflows-dir))
    (when (y-or-n-p "Run DRY RUN first? (recommended) ")
      (shell-command "hledger import *.csv --rules-file import.rules --dry-run"))
    (when (y-or-n-p "Proceed with real import? ")
      (shell-command "hledger import *.csv --rules-file import.rules")
      (message "Import complete.  Review with M-x accounting-show-balance-sheet"))))

(defun accounting-import-single-csv (CSV-FILE)
  "Import a single CSV file with review step."
  (interactive "fCSV file to import: ")
  (let ((default-directory accounting-cashflows-dir))
    (shell-command (format "hledger import %s --rules-file import.rules --dry-run"
                           (shell-quote-argument CSV-FILE)))
    (when (y-or-n-p "Looks good? Import for real? ")
      (shell-command (format "hledger import %s --rules-file import.rules"
                             (shell-quote-argument CSV-FILE))))))


;;; Section: High-Level Report Functions

(defun accounting-show-balance-sheet ()
  "Display a professional balance sheet showing Assets, Liabilities,
and Equity/Net Worth.  This is the single most useful view for
understanding your overall financial position."
  (interactive)
  (accounting-run-report "balancesheet" "--pretty-tables -H"))

(defun accounting-show-net-worth ()
  "Show your current net worth using the balancesheetequity command.
Includes equity accounts for the most accurate picture."
  (interactive)
  (accounting-run-report "balancesheetequity" "-H --pretty-tables"))

(defun accounting-show-investments ()
  "Display all investment holdings with current market value (-V flag).
Ideal for tracking shares, ETFs, superannuation, and crypto."
  (interactive)
  (accounting-run-report "balance" "assets:investments -V --pretty-tables"))

(defun accounting-show-tax-overview ()
  "Generate a tax-focused summary.  Looks for accounts or tags
containing 'tax', 'deductible', 'gst', or 'ato'.  Customize the
query inside this function if your tagging differs."
  (interactive)
  (accounting-run-report "balance" "tag:tax or tag:deductible or tag:gst --pretty-tables"))

;;; Section: Wife-Friendly Web Dashboard

(defun accounting-start-web-ui ()
  "Start hledger-web on port `accounting-web-port' and open it in
your default browser.  This gives your wife (and anyone else) a
beautiful interactive dashboard with charts and filters without
needing to use Emacs at all."
  (interactive)
  (let ((port accounting-web-port)
        (journal accounting-main-journal-file))
    (message "Starting hledger-web dashboard on port %d..." port)
    (start-process "accounting-web"
                   "*accounting-web*"
                   "hledger"
                   "web"
                   "--file" journal
                   "--port" (number-to-string port)
                   "--serve")
    (sleep-for 1.5)
    (browse-url (format "http://localhost:%d" port))
    (message "Web dashboard ready at http://localhost:%d — share this link!")))

(defun accounting-stop-web-ui ()
  "Stop the hledger-web process started by `accounting-start-web-ui'."
  (interactive)
  (when (get-process "accounting-web")
    (delete-process "accounting-web")
    (message "Web dashboard stopped.")))

;;; Section: Org-mode Integration Hooks

(with-eval-after-load 'org
  (add-hook 'hledger-mode-hook
            (lambda ()
              (setq-local org-link-file-path-type 'relative)))

  ;; Enable hledger source blocks in org-mode files if desired
  (org-babel-do-load-languages
   'org-babel-load-languages
   '((hledger . t))))

;;; Section: Final Polish

(add-hook 'hledger-mode-hook
          (lambda ()
            (hl-line-mode 1)
            (setq truncate-lines t)))


(log/debug :fn 'markdown-support
           :msg "Finished load of accounting-support.el module."
           :obj t)


(provide 'accounting-support)

;;; accounting-support.el ends here
