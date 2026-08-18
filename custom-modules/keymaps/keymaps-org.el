;;; keymaps-org.el --- Org keymap (C-c C-o) -*- lexical-binding: t; -*-

;; Copyright (C) 2026 Simon Watson
;; SPDX-License-Identifier: MIT

;;; Commentary:
;;
;; Populate the previously almost-empty my-org-keymap.
;; The three highest-priority unbound Org functions now receive keys.

;;; Code:

(require 'keymaps-core)
(require 'logging-config)

(log/debug :fn 'keymaps-org
           :msg "Starting load of the keymaps-org module."
           :obj t)

;;; ----------------------------------------------------------------------
;;; Org map (C-c C-o)
;;; ----------------------------------------------------------------------

;; The sparse keymap was already created in org-support.el.
;; We simply ensure it exists and then populate it.
(unless (boundp 'my-org-keymap)
  (defvar my-org-keymap (make-sparse-keymap)
    "Keymap for Org-related commands under C-c C-o."))

(define-prefix-command 'my-org-keymap)
(global-set-key (kbd "C-c C-o") my-org-keymap)

;; Highest-priority bindings
(when (fboundp 'my-org/agenda-in-new-frame)
  (keymap-set my-org-keymap "a" #'my-org/agenda-in-new-frame))

(when (fboundp 'my-agenda/dashboard)
  (keymap-set my-org-keymap "d" #'my-agenda/dashboard))

(when (fboundp 'my-org/update-parent-dates)
  (keymap-set my-org-keymap "u" #'my-org/update-parent-dates))

(with-eval-after-load 'which-key
  (keymaps-core/add-titles my-org-keymap
                           "a" "Agenda Frame"
                           "d" "Dashboard"
                           "u" "Update Dates"))

(log/debug :fn 'keymaps-org
           :msg "Ending load of the keymaps-org module."
           :obj t)

(provide 'keymaps-org)
;;; keymaps-org.el ends here
