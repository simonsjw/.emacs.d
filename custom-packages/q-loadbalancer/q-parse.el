;;; q-parse.el --- Manage KDB/Q processes via Emacs Lisp

;; Author: Simon Watson
;; Version: 0.9
;; Keywords: KDB, Q, process management, Emacs Lisp
;; Package-Requires: ((emacs "24.3") (q-mode "1.0"))

;;; Commentary:
;;
;; This package provides functionality to parse q code for font locking.
;;



(defvar comint-prompt-regexp)

;;  Additional faces for font-locking.

;;; Parsing/Font locking
;;  --------------------

;; Define the face group
(defgroup q-log-faces nil
  "Faces for highlighting q log messages."
  :group 'faces)

;; Define faces for log highlighting
(unless (facep 'q-log-delimiter-face)
  (defface q-log-delimiter-face
    '((t :foreground "#696969"))
    "Face for log delimiters (e.g., brackets)."
    :group 'q-log-faces)
  )

(unless (facep 'q-log-datetime-face)
  (defface q-log-datetime-face
    '((t :foreground "dark green"))
    "Face for log date and time components."
    :group 'q-log-faces)
  )

(unless (facep 'q-log-level-face)
  (defface q-log-level-face
    '((t :foreground "deep pink"))
    "Face for log date and time components."
    :group 'q-log-faces)
  )

(unless (facep 'q-log-process-face)
  (defface q-log-process-face
    '((t :foreground "purple"))
    "Face for log process information."
    :group 'q-log-faces)
  )

(unless (facep 'q-log-message-face)
  (defface q-log-message-face
    '((t :foreground "yellow"))
    "Face for the main log message."
    :group 'q-log-faces)
  )


(defvar q-function-regex
  (concat
   "\\_<"                                                                      ; Match the start of a symbol or word (word boundary)
   "\\([.]?[a-zA-Z]"                                                           ; Match an optional dot followed by a letter, indicating a namespace or identifier
   "\\(?:\\s_\\|\\w\\|_\\)*"                                                   ; Followed by any combination of symbol characters, word characters, or underscores
   "\\s-*"                                                                     ; Optional whitespace after the identifier
   "\\)::?"                                                                    ; Close the group and match optional `::` for local and global functions
   "\\s-*"                                                                     ; Optional whitespace after `::`
   "\\(?:{\\|'\\s-*\\[\\|[^;{\n]*?"                                            ; Match function bodies, parameter lists, or certain characters
   "\\(?:::\\|[-.~=!@#$%^&*_+|,<>?/\\:']\\)\\s-*"                              ; Handle operators or `::`, followed by optional whitespace
   "\\(?:\\s<\\|$\\|;\\)")                                                     ; End with comments, end-of-line, or semicolon
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


(defvar q-variable-regex
  (concat
   "\\_<"                                                                      ; Match the start of a symbol or word (word boundary)
   "\\([.]?[a-zA-Z]"                                                           ; Match an optional dot followed by a letter, indicating a namespace or identifier
   "\\(?:\\s_\\|\\w\\|_\\)*"                                                   ; Followed by any combination of symbol characters, word characters, or underscores
   "\\s-*"                                                                     ; Optional whitespace after the identifier
   "\\)[-.~=!@#$%^&*_+|,<>?]?"                                                 ; Optionally match operators such as `-`, `~`, `=`, `!`, and more
   "::?")                                                                      ; Match optional `::`, allowing both local and global variable declarations
  "Regular expression used to find variable declarations.

   This regex matches a variety of variable declarations in `q', supporting:
   - Namespaced variables
   - Variables that may include operators in their assignment (e.g., `+=')
   - Handles both global (`::') and local variables.

   Examples:
   - `myVar::\ 42'
   - `.config.setting::\ 'enabled'
   - `counter\ +=\ 1'")

(defvar q-keywords
  (eval-when-compile
    (regexp-opt
     '("abs" "acos" "asin" "atan" "avg" "bin" "binr" "by" "cor" "cos" "cov"
       "dev" "delete" "div" "do" "enlist" "exec" "exit" "exp" "from" "getenv"
       "hopen" "if" "in" "insert" "last" "like" "log" "max" "min" "prd"
       "select" "setenv" "sin" "sqrt" "ss" "sum" "tan" "update" "var" "wavg"
       "while" "within" "wsum" "xexp")
     `words))
  "Keywords for q mode.")

(defvar q-type-words
  (eval-when-compile
    (concat "\\(`"
            (regexp-opt
             '("boolean" "byte" "short" "long" "real" "int" "float" "char"
               "symbol" "month" "date" "datetime" "minute" "second" "time"
               "timespan" "timestamp" "year" "mm" "dd" "hh" "uu" "ss" "week")
             t)
            "\\)\\s-*[$]"))
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
   from the `q` programming language. The pattern is optimized for 
   performance using `regexp-opt` and supports matching optional 
   `.q.` prefixes. It ensures that only whole words or symbols are 
   matched, not substrings.

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


(defvar q-font-lock-keywords-2                                                 ; keywords & literals
  (append q-font-lock-keywords-1
          (list
           (cons q-constant-words 'font-lock-constant-face)                    ; .z.* ; constants
           (list q-variable-regex 1 'font-lock-variable-name-face nil)         ; variables

           ;; Use the defined regex variables with explicit list notation
           (cons q-datetime-regex 'font-lock-constant-face)                    ; Apply the month/date/datetime face
           (cons q-timespan-timestamp-regex 'font-lock-constant-face)          ; timespan/timestamp
           (cons q-guid-regex 'font-lock-constant-face)                        ; GUID
           (cons q-time-regex 'font-lock-constant-face)                        ; time

           '("\\<[0-9]*[0-9.][0-9]*\\(?:[eE][+-]?[0-9]+\\)?[ef]?\\>"
             . font-lock-constant-face)                                        ; Match float/real numbers (e.g., `123.45`, `1.2e3`)

           '("\\_<[0-9]+[cefhijnptuv]?\\_>"
             . font-lock-constant-face)                                        ; Match char/real/float/short/int/long/time-types (e.g., `42f`, `100h`)

           '("\\_<[01]+b\\_>"
             . font-lock-constant-face)                                        ; Match boolean values (e.g., `0b`, `1b`)

           '("\\_<0x[0-9a-fA-F]+\\_>"
             . font-lock-constant-face)                                        ; Match byte values in hexadecimal (e.g., `0x1A3F`)

           '("\\_<0[nNwW][cefghijmndzuvtp]?\\_>"
             . font-lock-constant-face)                                        ; Match null/infinity representations (e.g., `0n`, `0w`, `0N`)

           '("\\(?:TODO\\|NOTE\\)\\:?" 0 font-lock-warning-face t)             ; Highlight TODO-like comments (e.g., `TODO`, `NOTE:`)
           ))
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

(defvar q-mode-syntax-table
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
  "Syntax table for `q-mode'.")


(define-derived-mode q-shell-mode comint-mode "Q-Shell"
  "Major mode for interacting with a q interpreter."
  :syntax-table q-mode-syntax-table
  (add-hook (make-local-variable 'comint-output-filter-functions) 'comint-strip-ctrl-m)
  (setq comint-prompt-regexp "^\\(q)+\\|[^:]*:[0-9]+>\\)")
  (setq font-lock-defaults q-font-lock-defaults)
  (set (make-local-variable 'comint-process-echoes) nil)
  (set (make-local-variable 'comint-password-prompt-regexp) "[Pp]assword")
  
  ;; Add the logging font-lock keywords
  ;; (font-lock-add-keywords
  ;;  nil                                                                         ; Apply to the current buffer
  ;;  `((,(concat
  ;;       "\\(\\[\\)"                                                            ; 1. Opening bracket
  ;;       "\\([0-9]\\{4\\}\\)"                                                   ; 2. Year
  ;;       "\\(\\.\\)"                                                            ; 3. Dot
  ;;       "\\([0-9]\\{2\\}\\)"                                                   ; 4. Month
  ;;       "\\(\\.\\)"                                                            ; 5. Dot
  ;;       "\\([0-9]\\{2\\}\\)"                                                   ; 6. Day
  ;;       "\\(D\\)"                                                              ; 7. Literal 'D'
  ;;       "\\([0-9]\\{2\\}\\)"                                                   ; 8. Hours
  ;;       "\\(:\\)"                                                              ; 9. Colon
  ;;       "\\([0-9]\\{2\\}\\)"                                                   ; 10. Minutes
  ;;       "\\(:\\)"                                                              ; 11. Colon
  ;;       "\\([0-9]\\{2\\}\\)"                                                   ; 12. Seconds
  ;;       "\\(\\.\\)"                                                            ; 13. Dot
  ;;       "\\(\\([0-9]+\\)\\)"                                                   ; 14. Milliseconds
  ;;       "\\(\\;\\)"                                                            ; 15. Semicolon
  ;;       "\\([^;]+\\)"                                                          ; 16. Section up to first semicolon
  ;;       "\\(\\;\\)"                                                            ; 17. Semicolon
  ;;       "\\([^;]+\\)"                                                          ; 18. process: Section up to second semicolon
  ;;       "\\(\\;\\)"                                                            ; 19. Semicolon
  ;;       "\\([^;]+\\)"                                                          ; 20. log level: Section up to third semicolon
  ;;       "\\(\\]\\)"                                                            ; 21. Closing bracket
  ;;       ;; "\\(\\.\\)"                                                            ; 22. Catch-all at the end
  ;;       )
  ;;     ;; Highlighting groups
  ;;     (1 'q-log-delimiter-face t)                                                ; Opening bracket
  ;;     (2 'q-log-datetime-face t)                                                   ; Year
  ;;     (3 'q-log-datetime-face t)        
  ;;     (4 'q-log-datetime-face t)                                                 ; Month
  ;;     (5 'q-log-datetime-face t)        
  ;;     (6 'q-log-datetime-face t)                                                 ; Day
  ;;     (7 'q-log-datetime-face t)       
  ;;     (8 'q-log-datetime-face t)                                                 ; Hours
  ;;     (9 'q-log-datetime-face t)        
  ;;     (10 'q-log-datetime-face t)                                                ; Minutes
  ;;     (11 'q-log-datetime-face t)        
  ;;     (12 'q-log-datetime-face t)                                                ; Seconds
  ;;     (13 'q-log-datetime-face t)        
  ;;     (14 'q-log-datetime-face t)                                                ; Milliseconds
  ;;     (15 'q-log-datetime-face t)   
  ;;     (16 'q-log-datetime-face t)                                                   ; log level: Section after date, e.g., process name
  ;;     (17 'q-log-datetime-face t) 
  ;;     (18 'q-log-datetime-face t)                                                 ; process
  ;;     (19 'q-log-datetime-face t) 
  ;;     (20 'q-log-datetime-face t)                                                  ; log message
  ;;     (21 'q-log-datetime-face t)      
  ;;     ;;  (22 'q-log-message-face t)                                                 ; log object
  ;;     )))
  )

(define-derived-mode q-script-mode prog-mode "Q-Script"
  "Major mode for editing Q scripts."
  :syntax-table q-mode-syntax-table
  (setq font-lock-defaults q-font-lock-defaults)
  ;; Any additional setup can go here
  )

(provide 'q-parse)

;;; q-parse.el ends here

                                        ; LocalWords:  cefhijnptuv
                                        ; LocalWords:  assword concat
                                        ; LocalWords:  cefghijmndzuvtp
