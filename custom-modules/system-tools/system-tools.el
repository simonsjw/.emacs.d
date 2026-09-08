;;; system-tools.el --- Loader for env, buffer, disk, frame, and SSH helpers. -*- lexical-binding: t; -*-

;; Copyright (C) 2026 Simon Watson
;; SPDX-License-Identifier: MIT

;; Author: Simon Watson

;;; Commentary:

;; MAP feature and `provide' of shared system helpers.  Load from
;; `init.el' with:
;;
;;   (require 'system-tools)
;;
;; This file keeps dictionary and SSH helpers and pulls in the
;; piece files:
;;
;;   system-env-tools     — env, hash, string
;;   system-disk-tools    — Dired, image, filesystem
;;   system-buffer-tools  — buffer and in-buffer helpers
;;   system-frame-tools   — frame, fringe/margin, `ss' ports
;;
;; Directory creation is `my-on-disk-tools/ensure-directory-exists' in
;; `path-support.el' ("Creating directory: %s").  Do not reintroduce a
;; second copy here.
;;
;; Map:
;;   Feature:    system-tools
;;   Load-after: path-support logging-config
;;   Load-phase: bootstrap
;;   Keymaps:    none
;;   Docs:       docs/system-tools.org
;;   OS:         ss

;;; Code:

(require 'path-support)
(require 'logging-config)
(log/debug :fn 'system-tools
           :msg "Starting load of the system-tools module."
           :obj t)

(require 'system-env-tools)
(require 'system-disk-tools)
(require 'system-buffer-tools)
(require 'system-frame-tools)

;;;; TOOLS FOR LANGUAGE & DICTIONARIES

(defun my-dictionary/use-american ()
  "Switch to American English dictionary."
  (interactive)
  (setq ispell-dictionary "American")
  (ispell-change-dictionary "American")
  (message "Switched to American English dictionary"))

(defun my-dictionary/use-british ()
  "Switch to British English dictionary."
  (interactive)
  (setq ispell-dictionary "British")
  (ispell-change-dictionary "British")
  (message "Switched to British English dictionary"))

(defun my-dictionary/use-australian ()
  "Switch to Australian English dictionary."
  (interactive)
  (setq ispell-dictionary "Australian")
  (ispell-change-dictionary "Australian")
  (message "Switched to Australian English dictionary"))

;; ---end of TOOLS FOR LANGUAGE & DICTIONARIES---


;;;; TOOLS FOR SSH
(defun my-ssh/refresh-ssh-agent ()
  "Reload SSH identities into the agent from Emacs."
  (interactive)
  (shell-command "ssh-add ~/.ssh/id_ed25519")
  (message "SSH key added to agent."))

;; ---end of TOOLS FOR SSH---

(log/debug :fn 'system-tools
           :msg "Finishing load of the system-tools module."
           :obj t)

(provide 'system-tools)
;;; system-tools.el ends here
