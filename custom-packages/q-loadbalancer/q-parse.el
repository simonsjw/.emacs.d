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
(require 'cl-lib)
(require 'cl-seq)
(require 'comint)
(defvar comint-prompt-regexp)
(defvar q-font-lock-keywords)

;;  Additional faces for font-locking.
(message "loading q-parse.el")
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



(defvar q-comments-single-line-regex
  "[[:space:]]/+.*\\|^/+.*"
  "Regex for single line comments starting / or // and allows preceding code.")

(defvar q-comments-multi-line-regex
  "\\(?:^/[[:space:]]*\n\\)\\(?:[^\\]\\|\n\\)*\\(?:^\\\\\\)"
  "Regex for multi line comments starting /and finishing \.")  ;; wip - this can be ended by \ at any point in comment at present.

(defvar q-comments-tag
  (eval-when-compile
    (concat
     "\\_<"                                                                    ; Match the beginning of a symbol or word (word boundary)
     (regexp-opt                                                               ; Key words that can be active in comments.
      '("todo" "TODO" "note" "NOTE"))
     "\\_>"))
  "These key words can be used in comments."
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



(defvar q-variable-regex
  "\\_<\\([.]?[a-zA-Z]\\(?:\\s_\\|\\w\\|_\\)*\\s-*\\)[-.~=!@#$%^&*_+|,<>?]?::?"
  "Regular expression used to find variable declarations.")

(defvar q-data-types
  (concat
   "\\_<"                                                                      ; Match the beginning of a symbol or word (word boundary)
   (regexp-opt                                                                 ; Use `regexp-opt` to create an efficient regex pattern that matches any of the built-in keywords
    '(
      "boolean" "byte" "short" "long" "real" "int" "float" "char" "symbol"
      "month" "date" "datetime" "minute" "second" "time" "timespan" "timestamp"
      "year" "mm" "dd" "hh" "uu" "ss" "week"
      ))
   "\\_>")
  "Regular expression for highlighting data types in q.k.

The pattern is optimized for performance using `regexp-opt`.
It ensures that only whole words or symbols are matched, not sub-strings.

For example, this regex will match:
   - `byte', `long', `char' but not `gigabyte', `longjohn' or `character'."
  )


(defvar q-standalone-operators
  "[~!@#$%^&*_+=|:'<,>.?/-]"                                                   ; note inside an alternative block ^ can't be at the start and - must be at the end.
  "Regular expression for matching standalone Q operators.")

(defvar q-standalone-operators-space-prefix
  "\\(?:[[:space:]]\\|[)\\]}]\\)[_]")

(defvar q-standalone-operators-space-prefix-suffix
  "\\(?:[[:space:]]\\|[])}]\\)\\([.]\\)\\(?:[[:space:]]\\|[[({]\\)")

(defvar q-built-in-namespaces
  "\\(?:[.]q[.]\\|[.]Q[.]\\|[.]j[.]\\|[.]z[.]\\|[.]m[.]\\)[[:word:]]*"
  "Regular expression to match built-in namespaces.

   This regex matches the Q, j, z, and m namespaces to a depth of 1:
       .Q.foo
       .j.k
       .z.bar
       .m.x
   It will not match .Q.foo.bar.")

(defvar q-attributes-and-syntactic-sugar
  (concat
   "\\_<"                                                                      ; Match the beginning of a symbol or word (word boundary)
   (regexp-opt                                                                 ; Use `regexp-opt` to create an efficient regex pattern that matches any of the built-in keywords
    '("g" "p" "s" "u"                                                          ; attributes
      "aj" "aj0" "ajf" "ajf0" "all" "and" "any" "asc" "asof" "attr"            ; syntactic sugar
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
      "xkey" "xlog" "xprev" "xrank"
      "abs" "acos" "asin" "atan" "avg" "bin" "binr" "by" "cor" "cos" "cov"
      "dev" "delete" "div" "do" "enlist" "exec" "exit" "exp" "from" "getenv"
      "hopen" "if" "in" "insert" "last" "like" "log" "max" "min" "prd"
      "select" "setenv" "sin" "sqrt" "ss" "sum" "tan" "update" "var" "wavg"
      "while" "within" "wsum" "xexp"))
   "\\_>")
  "Regular expression for highlighting built-in functions in q.k.

   This variable defines a regex pattern to match built-in keywords
   from the `q` programming language.  The pattern is optimized for
   performance using `regexp-opt`.
   It ensures that only whole words or symbols are matched, not sub-strings.

   For example, this regex will match:
   - `aj', `each', `count' (built-in functions)"
  )




;; (defvar q-font-lock-keywords
;;   (list '("^\\\\\\_<.*?$" 0 font-lock-constant-face keep)                      ; lines starting with a '\' immediately followed by text  compile time functions
;;         (list q-function-regex 1 font-lock-function-name-face nil)
;;         )
;;   "Minimal highlighting expressions for q mode.")

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

(defun q-setup-log-output-font-lock ()
  "Setup font-lock rules for Q log entries.

Assumes form of
    [datetime; process; log-level;function]:message; object (as text)"
  (font-lock-add-keywords
   nil                                                                         ; Apply to the current buffer
   `(
     (,
      (rx (group "[")                                                          ;  1: Opening bracket
          (group (= 4 digit))                                                  ;  2: Four-digit year
          (group ".")                                                          ;  3: Dot separator
          (group (= 2 digit))                                                  ;  4: Two-digit month
          (group ".")                                                          ;  5: Dot separator
          (group (= 2 digit))                                                  ;  6: Two-digit day
          (group "D")                                                          ;  7: `D' character
          (group (= 2 digit))                                                  ;  8: Two-digit hour
          (group ":")                                                          ;  9: Colon separator
          (group (= 2 digit))                                                  ; 10: Two-digit minute
          (group ":")                                                          ; 11: Colon separator
          (group (= 2 digit))                                                  ; 12: Two-digit second
          (group ".")                                                          ; 13: Dot separator
          (group (+ digit))                                                    ; 14: One or more digits (fractional seconds)
          (group ";")                                                          ; 15: Semicolon separator
          (group (+ (not (any ";"))))                                          ; 16: First field (non-semicolon characters)
          (group ";")                                                          ; 17: Semicolon separator
          (group (+ (not (any ";"))))                                          ; 18: Second field (non-semicolon characters)
          (group ";")                                                          ; 19: Semicolon separator
          (group (+ (not (any "]"))))                                          ; 20: Third field (non-closing-bracket characters)
          (group "]:")                                                         ; 21: Closing bracket and colon
          (group (+ (not (any ";"))))                                          ; 22: Fourth field (non-semicolon characters)
          (group ";")                                                          ; 23: Semicolon separator
          (group (0+ any) line-end))                                           ; 24: Everything from here to the end of the line

      ;; Highlighting groups
      (1 'q-log-delimiter-face t)                                              ;  1: Opening bracket
      (2 'q-log-datetime-face t)                                               ;  2: Four-digit year
      (3 'q-log-datetime-face t)                                               ;  3: Dot separator
      (4 'q-log-datetime-face t)                                               ;  4: Two-digit month
      (5 'q-log-datetime-face t)                                               ;  5: Dot separator
      (6 'q-log-datetime-face t)                                               ;  6: Two-digit day
      (7 'q-log-datetime-face t)                                               ;  7: `D' character
      (8 'q-log-datetime-face t)                                               ;  8: Two-digit hour
      (9 'q-log-datetime-face t)                                               ;  9: Colon separator
      (10 'q-log-datetime-face t)                                              ; 10: Two-digit minute
      (11 'q-log-datetime-face t)                                              ; 11: Colon separator
      (12 'q-log-datetime-face t)                                              ; 12: Two-digit second
      (13 'q-log-datetime-face t)                                              ; 13: Dot separator
      (14 'q-log-datetime-face t)                                              ; 14: One or more digits (fractional seconds)
      (15 'q-log-delimiter-face t)                                             ; 15: Semicolon separator
      (16 'q-log-process-face t)                                               ; 16: Process (non-semicolon characters)
      (17 'q-log-delimiter-face t)                                             ; 17: Semicolon separator
      (18 (let ((log-level (match-string 18)))                                 ; 18: Log Level (non-semicolon characters) - Conditional face based on text content
            (cond
             ((or (string= log-level "ERROR") (string= log-level "FATAL"))
              'q-log-level-err-face)
             ((string= log-level "WARN") 'q-log-level-warn-face)
             ((or (string= log-level "INFO") (string= log-level "DEBUG")
                  (string= log-level "SILENT"))
              'q-log-level-info-face)))
          t)
      (19 'q-log-delimiter-face t)                                             ; 19: Semicolon separator
      (20 'q-log-process-face t)                                               ; 20: Current function (non-closing-bracket characters)
      (21 'q-log-delimiter-face t)                                             ; 21: Closing bracket and colon
      (22 'q-log-message-face t)                                               ; 22: Fourth field (non-semicolon characters)
      (23 'q-log-delimiter-face t)                                             ; 23: Semicolon separator
      (24 'q-log-object-face t))                                               ; 24: Everything from here to the end of the line
     )
   )
  )


;; syntax table
(defvar q-script-mode-syntax-table
  (let ((table (make-syntax-table)))

    ;; String delimiter
    (modify-syntax-entry ?\" "\"" table) ; String quote

    ;; white-space
    (modify-syntax-entry ?\; " " table)  ; semi-colon as white-space allows us to define single character operators as punctuation and so handle font-locking based on syntax for them. 
    
    ;; prefixes
    (modify-syntax-entry ?\` "'" table)  ; Treat the back-tick as part of an expression if it appears next to it.

    ;; Comments (comment start handled in syntax-propertize-function
    (modify-syntax-entry ?/ "<" table)   ; Treat / (slash) as comment block start
    (modify-syntax-entry ?\n ">" table)  ; Newline as whitespace and comment end
    (modify-syntax-entry ?\r ">" table)  ; Newline as whitespace and comment end

    ;; Word constituent
    ;; numbers as part of words (variable names) (cons uses functionality in
    ;; modify-syntax-entry to apply the class to the elements between the two
    ;; values in the car and cdr positions.)
    (modify-syntax-entry (cons ?0 ?9) "w" table)
    (modify-syntax-entry ?_ "w" table)
    (modify-syntax-entry ?. "w" table)
    
    ;; Punctuation characters
    (modify-syntax-entry ?$ "." table)
    (modify-syntax-entry ?% "." table)
    (modify-syntax-entry ?& "." table)
    (modify-syntax-entry ?+ "." table)
    (modify-syntax-entry ?= "." table)
    (modify-syntax-entry ?* "." table)
    (modify-syntax-entry ?< "." table)
    (modify-syntax-entry ?> "." table)
    (modify-syntax-entry ?| "." table)
    (modify-syntax-entry ?, "." table)
    (modify-syntax-entry ?- "." table)
    (modify-syntax-entry ?\\ "." table)
    (modify-syntax-entry ?# "." table)
    (modify-syntax-entry ?: "." table)
    (modify-syntax-entry ?' "." table)
    (modify-syntax-entry ?^ "." table)
    (modify-syntax-entry ?! "." table)
    (modify-syntax-entry ?@ "." table)
    (modify-syntax-entry ?* "." table)
    (modify-syntax-entry ?| "." table)
    (modify-syntax-entry ?? "." table)
    (modify-syntax-entry ?~ "." table)

    
    ;; Bracket matching
    ;; Parentheses and brackets the element after ? is the character
    ;; the first element in the string is either ( or ) denoting it as an open
    ;;  or close
    ;; the second element in the string is the opposite kind of bracket
    ;;  (so matching close for an open or matching open for a close).
    (modify-syntax-entry ?\( "()" table)
    (modify-syntax-entry ?\) ")(" table)
    (modify-syntax-entry ?\[ "(]" table)
    (modify-syntax-entry ?\] ")[" table)
    (modify-syntax-entry ?{ "(}" table)
    (modify-syntax-entry ?} "){" table)

    ;;  syntax-propertize-function used for:
    ;;   `      beginning a word denotes the object name is a symbol, alone it is a null or symbol type.
    ;;              (prefix here by default)
    ;;   .      word, name space, index object.
    ;;              (set as word here by default)
    ;;   /      comment block start and over.
    ;;              (set as comment block start here by default)
    ;;   \      comment block end, script end, scan, terminal command (set as scan here by default).
    ;;   _      word, cut (set as word here by default)
    ;;   -      word, minus (set as minus here by default)
    table)
  "Syntax table for `q-script-mode'.")






;;  syntax-propertize-function used for:
;;   `      beginning a word denotes the object name is a symbol, alone it is a null or symbol type.
;;              (prefix here by default)
;;   .      word, name space, index object.
;;              (set as word here by default)
;;   /      comment block start and over.
;;              (set as comment block start here by default)
;;   \      comment block end, script end, scan, terminal command (set as scan here by default).
;;   _      word, cut (set as word here by default)
;;   -      word, minus (set as minus here by default)
(defun q-syntax-propertize (start end)
  "Set syntax properties in the region between START and END for `q-mode`."
  (goto-char start)
  (let ((patterns
         `(
           ;; comments
           (,q-comments-single-line-regex . q-comment)
           ;;(,q-comments-multi-line-regex . q-comment)
           ;; (,q-comments-tag . q-comment-tag)
           
           ;; operators
           ;;  (,q-standalone-operators . q-function)                            ; q-standalone-operators
           ;;  (,q-standalone-operators-space-prefix . q-function)               ; q-standalone-operators-space-prefix for `_'        (default word)
           ;;  (,q-standalone-operators-space-prefix-suffix . q-function)        ; q-standalone-operators-space-prefix-suffix for `.' (default word)

           ;; name-spaces
           ;;  (,q-built-in-namespaces . q-function)                             ; q-built-in-name-spaces

           ;; symbols
           ;;  ("\\(?:[[:space:]]\\)[[:alnum:].]+" . q-symbol)                   ; New case for `q-symbol'

           ;; attributes and syntactic sugar. 
           ;;  (,q-attributes-and-syntactic-sugar . q-function)                  ; q-built-in-functions

           ;; data types
           ;;  (,q-data-types . q-data-types)

           )))                                                     
    
    (while (re-search-forward
            (mapconcat #'car patterns "\\|") ;; Combine all patterns into a single regex
            end t)
      (let* ((match (match-string 0))
             (property (cdr (cl-assoc-if (lambda (regex) (string-match-p regex match)) patterns))))
        (when property
          (put-text-property (match-beginning 0) (match-end 0) property t))))))



(defvar q-font-lock-defaults
  `(
    ;; Match text with the 'q-comment' property and apply font-lock-comment-face.
    (,(lambda (limit)
        (let ((pos (text-property-any (point) limit 'q-comment t)))
          (when pos
            ;; Find the end of the region with the 'q-comment' property.
            (let ((end (next-single-property-change pos 'q-comment nil limit)))
              (set-match-data (list pos end))
              (goto-char end)  ;; Move point to end of match.
              t))))
     . 'font-lock-comment-face)

    ;; Match text with the 'q-function' property and apply font-lock-constant-face.
    (,(lambda (limit)
        (let ((pos (text-property-any (point) limit 'q-function t)))
          (when pos
            (let ((end (next-single-property-change pos 'q-function nil limit)))
              (set-match-data (list pos end))
              (goto-char end)
              t))))
     . 'font-lock-constant-face)

    ;; Match text with the 'q-data-types' property and apply font-lock-preprocessor-face.
    (,(lambda (limit)
        (let ((pos (text-property-any (point) limit 'q-data-types t)))
          (when pos
            (let ((end (next-single-property-change pos 'q-data-types nil limit)))
              (set-match-data (list pos end))
              (goto-char end)
              t))))
     . 'font-lock-preprocessor-face))
  "Font-lock keywords for `q-mode`, using `q-syntax-propertize`.")


(defvar q-font-lock-defaults
  '(
    (q-font-lock-keywords q-font-lock-keywords-1 q-font-lock-keywords-2)       ; Key words  
    nil                                                                        ; key words only 
    nil                                                                        ; case fold
    nil                                                                        ; syntax-alist  (replaces syntax table if defined)
    nil                                                                        ; OTHER VARS
    (font-lock-syntactic-keywords . (("^\\(\/\\)\\s-*$"     1 "< b") ;            begin multiline comment /
                                     ("^\\(\\\\\\)\\s-*$"   1 "> b") ; end multiline comment   \
                                     ("\\(?:^\\|[ \t]\\)\\(\/\\)"    1 "<  ") ; comments start flush left or after white space
                                     ("\\(\"\\)\\(?:[^\"\\\\]\\|\\\\.\\)*?\\(\"\\)" (1 "\"") (2 "\""))
                                     )))
  "List of font lock keywords to properly highlight q syntax.")

(defun my-show-paren-ignore-q-prompt ()
  "Ignore `q)` as a matching parenthesis in `show-paren-mode'."
  (let ((pos (point)))
    (save-excursion
      (beginning-of-line)
      (if (looking-at "^q)")  ; Match `q)` at the start of the line
          ;; Do nothing (return nil to ignore this match)
          nil
        ;; Otherwise, use the default behaviour
        (show-paren--default)))))

(defun q-paren-ignore ()
  "Set `show-paren-data-function` to ignore the `q)' prompt in comint."
  (setq-local show-paren-data-function #'my-show-paren-ignore-q-prompt))

(message "finished loading q-parse.el")
(provide 'q-parse)

;;; q-parse.el ends here

                                                                                 ; LocalWords:  cefhijnptuv ij assword concat cefghijmndzuvtp xgroup msum mins signum xlog pj loadbalancer paren
                                                                                 ; LocalWords:  xexp
