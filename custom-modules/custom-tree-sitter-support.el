;; custom-tree-sitter-support.el -*- lexical-binding: t; -*-

;; Copyright (C) 2022
;; SPDX-License-Identifier: MIT

;; Author: System Crafters Community

;; Commentary

;; Support for tree-sitter in emacs.
;; Text here is from Micky's site, masteringemacs.org.
;; https://www.masteringemacs.org/article/how-to-get-started-tree-sitter

;;; Suggested additional keybindings

;;; customization
(require 'straight)

;; (use-package tree-sitter-indent)
;; (use-package tree-sitter-ispell)
(use-package treesit-fold)
(use-package combobulate)

(use-package treesit-auto
  :custom
  (treesit-auto-install 'prompt)
  :config
  (treesit-auto-add-to-auto-mode-alist 'all)
  (global-treesit-auto-mode))


(defvar treesit-fold-indicators-fringe)
(defvar treesit-fold-indicators-priority)
(defvar fold-state)
(declare-function treesit-fold-mode "treesit-fold")
(declare-function combobulate-mode "combobulate")

;; (require 'tree-sitter-indent)
;; (require 'tree-sitter-ispell)
(require 'treesit-fold)
(require 'combobulate)
(require 'treesit-auto)



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

(setq treesit-fold-indicators-fringe 'right-fringe)
(setq treesit-fold-indicators-priority 30)

(with-eval-after-load 'treesit-fold-indicators
  (define-key treesit-fold-indicators-mode-map [left-fringe mouse-1] nil))       ; ensure only the right fringe captures events for fold. The left is needed elsewhere!


(defun my-treesit-fold/state-at-point ()
  "Return the fold state at the current point in tree-sitter-fold.

Useful for implementing toggles for the mode in hydras."
  (interactive)
  (setq fold-state nil)
  (let* ((node (treesit-fold--foldable-node-at-pos))
         (overlay (when node (treesit-fold-overlay-at node))))
    (if (and overlay (overlay-get overlay 'invisible))
        (setq fold-state 'folded)
      (setq fold-state 'unfolded)))
  (message "fold-state: %s" fold-state))

(when (locate-library "combobulate")
  ;; perhaps too gross of an application, but the *-ts-modes
  ;; eventually derive from this mode.
  (add-hook 'prog-mode-hook #'combobulate-mode))

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
;; Ensure the context menu for treesit-fold menu appears on right-click
(add-hook 'treesit-fold-mode-hook
          #'my-treesitter/add-treesit-fold-to-context-menu)

;;; customization
;; (empty)

(provide 'custom-tree-sitter-support)
;;; custom-tree-sitter-support.el ends here

