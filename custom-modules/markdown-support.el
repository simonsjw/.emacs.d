;;;; markdown-support.el --- Tree-sitter powered Markdown editing support  -*- lexical-binding: t; -*-

;; Copyright (C) 2023-2026
;; SPDX-License-Identifier: MIT

;; Author: Simon Watson (refactored from writing-config.el)

;;; Commentary:

;; This module provides a clean, modular, and modern configuration for
;; editing Markdown files in Emacs.  It prioritises Tree-sitter
;; (`markdown-ts-mode') for fast, accurate syntax highlighting,
;; structural navigation, and folding.  It integrates Marksman (LSP)
;; via Eglot for intelligent completion, diagnostics, and refactoring.
;;
;; Additional tools include live preview (with Mermaid support),
;; automatic table of contents, linting via markdownlint, and sensible
;; defaults for fill columns, visual wrapping, and display indicators.
;;
;; The design follows these principles:
;; - Verbose, self-documenting docstrings with two spaces after
;;   sentence periods.
;; - All function arguments (when present) documented in UPPER CASE
;;   in the docstring, with clear explanations of purpose, expected
;;   type, and usage constraints.
;; - Lazy loading via `use-package' and `defer' / `hook' where
;;   possible for startup efficiency.
;; - Compatibility shims for both `markdown-mode' (classic) and
;;   `markdown-ts-mode' (Tree-sitter) so existing workflows continue
;;   to work while new files benefit from Tree-sitter.
;; - Idempotent grammar installation and safe fallbacks if
;;   Tree-sitter or Marksman are unavailable.
;; - Use of the modern `major-mode-remap-alist` to avoid polluting
;;   `auto-mode-alist' with duplicate entries.
;;
;; To use this module:
;;   1. Place this file in your `load-path' (e.g. ~/.emacs.d/lisp/).
;;   2. Add (require 'markdown-support) to your init.el or
;;      writing-config.el AFTER (require 'path-support) and
;;      (require 'logging-config) if you use them.
;;   3. **IMPORTANT:** Remove or comment out ALL Markdown-related
;;      sections from writing-config.el (especially any
;;      `auto-mode-alist' entries for .md, the old
;;      `my-writing-config/markdown-mode-setup' function, and any
;;      direct `add-hook' for markdown-ts-mode).  Duplicate entries
;;      are the #1 cause of the exact error you are seeing.
;;   4. Restart Emacs or `M-x eval-buffer' on this file.
;;   5. Open a .md file; Tree-sitter mode should activate
;;      automatically (run `M-x treesit-install-language-grammar'
;;      for `markdown' and `markdown-inline' if prompted or if
;;      highlighting is incomplete).
;;
;; Edge cases handled:
;; - No Tree-sitter support: falls back to classic `markdown-mode'.
;; - Missing Marksman: Eglot silently skips; manual `M-x eglot' still
;;   possible with other servers.
;; - Grammar not installed: clear message with exact command.
;; - Mixed classic / ts buffers: both hooks run safely.
;; - Duplicate auto-mode-alist entries from old config: prevented by
;;   using `major-mode-remap-alist' + single clean entry.
;; - Windows / macOS / Linux path differences: relies on
;;   `executable-find' which is cross-platform.
;;
;; Implications:
;; - Tree-sitter gives ~10-100x faster fontification and enables
;;   structural editing (e.g. `treesit-forward-sexp').
;; - Marksman provides cross-file link completion and diagnostic
;;   squiggles that classic regex-based modes cannot match.
;; - You can still use Pandoc / LaTeX export pipelines unchanged.
;; - This setup is future-proof for Emacs 31+ where `markdown-ts-mode'
;;   is built-in.

;;; Code:

(require 'logging-config)
(log/debug :fn 'markdown-support
           :msg "Starting load of the markdown-support module."
           :obj t)


;;;; Unified Buffer Setup Function (defined FIRST for hook safety)
;;   -------------------------------------------------------------

(defun markdown-support/markdown-mode-setup ()
  "Apply productivity defaults to any Markdown buffer (classic or
Tree-sitter).

This function is the single hook target for both
`markdown-mode-hook' and `markdown-ts-mode-hook'.  It performs the
following actions, each guarded so that missing optional packages
do not cause errors:

- Enables `visual-line-mode' for soft line wrapping (no hard
  newlines inserted).
- Starts Eglot (which will connect to Marksman if the executable
  is present and the server is registered).
- Activates Tree-sitter folding (`treesit-fold-mode' and
  indicators) when the grammar is available; this gives
  collapsible headings and code blocks.
- Sets generous fill columns (140) suitable for modern wide
  displays and documentation that may contain long code examples
  or tables.
- Turns on the fill-column indicator as a visual guide.
- Optionally loads `treesit-fold' (the require is safe).

No arguments are accepted.  The function inspects the current
buffer's major mode and Tree-sitter state at runtime.

Intended usage (added automatically by this module):
  (add-hook 'markdown-ts-mode-hook #'markdown-support/markdown-mode-setup)
  (add-hook 'markdown-mode-hook #'markdown-support/markdown-mode-setup)

Edge-case behaviour:
- If `eglot' is not loaded, the call is a harmless no-op.
- If `treesit-fold' is absent, folding is simply skipped.
- The function is re-entrant; calling it twice on the same buffer
  has no adverse effects.
- It is safe to call even if the buffer is not actually a Markdown
  buffer (it simply does nothing harmful)."
  (visual-line-mode 1)

  (when (fboundp 'eglot-ensure)
    (eglot-ensure))
  
  (with-eval-after-load 'eglot
    (add-to-list 'eglot-server-programs '(markdown-mode . ("marksman")))
    )

  (when (fboundp 'markdown-ts-mode)
    (require 'treesit-fold nil 'noerror)
    (when (fboundp 'treesit-fold-mode)
      (treesit-fold-mode 1)
      (when (fboundp 'treesit-fold-indicators-mode)
        (treesit-fold-indicators-mode 1))))

  (setq-local display-fill-column-indicator-column 140
              fill-column 140
              comment-fill-column 140
              comment-column 142)
  (display-fill-column-indicator-mode 1))


;;;; Grammar Installation Helper (forces correct modern sources)
;;   ----------------------------------------------------------------

;; (defun markdown-support/install-grammars ()
;;   "Ensure the Tree-sitter grammars required by `markdown-ts-mode' are
;; installed and registered, using the modern split_parser versions.

;; This function first removes any existing 'markdown' or
;; 'markdown-inline' entries (to override older sources such as the
;; ikatyang version that may be present in treesit-support.el), then
;; adds the official split_parser sources from tree-sitter-grammars.

;; It always prints the current status of the two Markdown grammars
;; after attempting installation.

;; The function is idempotent.  It does nothing (and returns nil) if
;; `treesit-available-p' is nil.

;; No arguments are accepted.  Returns t if both grammars are (now)
;; available, nil otherwise."
;;   (if (not (treesit-available-p))
;;       (progn
;;         (message "Tree-sitter not available in this Emacs build; \
;; falling back to classic markdown-mode.")
;;         nil)
;;     ;; Remove any old/outdated markdown entries first (critical)
;;     (setq treesit-language-source-alist
;;           (seq-remove (lambda (entry)
;;                         (memq (car entry) '(markdown markdown-inline)))
;;                       treesit-language-source-alist))

;;     (let ((needed nil))
;;       (dolist (lang '(markdown markdown-inline))
;;         (unless (treesit-language-available-p lang)
;;           (setq needed t)
;;           (add-to-list 'treesit-language-source-alist
;;                        (list lang
;;                              "https://github.com/tree-sitter-grammars/tree-sitter-markdown"
;;                              "split_parser"
;;                              (if (eq lang 'markdown)
;;                                  "tree-sitter-markdown/src"
;;                                "tree-sitter-markdown-inline/src"))
;;                        t)))
;;       (when needed
;;         (message "Markdown Tree-sitter grammars (split_parser) were missing or outdated.\n\
;; Please run: M-x treesit-install-language-grammar RET markdown RET\n\
;;           M-x treesit-install-language-grammar RET markdown-inline RET"))
;;       (let ((md-ok (treesit-language-available-p 'markdown))
;;             (inline-ok (treesit-language-available-p 'markdown-inline)))
;;         (message "Markdown grammar status: markdown=%s  markdown-inline=%s"
;;                  md-ok inline-ok)
;;         (and md-ok inline-ok)))))


;;;; Core Markdown Mode (maximum robustness - always claims .md files)
;;   ------------------------------------------------------------------
;;;; LSP Support via Marksman + Eglot
;;   ---------------------------------


(if (fboundp 'markdown-ts-mode)
    (progn
      ;; Tree-sitter mode is available — use it
      (add-to-list 'auto-mode-alist '("\\.md\\'" . markdown-ts-mode))
      (add-to-list 'auto-mode-alist '("\\.MD\\'" . markdown-ts-mode))
      (add-to-list 'major-mode-remap-alist '(markdown-mode . markdown-ts-mode))
      (markdown-support/install-grammars))
  ;; Fallback: markdown-ts-mode is not defined on this Emacs build
  (progn
    (message "markdown-ts-mode is not available on this Emacs. Falling back to classic markdown-mode.")
    (add-to-list 'auto-mode-alist '("\\.md\\'" . markdown-mode))
    (add-to-list 'auto-mode-alist '("\\.MD\\'" . markdown-mode))))

;; (use-package markdown-ts-mode
;;   :ensure t
;;   :defer t
;;   :hook (markdown-ts-mode . markdown-support/markdown-mode-setup)
;;   :config
;;   (message "markdown-ts-mode package loaded."))


;;;; Classic markdown-mode (fallback if ts-mode can't activate)
;;   ------------------------------------------------------------

;; (use-package markdown-mode
;;   :ensure t
;;   :defer t
;;   :hook (markdown-mode . visual-line-mode)
;;   :config
;;   (when (fboundp 'markdown-mode)
;;     (unless (or (bound-and-true-p markdown-command)
;;                 (executable-find "markdown")
;;                 (executable-find "pandoc"))
;;       (message "No Markdown processor found; preview/export may be limited."))))


;; (defcustom markdown-support/marksman-executable nil
;;   "Path to the Marksman executable, or nil to auto-detect.
;; Common on Ubuntu: \"/snap/bin/marksman\" when installed via Snap.
;; Leave as nil for automatic detection (recommended)."
;;   :type '(choice (const :tag "Auto-detect" nil) string)
;;   :group 'markdown-support)

;; (defun markdown-support/maybe-register-marksman ()
;;   "Register Marksman LSP with Eglot only if the executable is found.
;; Tries the customizable variable first, then auto-detects including
;; common Snap path on Ubuntu (/snap/bin/marksman)."
;;   (let* ((candidates (list markdown-support/marksman-executable
;;                            "marksman"
;;                            "/snap/bin/marksman"))
;;          (cmd (seq-some #'executable-find (remq nil candidates))))
;;     (if cmd
;;         (progn
;;           (add-to-list 'eglot-server-programs
;;                        `(markdown-mode . (,cmd)))
;;           (add-to-list 'eglot-server-programs
;;                        `(markdown-ts-mode . (,cmd)))
;;           (message "Marksman LSP registered for Markdown (via Eglot) using %s" cmd))
;;       (message "Marksman not found.
;; Tried: marksman and /snap/bin/marksman
;; Fix: (setq markdown-support/marksman-executable \"/snap/bin/marksman\")"))))

;; (setq markdown-support/marksman-executable "/snap/bin/marksman")

;; (with-eval-after-load 'eglot
;;   (markdown-support/maybe-register-marksman))


;;;; Preview, TOC, and Linting Tools
;;   -------------------------------

;; (use-package markdown-preview-mode
;;   :ensure t
;;   :config
;;   (setq markdown-preview-stylesheets
;;         (list "https://cdnjs.cloudflare.com/ajax/libs/github-markdown-css/5.2.0/github-markdown.min.css"))
;;   (setq markdown-preview-javascript
;;         (list "https://cdn.jsdelivr.net/npm/mermaid@10/dist/mermaid.min.js")))

;; (use-package markdown-toc
;;   :ensure t
;;   :config
;;   (add-hook 'markdown-mode-hook #'markdown-toc-mode)
;;   (add-hook 'markdown-ts-mode-hook #'markdown-toc-mode))

;; (use-package flymake-markdownlint
;;   :ensure t
;;   :hook
;;   ((markdown-mode markdown-ts-mode) . flymake-markdownlint-setup)
;;   ((markdown-mode markdown-ts-mode) . flymake-mode))


;;;; Additional safe hooks
;;   ---------------------

(add-hook 'markdown-mode-hook #'markdown-support/markdown-mode-setup)
;;(add-hook 'markdown-ts-mode-hook #'markdown-support/markdown-mode-setup)


(log/debug :fn 'markdown-support
           :msg "Finishing load of the markdown-support module."
           :obj t)

(provide 'markdown-support)
;;; markdown-support.el ends here
