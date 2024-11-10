;;; custom-defaults-config.el --- Defaults for the Emacs setup config  -*- lexical-binding: t; -*-

;; Copyright (C) 2023
;; SPDX-License-Identifier: MIT

;; Author: Simon Watson

;;; Commentary:
;;
;; Some of these settings were inspired by the following:
;; - Charles Choi: "Surprise and Emacs Defaults"
;;   http://yummymelon.com/devnull/surprise-and-emacs-defaults.html
;; - Mickey Petersen: "Mastering Emacs",
;;   especially "Demystifying Emacs’s Window Manager"
;;   https://www.masteringemacs.org/article/demystifying-emacs-window-manager

;;; Code:

;; Set default coding system.
(set-default-coding-systems 'utf-8)

(defvar my-paths/ispell-word-replacement)

(require 'dired)
(require 'ispell)
(require 'xref)
(require 'display-line-numbers)
(require 'custom-system-tools)
(require 'helpful)
;;(require 'aggressive-indent)

;;; Buffers
;;  #######
;; turn off linewrap by default.
;; (we use setq-default since this value can be adjusted on a per buffer basis)
(setq-default truncate-lines t)

;; Do not open new frames for new buffers, reuse existing windows
(setq pop-up-frames nil)

;; show the path to the sym-link rather than the underlying file
;; when using sym-link file paths in emacs.
(customize-set-variable
 'find-file-visit-truename t
 "Show path to sym-link rather than underlying file when viewing sym-link
file paths.")

;; Revert Dired and other buffers
(customize-set-variable
 'global-auto-revert-non-file-buffers t
 "Automatically refresh files found with changes on disk.")

;; Revert buffers when the underlying file has changed
(global-auto-revert-mode 1)


;;; Dired
;;  -----
;; Make dired do something intelligent when two directories are shown
;; in separate dired buffers.  Makes copying or moving files between
;; directories easier.  The value `t' means to guess the default
;; target directory.
(customize-set-variable 'dired-dwim-target t)

;; Enable the dired-find-alternate-file function, removing any
;; restrictions on its use. After evaluating this line, users can use
;; dired-find-alternate-file without seeing the warning message that
;; usually prompts the user to enable the command. This is
;; particularly useful for users who frequently use
;; dired-find-alternate-file to navigate directories in Dired mode
;; without opening new buffers for each visited directory.
(put 'dired-find-alternate-file 'disabled nil)

;; automatically update dired buffers on revisiting their directory
(customize-set-variable 'dired-auto-revert-buffer t)

;; ensure that we start with a detailed view of our directories
(add-hook 'dired-mode-hook
          (lambda ()
            (dired-hide-details-mode nil)))

;; Ensure that we navigate through directories using the same dired
;; buffer whilst files are opened in a new buffer.
(defun my-dired/open-in-a-new-buffer ()
  "Open the file or directory at point in a new buffer or the same buffer."
  (interactive)
  (let ((file (dired-get-file-for-visit)))
    (if (file-directory-p file)
        (dired-find-alternate-file)
      (dired-find-file-other-window))))

(add-hook 'dired-mode-hook
          (lambda ()
            (define-key dired-mode-map (kbd "RET")
                        'my-dired/open-in-a-new-buffer)
            (define-key dired-mode-map (kbd "^")
                        (lambda () (interactive) (find-alternate-file "..")))))



;;; eShell
;;  ------
;; scroll eshell buffer to the bottom on input, but only in "this"
;; window.
(customize-set-variable 'eshell-scroll-to-bottom-on-input 'this)

;; pop up dedicated buffers in a different window.
;;(customize-set-variable 'switch-to-buffer-in-dedicated-window 'pop)

;; treat manual buffer switching (C-x b for example) the same as
;; programmatic buffer switching.
(customize-set-variable 'switch-to-buffer-obey-display-actions t)

;; prefer the more full-featured built-in ibuffer for managing
;; buffers.
(keymap-global-set "<remap> <list-buffers>" #'ibuffer-list-buffers)
;; turn on forward and backward movement cycling
(customize-set-variable 'ibuffer-movement-cycle t)
;; the number of hours before a buffer is considered "old" by
;; ibuffer.
(customize-set-variable 'ibuffer-old-time 24)

;;; helpful
;;  -------
;; prefer the helpful menus over standard documentation.

;; Note that the built-in `describe-function' includes both functions
;; and macros. `helpful-function' is functions only, so we provide
;; `helpful-callable' as a drop-in replacement.
(global-set-key (kbd "C-h f") #'helpful-callable)
;;
(global-set-key (kbd "C-h v") #'helpful-variable)
(global-set-key (kbd "C-h k") #'helpful-key)
(global-set-key (kbd "C-h x") #'helpful-command)
;;
;; Lookup the current symbol at point. C-c C-d is a common keybinding
;; for this in lisp modes.
(global-set-key (kbd "C-c C-d") #'helpful-at-point)
;;
;; Look up *F*unctions (excludes macros).
;;
;; By default, C-h F is bound to `Info-goto-emacs-command-node'. Helpful
;; already links to the manual, if a function is referenced there.
(global-set-key (kbd "C-h F") #'helpful-function)


;;; Completion settings
;;  ###################
;;
;; Turn on the best completion-mode available:
;; - Assume use of vertico
;;

;; No matter which completion mode is used:
(customize-set-variable 'tab-always-indent 'complete)
(customize-set-variable 'completion-cycle-threshold 3)
(customize-set-variable 'completion-category-overrides
                        '((file (styles . (partial-completion)))))
(customize-set-variable 'completions-detailed t)

;; use completion system instead of popup window for cross-references.
(customize-set-variable 'xref-show-definitions-function
                        #'xref-show-definitions-completing-read)

;; set consult-flyspell defaults.
;; ------------------------------
;; consult-flyspell-set-point-after-word
;; If set to t (default) the point will be at the end of the word
;; after jumping to it, nil will set the point before the word.
(customize-set-variable 'consult-flyspell-set-point-after-word t)
;; consult-flyspell-always-check-buffer
;; If set to nil (default) prefix argument is needed to check the
;; buffer with flyspell-buffer first.
;; If set to t flyspell-buffer will always be called first, unless
;; the prefix argument is set.
(customize-set-variable 'consult-flyspell-always-check-buffer nil)

;; correction at point functions
;; -----------------------------
;; There are two useful functions for correcting words at a point: 
;; *  flyspell-auto-correct-word
;;    This function automatically corrects the word that's
;;    currently under or immediately before the cursor (point).
;;    When you invoke this function, it doesn't show you a list of
;;    suggestions. Instead, it immediately replaces the word with
;;    the first suggestion from its internal dictionary. If the
;;    replacement is not the word you wanted, you can keep
;;    invoking flyspell-auto-correct-word to cycle through other
;;    suggested words.
;;
;; *  flyspell-correct-at-point
;;    This function is a bit different. When you use it, it provides a
;;    list of suggested corrections for the misspelled word at the
;;    cursor (point). This is more interactive because you get to see
;;    a list of possible corrections and choose the one that fits.
;;    It's a bit like right-clicking a misspelled word in a word
;;    processor and seeing a list of suggestions.
(customize-set-variable
 'consult-flyspell-select-function #'flyspell-correct-at-point)

;;; Editing
;;  #######
;; 
;; Typed text replaces the selection if the selection is active,
;; pressing delete or backspace deletes the selection.
(delete-selection-mode)

;; Use spaces instead of tabs
(setq-default indent-tabs-mode nil)

;; Do not save duplicates in kill-ring
(customize-set-variable 'kill-do-not-save-duplicates t)

;; Better support for files with long lines
(setq-default bidi-paragraph-direction 'left-to-right)
(setq-default bidi-inhibit-bpa t)
(global-so-long-mode 1)


;; Dictionary/Thesaurus
;; Set the default dictionary server. 
(defconst dictionary-server
  "dict.org" "Ensure the look-up is defined with a locally available dict.")

;; define a key to define the word at point.
(keymap-set global-map "C-c d l" #'dictionary-lookup-definition)


;; Set up the spell-checker
;; ------------------------
(setq ispell-program-name "aspell") ; Or "hunspell" or "ispell"

(setq ispell-extra-args
      `("--sug-mode=normal"
        ,(concat "--repl=" my-paths/ispell-word-replacement)))

(setq ispell-local-dictionary-alist
      '(("Australian"
         "[A-Za-z]" "[^A-Za-z]" "[']" nil
         ("-B" "-d" "en_AU" "--encoding=utf-8") nil utf-8)
        ("British"
         "[A-Za-z]" "[^A-Za-z]" "[']" nil
         ("-B" "-d" "en_GB" "--encoding=utf-8") nil utf-8)
        ("American"
         "[A-Za-z]" "[^A-Za-z]" "[']" nil
         ("-B" "-d" "en_US" "--encoding=utf-8") nil utf-8)))

;; now set the dictionary locale to en_AU.
(customize-set-variable
 'ispell-dictionary "Australian" "Set default dictionary locale. ")

(global-set-key (kbd "C-c d a") #'my-dictionary/use-australian)
(global-set-key (kbd "C-c d b") #'my-dictionary/use-british)
(global-set-key (kbd "C-c d u") #'my-dictionary/use-american)

;; turn on spell checking, if available.
(with-eval-after-load 'ispell
  (when (executable-find ispell-program-name)
    (add-hook 'text-mode-hook #'flyspell-mode)
    (add-hook 'prog-mode-hook #'flyspell-prog-mode)))

;;; Persistence between sessions

;; Turn on recentf mode
(add-hook 'after-init-hook #'recentf-mode)

;; Enable savehist-mode for command history
(savehist-mode 1)

;; save the bookmarks file every time a bookmark is made or deleted
;; rather than waiting for Emacs to be killed.  Useful especially when
;; Emacs is a long running process.
(customize-set-variable 'bookmark-save-flag 1)


;;; Window management
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

;; Make scrolling less stuttered
(setq auto-window-vscroll nil)

(defvar fast-but-imprecise-scrolling)
(defvar scroll-conservatively)
(defvar scroll-margin)
(defvar scroll-preserve-screen-position)

(setq fast-but-imprecise-scrolling t)
(setq scroll-conservatively 101)
(setq scroll-margin 0)
(setq scroll-preserve-screen-position t)

;; open man pages in their own window, and switch to that window to
;; facilitate reading and closing the man page.
;;(customize-set-variable 'Man-notify-method 'aggressive)

;; keep the Ediff control panel in the same frame
(customize-set-variable 'ediff-window-setup-function
                        'ediff-setup-windows-plain)


;;; Miscellaneous
;;  #############
;;

;; Make shebang (#!) file executable when saved
(add-hook 'after-save-hook
          #'executable-make-buffer-file-executable-if-script-p)

;; Turn on repeat mode to allow certain keys to repeat on the last
;; keystroke. For example, C-x [ to page backward, after pressing this
;; keystroke once, pressing repeated [ keys will continue paging
;; backward. `repeat-mode' is exited with the normal C-g, by movement
;; keys, typing, or pressing ESC three times.
(repeat-mode 1)

;; Provide a function to set the fill column indicator.
;; This has a default of 80 but can be set on a per mode basis.
(defun my-programming-mode/set-fill-column-indicator (&optional column)
  "Set the preferred fill-column indicator for the current mode.
If COLUMN is not provided, use 80 as the default value."
  (setq display-fill-column-indicator-column (or column 80)) ; Use COLUMN or 80 if COLUMN is nil
  (display-fill-column-indicator-mode 1))


;; Configuration for all programming modes.
(defun my-programming-mode/programming-mode-config-hook ()
  "Set useful layout tweeks for programming modes."
  (interactive)

  ;; Provide an autosave hook.
  (defun my/auto-save-hook ()
    "Enable auto-saving in prog-mode buffers."
    (when buffer-file-name
      (setq-local compilation-ask-about-save nil)))

  ;; Set programming modes to pick up the custom prog-mode face.
  ;; (after custom-theme-support has defined the face.)
  (when (facep 'my-font-faces/prog-mode-face)
    (face-remap-add-relative 'default 'my-font-faces/prog-mode-face))


  (setq display-line-numbers-type 'absolute)
  (display-line-numbers-mode)           ; activate line numbers.
  (set-face-attribute 'line-number nil :height 0.8)

  ;; (set-face-attribute 'line-number-current-line nil :height `unspecified)
  ;; careful with `line-number-current-line. - setting line size changes for the line number current
  ;; line causes the text to indent slightly. I find it quite annoying.

  ;; make the left and right fringe-mode 5 and 10 pixels respectively.
  ;; (left is narrower because it  has a following line number adding thickness)
  (fringe-mode '(5 . 10))
  
  ;; show the fill column with an indicator line
  (setq display-fill-column-indicator-column t)
  (display-fill-column-indicator-mode)

  ;; ensure changes are visible in the buffer. 
  ;; (highlight-changes-mode)
  
  ;; (setq yas-use-menu 'abbreviate)  ;; show only the snippets for the mode of the buffer.
  ;; activate yas mode.
  ;; (yas-minor-mode) ;; or M-x yas-reload-all if you've started YASnippet already.
  ;; (yas-mode 1)

  ;; (setq fci-rule-width 1)
  ;; (setq fci-rule-color "darkgrey")
  
  (setq truncate-lines t))               ; deactivate line-wrapping.

;; Hooks

;; add the programming mode config to prog-mode
(add-hook 'prog-mode-hook 'my-programming-mode/programming-mode-config-hook)

(provide 'custom-defaults-config)
;;; custom-defaults-config.el ends here
