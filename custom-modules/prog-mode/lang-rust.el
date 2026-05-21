;;; lang-rust.el --- Modern Rust development with rustic + eglot -*- lexical-binding: t; -*-

;;; Commentary:
;; Clean, native-Emacs-friendly Rust setup.
;; Uses rustic as the primary mode (best practice in 2026).
;; LSP via eglot, completion via corfu, tree-sitter, and nice cargo keybindings.

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

  ;; Prefer eglot diagnostics over flymake
  (add-hook 'eglot--managed-mode-hook (lambda () (flymake-mode -1)))

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
