;;; keymaps-vc.el --- Bindings and which-key titles for vc-support. -*- lexical-binding: t; -*-

;; Copyright (C) 2026 Simon Watson
;; SPDX-License-Identifier: MIT

;; Author: Simon Watson

;;; Commentary:

;; Keymap module for `vc-support'.  Titles and a few bindings on
;; `vc-prefix-map' and `diff-hl-command-map'.  Load after
;; `keymaps-core'.  Menus for these keys live in `keymaps-menus.el'
;; (loaded last).
;;
;; Map:
;;   Feature:    keymaps-vc
;;   Load-after: keymaps-core logging-config
;;   Load-phase: keymaps
;;   Keymaps:    keymaps-vc.el
;;   Docs:       docs/keymaps-vc.org
;;   OS:         none

;;; Code:

(require 'keymaps-core)
(require 'logging-config)

(log/debug :fn 'keymaps-vc
           :msg "Starting load of the keymaps-vc module."
           :obj t)

;;;; Which-key titles for the VC family
;;   ----------------------------------

(with-eval-after-load 'which-key
  (keymaps-core/add-titles vc-prefix-map
                           "h" "Diff HL"
                           "f" "File-path"
                           "b" "Branches"
                           "M" "Merge Base"
                           "t" "Time Machine")

  ;; If diff-hl-command-map is visible as a nested map we can title it too.
  (when (boundp 'diff-hl-command-map)
    (keymaps-core/add-titles diff-hl-command-map
                             "s" "Stage Hunk"
                             "r" "Revert Hunk"
                             "v" "Show Staged")))

;;;; Extra VC bindings
;;   -----------------

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
