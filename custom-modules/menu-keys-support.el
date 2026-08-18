;;; menu-keys-support.el --- Menu configuration  -*- lexical-binding: t; -*-

;; Copyright (C) 2024
;; SPDX-License-Identifier: MIT

;; Author: Simon Watson
;; Keywords: UI, menu

;;; Commentary:

;; Better menu organisation and key bindings.

;;; Code:
(require 'path-support)
(require 'logging-config)
(log/debug :fn 'menu-keys-support
           :msg "Starting load of the menu-keys-support module."
           :obj t)




;;;; KEYBOARDSHORTCUTS
;;   -----------------


;;;;; Dictionary
;; define a key to define the word at point.
(keymap-global-set "C-c d l" #'dictionary-lookup-definition)

;;;;; Menu-bar
;; define the master menu toggle.
(keymap-global-set "C-<tab>" #'menu-bar-mode)

;; Set context menu mode to t (right-click in buffer)
;; and enable the global mode context-menu-mode.
(context-menu-mode 1)
(global-set-key [down-mouse-3] 'mouse-popup-menu)


;;;;; VC-MODE keymaps


;; Optional: If remote files are slow, disable there.
;; (setq diff-hl-disable-on-remote t)

;; Define a fuller menu for diff-hl, extendable to menu-bar.
;; Use easy-menu-define for integration:
;;     (easy-menu-define
;;         diff-hl-menu global-map "Diff Highlights" my-custom-menus/diff-hl)
(defvar my-custom-menus/diff-hl
  '("Diff Highlights"
    ["Navigation" :enable nil]                                                    ; Section header; disabled for display.
    ["Next hunk" diff-hl-next-hunk
     :help "Jump to the next hunk in the buffer."]
    ["Previous hunk" diff-hl-previous-hunk
     :help "Jump to the previous hunk in the buffer."]
    ["Goto hunk diff" diff-hl-diff-goto-hunk
     :help "Open the diff buffer for the hunk at point."]
    "---"
    ["Hunk Operations" :enable nil]
    ["Stage hunk" diff-hl-stage-current-hunk
     :help "Stage the current hunk via VC for commit."]
    ["Revert hunk" diff-hl-revert-hunk
     :help "Revert the hunk at point to its previous state."]
    ["Show hunk" diff-hl-show-hunk
     :help "Display the diff for the hunk in a popup."]
    ["Mark hunk" diff-hl-mark-hunk
     :help "Select the current hunk as a region."]
    "---"
    ["Display Modes" :enable nil]
    ["Toggle flydiff" diff-hl-flydiff-mode
     :help "Enable/disable real-time diff updates."]
    ["Toggle margin" diff-hl-margin-mode
     :help "Switch between fringe and margin display."]
    ["Toggle amends" diff-hl-show-staged-changes-p
     :help "Show/hide staged changes in the display."]
    "---"
    ["Global Controls" :enable nil]
    ["Global mode" diff-hl-global-mode
     :help "Toggle diff-hl globally across buffers."]
    ["Dired mode" diff-hl-dired-mode
     :help "Enable diff-hl in Dired buffers."]
    ["Dir mode" diff-hl-dir-mode
     :help "Enable diff-hl in vc-dir buffers."]
    ["Set reference rev" diff-hl-set-reference-rev
     :help "Change the Git revision used for diffs."]
    ["Overlay modified" diff-hl-overlay-modified
     :help "Toggle overlay for modified lines."]
    ["Show staged hunk(s)" my-vc/show-staged-dif
     :help "Show the hunk or hunks staged for the next git commit."])
  "Menu for diff-hl functions for navigation, operations, modes, and globals.")


(defun my-setup-menus/diff-hl-setup-menu ()
  "Set up Diff HL menu and place it at the end of the menu-bar."
  (unless (lookup-key global-map [menu-bar Diff-HL])
    ;; 1. Create the menu keymap but do *not* bind it yet.
    (easy-menu-define diff-hl-menu nil
      "Diff HL"
      my-custom-menus/diff-hl)          ; your menu definition

    ;; 2. Install it *after* the last normal item (or after a named one).
    ;;    Passing `t` (or omitting the AFTER argument) puts it at the end
    ;;    of the keymap, just before anything in `menu-bar-final-items`
    ;;    (normally Help).
    (define-key-after (lookup-key global-map [menu-bar])
      [Diff-HL]                         ; the fake key used in the keymap
      (cons "Diff Highlights" diff-hl-menu)  ; visible title + the keymap
      t)
    ))

;; ALERNATIVES FOR POSITIONING THE KEYMAP
;; 1: DEFINE KEY AFTER
;; (define-key-after (lookup-key global-map [menu-bar])
;;   [Diff-HL]
;;   (cons "Diff Highlights" diff-hl-menu)
;;   'tools)          ; or 'options, 'edit, etc.
;; 2: ADD TO SUB ELEMENT OF TOOLBAR
;; (add-to-list 'menu-bar-final-items 'Diff-HL t)  ; t = append

;; Call setup on load (efficient: Runs once).
(my-setup-menus/diff-hl-setup-menu)



;;;;; Org Links
;; (global-set-key (kbd "C-c l s") #'org-store-link)
;; (global-set-key (kbd "C-c l i") #'org-insert-link-global)
;; (global-set-key (kbd "C-c l o") #'org-open-at-point-global)



;;;; PROG_MODE Menus
;;   ---------------
;;;;;; Comment Key Map and Menu

;; The below comments menu is bound in lang-prog-mode.el in the
;;  my-prog-mode/programming-mode-config-hook defun using this form:
;; (local-set-key
;;  (kbd my-custom-prefix-keys/comment) 'my-key-maps/comments)



;;; Define Org-mode key-maps
;;;; Links
;; (global-set-key (kbd "C-c l s") #'org-store-link)
;; (global-set-key (kbd "C-c l i") #'org-insert-link-global)
;; (global-set-key (kbd "C-c l o") #'org-open-at-point-global)

;;;; Agenda
;;(global-set-key (kbd "C-c a") #'org-agenda-list)
(global-set-key (kbd "C-c a") #'my-org/open-agenda)

;;;; Org Capture
(global-set-key (kbd "C-c x") #'org-capture)

(with-eval-after-load 'pdf-tools
  (define-key pdf-view-mode-map
              (kbd "<down-mouse-1>") 'pdf-view-mouse-set-region))

(log/debug :fn 'menu-keys-support
           :msg "Finishing the load of the menu-keys-support module."
           :obj t)


(provide 'menu-keys-support)
;;; menu-keys-support.el ends here
