;;; lang-systemd.el --- systemd unit editing via systemd-mode. -*- lexical-binding: t; -*-

;; Copyright (C) 2026 Simon Watson
;; SPDX-License-Identifier: MIT

;; Author: Simon Watson

;;; Commentary:

;; Language module for systemd unit files using the local
;; `systemd-mode' submodule.  Completion uses CAPF / Corfu, not
;; company-mode.
;;
;; Map:
;;   Feature:    lang-systemd
;;   Load-after: path-support logging-config
;;   Load-phase: lang
;;   Keymaps:    none
;;   Docs:       docs/lang-systemd.org
;;   OS:         systemd

;;; Code:

(require 'path-support)
(require 'logging-config)
(log/debug :fn 'lang-systemd
           :msg "Starting load of the lang-systemd module."
           :obj t)

(defvar my-paths/systemd-mode)                                                    ; path defined in path-support.el
;;; Packages phase
(add-to-list 'load-path my-paths/systemd-mode) ; Add directory to the load path

;;; Configuration phase

(log/debug :fn 'lang-systemd
           :msg "Ending load of the lang-systemd module."
           :obj t)

(provide 'lang-systemd)
;;; lang-systemd.el ends here
