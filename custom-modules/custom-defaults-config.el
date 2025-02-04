;;; custom-defaults-config.el --- Defaults for the Emacs setup config  -*- lexical-binding: t; -*-
;; outline-regexp: ";;;+"
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


;;;; Global Settings
;;   ---------------
(setq-default lexical-binding t)                                               ; set variable scoping to be within the functions called by default as per modern languages.
(set-default-coding-systems 'utf-8)                                            ; set default coding system.

(defvar my-paths/ispell-word-replacement)
(defvar custom-info-dir)

(require 'dired)
(require 'ispell)
(require 'xref)
(require 'system-tools)
(require 'helpful)
;;(require 'aggressive-indent)


;; load in the custom info files for use with the info docs. 
(when (file-directory-p custom-info-dir)
  (require 'info)
  (info-initialize)
  (add-to-list 'Info-directory-list custom-info-dir))

;;; Windows
;; ensure that you must click a window to select it. The alternative is that
;; the window under the mouse is automatically selected when it is hovered over.
(setq mouse-autoselect-window nil)

;;;; Buffers
;;   -------
;; turn off linewrap by default.
;; (we use setq-default since this value can be adjusted on a per buffer basis)
(setq-default truncate-lines t)

;; remove any space between text lines in a buffer.
(setq-default line-spacing 0)

;; Do not open new frames for new buffers, reuse existing windows
;; (setq pop-up-frames nil)

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


;;;; Dired
;;   -----
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

;; ensure that we start with a detailed view of our directories and
;; show the breadcrumbs header. 
(add-hook 'dired-mode-hook
          (lambda ()
            (dired-hide-details-mode nil)
	    (diredp-breadcrumbs-in-header-line-mode 1)))

;; Ensure that we navigate through directories using the same dired
;; buffer whilst files are opened in a new buffer.
(defun my-dired/open-in-a-new-buffer ()
  "Open the file or directory at point in a new buffer or the same buffer."
  (interactive)
  (let ((file (dired-get-file-for-visit)))
    (if (file-directory-p file)
        (dired-find-alternate-file)  ; function run if file is a directory
      (dired-find-file-other-window)))) ;function run if file is a file. 

(add-hook 'dired-mode-hook
          (lambda ()
            (define-key dired-mode-map (kbd "RET")
                        'my-dired/open-in-a-new-buffer)
            (define-key dired-mode-map (kbd "^")
                        (lambda () (interactive) (find-alternate-file "..")))))



;;;; eShell
;;   ------
;; scroll eshell buffer to the bottom on input, but only in "this"
;; window.
(customize-set-variable 'eshell-scroll-to-bottom-on-input 'this)

;; pop up dedicated buffers in a different window.
;;(customize-set-variable 'switch-to-buffer-in-dedicated-window 'pop)

;; treat manual buffer switching (C-x b for example) the same as
;; programmatic buffer switching.
(customize-set-variable 'switch-to-buffer-obey-display-actions t)

;;;; helpful
;;   -------
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


;;;; Completion settings
;;   -------------------
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



;;;; Editing
;;   -------
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


;;;; Set up the spell-checker
;;   ------------------------
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


;;;; set consult-flyspell defaults.
;;   ------------------------------
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

;;;; correction at point functions
;;   -----------------------------
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

;; (customize-set-variable
;;  'consult-flyspell-select-function #'flyspell-correct-at-point)

;;;; Persistence between sessions

;; Enable savehist-mode for command history
(savehist-mode 1)

;; save the bookmarks file every time a bookmark is made or deleted
;; rather than waiting for Emacs to be killed.  Useful especially when
;; Emacs is a long running process.
(customize-set-variable 'bookmark-save-flag 1)

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


;;;; Miscellaneous
;;   -------------
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


(provide 'custom-defaults-config)
;;; custom-defaults-config.el ends here

                                                                                  ; LocalWords:  newcomment
                                                                                  ; LocalWords:  RET
                                                                                  ; LocalWords:  keymap
                                                                                  ; LocalWords:  YASnippet darkgrey
                                                                                  ; LocalWords:  vertico
