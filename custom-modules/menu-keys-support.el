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

;;;; Keymaps: how do we do this?
;; 1) Define the custom group for the keymap
;; -----------------------------------------
;; (defgroup custom-special-keys '()
;;   "An example container group `custom-special-keys'."
;;   :tag "Custom special keys"
;;   :group 'custom)

;; 2) Set the prefix key for the group
;; -----------------------------------
;; Set the prefix key for the new group and add it to your previously defined
;; `custom-special-keys' group.
;; (defcustom custom-special-keys-prefix-key
;;     "C-c i" "Configure the prefix key for my special keys."
;;     :group 'custom-special-keys
;;     :type 'string)


;; 3) Create a sparse keymap
;; -------------------------
;; ;; Define prefix command map
;; (define-prefix-command 'my-key-maps/custom-special-key-map)

;; 4) Populate the keymap
;; ----------------------
;; ;; Add existing window management commands
;; (keymap-set 'my-key-maps/custom-special-key-map "a" 'my/fun)
;; (keymap-set 'my-key-maps/custom-special-key-map "b" 'my/other-func)
;; (keymap-set 'my-key-maps/custom-special-key-map "c" 'my/still-another-fun)
;; (keymap-set 'my-key-maps/custom-special-key-map "d" 'my/final-func)

;; 5) Optionally, create a menu for your keys
;; ------------------------------------------
;; 5.1) create the menu
;; (defvar my-custom-menus/special-menu
;;   '("Those special keys"
;;     "---"
;;     ["the first group" :enable nil]            ; This group will have a title. The group below will not.
;;     ["run my/fun" 'my/fun :keys "C-c i a" :help "Optional popup help text here."]
;;     ["do something else" 'my/other-fun :keys "C-c i b"]
;;     "---"
;;     ["are we there yet?" 'my/still-another-fun :keys "C-c i c"]
;;     ["last one" 'my/final-func :keys "C-c i d" :help "say something funny"]
;;     )
;;   "Menu for example 'special' keymap.")
;;
;; 5.2) Assign your menu to somewhere it can be accessed.
;;    a. The global menu bar
;;
;;    b. The context menu




;;;; KEYBOARDSHORTCUTS
;;   -----------------
;;   (no function commands with no corresponding menu item)

;;;;; Dictionary
;; define a key to define the word at point.
(keymap-global-set "C-c d l" #'dictionary-lookup-definition)

;;;;; Menu-bar
;; define the master menu toggle.
(keymap-global-set "C-<tab>" #'menu-bar-mode)


;;;;; VC-MODE keymaps

;; Set some useful vc keyboard shortcuts.
(global-set-key (kbd "C-x v f r") #'vc-rename-file) ; Track renamed files in git by renaming them *in* git.


(with-eval-after-load 'diff-hl
  ;; Remove the package’s default binding of the whole map under C-x v
  (define-key diff-hl-mode-map diff-hl-command-prefix nil)

  ;; Put the map under the normal VC prefix as a sub-map
  (define-key vc-prefix-map (kbd "h") diff-hl-command-map)

  ;; Add additional keymaps.
  (define-key diff-hl-command-map (kbd "s") #'diff-hl-stage-current-hunk)         ; Explicit stage-current via VC.
  (define-key diff-hl-command-map (kbd "r") #'diff-hl-revert-hunk)                ; An alternative “r” revert key.
  (define-key diff-hl-command-map (kbd "v") #'my-vc/show-staged-diff)             ; show the staged hunk in a separate buffer.
  )


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

;; TODO: Other menus
;; branch commands
(defvar my-custom-menus/vc-branch
  '("VC"
    ["Branches" :enable nil]                                                    ; Section header; disabled for display.
    ["Create branch" vc-create-branch :keys "C-x v b c"
     :help "Make a branch called NAME in directory DIR.."]
    ["Switch branch" vc-swich-branch  :keys "C-x v b s"
     :help "Switch to the branch NAME in the directory DIR."]
    ["Print Branch" vc-print-branch-log :keys "C-x v b l"
     :help "Show the change log for BRANCH in another window."])
  "Menu for git branch operations in VC.")



;;;;; UI keymaps (prefix "C-c i ...)"
;; Define the custom keymap for window management.
;; Note that we do the mappings after startup-config has loaded
;; to ensure the functions we map actually exist.
(defgroup custom-ui '()
  "Window related configuration for Custom Emacs."
  :tag "Custom UI"
  :group 'custom)

(defcustom custom-ui-prefix-key "C-c i"
  "Configure the prefix key for useful ui maps."
  :group 'custom-ui
  :type 'string)

;; Define prefix command map
(define-prefix-command 'my-key-maps/ui)

(with-eval-after-load 'startup-config
  ;; Define IDE view
  (keymap-set 'my-key-maps/ui "d" #'IDE-refresh)

  ;; Breadcrumb path
  (keymap-set 'my-key-maps/ui "b l" #'breadcrumb-local-mode)
  (keymap-set 'my-key-maps/ui "b g" #'breadcrumb-mode)

  ;; whitespace reporting and cleanup.
  (keymap-set 'my-key-maps/ui "w c" #'whitespace-cleanup)
  (keymap-set 'my-key-maps/ui "w v" #'whitespace-mode)
  (keymap-set 'my-key-maps/ui "w r" #'whitespace-report)

  ;; tidy the window
  (keymap-set 'my-key-maps/ui "t d" #'my-window-tools/tidy-window)

  ;; Bind the prefix key
  (keymap-global-set custom-ui-prefix-key 'my-key-maps/ui)
  )


;;;;; Org Links
;; (global-set-key (kbd "C-c l s") #'org-store-link)
;; (global-set-key (kbd "C-c l i") #'org-insert-link-global)
;; (global-set-key (kbd "C-c l o") #'org-open-at-point-global)

;;;;; Org Agenda
;;  (keymap-global-set "C-c o a" #'my-org/open-agenda)

;;;; Org Capture
;; (global-set-key (kbd "C-c c") #'org-capture)


;; Set context menu mode to t (right-click in buffer)
;; and enable the global mode context-menu-mode.
(context-menu-mode 1)
(global-set-key [down-mouse-3] 'mouse-popup-menu)

;;;; PROG_MODE Menus
;;   ---------------
;;;;;; Comment Key Map and Menu

;; The below comments menu is bound in lang-prog-mode.el in the
;;  my-prog-mode/programming-mode-config-hook defun using this form:
;; (local-set-key
;;  (kbd my-custom-prefix-keys/comment) 'my-key-maps/comments)

;; Define the keymap for 'comments' related commands
(defvar my-key-maps/comments (make-sparse-keymap "Comment")
  "Keymap for comment commands in programming modes.")

(defgroup custom-comment-keymaps '()
  "Window related configuration for Custom Emacs."
  :tag "Custom comment formatting"
  :group 'custom)

(defcustom my-custom-prefix-keys/comment "C-c c"
  "Key prefix for comment formatting functions.

These are available in `prog-mode'."
  :group 'custom-comment-keymaps
  :type 'string)

