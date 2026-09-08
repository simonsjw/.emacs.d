;;; lang-python.el --- Python Tree-sitter, Pyrefly/Eglot, Ruff, and pytest. -*- lexical-binding: t; -*-

;; Copyright (C) 2026 Simon Watson
;; SPDX-License-Identifier: MIT

;; Author: Simon Watson

;;; Commentary:

;; Language module for `python-ts-mode': Eglot + Pyrefly, Apheleia
;; + Ruff, pyvenv, pytest, and Dape/debugpy.  Diagnostics are
;; Flymake via Eglot.  Load from `init.el' after `lang-prog-mode'.
;;
;; `my-lang-python/python-mode-setup' is the only `python-ts-mode-hook'
;; function.  It calls `my-lang-python/format-setup',
;; `my-lang-python/eglot-setup', and `my-lang-python/menus-setup'.
;; Leftovers (Sphinx, stubgen, jinx, Dape, folding, imenu, pytest and
;; running keys) stay in that hook.
;;
;; Map:
;;   Feature:    lang-python
;;   Load-after: path-support logging-config lang-prog-mode
;;   Load-phase: lang
;;   Keymaps:    keymaps-prog.el
;;   Docs:       docs/lang-python.org
;;   OS:         ruff pyrefly debugpy pytest conda

;;; Code:

