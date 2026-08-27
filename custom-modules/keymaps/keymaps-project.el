;;; keymaps-project.el --- Shared Project keymap (C-c p) -*- lexical-binding: t; -*-

;; Copyright (C) 2026 Simon Watson
;; SPDX-License-Identifier: MIT

;;; Commentary:
;;
;; Shared Project prefix (C-c p).
;; Common project-related commands live here so that language files
;; (especially Python) can become thin overrides instead of owning
;; the only copy of these bindings.

;;; Code:

(require 'keymaps-core)
(require 'logging-config)

(log/debug :fn 'keymaps-project
           :msg "Starting load of the keymaps-project module."
           :obj t)

;; ----------------------------------------------------------------------
;;; Project map (C-c p)
;; ----------------------------------------------------------------------

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