;; define a keymap for the functionality in newcomment.el
(define-prefix-command 'my-key-maps/comments)

(keymap-set 'my-key-maps/comments "h" 'my-in-buffer-tools/insert-section-header)
(keymap-set 'my-key-maps/comments "TAB" 'comment-indent)
(keymap-set 'my-key-maps/comments "f" 'fill-comment-paragraph)
(keymap-set 'my-key-maps/comments "a" 'my-in-buffer-tools/comment-align-buffer)
(keymap-set 'my-key-maps/comments "b" 'comment-box)
(keymap-set 'my-key-maps/comments ";" 'comment-dwim)
(keymap-set 'my-key-maps/comments "l" 'comment-line)
(keymap-set 'my-key-maps/comments "r" 'comment-region)
(keymap-set 'my-key-maps/comments "u" 'uncomment-region)
(keymap-set 'my-key-maps/comments "k" 'comment-kill)
(keymap-set 'my-key-maps/comments "RET" 'comment-indent-new-line)

(defvar my-custom-menus/comment
  '("Comments"
    "---"
    ["Format Comment" :enable nil]
    ["Create Header" my-in-buffer-tools/my-comment-align-region-or-line :keys "C-c c h" :help "Create comment header"]
    ["Align Comment" my-in-buffer-tools/my-comment-align-region-or-line :keys "C-c c TAB" :help "Align comment"]
    ["Fill Comment Paragraph" fill-comment-paragraph :keys "C-c c f" :help "Fill comment paragraph"]
    ["Add Box Around Comment" comment-box :keys "C-c c b" :help "Add box around comment"]
    ["Align All Comments" my-in-buffer-tools/comment-align-buffer :keys "C-c c a" :help "Align all inline comments in buffer to comment column"]
    "---"
    ["Make Comment" :enable nil]
    ["Toggle/Tab Comment as Needed" comment-dwim :keys "C-c c ;" :help "Toggle/tab comment as needed"]
    ["Comment Line" comment-line :keys "C-c c l" :help "Comment whole cursor line"]
    ["Comment Region" comment-region :keys "C-c c r" :help "Comment selected region"]
    ["Uncomment Region" uncomment-region :keys "C-c c u" :help "Uncomment selected region"]
    ["Kill Comment" comment-kill :keys "C-c c k" :help "Kill full comment"]
    ["Break Line at Point and Indent" comment-indent-new-line :keys "C-c c RET" :help "Break line at point and indent"]
    )
  "Menu for comment-related functions.")

