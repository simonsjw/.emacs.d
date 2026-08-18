;;; keymaps-vc.el --- VC / Diff / Git keymaps and titles -*- lexical-binding: t; -*-

;; Copyright (C) 2026 Simon Watson
;; SPDX-License-Identifier: MIT

;;; Commentary:
;;
;; Centralised VC, diff-hl and related bindings.
;; Most of the heavy lifting still lives in vc-support.el and
;; menu-keys-support.el; this module focuses on which-key titles
;; and a clean activation point.

;;; Code:

(require 'keymaps-core)
(require 'logging-config)

(log/debug :fn 'keymaps-vc
           :msg "Starting load of the keymaps-vc module."
           :obj t)

;;; ----------------------------------------------------------------------
;;; which-key titles for the VC family
;;; ----------------------------------------------------------------------

(with-eval-after-load 'which-key
  (keymaps-core/add-titles vc-prefix-map
                           "h" "Diff HL"
                           "b" "Branches"
                           "M" "Merge Base"
                           "t" "Time Machine")

  ;; If diff-hl-command-map is visible as a nested map we can title it too.
  (when (boundp 'diff-hl-command-map)
    (keymaps-core/add-titles diff-hl-command-map
                             "s" "Stage Hunk"
                             "r" "Revert Hunk"
                             "v" "Show Staged")))

;;; ----------------------------------------------------------------------
;;; Extra bindings that were previously scattered
;;; ----------------------------------------------------------------------

;; Rename file via VC (already present in menu-keys-support; kept here
;; for completeness when that file is thinned).
(global-set-key (kbd "C-x v f r") #'vc-rename-file)

;; Ensure diff-hl lives under the normal VC prefix.
(with-eval-after-load 'diff-hl
  (define-key diff-hl-mode-map diff-hl-command-prefix nil)
  (define-key vc-prefix-map (kbd "h") diff-hl-command-map)

  ;; Extra convenience keys on the diff-hl map
  (define-key diff-hl-command-map (kbd "s") #'diff-hl-stage-current-hunk)
  (define-key diff-hl-command-map (kbd "r") #'diff-hl-revert-hunk)
  (when (fboundp 'my-vc/show-staged-diff)
    (define-key diff-hl-command-map (kbd "v") #'my-vc/show-staged-diff)))

(log/debug :fn 'keymaps-vc
           :msg "Ending load of the keymaps-vc module."
           :obj t)

(provide 'keymaps-vc)
;;; keymaps-vc.el ends here
