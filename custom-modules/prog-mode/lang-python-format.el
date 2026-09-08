;;; lang-python-format.el --- Ruff / Apheleia formatting for Python. -*- lexical-binding: t; -*-

;; Copyright (C) 2026 Simon Watson
;; SPDX-License-Identifier: MIT

;; Author: Simon Watson

;;; Commentary:

;; Piece of `lang-python': Ruff format/isort via Apheleia.  Buffer-local
;; forms run from `my-lang-python/format-setup', called by the loader
;; hook.  Do not enable `apheleia-mode' at `require'.
;;
;; Map:
;;   Feature:    lang-python-format
;;   Load-after: path-support logging-config
;;   Load-phase: lang
;;   Keymaps:    none
;;   Docs:       docs/lang-python-format.org
;;   OS:         ruff

;;; Code:

(require 'path-support)
(require 'logging-config)
(log/debug :fn 'lang-python-format
           :msg "Starting load of the lang-python-format module."
           :obj t)

(declare-function my-in-buffer-tools/comment-align-buffer "system-buffer-tools")
(declare-function apheleia-format-buffer "apheleia")
(defvar apheleia-formatters)

(defun my-lang-python/organize-imports ()
  "Organise imports in the current buffer using ruff-isort via Apheleia.
This runs only the import organisation formatter, preserving the buffer's
point and avoiding full reformatting."
  (interactive)
  (unless (derived-mode-p 'python-ts-mode 'python-mode)
    (user-error "Not in a Python mode"))
  (apheleia-format-buffer 'ruff-isort))

(defun my-lang-python/format-buffer ()
  "Format the entire buffer using ruff-format via Apheleia.
This applies Ruff's code style formatter, preserving point."
  (interactive)
  (unless (derived-mode-p 'python-ts-mode 'python-mode)
    (user-error "Not in a Python mode"))
  (apheleia-format-buffer 'ruff-format)
  (my-in-buffer-tools/comment-align-buffer (point-min) (point-max)))

(defun my-lang-python/format-region ()
  "Format active Python region with full Apheleia chain + align, via temp-buffer.
Copies region to temp-buffer, runs buffer format (isort + format + align),
then replaces original region.  Skips on hard syntax/runtime error; proceeds on lint."
  (interactive)
  (if (not (use-region-p))
      (error "No region active; use `my-lang-python/format-buffer' for whole buffer")
    (let* ((start (region-beginning))
           (end (region-end))
           (orig-content (buffer-substring-no-properties start end))            ; Save original.
           (temp-buffer (generate-new-buffer " *python-region-format*" t))
           (check-ok t))
      (unwind-protect
          (with-current-buffer temp-buffer
            (python-ts-mode)                                                    ; Set mode for Apheleia/align.
            (insert orig-content)                                               ; Region as "whole" buffer.
            ;; Pre-check syntax/lint (plain check).
            (let* ((temp-file (make-temp-file "python-region-" nil ".py"))
                   (check-buffer (generate-new-buffer " *ruff-check*" t)))
              (unwind-protect
                  (progn
                    (write-region (point-min) (point-max) temp-file nil 'silent)
                    (with-current-buffer check-buffer
                      (let ((check-code (call-process "ruff" nil t t "check" temp-file)))
                        (cond
                         ((= check-code 0) (message "No issues; proceeding."))
                         ((= check-code 1) (message "Lint violations; still formatting: %s" (buffer-string))) ; Proceed on lint.
                         (t (setq check-ok nil)
                            (message "Hard error (code %d); skipping format: %s" check-code (buffer-string)))))))
                (when (file-exists-p temp-file) (delete-file temp-file))
                (kill-buffer check-buffer)))
            ;; Format + align if check ok (or lint-only).
            (when check-ok
              (my-lang-python/format-buffer))                                   ; Full chain on temp.
            ;; Fallback align if skipped.
            (unless check-ok
              (my-in-buffer-tools/comment-align-buffer (point-min) (point-max))))
        ;; Now back in original buffer: Replace region with formatted content.
        (delete-region start end)
        (insert (with-current-buffer temp-buffer (buffer-string)))
        (kill-buffer temp-buffer)))))

(defun my-lang-python/align-comments-before-save ()
  "Align existing inline comments before save, if in Python mode.
Operates on the whole buffer to match Apheleia's scope.  Runs after formatting."
  (when (and (derived-mode-p 'python-ts-mode 'python-mode)
             (fboundp 'my-in-buffer-tools/comment-align-buffer))
    (save-excursion
      (my-in-buffer-tools/comment-align-buffer (point-min) (point-max)))))

(defun my-lang-python/format-setup ()
  "Enable Apheleia and buffer-local format-on-save for `python-ts-mode'.
Do not call this at `require'; the loader hook invokes it."
  (apheleia-mode 1)
  ;; Define a ruff-format formatter
  ;; (for full Ruff formatting without isort).
  ;; This runs 'ruff format' to reformat code style.
  (setf (alist-get 'ruff-format apheleia-formatters)
        '("ruff" "format" "--quiet" "--stdin-filename" filepath "-"))
  ;; Define ruff-isort as custom formatter (matches Apheleia built-in).
  (setf (alist-get 'ruff-isort apheleia-formatters)
        '("ruff" "check" "--select=I" "--fix" "--quiet" "--stdin-filename" filepath "-"))
  (add-hook 'before-save-hook #'my-lang-python/align-comments-before-save nil t))

(log/debug :fn 'lang-python-format
           :msg "Finishing load of the lang-python-format module."
           :obj t)

(provide 'lang-python-format)
;;; lang-python-format.el ends here
