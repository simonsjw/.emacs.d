;;; custom-ide-config.el --- Provide IDE-like features -*- lexical-binding: t; -*-

;; Copyright (C) 2023
;; SPDX-License-Identifier: MIT

;; Author: System Crafters Community

;;; Commentary:

;; Eglot configuration.

;; Suggested additional keybindings
;; (with-eval-after-load "prog-mode"
;;   (keymap-set prog-mode-map "C-c e n" #'flymake-goto-next-error)
;;   (keymap-set prog-mode-map "C-c e p" #'flymake-goto-prev-error))

;;; Code:

(require 'straight)
(require 'eglot)
(require 'consult)
(require 'embark)

(require 'editorconfig)
(require 'aggressive-indent)

(declare-function consult-eglot-embark-mode "consult-eglot-embark")

(declare-function eldoc-box-hover-mode "s")

(declare-function s-starts-with? "s")
(declare-function s-ends-with? "s")

(use-package consult-eglot)
(use-package consult-eglot-embark)

(with-eval-after-load 'embark
  (with-eval-after-load 'consult-eglot
    (require 'consult-eglot-embark)
    (consult-eglot-embark-mode)))


(with-eval-after-load 'eglot
  ;; (add-to-list 'eglot-server-programs
  ;;              '(python-mode . ("ruff" "server")))
  ;; Assuming python-ts-mode is the major mode for Python files
  (add-to-list 'eglot-server-programs
               '(python-ts-mode . ("ruff" "server")))
  ;; (add-hook 'after-save-hook 'eglot-format)
  )

;; ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
;; eglot setup
;; -----------
;; Excluding Pyright diagnostic notes
;; Pyright has some diagnostic notes that overlap with diagnostics provided by
;; ruff. These diagnostic notes can't be disabled via Pyright's config, but
;; you can exclude them by adding a filter to eglot--report-to-flymake.
;; For example,
;;   to remove Pyright's "variable not accessed" notes, add the following:
(defun my-filter-eglot-diagnostics (diags)
  "Drop Pyright `variable not accessed' notes from DIAGS."
  (list
   (seq-remove
    (lambda (d)
      (and (eq (flymake-diagnostic-type d) 'eglot-note)
           (s-starts-with? "Pyright:" (flymake-diagnostic-text d))
           (s-ends-with? "is not accessed" (flymake-diagnostic-text d))))
    (car diags))))
(advice-add 'eglot--report-to-flymake
            :filter-args #'my-filter-eglot-diagnostics)

(defun my-eglot/mp-eglot-eldoc ()
  "Set `eldoc-documentation-strategy` - `eldoc-documentation-compose-eagerly`."
  (setq eldoc-documentation-strategy
        'eldoc-documentation-compose-eagerly))

;; Add the function to the eglot-managed-mode hook
(add-hook 'eglot-managed-mode-hook #'my-eglot/mp-eglot-eldoc)

;; use eldoc-box-hover-mode.
(add-hook 'eglot-managed-mode-hook #'eldoc-box-hover-mode t)
;; the below stops eldoc-box showing up if not explicitly requested.
(add-to-list 'eglot-ignored-server-capabilites :hoverProvider)

;; ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
;; Handle returns in comments.
;; ---------------------------
;; Make the return more intelligent.
(defun my-ide/handle-return-in-comment (char)
  "Handle the return key in a comment context.

CHAR denotes the character used for delimiting the comment."
  (let ((indent (current-indentation)))
    (newline)
    (indent-line-to indent)
    (when char
      (insert char))))


(defun my-ide/handle-return-in-doc ()
  "Handles return key in a docstring context."
  (let ((indent (current-indentation)))
    (newline)
    (indent-line-to indent)))

(defun  my-ide/handle-return-in-string ()
  "Handle a return in the middle of a string.

Search the current line for the latest occurrence of `\"` or `'`, insert a
newline and indent, and then insert the character found, if any."
  (interactive)
  (let ((char-to-insert nil)
        (indent (current-indentation))
        ;; Search the current line backward for `"` or `'`
        (save-excursion
          (beginning-of-line)
          (when (re-search-forward "['\"]" (line-end-position) t)
            (setq char-to-insert (char-after (match-beginning 0)))))
        ;; Insert newline and indent
        (newline)
        (indent-line-to indent)
        ;; Insert the found character, if any
        (when char-to-insert
          (insert char-to-insert)))))

(defun my-ide/handle-return-in-default ()
  "Handles return key in a default context."
  (let ((indent (current-indentation)))
    (newline)
    (indent-line-to indent)))

(defun my-ide/smart-newline (&optional comment-escape)
  "Executes newline handling functions based on context, in the active buffer.

COMMENT-ESCAPE is the string used to escape a comment (e.g., '# ')."
  (interactive)
  (let ((current-face (face-at-point nil t)))
    (cond
     ((member 'font-lock-comment-face current-face)
      (my-ide/handle-return-in-comment comment-escape))
     ((member 'font-lock-doc-face current-face)
      (my-ide/handle-return-in-doc))
     ((member 'font-lock-string-face current-face)
      (my-ide/handle-return-in-string))
     (t
      (my-ide/handle-return-in-default)))))

(defun my-debug/smart-newline ()
  "Execute various newline handling functions based on the syntax context.

This function assumes the buffer is the current active buffer."
  (interactive)
  ;; Make sure to switch to the correct buffer (if not already in it)
  ;;(with-current-buffer (other-buffer (current-buffer) 1)
  (let ((current-face (face-at-point nil t)))
    (message "current face: %s" current-face)))


;; ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
;; tab inline comments to comment-column
;; -------------------------------------
;; Get better formatting of inline comments.
;; * `my-ide/comment-delimiter-char' must be set to provide the comment
;; character.
;; * my-ide/conditional-align-inline-comment aligns individual inline-comments.
;; * my-ide/align-comments-in-buffer aligns inline-comments buffer wide.

(defvar my-ide/comment-delimiter-char nil
  "Character delimiting a comment - used for inline comment alignment.")

(defun my-ide/align-comments-to-fill-column ()
  "Align single-line comments to fill column after code on the same line.

This function requires `my-ide/comment-delimiter-char' to get the character
use for comments (for example, ?# for Python, ?; for Emacs Lisp).
Aligns the comment to `fill-column` if it follows code on the same line,
without overwriting code."
  (let ((comment-char (or my-ide/comment-delimiter-char
                          (setq my-ide/comment-delimiter-char
                                (read-char "Enter the comment character: ")))))
    (save-excursion  ; Preserve cursor position
      (goto-char (line-beginning-position))  ; Start at the beginning of the line
      (when
          (and
           (re-search-forward
            (concat "[^[:space:]]" (char-to-string comment-char))
            (line-end-position) t)
           (< (current-column) fill-column))  ; Ensure code doesn't reach `fill-column`
        (move-to-column fill-column t)))))  ; Align comment to `fill-column` if safe


(defun my-ide/conditional-align-inline-comment ()
  "Align comment delimiters to fill column where code precedes the comment.

This function requires `my-ide/comment-delimiter-char' to get the character
used for comments (for example, ?# for Python, ?; for Emacs Lisp).
If there is no code before the comment, if the line is blank, or if code
reaches `fill-column`, use default TAB functionality."
  (interactive)
  ;; Ensure `my-ide/comment-delimiter-char` is set, prompting if not
  (let ((comment-char (or my-ide/comment-delimiter-char
                          (setq my-ide/comment-delimiter-char
                                (read-char "Enter the comment character: ")))))
    (let ((line-has-code-before-comment
           (save-excursion
             (goto-char (line-beginning-position))  ; Move to the beginning of the line
             (and
              (re-search-forward "[^[:space:]]" (point) t)  ; Check for code (non-whitespace) on the line
              (search-forward (char-to-string comment-char) (line-end-position) t)))))  ; Look for comment char after code
      (if (and line-has-code-before-comment
               (< (current-column) fill-column))  ; Ensure code doesn't reach `fill-column`
          (my-ide/align-comments-to-fill-column)  ; Align if there's code before the comment and space available
        (indent-for-tab-command)))))  ; Otherwise, use default TAB behaviour



(defun my-ide/align-comments-in-buffer ()
  "Align in-line comments in the current buffer to fill column on code lines.

This function requires `my-ide/comment-delimiter-char' to get the character used
for comments (for example, ?# for Python, ?; for Emacs Lisp).
This applies the alignment only if there is code before the comment and if it
won't overwrite existing code."
  (interactive "cEnter the comment character: ")  ; Prompt for the comment character
  (save-excursion  ; Preserve the cursor position after running the function
    (goto-char (point-min))  ; Start at the beginning of the buffer
    (while (not (eobp))  ; Loop until the end of the buffer
      (let
          ((line-has-code-before-comment
            (save-excursion
              (goto-char (line-beginning-position))  ; Move to the start of the line
              (and
               (re-search-forward "[^[:space:]]" (point) t)  ; Check for code before the comment
               (search-forward
                (char-to-string my-ide/comment-delimiter-char)
                (line-end-position) t)))))  ; Locate comment char
        (when (and line-has-code-before-comment
                   (< (current-column) fill-column))  ; Ensure code doesn't reach `fill-column`
          (my-ide/align-comments-to-fill-column)))  ; Align the comment if conditions are met
      (forward-line 1))))  ; Move to the next line


;; Example: Bind this function to the TAB key in programming modes only
;; (add-hook
;;  'prog-mode-hook
;;  (lambda ()
;;    (local-set-key (kbd "TAB") (lambda ()
;;                                 (interactive)
;;                                 (conditional-align-or-tab ?\;)))))

;; turn on editorconfig if it is available
(when (require 'editorconfig nil :noerror)
  (add-hook 'prog-mode-hook #'editorconfig-mode))


(provide 'custom-ide-config)
;;; custom-ide-config.el ends here


                                        ; LocalWords:  eglot dape ide
                                        ; LocalWords:  cEnter
