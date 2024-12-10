;;; custom-lang-bash.el -*- lexical-binding: t; -*-

;;; Commentary:

;; A config for editing Bash scripts with enhanced syntax highlighting
;; via Tree-sitter (bash-ts-mode), LSP code completion via Eglot, and
;; on-the-fly syntax checking with Flymake.
;;
;; Prerequisites:
;;
;; - Emacs with Tree-sitter installed and the Bash grammar for Tree-sitter.
;; - bash-language-server for LSP features.
;; - shellcheck for Flymake syntax checking.

;;; Code:

;;; Packages phase

(use-package flymake-shellcheck)

(require 'sh-script)

;; Assuming bash-ts-mode is set up to be used with Tree-sitter
;; and is either autoloaded or required elsewhere in your config.
;;(require 'bash-ts-mode)

;; Ensure we have 

;; Eglot for LSP support
;; (add-to-list 'eglot-server-programs
;;             '(bash-ts-mode . ("bash-language-server" "start")))

;; (defun my/bash-ts-mode-setup ()
;;   "Setup function for `bash-ts-mode`."
;;   (when (executable-find "bash-language-server")
;;     (eglot-ensure)))

;; (add-hook 'bash-ts-mode-hook 'my/bash-ts-mode-setup)

;;(add-to-list 'auto-mode-alist '("\\.sh\\'" . bash-ts-mode))
(add-hook 'shell-script-mode-hook
          (lambda ()
            ;; Activate bash-ts-mode, replace with the correct function to activate bash-ts-mode
            (bash-ts-mode)

            ;; Start flymake for shell scripts
            (flymake-mode t)))

;; (require 'eglot)

;; Bash Language Server setup
;; (add-hook 'bash-ts-mode-hook
;;           (lambda ()
;;             (eglot-ensure)))

;; formatting function 
(defun my/format-bash-script-with-shfmt ()
  "Format the current Bash script using shfmt."
  (interactive)
  (let ((buffer (current-buffer))
        (point (point)))
    (shell-command-on-region (point-min) (point-max) "shfmt" buffer t)
    (goto-char point)))


;; linting function. 
;; (defun my/flymake-shellcheck-setup ()
;;   "Configure Flymake to use shellcheck."
;;   (when (and buffer-file-name
;;              (string-match-p "\\.sh\\'" buffer-file-name))
;;     (flymake-mode)
;;     (flymake-shellcheck-load)))
;; (add-hook 'sh-mode-hook 'my-flymake-shellcheck-setup)



;; Flymake for syntax checking
;; (require 'flymake-shellcheck)
;; (add-hook 'bash-ts-mode-hook 'flymake-shellcheck-load)

;; save the file automatically. 
;; (add-hook 'bash-ts-mode-hook 'my-programming-mode/auto-save-hook) 

;; Configuration for bash-ts-mode
;; (add-hook 'bash-ts-mode-hook
;;           (lambda ()
;;             ;; prefer spaces not tabs. 
;;             (setq indent-tabs-mode nil)
;;             ;; Enable Tree-sitter syntax highlighting
;;             (tree-sitter-hl-mode)))

;; Keybindings and other functionalities from bash-mode and shell-mode
;; may need to be manually integrated or adapted for bash-ts-mode.
;; This could involve setting up specific keybindings or functions
;; that replicate or call the equivalent functionality in bash-mode and shell-mode.

;; For example, to integrate a common shell-mode functionality:
;; (with-eval-after-load 'bash-ts-mode
;;   ;; Here you can define keybindings or functionalities specific to bash-ts-mode
;;   ;; Example: (define-key bash-ts-mode-map (kbd "YOUR-KEYBINDING") 'SOME-FUNCTION)

;;   ;;;;;;;;;;;;;
;;   ;; IDE layout
;;   ;; ----------
;;   ;; set preferred buffer width


;;   ;;;;;;;;;;;;;;;;;;;;;;;;
;;   ;; IDE functionality map
;;   ;; ---------------------
;;   ;; compiling the code
;;   ;; (keymap-set rust-ts-mode-map "C-c C-c C-u" #'rust-compile)

;;   ;; checking the code
;;   ;; (keymap-set rust-ts-mode-map "C-c C-c C-k" #'rust-check)

;;   ;; testing
;;   ;; (keymap-set rust-ts-mode-map "C-c C-c C-t" #'rust-test)

;;   ;; running the code
;;   ;; (keymap-set rust-ts-mode-map "C-c C-c C-r" #'rust-run)

;; linting

;;  formatting
(keymap-set bash-ts-mode-map "C-c C-f" #'my/format-bash-script-with-shfmt)

;;   ;; list all errors

;;   ;; formatting errors
;;   ;; (keymap-set rust-ts-mode-map "C-c C-n" #'rust-goto-format-problem)

;;   ;; lsp-execute-code-action
;;   ;; - run when lsp-ui displays code action at the top of the sideline

;;   ;; xref-find-definitions

;;   ;; xref-find-references

;;   ;; rustic-cargo-add-missing-dependencies

;;   ;;;;;;;;;;;;;;;;;;;
;;   ;; Project settings
;;   ;; ----------------


;;   )


(provide 'custom-lang-bash)
;;; custom-lang-bash.el ends here


