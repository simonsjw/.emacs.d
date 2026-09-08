;;; keymaps-llm.el --- LLM prefix map for llm-support. -*- lexical-binding: t; -*-

;; Copyright (C) 2026 Simon Watson
;; SPDX-License-Identifier: MIT

;; Author: Simon Watson

;;; Commentary:

;; Keymap module for `llm-support'.  gptel and Aidermacs bindings under
;; `C-c m' (not `C-c l').  Commands live in `llm-support.el'; this
;; file owns the keymap and which-key titles.  Load after
;; `keymaps-core'.  Menus last in `keymaps-menus.el'.
;;
;; Map:
;;   Feature:    keymaps-llm
;;   Load-after: keymaps-core logging-config
;;   Load-phase: keymaps
;;   Keymaps:    keymaps-llm.el
;;   Docs:       docs/keymaps-llm.org
;;   OS:         none

;;; Code:

(require 'keymaps-core)
(require 'logging-config)

(log/debug :fn 'keymaps-llm
           :msg "Starting load of the keymaps-llm module."
           :obj t)

;;;; LLM map (C-c m)
;;   ---------------

(define-prefix-command 'my-key-maps/llm)

(keymap-global-set "C-c m" 'my-key-maps/llm)

;; Core commands (defined in llm-support.el)
(when (fboundp 'my-llm/new-chat)
  (keymap-set my-key-maps/llm "n" #'my-llm/new-chat))

(when (fboundp 'my-llm/aidermacs-menu)
  (keymap-set my-key-maps/llm "a" #'my-llm/aidermacs-menu))

(when (fboundp 'my-llm/switch-preset)
  (keymap-set my-key-maps/llm "p" #'my-llm/switch-preset))

;; Optional direct starters (can be left unbound if the transient is preferred)
(when (fboundp 'my-llm/aidermacs-start-grok)
  (keymap-set my-key-maps/llm "g" #'my-llm/aidermacs-start-grok))

(when (fboundp 'my-llm/aidermacs-start-qwen)
  (keymap-set my-key-maps/llm "q" #'my-llm/aidermacs-start-qwen))

(with-eval-after-load 'which-key
  (keymaps-core/add-titles my-key-maps/llm
                           "n" "New Chat"
                           "a" "Aidermacs"
                           "p" "Preset"
                           "g" "Grok"
                           "q" "Qwen"))

;;;; Migration note
;;   --------------

;; Previous `C-c l' globals should not be restored; `C-c m' is the
;; live prefix.

(log/debug :fn 'keymaps-llm
           :msg "Ending load of the keymaps-llm module."
           :obj t)

(provide 'keymaps-llm)
;;; keymaps-llm.el ends here
