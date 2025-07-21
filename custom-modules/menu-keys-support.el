;;; menu-keys-support.el --- Menu configuration  -*- lexical-binding: t; -*-

;; Copyright (C) 2024
;; SPDX-License-Identifier: MIT

;; Author: Simon Watson
;; Keywords: UI, menu

;;; Commentary:

;; Better menu organisation and key bindings.

;;; Code:

;; define the master menu toggle.
(define-key input-decode-map [C-tab] [control-tab])
(global-set-key [control-tab] 'menu-bar-mode)


;; Set context menu mode to t (right-click in buffer)
;; and enable the global mode context-menu-mode.
(context-menu-mode 1)
(global-set-key [down-mouse-3] 'mouse-popup-menu)

;; (with-eval-after-load 'vc
;;   (defun my-menus/add-vc-mode-to-context-menu (menu click)
;;     "Add the VC mode menu as a submenu to the context menu."
;;     (when vc-mode
;;       (define-key menu [vc-submenu]
;;                   `(menu-item "Version Control" ,vc-menu-map))))
;;   ;; Add the function to context-menu-functions
;;   (add-hook 'context-menu-functions #'my-menus/add-vc-mode-to-context-menu))


;;;; PROG_MODE: Comment Key Map and Menu

;; Define the keymap for 'comments' related commands
(defvar my-key-maps/prog-mode-comment-map (make-sparse-keymap "Comment")
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
(define-prefix-command 'my-key-maps/prog-mode-comment-map)

(keymap-set
 'my-key-maps/prog-mode-comment-map "TAB" 'comment-indent)
(keymap-set
 'my-key-maps/prog-mode-comment-map "f" 'fill-comment-paragraph)
(keymap-set
 'my-key-maps/prog-mode-comment-map "a" 'my-in-buffer-tools/comment-align-buffer)
(keymap-set
 'my-key-maps/prog-mode-comment-map "b" 'comment-box)
;; (keymap-set
;;   'my-key-maps/prog-mode-comment-map "s" 'checkdoc-ispell-comments)
;; (keymap-set
;;   'my-key-maps/prog-mode-comment-map "p" 'ispell-comment-or-string-at-point)
;; (keymap-set
;;   'my-key-maps/prog-mode-comment-map "x" 'set-comment-set-column)
(keymap-set
 'my-key-maps/prog-mode-comment-map ";" 'comment-dwim)
(keymap-set
 'my-key-maps/prog-mode-comment-map "l" 'comment-line)
(keymap-set
 'my-key-maps/prog-mode-comment-map "r" 'comment-region)
(keymap-set
 'my-key-maps/prog-mode-comment-map "u" 'uncomment-region)
(keymap-set
 'my-key-maps/prog-mode-comment-map "k" 'comment-kill)
(keymap-set
 'my-key-maps/prog-mode-comment-map "RET" 'comment-indent-new-line)

(defvar my-custom-menus/comment-menu
  '("Comments"
    "---"
    ["Format Comment" :enable nil]
    ["Align Comment" comment-indent :keys "C-c c TAB" :help "Align comment"]
    ["Fill Comment Paragraph" fill-comment-paragraph :keys "C-c c f" :help "Fill comment paragraph"]
    ["Add Box Around Comment" comment-box :keys "C-c c b" :help "Add box around comment"]
    ["Align All Comments" my-in-buffer-tools/comment-align-buffer :keys "C-c c a" :help "Align all inline comments in buffer to comment column"]
    ;; ["Check Comment Spellings in Buffer" checkdoc-ispell-comments :keys "C-c c s" :help "Check comment spellings in buffer"]
    ;; ["Check Comment Spellings at Point" ispell-comment-or-string-at-point :keys "C-c c p" :help "Check comment spellings at point"]
    ;; ["Set Comment Column to Cursor" set-comment-set-column :keys "C-c c x" :help "Set comment column to cursor"]
    "---"
    ["Make Comment" :enable nil]
    ["Toggle/Tab Comment as Needed" comment-dwim :keys "C-c c ;" :help "Toggle/tab comment as needed"]
    ["Comment Line" comment-line :keys "C-c c l" :help "Comment whole cursor line"]
    ["Comment Region" comment-region :keys "C-c c r" :help "Comment selected region"]
    ["Uncomment Region" uncomment-region :keys "C-c c u" :help "Uncomment selected region"]
    ["Kill Comment" comment-kill :keys "C-c c k" :help "Kill full comment"]
    ["Break Line at Point and Indent" comment-indent-new-line :keys "C-c c RET" :help "Break line at point and indent"])
  "Menu for comment-related functions in `prog-mode'.")


;;;; Window management: Key Map

;;;; Custom Windows Menu and Key Bindings

;; Ensure `winner-mode` is enabled for undo/redo of window layouts
(winner-mode 1)

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
(define-prefix-command 'custom-windows-key-map)

;; Add existing window management commands
(keymap-set 'custom-windows-key-map "u" 'winner-undo)
(keymap-set 'custom-windows-key-map "r" 'winner-redo)
(keymap-set 'custom-windows-key-map "n" 'windmove-down)
(keymap-set 'custom-windows-key-map "p" 'windmove-up)
(keymap-set 'custom-windows-key-map "b" 'windmove-left)
(keymap-set 'custom-windows-key-map "f" 'windmove-right)

;; Add new vertical shrink window command key binding.
(keymap-set 'custom-windows-key-map "v" 'shrink-window)

;; Bind the prefix key
(keymap-global-set custom-windows-prefix-key 'custom-windows-key-map)

;; Define the "Windows" menu
(define-key global-map [menu-bar windows]
            (cons "Windows" (make-sparse-keymap "Windows")))

;; Add window resizing commands with existing global keybindings
(define-key global-map [menu-bar windows enlarge-window]
            '(menu-item "Increase Height" enlarge-window))

(define-key
 global-map [menu-bar windows shrink-window]
 '(menu-item "Decrease Height" shrink-window))                                    ; Custom binding

(define-key
 global-map [menu-bar windows enlarge-window-horizontally]
 '(menu-item "Increase Width" enlarge-window-horizontally))

(define-key
 global-map [menu-bar windows shrink-window-horizontally]
 '(menu-item "Decrease Width" shrink-window-horizontally))

;; Add separator line
(define-key global-map [menu-bar windows separator]
            '(menu-item "--"))

;; Add window movement and undo/redo commands to the menu
(define-key global-map [menu-bar windows winner-undo]
            '(menu-item "Undo Window Change" winner-undo))

(define-key global-map [menu-bar windows winner-redo]
            '(menu-item "Redo Window Change" winner-redo))

(define-key global-map [menu-bar windows windmove-down]
            '(menu-item "Move to Window Below" windmove-down))

(define-key global-map [menu-bar windows windmove-up]
            '(menu-item "Move to Window Above" windmove-up))

(define-key global-map [menu-bar windows windmove-left]
            '(menu-item "Move to Window Left" windmove-left))

(define-key global-map [menu-bar windows windmove-right]
            '(menu-item "Move to Window Right" windmove-right))


(provide 'menu-keys-support)
;;; menu-keys-support.el ends here
