;;; keymaps-llm.el --- LLM / AI keymap (C-c m) -*- lexical-binding: t; -*-

;; Copyright (C) 2026 Simon Watson
;; SPDX-License-Identifier: MIT

;;; Commentary:
;;
;; LLM and Aidermacs bindings under the new prefix C-c m
;; (moved from the previous C-c l to free that prefix).
;;
;; The actual implementation of the commands lives in LLM-support.el;
;; this module only owns the keymap and which-key titles.

;;; Code:

(require 'keymaps-core)
(require 'logging-config)

(log/debug :fn 'keymaps-llm
           :msg "Starting load of the keymaps-llm module."
           :obj t)

;; ----------------------------------------------------------------------
;;; LLM map (C-c m)
;; ----------------------------------------------------------------------

(define-prefix-command 'my-key-maps/llm)

(keymap-global-set "C-c m" 'my-key-maps/llm)

;; Core commands (defined in LLM-support.el)
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

;; ----------------------------------------------------------------------
;;; Migration note
;; ----------------------------------------------------------------------
;; The previous global bindings
;;   (global-set-key (kbd "C-c l n") #'my-llm/new-chat)
;;   (global-set-key (kbd "C-c l a") #'my-llm/aidermacs-menu)
;; should be removed from LLM-support.el once this module is loaded.
;; Until then both prefixes will work (harmless but confusing).

(log/debug :fn 'keymaps-llm
           :msg "Ending load of the keymaps-llm module."
           :obj t)

(provide 'keymaps-llm)
;;; keymaps-llm.el ends here