(require 'path-support)
(require 'logging-config)
(log/debug :fn 'lang-python
           :msg "Starting load of the lang-python module."
           :obj t)

(require 'lang-prog-mode)
(require 'lang-python-format)
(require 'lang-python-eglot)
(require 'lang-python-menus)

(defvar python-ts-mode-map)
(defvar pyvenv-virtual-env)
(declare-function project-root "project")
(declare-function project-current "project")
(declare-function eglot-current-server "eglot")
(declare-function eglot-managed-p "eglot")
(declare-function eglot-reconnect "eglot")
(declare-function my-spell-check/add-words-to-jinx "defaults-config")
(declare-function my-dape/breakpoint-mode "debugger-support")
(declare-function my-outline-mode/outline-level "lang-prog-mode")

;; functions for python to run before entering the mode.
(defun my-lang-python/update-python-path ()
  "Update the variable `exec-path' and PATH for the active pyvenv."
  (when-let ((env-dir pyvenv-virtual-env))
    (let ((bin-dir (expand-file-name "bin" env-dir)))
      (setq exec-path (cons bin-dir (delete bin-dir exec-path)))
      (setenv "PATH" (concat bin-dir ":" (getenv "PATH"))))))


(defun my-lang-python/restart-eglot-on-env-change ()
  "Reconnect eglot if running after pyvenv activation."
  (when (and (eglot-current-server)
             (eglot-managed-p))
    (eglot-reconnect (eglot-current-server))))

;; Use Ipython
(setq python-shell-interpreter "ipython"                                          ; Use IPython executable.
      python-shell-interpreter-args                                               ; Command-line args for IPython.
      "--simple-prompt --matplotlib=inline")

(defun my-lang-python/save-env-to-project ()
  "Save the current pyvenv env to the project's .dir-locals.el.
Uses pyvenv-activate with the full path for reliability."
  (interactive)
  (unless pyvenv-virtual-env
    (user-error "No active virtualenv/Conda env"))
  (let* ((project-root (or (project-root (project-current))
                           (user-error "No project detected")))
         (dir-locals-file (expand-file-name ".dir-locals.el" project-root))
         (env-path pyvenv-virtual-env)
         (entry `((nil . ((pyvenv-activate . ,env-path))))))
    (if (file-exists-p dir-locals-file)
        (dir-locals-set-directory-class project-root entry)                     ; Update existing.
      (with-temp-file dir-locals-file
        (insert (format "%S" entry))))                                          ; Create new.
    (message "Saved env %s to %s" env-path dir-locals-file)))

(defun my-lang-python/generate-stub ()
  "Generate a typing stub (.pyi) for the current Python file.
Runs stubgen into a temporary directory (preserving its natural
package hierarchy), moves the .pyi file next to the source, then cleans up."
  (interactive)
  (unless (buffer-file-name)
    (user-error "No file associated with this buffer"))
  (let* ((py-file    (buffer-file-name))
         (file-dir   (file-name-directory py-file))
         (temp-dir   (make-temp-file "stubgen-" t))
         (command    (format "stubgen -o %s %s"
                             (shell-quote-argument temp-dir)
                             (shell-quote-argument py-file))))
    (shell-command command)
    ;; Relocate .pyi files, stripping the extra top-level package directory
    ;; that stubgen creates when __init__.py is present.
    (shell-command
     (format "find %s -name '*.pyi' -exec sh -c '
       for f; do
         rel=\"${f#$1/}\"
         new_rel=\"${rel#*/}\"
         target=\"$2/$new_rel\"
         mkdir -p \"$(dirname \"$target\")\"
         mv \"$f\" \"$target\"
       done' sh {} + %s %s"
             (shell-quote-argument temp-dir)
             (shell-quote-argument temp-dir)
             (shell-quote-argument file-dir)))
    (delete-directory temp-dir t)
    (message "stubgen completed: %s.pyi placed next to source file"
             (file-name-sans-extension (file-name-nondirectory py-file)))))

(defun my-lang-python/generate-dir-stubs ()
  "Generate typing stubs (.pyi) for all Python files in the current directory.
Runs stubgen into a temporary directory, moves the stubs to the correct
colocated locations, then removes the temporary directory."
  (interactive)
  (unless (buffer-file-name)
    (user-error "No file associated with this buffer"))
  (let* ((file-dir  (file-name-directory (buffer-file-name)))
         (temp-dir  (make-temp-file "stubgen-" t))
         (command   (format "stubgen -o %s %s"
                            (shell-quote-argument temp-dir)
                            (shell-quote-argument
                             (directory-file-name file-dir)))))
    (shell-command command)
    ;; Same relocation logic as the single-file function
    (shell-command
     (format "find %s -name '*.pyi' -exec sh -c '
       for f; do
         rel=\"${f#$1/}\"
         new_rel=\"${rel#*/}\"
         target=\"$2/$new_rel\"
         mkdir -p \"$(dirname \"$target\")\"
         mv \"$f\" \"$target\"
       done' sh {} + %s %s"
             (shell-quote-argument temp-dir)
             (shell-quote-argument temp-dir)
             (shell-quote-argument file-dir)))
    (delete-directory temp-dir t)
    (message "Directory stub generation completed: all .pyi files placed in source locations")))

;;;;;; Sphinx document integration.
(defun my-lang-python/sphinx-build ()
  "Build the Sphinx documentation for the current project."
  (interactive)
  (let ((default-directory (expand-file-name "docs" (project-root (project-current t)))))
    (compile "sphinx-build -b html . _build/html")))

(defun my-lang-python/sphinx-autobuild ()
  "Run sphinx-autobuild for live preview (requires sphinx-autobuild)."
  (interactive)
  (let ((default-directory (expand-file-name "docs" (project-root (project-current t)))))
    (async-shell-command "sphinx-autobuild . _build/html --open-browser")))

(defconst my-prog-mode/python-base-mode-accepted-words
  '("def" "class" "import" "from" "as" "return" "yield"
    "async" "await" "self" "cls" "None" "True" "False"
    "ValueError" "ImportError")
  "Python-specific keywords often appearing in comments/docstrings.")

;;;; Main function to set up python mode.
;;   -----------------------------------

(defun my-lang-python/python-mode-setup ()
  "Central setup for `python-ts-mode'.
This is the only `python-ts-mode-hook' function.  It calls the piece
setup functions, then leftover jinx/Dape/folding/imenu/pytest/running
forms."
  (my-lang-python/format-setup)
  (my-lang-python/eglot-setup)

  ;;;;;; spellchecking with jinx
  (my-spell-check/add-words-to-jinx
   my-prog-mode/python-base-mode-accepted-words 'session 'python-mode)

  ;;;;;; Dape integration.
  (dape-active-mode 1)
  ;; debugging the code with dape
  (my-dape/breakpoint-mode)

  ;;;;;; Folding
  ;; Set up customisations for outline-minor-mode.
  (setq-local outline-minor-mode-use-buttons 'in-margins)                         ; Show buttons
  (setq-local outline-blank-line t)                                               ; Blank line before headers
  (setq-local outline-minor-mode-highlight t)                                     ; Font-lock outlines
  (setq-local outline-regexp "^[[:space:]]*##+")                                  ; Match `##' and more.
  (setq-local outline-start "#")                                                  ; Start marker
  (setq-local outline-level #'my-outline-mode/outline-level)                      ; Custom level function
  (set-fringe-mode '(12 . 12))                                                    ; Set the fringe mode for python-ts-mode folding.
  (outline-minor-mode 1)                                                          ; Use outline-minor-mode
  (treesit-fold-mode 1)
  (treesit-fold-indicators-mode 1)
  (keymap-set python-ts-mode-map "C-c f" #'treesit-fold-toggle)                   ; set toggle keys

  ;;;;;; Imenu with treesitter.
  (setq-local treesit-simple-imenu-settings
              '(
                ("Classes" "\\`class_definition\\'" nil
                 treesit-defun-name)
                ("Functions" "\\`function_definition\\'"
                 (lambda (node)
                   ;; Include only top-level functions (not methods)
                   (not (equal (treesit-node-type (treesit-node-parent node))
                               "class_definition")))
                 treesit-defun-name)
                ("Methods" "\\`function_definition\\'"
                 (lambda (node)
                   ;; Include only methods (nested in classes)
                   (equal (treesit-node-type (treesit-node-parent node))
                          "class_definition"))
                 treesit-defun-name)
                ("Type Aliases" "\\`type_alias_statement\\'" nil
                 treesit-defun-name)
                ("Imports" "\\`import_statement\\'" nil
                 treesit-defun-name)
                ;; Optional: Decorated items are captured via their inner defs
                ;; Add more, e.g., ("Imports" "\\`import_statement\\'" nil treesit-defun-name)
                )
              )

  ;;;;;; debug/Testing
  (keymap-set python-ts-mode-map "C-x C-a d" #'dape)
  (keymap-set python-ts-mode-map "C-c t t" #'python-pytest-dispatch)
  (keymap-set python-ts-mode-map "C-c t r" #'python-pytest-repeat)

  ;;;;;; running the code
  ;; these keys are already set in python mode.
  ;; (keymap-set python-ts-mode-map "C-c C-c" #'eval-buffer)
  ;; (keymap-set python-ts-mode-map "C-c C-r" #'python-shell-send-region)
  ;; (keymap-set python-ts-mode-map "C-c C-l" #'python-shell-send-file)
  ;; (keymap-set python-ts-mode-map "C-c r p" #'run-python)                          ; run an inferior python process

  ;; keymaps for Pyvenv
  (keymap-set python-ts-mode-map "C-c v w" #'pyvenv-workon)
  (keymap-set python-ts-mode-map "C-c v r" #'pyvenv-restart-python)
  (keymap-set python-ts-mode-map "C-c v a" #'pyvenv-activate)
  (keymap-set python-ts-mode-map "C-c v d" #'pyvenv-deactivate)
  (keymap-set python-ts-mode-map "C-c v c" #'pyvenv-create)

  (my-lang-python/menus-setup)

  (let ((mode (derived-mode-all-parents major-mode)))
    (log/debug :fn 'my-lang-python/python-mode-setup
               :msg "Finished loading the python-mode-setup."
               :obj mode)))

;; Set up python mode when python-ts-mode is started.
(add-hook 'python-ts-mode-hook #'my-lang-python/python-mode-setup)

;; Make sure that files with the suffix .p are recognised as python files.
(add-to-list 'auto-mode-alist '("\\.p\\'" . python-ts-mode))
(add-to-list 'auto-mode-alist '("\\.py\\'" . python-ts-mode))

;; if a shebang is included in the file, choose mode by the implied interpreter,
;; Note that this overrides any file extension map.
(add-to-list 'interpreter-mode-alist '("python" . python-ts-mode))
(add-to-list 'interpreter-mode-alist '("python3" . python-ts-mode))

;; finally, ensure that any non-standard shebangs are covered. This overrides
;; interpreter-mode-alist. The difference is that interpreter-mode-alist
;; matches strictly the interpreter at the end of the shebang. Magic-mode-alist
;; can match any regular expression against the first line in a file.
(add-to-list 'magic-mode-alist
             '((lambda ()
                 (looking-at "^#!.*\\(python\\|python3\\)")) . python-ts-mode))


(log/debug :fn 'lang-python
           :msg "Ending load of the lang-python module."
           :obj t)

(provide 'lang-python)
;;; lang-python.el ends here
