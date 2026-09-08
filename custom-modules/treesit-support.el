;;; treesit-support.el --- Tree-sitter grammars, fold, and Combobulate. -*- lexical-binding: t; -*-

;; Copyright (C) 2026 Simon Watson
;; SPDX-License-Identifier: MIT

;; Author: Simon Watson

;;; Commentary:

;; Tree-sitter support for Emacs 30: grammar setup, `treesit-fold',
;; and Combobulate.  Load from `init.el' after `logging-config'.
;;
;; Map:
;;   Feature:    treesit-support
;;   Load-after: path-support logging-config
;;   Load-phase: ide
;;   Keymaps:    none
;;   Docs:       docs/treesit-support.org
;;   OS:         none

;;; Code:

;; Commands 	                        Description
;; |treesit-fold-mode 	               | enable treesit-fold-mode in the current buffer.
;; |global-treesit-fold-mode 	       | enable treesit-fold-mode whenever tree-sitter is turned on and the major mode is supported by treesit-fold.
;; |treesit-fold-indicators-mode       | enable treesit-fold with indicators in the current buffer. See plugins section.
;; |global-treesit-fold-indicators-mode| enable treesit-fold with indicators globally.
;; |treesit-fold-line-comment-mode     | enable line comment folding.

;; Commands for using treesit-fold.
;; Commands 	                        Description
;; |treesit-fold-close 	               | fold the current syntax node.
;; |treesit-fold-open 	               | open the outermost fold of the current syntax node. Keep the sub-folds close.
;; |treesit-fold-open-recursively      | open all folds inside the current syntax node.
;; |treesit-fold-close-all 	       | close all foldable syntax nodes in the current buffer.
;; |treesit-fold-open-all 	       | open all folded syntax nodes in the current buffer.
;; |treesit-fold-toggle 	       | toggle the syntax node at `point'.


;; Note the version numbers set below. These were selected where
;; this code was sourced since that version was known to work
;; with that app and emacs:
;; https://github.com/mickeynp/combobulate
;; (defvar treesit-language-source-alist
;;   nil
;;   "The variable treesit-language-source-alist is a simple alist that
;; expects a form in the format of
;;     (LANG . (URL REVISION SOURCE-DIR CC C++))
;; Only LANG and URL are mandatory.")


(setq treesit-language-source-alist
      '((bash
         .
         ("https://github.com/tree-sitter/tree-sitter-bash" "v0.23.3"))
        (css
         .
         ("https://github.com/tree-sitter/tree-sitter-css" "v0.20.0"))
        (go
         .
         ("https://github.com/tree-sitter/tree-sitter-go" "v0.20.0"))
        (html
         .
         ("https://github.com/tree-sitter/tree-sitter-html" "v0.20.1"))
        (javascript
         .
         ("https://github.com/tree-sitter/tree-sitter-javascript" "v0.20.1" "src"))
        (json
         .
         ("https://github.com/tree-sitter/tree-sitter-json" "v0.20.2"))
       ;; (markdown
    ;;     .
     ;;    ("https://github.com/ikatyang/tree-sitter-markdown" "v0.7.1"))  ; see markdown-support.el
        (matlab
         .
         ("https://github.com/acristoffers/tree-sitter-matlab"))             ; added by simon watson
        (python
         .
         ("https://github.com/tree-sitter/tree-sitter-python" "v0.20.4"))
        (rust
         .
         ("https://github.com/tree-sitter/tree-sitter-rust" "v0.21.2"))
        (toml
         .
         ("https://github.com/tree-sitter/tree-sitter-toml" "v0.5.1"))
        (tsx
         .
         ("https://github.com/tree-sitter/tree-sitter-typescript" "v0.20.3" "tsx/src"))
        (typescript
         .
         ("https://github.com/tree-sitter/tree-sitter-typescript" "v0.20.3" "typescript/src"))
        (yaml
         .
         ("https://github.com/ikatyang/tree-sitter-yaml" "v0.5.0"))))

;;; LaTeX mode

(add-to-list 'treesit-language-source-alist
             '(latex (concat "file://" (expand-file-name "libtree-sitter-latex.so" my-paths/ts-lang-repo))
                     nil    ; REVISION (nil for current local state)
                     "src"  ; SOURCE-DIR
                     "cc"   ; CC compiler
                     nil))  ; C++ compiler (set to "c++" if scanner.cc exists)

(require 'treesit)
(require 'auctex)

;;(defvar latex-ts-mode-map (make-sparse-keymap) "Keymap for latex-ts-mode.")
;; (define-derived-mode latex-ts-mode text-mode "LaTeX[TS]"
;;   "Major mode for LaTeX with tree-sitter."
;;   (setq-local treesit-font-lock-defaults ;; Define font-lock rules here if needed
;;               ;; ... (consult treesit docs for examples)
;;               )
;;   (treesit-major-mode-setup))
;; (add-to-list 'major-mode-remap-alist '(latex-mode . latex-ts-mode))

;;; Helper functions

(defun my-treesitter/setup-install-grammars ()
  "Install Tree-sitter grammars if they are absent."
  (interactive)
  (dolist (grammar
           treesit-language-source-alist)

    ;; Only install `grammar' if we don't already have it
    ;; installed. However, if you want to *update* a grammar then
    ;; this obviously prevents that from happening.
    (unless (treesit-language-available-p (car grammar))
      (treesit-install-language-grammar (car grammar)))))

;; ensure we are enabling ts functionality in the lang major modes.
(add-to-list 'major-mode-remap-alist '(python-mode . python-ts-mode))

(setq treesit-fold-indicators-fringe 'right-fringe)
(setq treesit-fold-indicators-priority 30)

(with-eval-after-load 'treesit-fold-indicators
  (define-key treesit-fold-indicators-mode-map [left-fringe mouse-1] nil))       ; ensure only the right fringe captures events for fold. The left is needed elsewhere!


(defun my-treesit-fold/state-at-point ()
  "Return the fold state at the current point in tree-sitt-fold.

Useful for implementing toggles for the mode in hydras."
  (interactive)
  (setq fold-state nil)
  (let* ((node (treesit-fold--foldable-node-at-pos))
         (overlay (when node (treesit-fold-overlay-at node))))
    (if (and overlay (overlay-get overlay 'invisible))
        (setq fold-state 'folded)
      (setq fold-state 'unfolded)))
  (message "fold-state: %s" fold-state))

;;; customization

;; Ensure tree-sitter-major-mode-language-alist exists and add the matlab-mode entry
(unless (boundp 'tree-sitter-major-mode-language-alist)
  (setq tree-sitter-major-mode-language-alist '()))
(add-to-list 'tree-sitter-major-mode-language-alist '(matlab-mode . matlab))





;;; hooks

;; perhaps too gross of an application, but the *-ts-modes
;; eventually derive from this mode.
(when (locate-library "combobulate")
  (add-hook 'prog-mode-hook #'combobulate-mode))


;; Ensure native fontlocking is disabled in matlab-mode in favour of tree-sit.
;; (add-hook 'matlab-mode-hook
;;           (lambda ()
;;             (treesit-hl-mode)
;;             (font-lock-mode -1)))


(log/debug :fn 'treesit-support
           :msg "Finishing load of the treesit-support module."
           :obj t)

(provide 'treesit-support)
;;; treesit-support.el ends here

