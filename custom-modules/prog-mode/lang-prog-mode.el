;;; lang-prog-mode.el --- parent mode for programming -*- lexical-binding: t; -*-

;;; Commentary:

;; Functionality common across all lang settings.
;;

;;; Code:
(require 'path-support)
(require 'logging-config)
(log/debug :fn 'lang-prog-mode
           :msg "Starting load of the lang-prog-mode module."
           :obj t)
(require 'menu-keys-support)

(defvar display-line-numbers-type)                                                ; variable from display-line-numbers - show relative or absolute line numbers.

;; Provide an autosave hook.
(defun my-prog-mode/auto-save-hook ()
  "Enable auto-saving in `prog-mode' buffers."
  (when buffer-file-name
    (setq-local compilation-ask-about-save nil)))


;;;; Handling interpreted code
;; I was using insert-shebang but learned that Emacs already has functionality
;; built in via executable.el.

;; Load the built-in executable library
(require 'executable)

;; (defcustom executable-insert t
;;   "Non-nil means offer to add a magic number to a file.
;; This takes effect when you switch to certain major modes,
;; including Shell-script mode (`sh-mode').
;; When you type \\[executable-set-magic], it always offers to add or
;; update the magic number."
;;   :type 'boolean)
;; (defcustom executable-prefix-env nil
;;   "If non-nil, use \"/usr/bin/env\" in interpreter magic number.
;; If this variable is non-nil, the interpreter magic number inserted
;; by `executable-set-magic' will be \"#!/usr/bin/env INTERPRETER\",
;; otherwise it will be \"#!/path/to/INTERPRETER\"."
;;   :version "26.1"
;;   :type 'boolean)
;; (defcustom executable-chmod 73
;;   "After saving, if the file is not executable, set this mode.
;; This mode passed to `set-file-modes' is taken absolutely when negative, or
;; relative to the files existing modes.  Do nothing if this is nil.
;; Typical values are 73 (+x) or -493 (rwxr-xr-x)."
;;   :type '(choice integer
;;                  (const nil)))
;; Query behaviour:
;; (defcustom executable-query 'function
;;   "If non-nil, ask user before changing an existing magic number.
;; When this is `function', only ask when called non-interactively."
;;   :type '(choice (const :tag "Don't Ask" nil)
;; 		 (const :tag "Ask when non-interactive" function)
;;                  (other :tag "Ask" t)))

(setq executable-insert t                                                         ; always offer to insert
      executable-prefix-env t                                                     ; use \"/usr/bin/env\" in interpreter magic number.
      executable-prefix "#! "                                                     ; default is "#!" so this just shows you the variable exists. 
      executable-chmod 73                                                         ; octal for 0755. Alternatively, executable-chmod t would do chmod +x after insert
      executable-query t)                                                         ; ask user before changing an existing magic number.

;; Exclude files that shouldn't get shebangs (adapt your ignore list to a regexp;
;; this matches .txt, .org, .el, .tex, .csv, .pdf, .json, etc.)
;; (defcustom executable-magicless-file-regexp "/[Mm]akefile$\\|/\\.\\(z?profile\\|bash_profile\\|z?login\\|bash_login\\|z?logout\\|bash_logout\\|.+shrc\\|esrc\\|rcrc\\|[kz]shenv\\)$"
;;   "On files with this kind of name no magic is inserted or changed."
;;   :type 'regexp)

;;;;; My version of executable-magicless-file-regexp
;; I've tried to reconstruct the original executable-magicless-file-regexp in a
;; readable way. First, the Makefile part: matches /Makefile or /makefile at
;; end of path.
(defvar my-magicless-makefile-regexp "/[Mm]akefile$"
  "Regexp for Makefile variants to exclude from shebang insertion.")

;; Next, fixed shell dotfile literals: exact names like .profile, .zprofile, etc.
;; We expand patterns like z?profile into explicit strings for regexp-opt.
(defvar my-magicless-fixed-dotfiles
  '("profile" "zprofile"                                                          ; From z?profile
    "bash_profile"
    "login" "zlogin"                                                              ; From z?login
    "bash_login"
    "logout" "zlogout"                                                            ; From z?logout
    "bash_logout"
    "esrc" "rcrc"
    "kshenv" "zshenv")                                                            ; From [kz]shenv
  "List of exact shell dotfile base-names to exclude.")

(defvar my-magicless-fixed-dotfiles-regexp
  (concat "/\\." (regexp-opt my-magicless-fixed-dotfiles) "$")
  "Optimised regexp for fixed shell dot files.")

;; Finally, variable shell dot files: regex for .+shrc (e.g., .bashrc, .zshrc).
(defvar my-magicless-variable-dotfiles-regexp "/\\..+shrc$"
  "Regexp for variable-length shrc dot files.")

;; Combine original parts with alternation for efficiency.
(defvar my-magicless-original-regexp
  (concat my-magicless-makefile-regexp "\\|"
          my-magicless-fixed-dotfiles-regexp "\\|"
          my-magicless-variable-dotfiles-regexp)
  "Readable reconstruction of original `executable-magicless-file-regexp'.")

;; Add ignored extensions: simple endings like .txt, .org, etc.
;; Use regexp-opt for optimised grouping.
(defvar my-added-ignore-extensions '("txt" "org" "el" "tex" "csv" "pdf" "json")
  "List of file extensions to ignore for shebang insertion.")

(defvar my-added-ignore-regexp
  (concat "\\.\\(" (regexp-opt my-added-ignore-extensions) "\\)$")
  "Regexp for added ignore extensions, matching full path endings.")

;; Set the variable to combine original and added, preserving defaults.
(setq executable-magicless-file-regexp
      (concat my-magicless-original-regexp "\\|" my-added-ignore-regexp))

;;; Custom Programming dictionaries
;; The below should be used with a mode specific constant containing words
;; which might not be in standard English but should be ignored for the given
;; coding language. This can be done hierarchically so for example defining
;; `my-prog-mode/prog-mode-accepted-words' for generic prog-mode words then
;; `my-prog-mode/python-mode-accepted-words' for python specific words will
;; work provided `my-prog-mode/add-words-to-jinx' is run for the `prog-mode'
;; and `python-mode' contexts.
;;
;; Example:  python-mode
;; ---------------------
;; ;; Defining the below `defconst' and then running
;; ;;`my-prog-mode/add-mode-specific-words-to-jinx' causes these words to be
;; ;; ignored in a spell check of that language with jinx. This is done by
;; ;; adding words to the variable `ispell-buffer-session-localwords' in the
;; ;; local buffer.
;; (defconst my-prog-mode/python-mode-accepted-words
;;   '("def" "class" "import" "from" "as" "return" "yield"
;;     "async" "await" "self" "cls" "None" "True" "False")
;;   "Python-specific keywords often appearing in comments/docstrings.")
;;
;; (my-prog-mode/add-words-to-jinx
;;    my-prog-mode/python-mode-accepted-words 'prog-mode)


;;;; Configuration for all programming modes.
(defun my-prog-mode/programming-mode-config-hook ()
  "Set useful layout tweaks for programming modes."
  (interactive)
  
  (require 'eldoc)
  (require 'eldoc-box)
  (eldoc-mode 1)                                                                  ; enable eldoc-mode.
  ;; Set programming modes to pick up the custom prog-mode face.
  ;; (after theme-support has defined the face.)
  (when (facep 'my-font-faces/prog-mode-face)
    (face-remap-add-relative 'default 'my-font-faces/prog-mode-face))

  (setq-local display-line-numbers-type 'absolute)
  (display-line-numbers-mode)                                                     ; activate line numbers.
  (set-face-attribute 'line-number nil :height 0.8)
  
  ;; Auto-save files.
  (my-prog-mode/auto-save-hook)

  ;; (set-face-attribute 'line-number-current-line nil :height `unspecified)
  ;; careful with `line-number-current-line. - setting line size changes for
  ;; the line number current line causes the text to indent slightly. I find
  ;; it quite annoying.

  ;; make the left and right fringe-mode 5 and 10 pixels respectively.
  ;; (left is narrower because it  has a following line number adding thickness)
  (fringe-mode '(5 . 10))

  ;; show the fill column with an indicator line
  (setq-local display-fill-column-indicator-column t)
  (display-fill-column-indicator-mode)
  
  ;; ensure changes are visible in the buffer.
  ;; (highlight-changes-mode)

  ;; (setq yas-use-menu 'abbreviate)                                              ; show only the snippets for the mode of the buffer.

  ;; Set up the Jinx spell checker. 
  (jinx-mode 1)
  ;; Common programming words (you can run this manually per project)
  (defconst my-prog-mode/prog-mode-accepted-words
    '("bashrc" "zshrc" "foo" "bar" "foobar" "idx" "dotfile" "tstamp" "tex" "csv" "pdf"
      "ARGS" "Args" "Backtrace" "bmk" "bmenu" "DDirectory" "LaTeX" "LocalWords" "OPTARG"
      "README" "SPEEDBAR" "TODO" "alist" "autosave" "aspell" "basedpyright" "cd" "chmod" "chown" "concat" "const" "conda"
      "config" "csv" "defconst" "defcustom" "defvar" "dir" "docstring" "dotfile" "dotfiles"
      "docstrings" "Eglot" "eglot" "el" "elpa" "Emacs" "emacs"  "env" "flymake" "flyspell" 
      "github" "gitignore" "hdb" "http" "https" "ipynb" "ipython" "jdk" 
      "joinpath" "json" "jsonl" "keymap" "keymaps" "lang" "lvl" "makefile" "md" "mnt" "modeline" "noqa" "odbc" 
      "prog" "py" "rlwrap" "scipy" "sudo" "setq" "speedbar" "sql" "str" "sym" "systemd" "journalctl" "tmp" 
      "txt" "urls" "usr" "vterm" "ws" "yas" "yasmate" "yasnippet")
    "Words commonly accepted in all programming modes.
Run `M-x my-spell-check/add-prog-words` once per project to add them.")

  (my-spell-check/add-words-to-jinx
   my-prog-mode/prog-mode-accepted-words 'session 'prog-mode)
  
  (setq-local truncate-lines t)                                                   ; deactivate line-wrapping.

  ;; Keymaps and Menus
  ;; Assign buffer local prefixes to comment keymap.
  (local-set-key
   (kbd my-custom-prefix-keys/comment) 'my-key-maps/comments)


  ;; Create comment menu including those new buffer local keymaps.
  (easy-menu-define my-prog-mode-menu                                             ; symbol-name
    (current-local-map)                                                           ; maps
    "Menu for comment-related functions."                                         ; docs
    my-custom-menus/comment)                                                 ; menu

  )


;;; Hooks

;; add the programming mode config to prog-mode
(add-hook 'prog-mode-hook #'my-prog-mode/programming-mode-config-hook)

(log/debug :fn 'lang-prog-mode
           :msg "Ending load of the lang-prog-mode module."
           :obj t)

(provide 'lang-prog-mode)
;;; lang-prog-mode.el ends here

;; Local Variables:
;; jinx-local-words: "akefile magicless"
;; End:
