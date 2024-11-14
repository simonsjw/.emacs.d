;;; q-parse.el --- Syntax highlighting and modes for KDB/Q -*- lexical-binding: t; -*-

;; Author: Simon Watson
;; Version: 0.9
;; Keywords: KDB, Q, syntax highlighting
;; URL: https://github.com/simonsjw/q-loadbalancer
;; Package-Requires: (Emacs "24.3")

;;; Commentary:

;; This package provides syntax highlighting and mode definitions for editing Q scripts.
;;
;; This package provides functionality to parse q code for font locking.
;; There are two modes:
;; *   q-script-mode
;;     This mode is to be used for all buffers which show Q script
;;
;; *   q-loadbalancer-mode
;;     This mode is to be used on buffers which connect to a Q process.
;;
;; Functionality for creating groups of attached processes is provided in
;; q-loadbalancer.el
;;
;; The connection details to be used with q-loadbalancer.el are stored in
;; process-groups.el.

;;; Code:
(require 'comint)
(defvar comint-prompt-regexp)

;;  Additional faces for font-locking.

;;; Parsing/Font locking
;;  --------------------

;; Define the face group
(defgroup q-log-faces nil
  "Faces for highlighting q log messages."
  :group 'faces)

;; Define custom faces for different log levels
(unless (facep 'q-log-level-err-face)
  (defface q-log-level-err-face
    '((t :foreground "#9D1F1F")
      )
    "Face for ERROR log level."
    :group 'q-log-faces))
(unless (facep 'q-log-level-warn-face)
  (defface q-log-level-warn-face
    '((t :foreground "#CB4B16"))
    "Face for WARN log level."
    :group 'q-log-faces)
  )

(unless (facep 'q-log-level-info-face)
  (defface q-log-level-info-face
    '((t :foreground "#729FCF"))
    "Face for INFO log level."
    :group 'q-log-faces)
  )

(unless (facep 'q-log-level-debug-face)
  (defface q-log-level-debug-face
    '((t :foreground "#3465A4"))
    "Face for DEBUG log level."
    :group 'q-log-faces)
  )

;; Define faces for log highlighting
(unless (facep 'q-log-delimiter-face)
  (defface q-log-delimiter-face
    '((t :foreground "#696969"))
    "Face for log delimiters (e.g., brackets)."
    :group 'q-log-faces)
  )

(unless (facep 'q-log-datetime-face)
  (defface q-log-datetime-face
    '((t :foreground "#5A6800"))
    "Face for log date and time components."
    :group 'q-log-faces)
  )

(unless (facep 'q-log-process-face)
  (defface q-log-process-face
    '((t :foreground "#A6BE00"))
    "Face for log process information."
    :group 'q-log-faces)
  )

(unless (facep 'q-log-message-face)
  (defface q-log-message-face
    '((t :foreground "#4F9C02"))
    "Face for the main log message."
    :group 'q-log-faces)
  )

(unless (facep 'q-log-object-face)
  (defface q-log-object-face
    '((t :foreground "#61647A"))
    "Face for the main log message."
    :group 'q-log-faces)
  )


;; single line regex.
;; "\\_<\\([.]?[a-zA-Z]\\(?:\\s_\\|\\w\\|_\\)*\\s-*\\)::?\\s-*\\(?:{\\|'\\s-*\\[\\|[^;{\n]*?\\(?:::\\|[-.~=!@#$%^&*_+|,<>?/\\:']\\)\\s-*\\(?:\\s<\\|$\\|;\\)\\)"
(defvar q-function-regex
  (concat
   "\\_<"                                                                      ; Match the start of a symbol or word (word boundary)
   "\\([.]?[a-zA-Z]"                                                           ; Match an optional dot followed by a letter, indicating a namespace or identifier
   "\\(?:\\s_\\|\\w\\|_\\)*"                                                   ; Followed by any combination of symbol characters, word characters, or underscores
   "\\s-*"                                                                     ; Optional whitespace after the identifier
   "\\)::?"                                                                    ; Close the group and match optional `::` for local and global functions
   "\\s-*"                                                                     ; Optional whitespace after `::`
   "\\(?:{\\|'\\s-*\\[\\|[^;{\n]*?"                                            ; Match function bodies, parameter lists, or certain characters
   "\\(?:::\\|[-.~=!@#$%^&*_+|,<>?/\\:']\\)\\s-*"                              ; Handle operators or `::`, followed by optional white-space
   "\\(?:\\s<\\|$\\|;\\)\\)"                                                   ; End with comments, end-of-line, or semicolon
   )
  
  "Regular expression used to find function declarations.

   This regex matches a variety of function declarations in `q`, supporting:
   - Namespaced functions, like `.namespace.function'
   - Functions declared using `{}' or parameter lists
   - Handles both global (`::') and local functions
   - Ends cleanly at comments, newlines, or semicolons.
  
   Examples:
   - function: `myFunc::\ {x+y}'
   - `.ns.myFunc\ {x*y}'
   - `sum::\[x\;y\]\ x+y'")


;; (defvar q-variable-regex
;;   (concat
;;    "\\_<"                                                                      ; Match the start of a symbol or word (word boundary)
;;    "\\([.]?[a-zA-Z]"                                                           ; Match an optional dot followed by a letter, indicating a namespace or identifier
;;    "\\(?:\\s_\\|\\w\\|_\\)*"                                                   ; Followed by any combination of symbol characters, word characters, or underscores
;;    "\\s-*"                                                                     ; Optional whitespace after the identifier
;;    "\\)[-.~=!@#$%^&*_+|,<>?]?"                                                 ; Optionally match operators such as `-`, `~`, `=`, `!`, and more
;;    "::?")                                                                      ; Match optional `::`, allowing both local and global variable declarations
;;   "Regular expression used to find variable declarations.

;;    This regex matches a variety of variable declarations in `q', supporting:
;;    - Namespaced variables
;;    - Variables that may include operators in their assignment (e.g., `+=')
;;    - Handles both global (`::') and local variables.

;;    Examples:
;;    - `myVar::\ 42'
;;    - `.config.setting::\ 'enabled'
;;    - `counter\ +=\ 1'")




(defvar q-variable-regex
  "\\_<\\([.]?[a-zA-Z]\\(?:\\s_\\|\\w\\|_\\)*\\s-*\\)[-.~=!@#$%^&*_+|,<>?]?::?"
  "Regular expression used to find variable declarations.")

(defvar q-keywords
  (eval-when-compile
    (regexp-opt
     '("abs" "acos" "asin" "atan" "avg" "bin" "binr" "by" "cor" "cos" "cov"
       "dev" "delete" "div" "do" "enlist" "exec" "exit" "exp" "from" "getenv"
       "hopen" "if" "in" "insert" "last" "like" "log" "max" "min" "prd"
       "select" "setenv" "sin" "sqrt" "ss" "sum" "tan" "update" "var" "wavg"
       "while" "within" "wsum" "xexp")
     `words)
    )
  "Keywords for q mode.")

(defvar q-type-words
  (eval-when-compile
    (concat "\\(`"
            (regexp-opt '("boolean" "byte" "short" "long" "real" "int" "float" "char" "symbol"
                          "month" "date" "datetime" "minute" "second" "time" "timespan" "timestamp"
                          "year" "mm" "dd" "hh" "uu" "ss" "week")
                        t)
            "\\)\\s-*[$]")
    )
  "Types for q mode.")

(defvar q-builtin-words
  (eval-when-compile
    (concat
     "\\_<"                                                                    ; Match the beginning of a symbol or word (word boundary)
     "\\(?:[.]q[.]\\)?"                                                        ; Optional: Match `.q.` prefix, allowing for functions like `.q.someBuiltin`

     (regexp-opt                                                               ; Use `regexp-opt` to create an efficient regex pattern that matches any of the built-in keywords
      '( "aj" "aj0" "ajf" "ajf0" "all" "and" "any" "asc" "asof" "attr"
         "avgs" "ceiling" "cols" "count" "cross" "csv" "cut" "deltas"
         "desc" "differ" "distinct" "dsave" "each" "ej" "ema" "eval"
         "except" "fby" "fills" "first" "fkeys" "flip" "floor" "get"
         "group" "gtime" "hclose" "hcount" "hdel" "hsym" "iasc" "idesc"
         "ij" "ijf" "inter" "inv" "key" "keys" "lj" "ljf" "load"
         "lower" "lsq" "ltime" "ltrim" "mavg" "maxs" "mcount" "md5"
         "mdev" "med" "meta" "mins" "mmax" "mmin" "mmu" "mod" "msum"
         "neg" "next" "not" "null" "or" "over" "parse" "peach" "pj"
         "prds" "prior" "prev" "rand" "rank" "ratios" "raze" "read0"
         "read1" "reciprocal" "reval" "reverse" "rload" "rotate"
         "rsave" "rtrim" "save" "scan" "scov" "sdev" "set" "show"
         "signum" "ssr" "string" "sublist" "sums" "sv" "svar" "system"
         "tables" "til" "trim" "type" "uj" "ujf" "ungroup" "union"
         "upper" "upsert" "value" "view" "views" "vs" "where" "wj"
         "wj1" "ww" "xasc" "xbar" "xcol" "xcols" "xdesc" "xgroup"
         "xkey" "xlog" "xprev" "xrank"))

     "\\_>"))                                                                  ; Match the end of a symbol or word (word boundary), ensuring complete words are matched
  "Regular expression for highlighting built-in functions in q.k.
   
   This variable defines a regex pattern to match built-in keywords
   from the `q` programming language.  The pattern is optimized for 
   performance using `regexp-opt` and supports matching optional 
   `.q.` prefixes.  It ensures that only whole words or symbols are 
   matched, not sub-strings.

   For example, this regex will match:
   - `aj', `each', `count' (built-in functions)
   - `.q.save', `.q.load' (prefixed built-in functions)"
  )


(defvar q-constant-words
  (eval-when-compile
    (regexp-opt '(".z.D" ".z.K" ".z.T" ".z.Z" ".z.N" ".z.P" ".z.a" ".z.b"
                  ".z.d" ".z.exit" ".z.f" ".z.h" ".z.i" ".z.k" ".z.l" ".z.o"
                  ".z.pc" ".z.pg" ".z.ph" ".z.pi" ".z.po" ".z.pp" ".z.ps"
                  ".z.pw" ".z.s" ".z.t" ".z.ts" ".z.u" ".z.vs" ".z.w" ".z.x"
                  ".z.z" ".z.n" ".z.p" ".z.ws" ".z.bm")
                `words))
  "Constants for q mode.")

(defvar q-font-lock-keywords
  (list '("^\\\\\\_<.*?$" 0 font-lock-constant-face keep)                      ; lines starting with a '\' are compile time
        (list q-function-regex 1 font-lock-function-name-face nil)             ; functions
        )
  "Minimal highlighting expressions for q mode.")


(defvar q-datetime-regex
  (concat

   "\\_<"                                                                      ; Match the start of a symbol or word (word boundary)
   "[0-9]\\{4\\}\\."                                                           ; Four-digit year followed by a dot
   "[0-9]\\{2\\}"                                                              ; Two-digit month
   "\\(?:m\\|"                                                                 ; Non-capturing group for 'm' (month) or...
   "\\.[0-9]\\{2\\}"                                                           ; ...a two-digit day prefixed by a dot
   "\\(?:T\\(?:[0-9]\\{2\\}"                                                   ; Optional: Start of a timestamp with 'T' and two-digit hour
   "\\(?::[0-9]\\{2\\}"                                                        ; Optional: Colon and two-digit minutes
   "\\(?::[0-9]\\{2\\}"                                                        ; Optional: Colon and two-digit seconds
   "\\(?:\\.[0-9]*\\)?\\)?\\)?\\)?\\)?\\)"                                     ; Optional: Decimal fraction for seconds
   "\\_>"                                                                      ; End of symbol boundary
   )
  "Regular expression to match date and datetime formats.

   This regex matches:
   - Dates like `2023.10m` (year and month)
   - Full datetimes like `2023.10.12T15:30:00.123`
     (optional hour, minute, second, and fractional second)

   Examples:
   - `2023.10m`
   - `2023.10.12`
   - `2023.10.12T15:30:45.678`"
  )

(defvar q-timespan-timestamp-regex
  (concat
   "\\_<"                                                                      ; Match the start of a symbol or word (word boundary)
   "\\(?:[0-9]\\{4\\}\\.[0-9]\\{2\\}\\.[0-9]\\{2\\}"                           ; Full date (year.month.day)
   "\\|[0-9]+\\)D"                                                             ; Or digits followed by 'D' for timespan
   "\\(?:[0-9]\\(?:[0-9]\\(?::[0-9]\\{2\\}"                                    ; Optional: Hours, minutes, seconds
   "\\(?::[0-9]\\{2\\}\\(?:\\.[0-9]*\\)?\\)?\\)?\\)?\\)?\\_>"                  ; Optional: Decimal for fractions of a second
   )
  "Regular expression to match timespan and timestamp patterns.

   This regex matches:
   - Full dates and timespans, such as `2023.10.12D`
   - Time components, including optional fractional seconds

   Examples:
   - `2023.10.12D`
   - `12D23:45:30.12`"
  )

(defvar q-guid-regex
  (concat
   "\\_<"                                                                      ; Match the start of a symbol or word (word boundary)
   "[0-9a-f]\\{8\\}"
   "-"
   "[0-9a-f]\\{4\\}"
   "-"
   "[0-9a-f]\\{4\\}"
   "-"
   "[0-9a-f]\\{4\\}"
   "-"
   "[0-9a-f]\\{12\\}" ; Match typical GUID format
   "\\_>"                                                                      ; Match the end of a symbol or word (word boundary)
   )
  "Regular expression to match GUIDs (Globally Unique Identifiers).

   This regex identifies a typical GUID structure, consisting of:
   - Five segments separated by hyphens
   - The first segment is 8 hexadecimal characters
   - The second, third, and fourth segments are each 4 hexadecimal characters
   - The fifth segment is 12 hexadecimal characters

   Examples:
   - `123e4567-e89b-12d3-a456-426614174000`
   - `abcdef01-2345-6789-abcd-0123456789ab`"
  )

(defvar q-time-regex
  (concat
   "\\_<"                                                                      ; Match the start of a symbol or word (word boundary)
   "[0-9]\\{2\\}:[0-9]\\{2\\}"                                                 ; Two digits for hours, followed by a colon and two digits for minutes
   "\\(?::[0-9]\\{2\\}"                                                        ; Optional: Colon and two digits for seconds
   "\\(?:\\.[0-9]\\|\\.[0-9]\\{2\\}\\|\\.[0-9]\\{3\\}\\)?\\)?\\_>"             ; Optional: Dot followed by 1, 2, or 3 digits for fractional seconds
   )
  "Regular expression to match time components.

Includes optional seconds and fractional seconds.

   This regex matches time formats that include:
   - Mandatory hours and minutes (e.g., `12:34`)
   - Optional seconds (e.g., `12:34:56`)
   - Optional fractional seconds, supporting 1 to 3 decimal places
     (e.g., `12:34:56.7`, `12:34:56.78`, `12:34:56.789`)

   Examples:
   - `14:30`
   - `23:59:45`
   - `08:05:03.1`
   - `12:00:00.123`"
  )



(defvar q-font-lock-keywords-1                                                 ; types
  (append q-font-lock-keywords
          (list
           '("`:\\(?:\\w\\|[/:._]\\)*"                                         ; Match a `\`:' prefix followed by word characters or [`/:._']
             . font-lock-preprocessor-face)                                    ; files        - Examples: `:file/path', `:user.name'
           '("\\(`\\_<[gpsu]\\)#"                                              ; Match '` followed by `g`, `p', `s', or `u', and a `'
             1 font-lock-type-face nil)                                        ; attributes   - Examples: `g\#', `s\#'
           '("^'.*?$"                                                          ; Match a line starting with a single quote and ending anywhere (lazy match)
             0 font-lock-warning-face nil)                                     ; error        - Examples: `\'UnexpectedError', `\'SomeMessage'
           '("[; ]\\('`\\w*\\)"                                                ; Match a semicolon or space, followed by a backtick and word characters
             1 font-lock-warning-face nil)                                     ; signal       - Examples: `;\`backtickWord', `\ \`backtickError'
           '("`\\(?:\\(?:\\w\\|[.]\\)\\(?:\\s_\\|\\w\\|_\\)*\\)?"              ; Match backtick, optionally followed by word or dot characters, then word or symbol characters
             . font-lock-constant-face)                                        ; symbols      - Examples: `\`symbol', `\`s.1'
           '("\\b[0-2]:"                                                       ; Match word boundary followed by digits 0, 1, or 2, and a colon
             . font-lock-preprocessor-face)                                    ; IO/IPC       - Examples: `0:', `2:'
           
           (list q-type-words                                                  ; Highlight words defined in `q-type-words` with a type face
                 1 font-lock-type-face nil)                                    ; `minute`year - Examples: `\`minute', `\`year'
           (cons q-keywords 'font-lock-keyword-face)                           ; select from  - Examples: `\`select', `\`from'
           (cons q-builtin-words 'font-lock-builtin-face)                      ; q.k          - Examples: `\`q.k', `\`q.system'
           ))
  "More highlighting expressions for q mode.")

(defvar q-font-lock-keywords-1
  (append q-font-lock-keywords
          (list
           ;; Files
           `(,(rx "`:"
                  (0+ (or wordchar (any "/:._"))))                             ; Backtick followed by ':' and any word or file path characters
             . font-lock-preprocessor-face)

           ;; Attributes
           `(,(rx (group "`"
                         (or "g" "p" "s" "u")
                         "#"))                                                 ; Backtick, attribute letter, then '#'
             1 font-lock-type-face nil)

           ;; Errors
           `(,(rx line-start
                  "'"
                  (0+ not-newline)                                             ; Single quote followed by any content up to end of line
                  line-end)
             0 font-lock-warning-face nil)

           ;; Signals
           `(,(rx (or ";" " ")
                  (group "`" (0+ word)))                                       ; Semicolon or space, followed by a backtick and word characters
             1 font-lock-warning-face nil)

           ;; Symbols
           `(,(rx "`"
                  (optional (seq (or wordchar ".")
                                 (0+ (or symbol-start wordchar "_")))))        ; Optional backtick, optional symbols/word
             . font-lock-constant-face)

           ;; IO/IPC
           `(,(rx word-boundary
                  (char "0-2")                                                 ; Digits 0, 1, or 2
                  ":")
             . font-lock-preprocessor-face)

           ;; q-type-words, q-keywords, q-builtin-words
           `(,q-type-words 1 font-lock-type-face nil)
           `(,q-keywords . font-lock-keyword-face)
           `(,q-builtin-words . font-lock-builtin-face)))
  "More highlighting expressions for q mode.")


(defvar q-font-lock-keywords-2
  (append q-font-lock-keywords-1
          (list
           ;; Constants
           (cons q-constant-words 'font-lock-constant-face)

           ;; Variables
           (list q-variable-regex 1 'font-lock-variable-name-face nil)

           ;; Date, time, and GUID regexes
           (cons q-datetime-regex 'font-lock-constant-face)
           (cons q-timespan-timestamp-regex 'font-lock-constant-face)
           (cons q-guid-regex 'font-lock-constant-face)
           (cons q-time-regex 'font-lock-constant-face)

           ;; Floating point and real numbers
           `(,(rx word-start
                  (0+ digit)
                  (optional ".")
                  (0+ digit)
                  (optional (char "eE") (optional (char "+-")) (1+ digit))
                  (optional (char "ef"))
                  word-end)
             . font-lock-constant-face)

           ;; Char, real, float, short, int, long, time-type suffixes
           `(,(rx word-start
                  (1+ digit)
                  (optional (char "cefhijnptuv"))
                  word-end)
             . font-lock-constant-face)

           ;; Boolean values
           `(,(rx word-start
                  (char "01")
                  (char "b")
                  word-end)
             . font-lock-constant-face)

           ;; Byte values in hexadecimal
           `(,(rx word-start
                  "0x"
                  (1+ hex-digit)
                  word-end)
             . font-lock-constant-face)

           ;; Null and infinity representations
           `(,(rx word-start
                  "0"
                  (char "nNwW")
                  (optional (char "cefghijmndzuvtp"))
                  word-end)
             . font-lock-constant-face)

           ;; Highlight TODO-like comments
           `(,(rx (or "TODO" "NOTE") (optional ":"))
             0 font-lock-warning-face t)))

  "Most highlighting expressions for q mode.

   This list defines regular expressions used for highlighting key
   syntactic elements in `q` code, including:
   - Constants, variables, dates, times, GUIDs, and numeric types
   - TODO markers for comments or annotations

   Examples of matches:
   - Date: `2023.10m`, `2023.10.12T15:30`
   - Timespan/Timestamp: `2023.10.12D`, `12:34:56.789`
   - GUID: `123e4567-e89b-12d3-a456-426614174000`
   - Float: `1.23e-4`, `42.5f`
   - Boolean: `1b`, `0b`
   - Byte: `0x1A3F`
   - Null/Infinity: `0N`, `0n`, `0w`
   - TODO: `TODO`, `NOTE:`"
  )


(defvar q-font-lock-defaults
  '((q-font-lock-keywords q-font-lock-keywords-1 q-font-lock-keywords-2)
    nil nil nil nil
    (font-lock-syntactic-keywords
     . (("^\\(\/\\)\\s-*$"     1 "< b")                                        ; begin multiline comment /
        ("^\\(\\\\\\)\\s-*$"   1 "> b")                                        ; end multiline comment   \
        ("\\(?:^\\|[ \t]\\)\\(\/\\)"    1 "<  ")                               ; comments start flush left or after white space
        ("\\(\"\\)\\(?:[^\"\\\\]\\|\\\\.\\)*?\\(\"\\)" (1 "\"") (2 "\""))
        )))
  "List of font lock keywords to properly highlight q syntax.")


;; syntax table

(defvar q-loadbalancer-mode-syntax-table
  (let ((table (make-syntax-table)))
    (modify-syntax-entry ?\" ".  " table)                                      ; treat " as punctuation
    (modify-syntax-entry ?\/ ".  " table)                                      ; treat / as punctuation
    (modify-syntax-entry ?\n ">  " table)                                      ; comments are ended by a new line
    (modify-syntax-entry ?\r ">  " table)                                      ; comments are ended by a new line
    (modify-syntax-entry ?\. "_  " table)                                      ; treat . as a symbol
    (modify-syntax-entry ?\_ ".  " table)                                      ; treat _ as punctuation
    (modify-syntax-entry ?\\ ".  " table)                                      ; treat \ as punctuation
    (modify-syntax-entry ?\$ ".  " table)                                      ; treat $ as punctuation
    (modify-syntax-entry ?\% ".  " table)                                      ; treat % as punctuation
    (modify-syntax-entry ?\& ".  " table)                                      ; treat & as punctuation
    (modify-syntax-entry ?\+ ".  " table)                                      ; treat + as punctuation
    (modify-syntax-entry ?\, ".  " table)                                      ; treat , as punctuation
    (modify-syntax-entry ?\- ".  " table)                                      ; treat - as punctuation
    (modify-syntax-entry ?\= ".  " table)                                      ; treat < as punctuation
    (modify-syntax-entry ?\* ".  " table)                                      ; treat * as punctuation
    (modify-syntax-entry ?\< ".  " table)                                      ; treat < as punctuation
    (modify-syntax-entry ?\> ".  " table)                                      ; treat > as punctuation
    (modify-syntax-entry ?\| ".  " table)                                      ; treat | as punctuation
    (modify-syntax-entry ?\` "_  " table)                                      ; treat ` as symbol
    table)
  "Syntax table for `q-script-mode'.")

(defun my-show-paren-ignore-q-prompt ()
  "Ignore `q)` as a matching parenthesis in show-paren-mode."
  (let ((pos (point)))
    (save-excursion
      (beginning-of-line)
      (if (looking-at "^q)")  ; Match `q)` at the start of the line
          ;; Do nothing (return nil to ignore this match)
          nil
        ;; Otherwise, use the default behavior
        (show-paren--default)))))

(defun q-paren-ignore ()
  "Set `show-paren-data-function` to ignore `q)` prompts in comint."
  (setq-local show-paren-data-function #'my-show-paren-ignore-q-prompt))


(provide 'q-parse)

;;; q-parse.el ends here

                                        ; LocalWords:  cefhijnptuv ij
                                        ; LocalWords:  assword concat
                                        ; LocalWords:  cefghijmndzuvtp
                                        ; LocalWords:  xgroup msum mins signum xlog pj
                                        ; LocalWords:  loadbalancer
                                        ; LocalWords:  loadBalancer
