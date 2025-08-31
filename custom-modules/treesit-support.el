;;; treesit-support.el --- setup for treesit -*- lexical-binding: t; -*-

;; Copyright (C) 2022
;; SPDX-License-Identifier: MIT

;; Author: System Crafters Community

;;; Commentary

;; Support for tree-sit in Emacs.
;; Text here is from Micky's site, masteringemacs.org.
;; https://www.masteringemacs.org/article/how-to-get-started-tree-sitter

;;; Suggested additional keybindings

;;; customization

;; (use-package tree-sitter-indent)
;; (use-package tree-sitter-ispell)

(use-package treesit-fold
  :vc (:url "https://github.com/emacs-tree-sitter/treesit-fold.git")
  :ensure t)

(use-package combobulate
  :custom
  ;; You can customize Combobulate's key prefix here.
  ;; Note that you may have to restart Emacs for this to take effect!
  (combobulate-key-prefix "C-c o")
  :hook ((prog-mode . combobulate-mode))
  ;; The directory containing Combobulate's source code.
  :load-path (my-paths/combobulate))

;; (use-package treesit-auto
;;   :ensure t
;;   :custom
;;   (treesit-auto-install 'prompt)
;;   :config
;;   (treesit-auto-add-to-auto-mode-alist 'all)
;;   (global-treesit-auto-mode))

(defvar treesit-fold-indicators-fringe)
(defvar treesit-fold-indicators-priority)
(defvar fold-state)
(declare-function treesit-fold-mode "treesit-fold")
(declare-function combobulate-mode "combobulate")

;; (require 'tree-sitter-indent)
;; (require 'tree-sitter-ispell)
;; (require 'treesit-fold)
;;(require 'combobulate)
;;(require 'treesit-auto)

;; tree-sitter-load-path is set in early-init.el.
;; path is added to load-path in custom-path-support.el.

;; set a fallback should the treesitter grammar not be installed like this:
;; (add-to-list 'treesit-auto-fallback-alist '(toml-ts-mode . conf-toml-mode))

;; override any of the language names so they match the emacs mode
;; (for instance - javascript is js)
;;(setq treesit-load-name-override-list
;; '((js "libtree-sitter-js" "tree_sitter_javascript")))

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
        (markdown
         .
         ("https://github.com/ikatyang/tree-sitter-markdown" "v0.7.1"))
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
             '(latex "file:///home/simon/sync/primary/dotfiles/emacs/local-treesitter-repo/tree-sitter-latex"
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

(defun my-treesitter/add-treesit-fold-to-context-menu ()
  "Add treesit-fold-toggle to the right-click context menu.

This function can be added to a hook when treesitter fold is active or
alternatively as a function called inside a collection of other functions
where that collection is then linked to the mode. Here I've gone for using
it whenever treesitter-fold is active. "
  (easy-menu-define treesit-fold-menu global-map "Treesit Fold Menu"
    '("Context Menu"
      ["Toggle Folding" treesit-fold-toggle
       :visible (bound-and-true-p treesit-fold-mode)])))

;;; hooks

;; perhaps too gross of an application, but the *-ts-modes
;; eventually derive from this mode.
(when (locate-library "combobulate")

  (add-hook 'prog-mode-hook #'combobulate-mode))

;; Ensure the context menu for treesit-fold menu appears on right-click
(add-hook 'treesit-fold-mode-hook
          #'my-treesitter/add-treesit-fold-to-context-menu)

;; Ensure native fontlocking is disabled in matlab-mode in favour of tree-sit.
;; (add-hook 'matlab-mode-hook
;;           (lambda ()
;;             (treesit-hl-mode)
;;             (font-lock-mode -1)))


(provide 'treesit-support)
;;; treesit-support.el ends here

