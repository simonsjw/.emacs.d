;;; lang-systemd.el --- systemd service file support for the crafted setup   -*- lexical-binding: t; -*-

;;; Commentary:
;;
;; Major mode for editing systemd units.
;;
;; Similar to `conf-mode' but with enhanced highlighting; e.g. for
;; specifiers and booleans.  Employs strict regex for whitespace.
;; Features a facility for browsing documentation: use C-c C-o to open
;; links to documentation in a unit (cf. systemctl help).
;;
;; Supports completion of directives and sections in either units or
;; network configuration.  Both a completer for
;; `completion-at-point-functions' and a company backend are provided.
;; The latter can be enabled by adding `company-mode' to
;; `systemd-mode-hook' and adding `systemd-company-backend' to
;; `company-backends'.
;;
;; Prerequisites:
;;
;; - Not sure its a Prerequisite but having systemd on your system helps. 
;; Repo home:[[https://github.com/holomorph/systemd-mode][systemd-mode]]

;;; Code:
(defvar my-paths/systemd-mode)                                                    ; path defined in path-support.el
;;; Packages phase
(add-to-list 'load-path my-paths/systemd-mode) ; Add directory to the load path

;;; Configuration phase
;; (non - can add company-mode hooks if you use company though.)

(provide 'lang-systemd)
;;; lang-systemd.el ends here
