;;; keymaps-project.el --- Project prefix map for project-support. -*- lexical-binding: t; -*-

;; Copyright (C) 2026 Simon Watson
;; SPDX-License-Identifier: MIT

;; Author: Simon Watson

;;; Commentary:

;; Keymap module for `project-support'.  Shared Project prefix
;; (`C-c p') so language files can stay thin overrides.  Load after
;; `keymaps-core'.  Menus last in `keymaps-menus.el'.
;;
;; Map:
;;   Feature:    keymaps-project
;;   Load-after: keymaps-core logging-config
;;   Load-phase: keymaps
;;   Keymaps:    keymaps-project.el
;;   Docs:       docs/keymaps-project.org
;;   OS:         none

;;; Code:

(require 'keymaps-core)
(require 'logging-config)

(log/debug :fn 'keymaps-project
           :msg "Starting load of the keymaps-project module."
           :obj t)

;;;; Project map (C-c p)
;;   -------------------

(define-prefix-command 'my-key-maps/project)

(keymap-global-set "C-c p" 'my-key-maps/project)

;; Buffers / navigation
(when (fboundp 'consult-project-buffer)
  (keymap-set my-key-maps/project "b" #'consult-project-buffer))

;; Environment / dir-locals helpers (Python originally owned these;
;; they are now shared).
(when (fboundp 'my-lang-python/save-env-to-project)
  (keymap-set my-key-maps/project "s" #'my-lang-python/save-env-to-project))

;; Create project from template
(when (fboundp 'my-project/create-project-from-template)
  (keymap-set my-key-maps/project "t" #'my-project/create-project-from-template))

;; Vterm in the directory of the current buffer
(when (fboundp 'my-vterm/cd-to-current-dir)
  (keymap-set my-key-maps/project "v" #'my-vterm/cd-to-current-dir))

;; Optional: project dictionary helper (if present)
(when (fboundp 'my-prog-mode/set-project-dictionary)
  (keymap-set my-key-maps/project "d" #'my-prog-mode/set-project-dictionary))

(with-eval-after-load 'which-key
  (keymaps-core/add-titles my-key-maps/project
                           "b" "Buffers"
                           "s" "Save Env"
                           "t" "Template"
                           "v" "Vterm Here"
                           "d" "Dictionary"))

(log/debug :fn 'keymaps-project
           :msg "Ending load of the keymaps-project module."
           :obj t)

(provide 'keymaps-project)
;;; keymaps-project.el ends here
