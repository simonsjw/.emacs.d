;;; defaults-config.el --- Defaults for the Emacs setup config  -*- lexical-binding: t; -*-

;; Copyright (C) 2023 Simon Watson
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

(require 'logging-config)
(log/debug :fn 'defaults-config
           :msg "Starting load of the defaults-config module."
           :obj t)

;;;; Global Settings
(setq-default lexical-binding t)                                                  ; set variable scoping to be within the functions called by default as per modern languages.
(set-default-coding-systems 'utf-8)                                               ; set default coding system.

(require 'dired)
(require 'xref)
(require 'path-support)
;;(require 'aggressive-indent)

;;; Windows
;; ensure that you must click a window to select it. The alternative is that
;; the window under the mouse is automatically selected when it is hovered over.
(setq mouse-autoselect-window nil)

;;;; Buffers

;; turn off linewrap by default.
;; (we use setq-default since this value can be adjusted on a per buffer basis)
(setq-default truncate-lines t)

;; remove any space between text lines in a buffer.
(setq-default line-spacing 0)

;; Do not open new frames for new buffers, reuse existing windows
;; (setq pop-up-frames nil)

;; show the path to the sym-link rather than the underlying file
;; when using sym-link file paths in emacs.
;; Show path to sym-link rather than underlying file when viewing 
;; sym-link file paths.
(setopt find-file-visit-truename t)

;; Revert Dired and other buffers
;; Automatically refresh files found with changes on disk.
(setopt
 global-auto-revert-non-file-buffers t)
 

;; Revert buffers when the underlying file has changed
(global-auto-revert-mode 1)

;;;; Dired

;; Make dired do something intelligent when two directories are shown
;; in separate dired buffers.  Makes copying or moving files between
;; directories easier.  The value `t' means to guess the default
;; target directory.
(setopt dired-dwim-target t)

;; Enable the dired-find-alternate-file function, removing any
;; restrictions on its use. After evaluating this line, users can use
;; dired-find-alternate-file without seeing the warning message that
;; usually prompts the user to enable the command. This is
;; particularly useful for users who frequently use
;; dired-find-alternate-file to navigate directories in Dired mode
;; without opening new buffers for each visited directory.
(put 'dired-find-alternate-file 'disabled nil)

;; automatically update dired buffers on revisiting their directory
(setopt dired-auto-revert-buffer t)

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
        (dired-find-alternate-file)                                               ; function run if file is a directory
      (dired-find-file-other-window))))                                           ; function run if file is a file.

(add-hook 'dired-mode-hook
          (lambda ()
            (define-key dired-mode-map (kbd "RET")
                        'my-dired/open-in-a-new-buffer)
            (define-key dired-mode-map (kbd "^")
                        (lambda () (interactive) (find-alternate-file "..")))))

;;;; eShell

;; scroll eshell buffer to the bottom on input, but only in "this"
;; window.
(setopt eshell-scroll-to-bottom-on-input 'this)

;; pop up dedicated buffers in a different window.
;;(setopt switch-to-buffer-in-dedicated-window 'pop)

;; treat manual buffer switching (C-x b for example) the same as
;; programmatic buffer switching.
(setopt switch-to-buffer-obey-display-actions t)

;;;; helpful

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

;; Turn on the best completion-mode available:
;; - Assume use of vertico

;; No matter which completion mode is used:
(setopt tab-always-indent 'complete)
(setopt completion-cycle-threshold 3)
(setopt completion-category-overrides
        '((file (styles . (partial-completion)))))
(setopt completions-detailed t)

;; use completion system instead of popup window for cross-references.
(setopt xref-show-definitions-function
        #'xref-show-definitions-completing-read)

;;;; Editing

;; Typed text replaces the selection if the selection is active,
;; pressing delete or backspace deletes the selection.
(delete-selection-mode)

;; Use spaces instead of tabs
(setq-default indent-tabs-mode nil)

;; Do not save duplicates in kill-ring
(setopt kill-do-not-save-duplicates t)

;; Better support for files with long lines
(setq-default bidi-paragraph-direction 'left-to-right)
(setq-default bidi-inhibit-bpa t)
(global-so-long-mode 1)

;; Kill the fringe continuation indicators completely – fixes the
;; visual-fill-column “missing bands” bug when pasting long single lines.
(setq visual-line-fringe-indicators '(nil nil))                                   ; left-fringe nil, right-fringe nil


;; Setup of enchant
;; ----------------
;; sudo apt-get install hunspell hunspell-au
;;
;; ~/.config/enchant/
;; <+> ..
;; [?] en.dic
;; [?] en.exc
;; [?] en_AU.dic
;; [?] en_AU.exc
;; [?] en_GB.dic
;; [?] en_GB.exc
;; [?] en_US.dic
;; [?] en_US.exc
;; [?] enchant.ordering
;;
;; content of enchant.ordering:
;; *:hunspell,aspell
;; en_AU:hunspell
;;
;; ------------------

;; Dictionary/Thesaurus
;; Set the default dictionary server.
(setopt dictionary-server "dict.org")

(setopt dictionary-default-dictionary "gcide")

;; define a key to define the word at point.
(keymap-set global-map "C-c d l" #'dictionary-lookup-definition)

;; (global-set-key (kbd "C-c d a") #'my-dictionary/use-australian)
;; (global-set-key (kbd "C-c d b") #'my-dictionary/use-british)
;; (global-set-key (kbd "C-c d u") #'my-dictionary/use-american)

(use-package jinx
  :delight
  :ensure t
  :bind ("C-c C-j" . jinx-correct)
  :config
  (setq jinx-languages "en_AU en_GB"
        jinx-delay 0.1))

(require 'jinx)

;;; Set up the Jinx spellchecker.
;;; Jinx project/personal dictionary control (Simon’s preferred behaviour)

;; Make the project flag safe so Emacs never prompts you
(put 'jinx-project-spellings 'safe-local-variable #'booleanp)

(with-eval-after-load 'jinx

  ;; Common programming words (loaded to session only – no disk clutter)
  (defconst my-prog-mode/prog-mode-accepted-words
    '("foo" "bar" "foobar" "idx" "dotfile" "tstamp" "tex" "csv" "pdf"
      "ARGS" "Args" "Backtrace" "DDirectory" "LaTeX" "LocalWords" "OPTARG"
      "README" "SPEEDBAR" "TODO" "alist" "aspell" "basedpyright" "cd" "conda"
      "config" "csv" "defconst" "defcustom" "defvar" "dir" "docstring"
      "docstrings" "el" "elpa" "env" "flymake" "flyspell" "github" "gitignore"
      "hdb" "http" "https" "ipynb" "ipython" "jdk" "joinpath" "json" "jsonl"
      "lvl" "md" "mnt" "modeline" "noqa" "odbc" "prog" "py" "rlwrap" "scipy"
      "setq" "speedbar" "sql" "str" "sym" "tmp" "txt" "urls" "usr" "vterm" "ws"
      "yasnippet")
    "Words commonly accepted in all programming modes.
Loaded to session only (no .dir-locals.el write).")

  (defun my-spell-check/add-words-to-jinx (words location &optional mode-sym)
    "Add WORDS to Jinx dictionary at explicit LOCATION.
LOCATION is one of:
  'session    -- in-memory session only (no disk write – ideal for base setup)
  'file       -- buffer file-local (adds to Local Variables section)
  'directory  -- project .dir-locals.el (creates missing file in project root).
Purpose: Bulk/scripted adds while leaving interactive `jinx-correct` menu
         untouched.
Variables:
  WORDS    -- list of strings (duplicates ignored).
  LOCATION -- symbol as above.
  MODE-SYM -- for logging (e.g. 'prog-mode).
Flow:
  1. Require Jinx.
  2. Dispatch by LOCATION using official internals.
  3. For 'directory: auto-detect/create .dir-locals.el in project root.
  4. Log + safe recheck (no jit-lock crash risk)."
    (require 'jinx nil t)
    (when (and words (fboundp 'jinx--add-local-word))
      (let ((added 0))
        (dolist (word (delete-dups words))
          (pcase location
            ('session
             (cl-pushnew word jinx--session-words :test #'string-equal))
            ('file
             (jinx--add-local-word 'jinx-local-words word)
             (add-file-local-variable 'jinx-local-words jinx-local-words))
            ('directory
             (jinx--add-local-word 'jinx-dir-local-words word)
             (let ((default-directory
                    (or (locate-dominating-file default-directory
                                                ".dir-locals.el")
                        (when-let* ((proj (project-current)))
                          (project-root proj))
                        default-directory)))
               (save-window-excursion
                 (add-dir-local-variable nil 'jinx-dir-local-words
                                         jinx-dir-local-words))))
            (_ (message "Unknown Jinx location: %S" location)))
          (setq added (1+ added)))
        ;; Log only when useful
        (when (and (> added 0) mode-sym)
          (log/info :fn 'my-spell-check/add-words-to-jinx
                    :msg (format "Added %d words for %s to %s dictionary."
                                 added mode-sym location)
                    :obj mode-sym))
        ;; Safe recheck (always works)
        (jinx--recheck-overlays))))
  )

;;;; Miscellaneous

;; save the bookmarks file every time a bookmark is made or deleted
;; rather than waiting for Emacs to be killed.  Useful especially when
;; Emacs is a long running process.
(setopt bookmark-save-flag 1)

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
;;(setopt Man-notify-method 'aggressive)

;; keep the Ediff control panel in the same frame
(setopt ediff-window-setup-function
        'ediff-setup-windows-plain)

;; Make shebang (#!) file executable when saved
(add-hook 'after-save-hook
          #'executable-make-buffer-file-executable-if-script-p)
          
;; Turn on repeat mode to allow certain keys to repeat on the last
;; keystroke. For example, C-x [ to page backward, after pressing this
;; keystroke once, pressing repeated [ keys will continue paging
;; backward. `repeat-mode' is exited with the normal C-g, by movement
;; keys, typing, or pressing ESC three times.
(repeat-mode 1)

(log/debug :fn 'defaults-config
           :msg "Ending load of the defaults-config module."
           :obj t)

(provide 'defaults-config)
;;; defaults-config.el ends here
