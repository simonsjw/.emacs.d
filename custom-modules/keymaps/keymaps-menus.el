;;; keymaps-menus.el --- Easy-menu definitions for the centralised keymaps -*- lexical-binding: t; -*-

;; Copyright (C) 2026 Simon Watson
;; SPDX-License-Identifier: MIT

;;; Commentary:
;;
;; Menu definitions that stay in lock-step with the keymaps in the
;; sibling modules.  Every top-level group that has a keymap also has
;; a menu here.
;;
;; Installation:
;;   - Global groups are added to the menu-bar once.
;;   - Comments / Errors are also available for mode-local installation
;;     via `keymaps-menus/install-prog-menus'.
;;
;; This module is safe to load after `menu-keys-support.el': each
;; installer checks whether the menu-bar slot already exists.

;;; Code:

(require 'keymaps-core)
(require 'logging-config)

(log/debug :fn 'keymaps-menus
           :msg "Starting load of the keymaps-menus module."
           :obj t)

;; ----------------------------------------------------------------------
;;; Helpers
;; ----------------------------------------------------------------------

(defun keymaps-menus/install-menu-bar (slot title menu-def)
  "Install MENU-DEF on the menu-bar under SLOT.
SLOT is a symbol used as the fake menu-bar key (e.g. `WINDOWS-FNS').
TITLE is the visible menu-bar label.  MENU-DEF is an easy-menu list.

If SLOT is already present the menu is replaced so a reload picks up
new items (for example the IDE pane toggles)."
  (let ((map (easy-menu-create-menu title menu-def))
        (existing (lookup-key global-map (vector 'menu-bar slot))))
    (if existing
        (define-key global-map (vector 'menu-bar slot) (cons title map))
      (define-key-after (lookup-key global-map [menu-bar])
        (vector slot)
        (cons title map)
        t))))

;; ----------------------------------------------------------------------
;;; Comments (C-c c)
;; ----------------------------------------------------------------------

(defvar my-custom-menus/comment
  '("Comments"
    "---"
    ["Format Comment" :enable nil]
    ["Create Header" my-in-buffer-tools/insert-section-header
     :keys "C-c c h" :help "Create comment header"]
    ["Align Comment" my-in-buffer-tools/my-comment-align-region-or-line
     :keys "C-c c TAB" :help "Align comment on the current line or region"]
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

;; ----------------------------------------------------------------------
;;; Windows (C-c w)
;; ----------------------------------------------------------------------

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
    ["Redo Window Change" winner-redo :keys "C-c w r"]
    "---"
    ["IDE panes" :enable nil]
    ["Edit"
     my-window-tools/toggle-edit
     :style toggle
     :selected t
     :active nil
     :keys "C-c w t e"
     :help "The edit window cannot be closed"]
    ["Data"
     my-window-tools/toggle-data
     :style toggle
     :selected (and (fboundp 'my-window-tools/window-open-p)
                    (my-window-tools/window-open-p 'data))
     :active (and (fboundp 'my-window-tools--in-ide-frame-p)
                  (my-window-tools--in-ide-frame-p))
     :keys "C-c w t d"
     :help "Show or hide the data pane"]
    ["Config"
     my-window-tools/toggle-config
     :style toggle
     :selected (and (fboundp 'my-window-tools/window-open-p)
                    (my-window-tools/window-open-p 'config))
     :active (and (fboundp 'my-window-tools--in-ide-frame-p)
                  (my-window-tools--in-ide-frame-p))
     :keys "C-c w t c"
     :help "Show or hide the config pane"]
    ["Logs"
     my-window-tools/toggle-logs
     :style toggle
     :selected (and (fboundp 'my-window-tools/window-open-p)
                    (my-window-tools/window-open-p 'logs))
     :active (and (fboundp 'my-window-tools--in-ide-frame-p)
                  (my-window-tools--in-ide-frame-p))
     :keys "C-c w t l"
     :help "Show or hide the logs pane"]
    ["VC"
     my-window-tools/toggle-vc
     :style toggle
     :selected (and (fboundp 'my-window-tools/window-open-p)
                    (my-window-tools/window-open-p 'vc))
     :active (and (fboundp 'my-window-tools--in-ide-frame-p)
                  (my-window-tools--in-ide-frame-p))
     :keys "C-c w t v"
     :help "Show or hide the vc pane"]
    ["Terminal"
     my-window-tools/toggle-terminal
     :style toggle
     :selected (and (fboundp 'my-window-tools/window-open-p)
                    (my-window-tools/window-open-p 'terminal))
     :active (and (fboundp 'my-window-tools--in-ide-frame-p)
                  (my-window-tools--in-ide-frame-p))
     :keys "C-c w t s"
     :help "Show or hide the terminal pane"])
  "Menu for window functions.")

;; ----------------------------------------------------------------------
;;; UI / Layout (C-c i)
;; ----------------------------------------------------------------------

(defvar my-custom-menus/ui
  '("UI"
    "---"
    ["Refresh IDE layout" IDE-refresh :keys "C-c i d"
     :help "Reset the IDE window layout"]
    "---"
    ["Breadcrumbs" :enable nil]
    ["Breadcrumb (local)" breadcrumb-local-mode :keys "C-c i b l"
     :help "Toggle breadcrumbs in this buffer"]
    ["Breadcrumb (global)" breadcrumb-mode :keys "C-c i b g"
     :help "Toggle breadcrumbs globally"]
    "---"
    ["Whitespace" :enable nil]
    ["Cleanup whitespace" whitespace-cleanup :keys "C-c i w c"]
    ["Toggle whitespace view" whitespace-mode :keys "C-c i w v"]
    ["Whitespace report" whitespace-report :keys "C-c i w r"]
    "---"
    ["Tidy" :enable nil]
    ["Tidy this window" my-window-tools/tidy-window :keys "C-c i t d"
     :help "Clean the focused window's buffer history"])
  "Menu for UI / layout functions.")

;; ----------------------------------------------------------------------
;;; Errors / Diagnostics (C-c e)
;; ----------------------------------------------------------------------

(defvar my-custom-menus/flymake
  '("Errors"
    "---"
    ["Display errors" :enable nil]
    ["Buffer diagnostics" flymake-show-buffer-diagnostics
     :keys "C-c e b" :help "Show buffer errors in a buffer"]
    ["Project diagnostics" my-flymake/show-project-diagnostics
     :keys "C-c e a" :help "Show project errors in a buffer"]
    ["Error list" consult-flymake
     :keys "C-c e m" :help "Show errors in the minibuffer"]
    "---"
    ["Navigate errors" :enable nil]
    ["Next error" flymake-goto-next-error
     :keys "C-c e n" :help "Move to the next error"]
    ["Previous error" flymake-goto-prev-error
     :keys "C-c e p" :help "Move to the previous error"]
    "---"
    ["Preload" :enable nil]
    ["Preload directory" my-flymake/preload-directory-for-diagnostics
     :keys "C-c e l"]
    ["Preload project" my-flymake/preload-project-for-diagnostics
     :keys "C-c e d"]
    ["Preload directory recursively" my-flymake/preload-directory-recursive
     :keys "C-c e D"])
  "Menu for linting / Flymake functions.")

;; ----------------------------------------------------------------------
;;; Project (C-c p)
;; ----------------------------------------------------------------------

(defvar my-custom-menus/project
  '("Project"
    ["Project buffers" consult-project-buffer :keys "C-c p b"
     :help "Switch among project buffers"]
    ["Find project file" consult-project-extra-find :keys "C-c p f"
     :help "Find a file in the current project"]
    ["Find other window" consult-project-extra-find-other-window :keys "C-c p o"]
    "---"
    ["Save environment" my-lang-python/save-env-to-project :keys "C-c p s"
     :help "Write the current env into the project's .dir-locals.el"]
    ["Create from template" my-project/create-project-from-template :keys "C-c p t"]
    ["Project dictionary" my-prog-mode/set-project-dictionary :keys "C-c p d"]
    "---"
    ["Vterm here" my-vterm/cd-to-current-dir :keys "C-c p v"
     :help "cd the vterm buffer to the current file's directory"])
  "Menu for shared project commands.")

;; ----------------------------------------------------------------------
;;; LLM (C-c m)
;; ----------------------------------------------------------------------

(defvar my-custom-menus/llm
  '("LLM"
    ["New chat" my-llm/new-chat :keys "C-c m n"
     :help "Open a new Grok chat buffer"]
    ["Aidermacs menu" my-llm/aidermacs-menu :keys "C-c m a"
     :help "Open the Aidermacs transient"]
    ["Switch preset" my-llm/switch-preset :keys "C-c m p"
     :help "Apply a gptel preset buffer-locally"]
    "---"
    ["Start Grok session" my-llm/aidermacs-start-grok :keys "C-c m g"]
    ["Start Qwen session" my-llm/aidermacs-start-qwen :keys "C-c m q"])
  "Menu for LLM / Aidermacs commands.")

;; ----------------------------------------------------------------------
;;; Org (C-c C-o)
;; ----------------------------------------------------------------------

(defvar my-custom-menus/org
  '("Org"
    ["Agenda in new frame" my-org/agenda-in-new-frame :keys "C-c C-o a"]
    ["Dashboard" my-agenda/dashboard :keys "C-c C-o d"]
    ["Update parent dates" my-org/update-parent-dates :keys "C-c C-o u"]
    "---"
    ["Open agenda" my-org/open-agenda :keys "C-c a"]
    ["Capture" org-capture :keys "C-c x"]
    "---"
    ["Roam: find node" org-roam-node-find :keys "C-c n f"]
    ["Roam: insert node" org-roam-node-insert :keys "C-c n i"]
    ["Roam: capture" org-roam-capture :keys "C-c n c"]
    ["Roam: toggle buffer" org-roam-buffer-toggle :keys "C-c n l"])
  "Menu for the strengthened Org keymap.")

;; ----------------------------------------------------------------------
;;; Diff HL / VC (C-x v h …)
;; ----------------------------------------------------------------------

(defvar my-custom-menus/diff-hl
  '("Diff Highlights"
    ["Navigation" :enable nil]
    ["Next hunk" diff-hl-next-hunk
     :help "Jump to the next hunk in the buffer"]
    ["Previous hunk" diff-hl-previous-hunk
     :help "Jump to the previous hunk in the buffer"]
    ["Goto hunk diff" diff-hl-diff-goto-hunk
     :help "Open the diff buffer for the hunk at point"]
    "---"
    ["Hunk Operations" :enable nil]
    ["Stage hunk" diff-hl-stage-current-hunk :keys "C-x v h s"
     :help "Stage the current hunk via VC"]
    ["Revert hunk" diff-hl-revert-hunk :keys "C-x v h r"
     :help "Revert the hunk at point"]
    ["Show hunk" diff-hl-show-hunk
     :help "Display the diff for the hunk in a popup"]
    ["Show staged hunk(s)" my-vc/show-staged-diff :keys "C-x v h v"
     :help "Show the hunk or hunks staged for the next git commit"]
    ["Mark hunk" diff-hl-mark-hunk
     :help "Select the current hunk as a region"]
    "---"
    ["Display Modes" :enable nil]
    ["Toggle flydiff" diff-hl-flydiff-mode]
    ["Toggle margin" diff-hl-margin-mode]
    "---"
    ["Global Controls" :enable nil]
    ["Global mode" diff-hl-global-mode]
    ["Dired mode" diff-hl-dired-mode]
    ["Set reference rev" diff-hl-set-reference-rev])
  "Menu for diff-hl navigation, operations and modes.")

;; ----------------------------------------------------------------------
;;; Installation
;; ----------------------------------------------------------------------

(defun keymaps-menus/install-global-menus ()
  "Install the shared menus on the menu-bar."
  (keymaps-menus/install-menu-bar 'WINDOWS-FNS "Windows" my-custom-menus/windows)
  (keymaps-menus/install-menu-bar 'UI-FNS     "UI"      my-custom-menus/ui)
  (keymaps-menus/install-menu-bar 'PROJECT-FNS "Project" my-custom-menus/project)
  (keymaps-menus/install-menu-bar 'LLM-FNS    "LLM"     my-custom-menus/llm)
  (keymaps-menus/install-menu-bar 'ORG-FNS    "Org"     my-custom-menus/org)
  (keymaps-menus/install-menu-bar 'Diff-HL    "Diff Highlights" my-custom-menus/diff-hl))

(defun keymaps-menus/install-prog-menus ()
  "Install Comments and Errors menus on the current local map.
Intended for `prog-mode-hook'."
  (easy-menu-define nil (current-local-map) "Comments" my-custom-menus/comment)
  (easy-menu-define nil (current-local-map) "Errors"   my-custom-menus/flymake))

(keymaps-menus/install-global-menus)
(add-hook 'prog-mode-hook #'keymaps-menus/install-prog-menus)

(log/debug :fn 'keymaps-menus
           :msg "Ending load of the keymaps-menus module."
           :obj t)

(provide 'keymaps-menus)
;;; keymaps-menus.el ends here