(defvar my-custom-menus/flymake
  '("linting"
    "---"
    ["Display errors" :enable nil]
    ["Error buffer" flymake-show-buffer-diagnostics :keys "C-c e b" :help "Show buffer errors in a buffer"]
    ["Project error buffer" flymake-show-project-diagnostics :keys "C-c e p" :help "Show project errors in a buffer"]
    ["Error list" consult-flymake :keys "C-c e m" :help "Show errors in the mini-buffer"]
    "---"
    ["Navigate errors" :enable nil]
    ["Next error" flymake-goto-next-error :keys "C-c e n" :help "Move to the next error."]
    ["Previous error" flymake-goto-prev-error :keys "C-c e p" :help "Move to the previous error."])
  ;; turn on flymake
  ;; check now
  ;; view flymake log
  ;; turn off flymake
  "Menu for linting/flymake-related functions.
 (see lang-prog-mode where it is added to current-local-map.)")



;;;; Window management: Key Map

;; Define the custom keymap for window management
(defgroup custom-windows '()
  "Window related configuration for Custom Emacs."
  :tag "Custom Windows"
  :group 'custom)

(defcustom custom-windows-prefix-key "C-c w"
  "Configure the prefix key for window movement bindings."
  :group 'custom-windows
  :type 'string)

;; Define prefix command map
(define-prefix-command 'my-key-maps/windows)

;; Add existing window management commands
(keymap-set 'my-key-maps/windows "u" 'winner-undo)
(keymap-set 'my-key-maps/windows "r" 'winner-redo)
(keymap-set 'my-key-maps/windows "n" 'windmove-down)
(keymap-set 'my-key-maps/windows "p" 'windmove-up)
(keymap-set 'my-key-maps/windows "b" 'windmove-left)
(keymap-set 'my-key-maps/windows "f" 'windmove-right)
;; Vertical window sizing command key binding.
(keymap-set 'my-key-maps/windows "^" 'enlarge-window)
(keymap-set 'my-key-maps/windows "v" 'shrink-window)
;; Horizontal window sizing command key binding.
(keymap-set 'my-key-maps/windows ">" 'enlarge-window-horizontally)
(keymap-set 'my-key-maps/windows "<" 'shrink-window-horizontally)

;; Bind the prefix key
(keymap-global-set custom-windows-prefix-key 'my-key-maps/windows)


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
    ["Window Above" windmove-up :keys "C-c w p" :help "Move cursor to the window above."]
    ["Window Below" windmove-down :keys "C-c w n" :help "Move cursor to the window below."]
    ["Window Left" windmove-left :keys "C-c w f"  :help "Move cursor to the left window."]
    ["Window Right" windmove-right :keys "C-c w b" :help "Move cursor to the right window. "]
    "---"
    ["Layout History" :enable nil]
    ["Undo Window Change" winner-undo :keys "C-c w u" :help "Undo the window layout change."]
    ["Redo Window Change" winner-redo :keys "C-c w r" :help "Redo the window layout change."]
    )
  "Menu for window functions.")


(defun my-setup-menus/windows-setup-menu ()
  "Set up windows menu and place it at the end of the menu-bar."
  (unless (lookup-key global-map [menu-bar WINDOWS-FNS])
    ;; 1. Create the menu keymap but do *not* bind it yet.
    (easy-menu-define windows-menu nil
      "Windows"
      my-custom-menus/windows)          ; your menu definition

    ;; 2. Install it *after* the last normal item (or after a named one).
    ;;    Passing `t` (or omitting the AFTER argument) puts it at the end
    ;;    of the keymap, just before anything in `menu-bar-final-items`
    ;;    (normally Help).
    (define-key-after (lookup-key global-map [menu-bar])
      [WINDOWS-FNS]                         ; the fake key used in the keymap
      (cons "Windows" windows-menu)  ; visible title + the keymap
      t)
    ))

(my-setup-menus/windows-setup-menu)


;;; Define Org-mode key-maps
;;;; Links
;; (global-set-key (kbd "C-c l s") #'org-store-link)
;; (global-set-key (kbd "C-c l i") #'org-insert-link-global)
;; (global-set-key (kbd "C-c l o") #'org-open-at-point-global)

;;;; Agenda
;;(global-set-key (kbd "C-c a") #'org-agenda-list)
(global-set-key (kbd "C-c a") #'my-org/open-agenda)

;;;; Org Capture
(global-set-key (kbd "C-c c") #'org-capture)

(with-eval-after-load 'pdf-tools
  (define-key pdf-view-mode-map
              (kbd "<down-mouse-1>") 'pdf-view-mouse-set-region))

(log/debug :fn 'menu-keys-support
           :msg "Finishing the load of the menu-keys-support module."
           :obj t)


(provide 'menu-keys-support)
;;; menu-keys-support.el ends here
