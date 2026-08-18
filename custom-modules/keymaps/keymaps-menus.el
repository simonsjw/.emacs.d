;;; keymaps-menus.el --- Easy-menu definitions for the centralised keymaps -*- lexical-binding: t; -*-

;; Copyright (C) 2026 Simon Watson
;; SPDX-License-Identifier: MIT

;;; Commentary:
;;
;; Menu definitions that stay in lock-step with the keymaps defined in
;; the sibling modules.  Many of the original menus still live in
;; menu-keys-support.el; they will be migrated here gradually.
;;
;; For Component 3 we only ensure the infrastructure exists and that
;; the most important new groups have at least a stub menu.

;;; Code:

(require 'keymaps-core)
(require 'logging-config)

(log/debug :fn 'keymaps-menus
           :msg "Starting load of the keymaps-menus module."
           :obj t)

;;; ----------------------------------------------------------------------
;;; Comments menu (already existed; kept for reference / future move)
;;; ----------------------------------------------------------------------

(defvar my-custom-menus/comment
  '("Comments"
    "---"
    ["Format Comment" :enable nil]
    ["Create Header" my-in-buffer-tools/insert-section-header
     :keys "C-c c h" :help "Create comment header"]
    ["Align Comment" my-in-buffer-tools/my-comment-align-region-or-line
     :keys "C-c c TAB" :help "Align comment"]
    ["Fill Comment Paragraph" fill-comment-paragraph
     :keys "C-c c f" :help "Fill comment paragraph"]
    ["Add Box Around Comment" comment-box
     :keys "C-c c b" :help "Add box around comment"]
    ["Align All Comments" my-in-buffer-tools/comment-align-buffer
     :keys "C-c c a" :help "Align all inline comments in buffer"]
    "---"
    ["Make Comment" :enable nil]
    ["Toggle/Tab Comment as Needed" comment-dwim
     :keys "C-c c ;" :help "Toggle/tab comment as needed"]
    ["Comment Line" comment-line :keys "C-c c l"]
    ["Comment Region" comment-region :keys "C-c c r"]
    ["Uncomment Region" uncomment-region :keys "C-c c u"]
    ["Kill Comment" comment-kill :keys "C-c c k"]
    ["Break Line at Point and Indent" comment-indent-new-line
     :keys "C-c c RET"])
  "Menu for comment-related functions.")

;;; ----------------------------------------------------------------------
;;; Windows menu (already existed)
;;; ----------------------------------------------------------------------

(defvar my-custom-menus/windows
  '("Windows"
    "---"
    ["Window sizing" :enable nil]
    ["Increase Height" enlarge-window :keys "C-c w ^"]
    ["Decrease Height" shrink-window :keys "C-c w v"]
    ["Increase Width" enlarge-window-horizontally :keys "C-c w >"]
    ["Decrease Width" shrink-window-horizontally :keys "C-c w <"]
    "---"
    ["Visit Window" :enable nil]
    ["Window Above" windmove-up :keys "C-c w p"]
    ["Window Below" windmove-down :keys "C-c w n"]
    ["Window Left" windmove-left :keys "C-c w b"]
    ["Window Right" windmove-right :keys "C-c w f"]
    "---"
    ["Layout History" :enable nil]
    ["Undo Window Change" winner-undo :keys "C-c w u"]
    ["Redo Window Change" winner-redo :keys "C-c w r"])
  "Menu for window functions.")

;;; ----------------------------------------------------------------------
;;; Stub menus for the new groups (to be expanded in Component 5)
;;; ----------------------------------------------------------------------

(defvar my-custom-menus/project
  '("Project"
    ["Project Buffers" consult-project-buffer :keys "C-c p b"]
    ["Save Environment" my-lang-python/save-env-to-project :keys "C-c p s"]
    ["Create from Template" my-project/create-project-from-template :keys "C-c p t"]
    ["Vterm Here" my-vterm/cd-to-current-dir :keys "C-c p v"])
  "Menu for shared project commands.")

(defvar my-custom-menus/llm
  '("LLM"
    ["New Chat" my-llm/new-chat :keys "C-c m n"]
    ["Aidermacs Menu" my-llm/aidermacs-menu :keys "C-c m a"]
    ["Switch Preset" my-llm/switch-preset :keys "C-c m p"])
  "Menu for LLM / Aidermacs commands.")

(defvar my-custom-menus/org
  '("Org"
    ["Agenda in New Frame" my-org/agenda-in-new-frame :keys "C-c C-o a"]
    ["Dashboard" my-agenda/dashboard :keys "C-c C-o d"]
    ["Update Parent Dates" my-org/update-parent-dates :keys "C-c C-o u"])
  "Menu for the strengthened Org keymap.")

;;; ----------------------------------------------------------------------
;;; Installation helpers (examples – expand in Component 5)
;;; ----------------------------------------------------------------------

(defun keymaps-menus/install-windows-menu ()
  "Install the Windows menu on the menu-bar if not already present."
  (unless (lookup-key global-map [menu-bar WINDOWS-FNS])
    (easy-menu-define windows-menu nil "Windows" my-custom-menus/windows)
    (define-key-after (lookup-key global-map [menu-bar])
      [WINDOWS-FNS]
      (cons "Windows" windows-menu)
      t)))

;; Call on load (safe; checks for existence).
(keymaps-menus/install-windows-menu)

(log/debug :fn 'keymaps-menus
           :msg "Ending load of the keymaps-menus module."
           :obj t)

(provide 'keymaps-menus)
;;; keymaps-menus.el ends here
