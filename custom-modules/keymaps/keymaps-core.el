;;; keymaps-core.el --- Shared which-key titles and keymap helpers. -*- lexical-binding: t; -*-

;; Copyright (C) 2026 Simon Watson
;; SPDX-License-Identifier: MIT

;; Author: Simon Watson

;;; Commentary:

;; First keymap module loaded from `init.el'.  It does not own a
;; prefix map of its own.  It registers which-key titles and small
;; activation helpers that the later `keymaps-*' files and language
;; modules call.
;;
;; Owning feature modules and their keymap files (load after this
;; file; `keymaps-menus.el' last):
;;
;;   vc-support      → keymaps-vc.el
;;   ui-config       → keymaps-ui.el
;;   lang-prog-mode  → keymaps-prog.el
;;   project-support → keymaps-project.el
;;   llm-support     → keymaps-llm.el
;;   org-support     → keymaps-org.el
;;   menus           → keymaps-menus.el
;;
;; Language files (`lang-*.el') should call the activation helpers
;; rather than defining large keymaps themselves.  Organised around
;; functionality, not mechanism: the same key sequence may call
;; different functions in different major modes when they do the
;; equivalent job.
;;
;; Map:
;;   Feature:    keymaps-core
;;   Load-after: path-support logging-config
;;   Load-phase: keymaps
;;   Keymaps:    none
;;   Docs:       docs/keymaps-core.org
;;   OS:         none

;;; Code:

(require 'path-support)
(require 'logging-config)
(log/debug :fn 'keymaps-core
           :msg "Starting load of the keymaps-core module."
           :obj t)

(declare-function which-key-add-keymap-based-replacements "which-key")
(declare-function which-key-add-key-based-replacements "which-key")

(defvar vc-prefix-map)
(defvar my-key-maps/comments)
(defvar my-custom-prefix-keys/comment)

;;;; Which-key title helpers
;;   -----------------------

(defun keymaps-core/add-titles (keymap &rest key-title-pairs)
  "Register which-key titles for KEYMAP.
KEY-TITLE-PAIRS is a flat list of KEY TITLE KEY TITLE ...
Do nothing if KEY-TITLE-PAIRS is empty:
`which-key-add-keymap-based-replacements' requires at least one KEY
REPLACEMENT pair.

Example:
  (keymaps-core/add-titles vc-prefix-map
    \"h\" \"Diff HL\"
    \"b\" \"Branches\")"
  (when (and key-title-pairs
             (fboundp 'which-key-add-keymap-based-replacements))
    (apply #'which-key-add-keymap-based-replacements keymap key-title-pairs)))

;;;; Activation helpers
;;   ------------------

(defun keymaps-core/activate-comments ()
  "Activate the shared comments keymap in the current buffer.
Intended for `prog-mode' and derived modes."
  (when (boundp 'my-key-maps/comments)
    (local-set-key (kbd (if (boundp 'my-custom-prefix-keys/comment)
                            my-custom-prefix-keys/comment
                          "C-c c"))
                   my-key-maps/comments)))

(defun keymaps-core/activate-errors ()
  "Ensure the shared Errors (C-c e) bindings are present.
Most of these already live on `prog-mode-map'; this is a safety net.
The actual bindings are installed in `keymaps-prog.el'."
  nil)

;;;; Global which-key titles
;;   -----------------------

(with-eval-after-load 'which-key
  (keymaps-core/add-titles vc-prefix-map
                           "h" "Diff HL"
                           "b" "Branches"
                           "M" "Merge Base"
                           "t" "Time Machine")
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
    "C-c \""    "Plot"))

(log/debug :fn 'keymaps-core
           :msg "Ending load of the keymaps-core module."
           :obj t)

(provide 'keymaps-core)
;;; keymaps-core.el ends here
