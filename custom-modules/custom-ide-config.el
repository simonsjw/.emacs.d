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


(use-package consult-eglot
  :straight (:type git
                   :flavor melpa
                   :host github
                   :repo "mohkale/consult-eglot"))

(use-package consult-eglot-embark
 :straight
 (:type git
        :flavor melpa
        :files
        ("extensions/consult-eglot-embark/consult-eglot-embark*.el"
         "consult-eglot-embark-pkg.el")
        :host github
        :repo "mohkale/consult-eglot"))

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

;; ;; https://github.com/scop/emacs-ruff-format
;; (use-package ruff-format
;;   :straight
;;   (:type git
;;          :flavor melpa
;;          :host github
;;          :repo "scop/emacs-ruff-format"))

;; ;; https://github.com/scop/emacs-ruff-format
;; (use-package flymake-ruff
;;   :straight (flymake-ruff
;;              :type git
;;              :host github
;;              :repo "erickgnavar/flymake-ruff")
;;   :hook (eglot-managed-mode . flymake-ruff-load))

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

;; (defun mp-eglot-eldoc ()
;;   "Set `eldoc-documentation-strategy` to
;; `eldoc-documentation-compose-eagerly`."
;;   (setq eldoc-documentation-strategy
;;         'eldoc-documentation-compose-eagerly))

;; ;; Add the function to the eglot-managed-mode hook
;; (add-hook 'eglot-managed-mode-hook 'mp-eglot-eldoc)

;; ensure that scratch is persistent. 
(persistent-scratch-setup-default)

;; use eldoc-box-hover-mode. 
(add-hook 'eglot-managed-mode-hook #'eldoc-box-hover-mode t)
;; the below stops eldoc-box showing up if not explicitly requested. 
(add-to-list 'eglot-ignored-server-capabilites :hoverProvider)

(defun my-ide/handle-return-in-comment (char)
  "Handles return key in a comment context."
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
  "Executes different newline handling functions based on the syntax
context, in the current active buffer."
  (interactive)
  ;; Make sure to switch to the correct buffer (if not already in it)
  ;;(with-current-buffer (other-buffer (current-buffer) 1)
  (let ((current-face (face-at-point nil t)))
    (message "current face: %s" current-face)))


(defvar-local align-comment-prefix nil
  "Buffer-local variable to store the comment prefix for align-eol-comments.")


(defvar-local align-comment-prefix nil
  "Buffer-local variable to store the comment prefix for align-eol-comments.")


;; (defun align-eol-comments ()
;;   "Align end-of-line comments to the fill column using `align-comment-prefix`.
;; If called with an active region, align comments within the region.
;; If no region is active, align comments on the current line.
;; If called without a region or line, align comments in the entire buffer.

;; Only aligns comments that are not in a string, and that follow other characters
;; on the same line.

;; Does not align comments that start with repeated COMMENT-PREFIX.

;; Example usage for aligning across the buffer:
;;    (align-eol-comments)"
;;   (interactive)
;;   (unless align-comment-prefix
;;     (error "align-comment-prefix is not set. Please set it using a mode-specific hook.")) ; Ensure comment prefix is defined
;;   (save-excursion
;;     (let (
;;           (comment-regex
;;            (concat
;;             "\\([^" (substring align-comment-prefix 0 1) "]\\)"                ; Match any character not starting with the prefix
;;             "\\(\\s-*\\)"                                                      ; Match and capture optional whitespace before the comment
;;             (regexp-quote align-comment-prefix)                                ; Match the actual comment prefix
;;             "\\s-*"))                                                          ; Match any following whitespace after the comment prefix

;;           (start (if (use-region-p) (region-beginning) (point-min)))           ; Determine the start point (region or whole buffer)
;;           (end (if (use-region-p) (region-end) (point-max))))                  ; Determine the end point (region or whole buffer)

;;       (goto-char start)                                                        ; Start searching from the determined position
;;       (while (re-search-forward comment-regex end t)                           ; Search for matches of the comment pattern
;;         (let ((comment-start (match-beginning 2)))                             ; Capture where the comment starts
;;           (unless (nth 3 (syntax-ppss))                                        ; Ensure we are not inside a string
;;             (goto-char comment-start)                                          ; Move to the start of the comment
;;             (unless (looking-at " ")                                           ; Ensure there's at least one space before the comment
;;               (insert " "))                                                    ; Insert a space if none is present
;;             (move-to-column fill-column t)                                     ; Move cursor to the `fill-column` for alignment
;;             (insert (match-string 3))))))))                                    ; Reinsert the matched comment part at the new column position




;; turn on editorconfig if it is available
(when (require 'editorconfig nil :noerror)
  (add-hook 'prog-mode-hook #'editorconfig-mode))


(provide 'custom-ide-config)
;;; custom-ide-config.el ends here

