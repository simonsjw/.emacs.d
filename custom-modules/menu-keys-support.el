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

;; enable the global mode context-menu-mode.
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


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;; Set comment shortcuts and build menu for prog-mode ;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

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
 'my-key-maps/prog-mode-comment-map "B" 'my-in-buffer-tools/comment-box-filled)
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
    ["Add Filled Box Around Comment" my-in-buffer-tools/comment-box-filled :keys "C-c d B" :help "Add filled box around comment"]
    ["Add Box Around Comment" comment-box :keys "C-c c b" :help "Add box around comment"]
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


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;; Window management ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

(defgroup custom-windows '()
  "Window related configuration for Custom Emacs."
  :tag "Custom Windows"
  :group 'custom)

(defcustom custom-windows-prefix-key "C-c w"
  "Configure the prefix key for window movement bindings.

Movement commands provided by `windmove' package, `winner-mode'
also enables undo functionality if the window layout changes."
  :group 'custom-windows
  :type 'string)

;; Turning on `winner-mode' provides an "undo" function for resetting
;; your window layout.  We bind this to `C-c w u' for winner-undo and
;; `C-c w r' for winner-redo (see below).
(winner-mode 1)

(define-prefix-command 'custom-windows-key-map)

(keymap-set 'custom-windows-key-map "u" 'winner-undo)
(keymap-set 'custom-windows-key-map "r" 'winner-redo)
(keymap-set 'custom-windows-key-map "n" 'windmove-down)
(keymap-set 'custom-windows-key-map "p" 'windmove-up)
(keymap-set 'custom-windows-key-map "b" 'windmove-left)
(keymap-set 'custom-windows-key-map "f" 'windmove-right)

(keymap-global-set custom-windows-prefix-key 'custom-windows-key-map)


(provide 'menu-keys-support)
;;; menu-keys-support.el ends here
