;;; init.el -*- lexical-binding: t; -*-

;;; Commentary:

;; A starter config for editing Rust code.
;;
;; This configuration provides syntax highlighting via tree sitter
;; (with rust-ts-mode), LSP code completion via Eglot and Corfu, and
;; some helpful keybindings for Rust tooling.
;;
;; Prerequisites:
;;
;; - Emacs with Tree Sitter installed (this comes with Emacs 29).
;;
;; - A Rust language server (e.g. rust-analyzer).  You can install
;;   rust-analyzer via "rustup component add rust-analyzer".

;;; Code:

;;; Packages phase

(use-package rust-mode
  :init
  (setq rust-mode-treesitter-derive t))
(use-package cargo)
(use-package cargo-mode)
(use-package cargo-transient)

;; use Rustic for Rust mode
;; https://github.com/brotzeit/rustic
;; https://github.com/rust-lang/rust-mode
;; (installed as a dependency by package manager installing rustic.)
(use-package rustic)



;; (add-hook 'some-mode-hook #'eglot-ensure)

;; Set path to rust-analyzer
(setq rustic-analyzer-command '("~/.cargo/bin/rust-analyzer"))
;; below approach gives finer control. 
;; (setq rustic-analyzer-command
;;       '("rustup" "run" "stable" "rust-analyzer"))

;;; Key maps

;; Reassign the rust-mode keybindings to the rust-ts-mode map.
(defun my-lang/rust-setup()
  "All the functionality you need for rust."

  (eglot-ensure)

  ;; set defaults for cargo.el
  (setq cargo-process--command-bench "bench")
  (setq cargo-process--command-build "build")
  (setq cargo-process--command-clean "clean")
  (setq cargo-process--command-doc "doc")
  (setq cargo-process--command-doc-open "doc --open")
  (setq cargo-process--command-new "new")
  (setq cargo-process--command-init "init")
  (setq cargo-process--command-run "run")
  (setq cargo-process--command-run-bin "run --bin")
  (setq cargo-process--command-run-example "run --example")
  (setq cargo-process--command-search "search")
  (setq cargo-process--command-test "test")
  (setq cargo-process--command-current-test "test")
  (setq cargo-process--command-current-file-tests "test")
  (setq cargo-process--command-update "update")
  (setq cargo-process--command-fmt "fmt")
  (setq cargo-process--command-check "check")
  (setq cargo-process--command-clippy "clippy")
  (setq cargo-process--command-add "add")
  (setq cargo-process--command-rm "rm")
  (setq cargo-process--command-upgrade "upgrade")
  (setq cargo-process--command-audit "audit -f")
  (setq cargo-process--command-script "script")
  (setq cargo-process--command-watch "watch -x build")
  
  ;; (require 'rust-mode)
  ;; Although this setup uses the tree sitter mode (rust-ts-mode) for
  ;; Rust language buffers, we still want to have the official rust-mode
  ;; around so we can use its various commands.
  ;; https://github.com/rust-lang/rust-mode
;;; Configuration phase
  (require 'rustic)
  (require 'treesit-fold)  ; code folding using tree-sit
  
  ;; -------
  ;; Folding
  ;; -------
  ;; Set the fringe mode for python-ts-mode folding.
  (set-fringe-mode '(12 . 6))
  
  ;; Enable treesit-fold-mode
  (treesit-fold-mode 1)
  ;; Enable treesit-fold-indicators-mode
  (treesit-fold-indicators-mode 1)

  ;; You will probably want to tweak this variable, it determines how
  ;; quickly the completion prompt provides LSP suggestions when
  ;; typing. Be careful if you set it to 0 in a large project!
  (customize-set-variable 'corfu-auto-delay 0.25)

  ;; Use eglot as lsp client (perfer emacs native approaches!)
  
  ;; ensure flymake is turned off. 
  (add-hook 'eglot--managed-mode-hook (lambda () (flymake-mode -1)))
  ;; (add-hook 'rust-mode-hook 'eglot-ensure)  - not used in rustic
  (setq rustic-lsp-client 'eglot)

  ;; You will probably want to tweak this variable, it determines how
  ;; quickly the completion prompt provides LSP suggestions when
  ;; typing. Be careful if you set it to 0 in a large project!
  (customize-set-variable 'corfu-auto-delay 0.25)

  ;; customize faces:
  (set-faces
   '(rustic-compilation-column
     ((t (:inherit compilation-column-number))))
   '(rustic-compilation-line ((t (:foreground "LimeGreen")))))

  ;; Additional faces:
  ;; * rustic-message
  ;; * rustic-compilation-error
  ;; * rustic-compilation-warning
  ;; * rustic-compilation-info

  ;; Hooks
  ;; The Rust style guide recommends spaces no tabs.
  ;; This should already be done in the main programming mode settings. 
  ;;    (add-hook 'rust-mode-hook (lambda () (setq indent-tabs-mode nil)))
  
  ;;;; IDE layout
  ;;   ----------


  ;;;; IDE functionality map
  ;;   ---------------------
  ;; compiling the code
  (keymap-set rustic-mode-map "C-c C-c C-u" #'rust-compile)
  
  ;; checking the code
  (keymap-set rustic-mode-map "C-c C-c C-k" #'rust-check)
  
  ;; testing
  (keymap-set rustic-mode-map "C-c C-c C-t" #'rust-test)
  
  ;; running the code
  (keymap-set rustic-mode-map "C-c C-c C-r" #'rust-run)
  
  ;; linting
  (keymap-set rustic-mode-map "C-c C-c C-l" #'rust-run-clippy)
  
  ;; formatting
  (keymap-set rustic-mode-map "C-c C-f" #'rustic-format-buffer)
  
  ;; list all errors
  
  ;; formatting errors
  (keymap-set rustic-mode-map "C-c C-n" #'rust-goto-format-problem)
  
  ;; lsp-execute-code-action
  ;; - run when lsp-ui displays code action at the top of the sideline

  ;; xref-find-definitions
  
  ;; xref-find-references
  
  ;; rustic-cargo-add-missing-dependencies

  
  )

(add-hook 'rustic-mode-hook #'my-lang/rust-setup)

(provide 'lang-rust)
;;; lang-rust.el ends here
