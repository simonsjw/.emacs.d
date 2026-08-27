;;; keymaps-core.el --- Central keymap infrastructure and which-key titles -*- lexical-binding: t; -*-

;; Copyright (C) 2026 Simon Watson
;; SPDX-License-Identifier: MIT

;;; Commentary:
;;
;; Core infrastructure for the centralised keymap system.
;;
;; This file provides:
;;   - Shared activation helpers
;;   - Global which-key title registrations
;;   - Common utilities used by the other keymaps-*.el modules
;;
;; Design principles (frozen in Component 2):
;;   - Organised around *functionality*, not mechanism.
;;   - Same key sequence may call different functions in different
;;     major modes when they perform the equivalent job.
;;   - Master maps live here (or in the sibling modules); language
;;     files only add thin overrides.
;;   - Every nested map receives a meaningful which-key title.
;;
;; Load order (recommended):
;;   (require 'keymaps-core)
;;   (require 'keymaps-vc)
;;   (require 'keymaps-ui)
;;   (require 'keymaps-prog)
;;   (require 'keymaps-project)
;;   (require 'keymaps-llm)
;;   (require 'keymaps-org)
;;   (require 'keymaps-menus)   ; menus after the maps exist
;;
;; The individual language files (lang-*.el) should then call the
;; activation helpers rather than defining large keymaps themselves.

;;; Code:

(require 'path-support)
(require 'logging-config)

(log/debug :fn 'keymaps-core
           :msg "Starting load of the keymaps-core module."
           :obj t)

;; ----------------------------------------------------------------------
;;; which-key title helpers
;; ----------------------------------------------------------------------

(defun keymaps-core/add-titles (keymap &rest key-title-pairs)
  "Register which-key titles for KEYMAP.
KEY-TITLE-PAIRS is a flat list of KEY TITLE KEY TITLE ...
Do nothing if KEY-TITLE-PAIRS is empty: `which-key-add-keymap-based-replacements'
requires at least one KEY REPLACEMENT pair.

Example:
  (keymaps-core/add-titles vc-prefix-map
    \"h\" \"Diff HL\"
    \"b\" \"Branches\")"
  (when (and key-title-pairs
             (fboundp 'which-key-add-keymap-based-replacements))
    (apply #'which-key-add-keymap-based-replacements keymap key-title-pairs)))

;; ----------------------------------------------------------------------
;;; Activation helpers (called from mode hooks / language files)
;; ----------------------------------------------------------------------

(defun keymaps-core/activate-comments ()
  "Activate the shared comments keymap in the current buffer.
Intended for prog-mode and derived modes."
  (when (boundp 'my-key-maps/comments)
    (local-set-key (kbd (if (boundp 'my-custom-prefix-keys/comment)
                            my-custom-prefix-keys/comment
                          "C-c c"))
                   my-key-maps/comments)))

(defun keymaps-core/activate-errors ()
  "Ensure the shared Errors (C-c e) bindings are present.
Most of these already live on prog-mode-map; this is a safety net."
  ;; The actual bindings are installed in keymaps-prog.el.
  ;; This helper exists so language files can call a single entry point.
  nil)

;; ----------------------------------------------------------------------
;;; Global which-key titles that apply across the whole system
;; ----------------------------------------------------------------------

(with-eval-after-load 'which-key
  ;; These are registered early so that even before the individual
  ;; modules finish loading the titles are available.
  (keymaps-core/add-titles vc-prefix-map
                           "h" "Diff HL"
                           "b" "Branches"
                           "M" "Merge Base"
                           "t" "Time Machine")

  ;; Placeholder registrations – the concrete maps are defined in the
  ;; sibling modules and will refine these titles further.
  (which-key-add-key-based-replacements
    "C-x v"     "VC"
    "C-x v f"   "VC File"
    "C-x v h"   "VC Diff"
    "C-x D"     "Dired"
    "C-x RET"   "Coding System"
    "C-c d"     "Dictionaries"
    "C-c g"     "Go"
    "C-c n"     "Org Roam"
    "C-c C-v"   "Org Babel"
    "C-c C-x"   "Org Extra"
    "C-c \""    "Plot")
  )

(log/debug :fn 'keymaps-core
           :msg "Ending load of the keymaps-core module."
           :obj t)

(provide 'keymaps-core)
;;; keymaps-core.el ends here
