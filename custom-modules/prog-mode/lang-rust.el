;;; lang-rust.el --- Rustic plus rust-analyzer via Eglot. -*- lexical-binding: t; -*-

;; Copyright (C) 2026 Simon Watson
;; SPDX-License-Identifier: MIT

;; Author: Simon Watson

;;; Commentary:

;; Language module for Rust: `rustic' with Eglot / rust-analyzer
;; and Flymake diagnostics enabled.  Load from `init.el'.
;;
;; Map:
;;   Feature:    lang-rust
;;   Load-after: path-support logging-config
;;   Load-phase: lang
;;   Keymaps:    keymaps-prog.el
;;   Docs:       docs/lang-rust.org
;;   OS:         rust-analyzer cargo

;;; Code:

(require 'path-support)
(require 'logging-config)

(log/debug :fn 'lang-rust
           :msg "Starting load of the lang-rust module."
           :obj t)

;;; ------------------------------------------------------------------
;;; Rust Mode (rustic is the recommended all-in-one package)
;;; ------------------------------------------------------------------

(use-package rustic
  :hook (rustic-mode . my-lang/rust-setup)
  :config
  (setq rustic-lsp-client 'eglot)
  (setq rustic-analyzer-command '("~/.cargo/bin/rust-analyzer"))
  ;; If you prefer rustup-managed rust-analyzer:
  ;; (setq rustic-analyzer-command '("rustup" "run" "stable" "rust-analyzer"))
  )

;;; ------------------------------------------------------------------
;;; Main setup function (runs on every Rust buffer)
;;; ------------------------------------------------------------------

(defun my-lang/rust-setup ()
  "All the functionality you need for Rust development."
  (eglot-ensure)

  ;; Completion popup delay (tweak if needed)
  (customize-set-variable 'corfu-auto-delay 0.25)

  ;; Tree-sitter code folding
  (require 'treesit-fold)
  (set-fringe-mode '(12 . 6))
  (treesit-fold-mode 1)
  (treesit-fold-indicators-mode 1)

  ;; Nicer faces in the compilation buffer
  (custom-set-faces
   '(rustic-compilation-column
     ((t (:inherit compilation-column-number))))
   '(rustic-compilation-line ((t (:foreground "LimeGreen")))))

  ;; ----------------------------------------------------------------
  ;; Keybindings (all rustic native commands)
  ;; ----------------------------------------------------------------
  (keymap-set rustic-mode-map "C-c C-c C-u" #'rustic-cargo-build)
  (keymap-set rustic-mode-map "C-c C-c C-k" #'rustic-cargo-check)
  (keymap-set rustic-mode-map "C-c C-c C-t" #'rustic-cargo-test)
  (keymap-set rustic-mode-map "C-c C-c C-r" #'rustic-cargo-run)
  (keymap-set rustic-mode-map "C-c C-c C-l" #'rustic-cargo-clippy)
  (keymap-set rustic-mode-map "C-c C-f"     #'rustic-format-buffer)
  (keymap-set rustic-mode-map "C-c C-n"     #'rustic-goto-format-problem))

;;; ------------------------------------------------------------------
;;; Final logging
;;; ------------------------------------------------------------------

(log/debug :fn 'lang-rust
           :msg "Ending load of the lang-rust module."
           :obj t)

(provide 'lang-rust)
;;; lang-rust.el ends here
