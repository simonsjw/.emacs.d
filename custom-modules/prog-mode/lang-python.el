;;; lang-python.el --- Modern Python IDE with Eglot/Pyrefly, Apheleia/Ruff, and pytest -*- lexical-binding: t; -*-

;;; Commentary:
;;
;; Enhanced configuration for python-ts-mode in Emacs 30:
;; - Tree-sitter syntax and folding.
;; - Eglot + Pyrefly for type checking, completions, navigation, hover,
;;   inlay hints, and code actions/refactoring.
;; - Apheleia + Ruff for asynchronous on-save formatting and import
;;   organisation.
;; - pyvenv for Conda/virtualenv management.
;; - python-pytest for granular test running.
;; - Dape for debugpy-powered debugging.
;; - Comprehensive keybindings and menus.
;;
;; Key changes in this version:
;; - Switched to Apheleia for superior Ruff formatting (async,
;;   point-preserving).
;; - Rely on Pyrefly/Eglot for all Flymake diagnostics (no separate Ruff
;;   linting backend).
;; - Enhanced code actions/refactoring keybindings and menu.
;; - Retained pytest, path updates, inlay hints, and folding.
;;
;; Install: apheleia and python-pytest from MELPA.

;;; Package phase
(use-package pythonic)
(use-package pyvenv
  :config
  (pyvenv-tracking-mode 1))                                                       ; ensure automatic switching of python environments depending on project settings.
(use-package numpydoc)
(use-package dape)
(use-package treesit-fold)

(use-package python-view-data)

(use-package python-pytest)
(use-package apheleia
  :delight (apheleia-mode)
  :config
  (apheleia-global-mode 1)                                                        ; Enable globally
  ;; Configure Ruff for formatting + imports (chain: isort then format)
  (with-eval-after-load 'apheleia
    (setf (alist-get 'python-ts-mode apheleia-mode-alist) '(ruff-isort ruff))
    (setf (alist-get 'python-mode apheleia-mode-alist) '(ruff-isort ruff))))

(use-package flymake-ruff
  :ensure t
  :after flymake
  :hook (python-ts-mode . flymake-ruff-load)
  :custom
  (setq flymake-ruff-program-args
        '("check" "--quiet" "--format=json" "--ignore=D203,COM812"))              ; Match your toml ignores
  )

;;; Code:

;; functions for python to run before entering the mode.
(defun my-lang-python/update-python-path ()
  "Update exec-path and PATH for the active pyvenv (Conda/virtualenv compatible)."
  (when-let ((env-dir pyvenv-virtual-env))
    (let ((bin-dir (expand-file-name "bin" env-dir)))
      (setq exec-path (cons bin-dir (delete bin-dir exec-path)))
      (setenv "PATH" (concat bin-dir ":" (getenv "PATH"))))))


(defun my-lang-python/restart-eglot-on-env-change ()
  "Reconnect eglot if running after pyvenv activation."
  (when (and (eglot-current-server)
             (eglot-managed-p))
    (eglot-reconnect (eglot-current-server))))

;;;; Main function to set up python mode. 
(defun my-lang-python/python-mode-setup ()
  "Central setup for `python-ts-mode'."

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
          (dir-locals-set-directory-class project-root entry)  ; Update existing.
        (with-temp-file dir-locals-file
          (insert (format "%S" entry))))  ; Create new.
      (message "Saved env %s to %s" env-path dir-locals-file)))

  (defun my-lang-python/organize-imports ()
    "Organise imports in the current buffer using ruff-isort via Apheleia.
This runs only the import organisation formatter, preserving the buffer's
point and avoiding full reformatting."
    (interactive)
    (unless (derived-mode-p 'python-ts-mode 'python-mode)
      (user-error "Not in a Python mode"))
    (apheleia-format-buffer 'ruff-isort))

  (defun my-lang-python/generate-stub ()
    "Generate a typing stub (.pyi) for the current Python file using mypy's stubgen.
Runs stubgen on the current file, placing output in the default ./out directory
(or customise with --output if preferred)."
    (interactive)
    (unless (buffer-file-name)
      (user-error "No file associated with this buffer"))
    (let* ((file-path (file-name-nondirectory (buffer-file-name)))                ; e.g., "mymodule.py"
           (command (format "stubgen %s" file-path)))
      (shell-command command)
      (message "stubgen executed: %s" command)))


  ;; Define a ruff-format formatter
  ;; (for full Ruff formatting without isort).
  ;; This runs 'ruff format' to reformat code style.
  (setf (alist-get 'ruff-format apheleia-formatters)
        '("ruff" "format" "--quiet" "--stdin-filename" filepath "-"))

  (defun my-lang-python/format-buffer ()
    "Format the entire buffer using ruff-format via Apheleia.
This applies Ruff's code style formatter, preserving point."
    (interactive)
    (unless (derived-mode-p 'python-ts-mode 'python-mode)
      (user-error "Not in a Python mode"))
    (apheleia-format-buffer 'ruff-format))


  (defun my-lang-python/format-region ()
    "Format the selected region using ruff-format with range via a temporary file.
Falls back to the whole buffer if no region is active.
This provides Ruff with full buffer context for accurate formatting,
while only applying changes to the specified lines.

Uses `replace-buffer-contents' to update the buffer efficiently,
preserving point and markers where possible."
    (interactive)
    (unless (derived-mode-p 'python-ts-mode 'python-mode)
      (user-error "Not in a Python mode"))
    (if (not (use-region-p))
        (apheleia-format-buffer 'ruff-format)                                     ; Fallback to your async buffer format
      (let* ((start (region-beginning))
             (end (region-end))
             ;; Calculate 1-based line numbers; adjust end if at beginning of line
             (start-line (line-number-at-pos start))
             (end-line (line-number-at-pos end t))                                ; t adjusts if at bol, giving previous line
             (range-str (format "%d-%d" start-line end-line))
             (temp-file (make-temp-file "ruff-format-" nil ".py")))
        (unwind-protect
            (save-restriction
              (widen)                                                             ; Ensure full buffer is written, even if narrowed
              (write-region (point-min) (point-max) temp-file nil 'silent)
              ;; Run Ruff format on temp file with range (in-place)
              (with-temp-buffer
                (let ((exit-code (call-process "ruff" nil t t
                                               "format" "--range" range-str
                                               "--quiet" temp-file)))
                  (unless (zerop exit-code)
                    (error "Ruff format failed (exit %d): %s"
                           exit-code (buffer-string)))))
              ;; Replace current buffer contents with formatted temp
              ;; (only the range has changed, so rest remains identical)
              (let ((temp-buffer (find-file-noselect temp-file)))
                (replace-buffer-contents temp-buffer)
                (kill-buffer temp-buffer)))
          (when (file-exists-p temp-file)
            (delete-file temp-file))))))

  
  
  ;; LSP with Pyrefly
  (eglot-ensure)
  ;; no need to enable inlay hints on the server since they are default enabled.

  ;; Environment
  (pyvenv-mode 1)
  (my-lang-python/update-python-path)
  

  ;; Diagnostics: Solely from Pyrefly via Eglot (covers types + semantics)
  (flymake-mode 1)                                                                ; Eglot auto-adds its backend

  ;; Ya-snippets
  (yas-minor-mode 1)

  ;; Python dataview
  (require 'python-view-data)

  ;; Layout and settings
  (setq display-fill-column-indicator-column 88
        fill-column 88
        comment-fill-column 250
        comment-column 90
        py-docstring-fill-column 250
        python-indent-offset 4)
  (display-fill-column-indicator-mode 1)

  ;; doc strings with numpydoc
  (setq numpydoc-insert-examples-block t                                          ; Add Examples if needed.
        numpydoc-prompt-for-input t)                                              ; Prompt for descriptions (wraps long input).
  (add-hook 'numpydoc-mode-hook 'auto-fill-mode)                                  ; Auto-wrap at fill-column=88.

;;;; Dape integration.
  (dape-active-mode 1)
  ;; debugging the code with dape
  (my-dape/breakpoint-mode)
  
;;;; Folding
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

  (defvar my-custom-menus/python-folding-menu
    '("Folding"
      ["Toggle Fold" treesit-fold-toggle :keys "C-c f"
       :help "Toggle folding at point"])
    "Menu for folding-related functions in `python-ts-mode'.")
  
;;;; Imenu with treesitter.
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
  
;;;; debug/Testing
  (keymap-set python-ts-mode-map "C-x C-a d" #'dape)
  (keymap-set python-ts-mode-map "C-c t t" #'python-pytest-dispatch)
  (keymap-set python-ts-mode-map "C-c t r" #'python-pytest-repeat)

  (defvar my-custom-menus/python-pytest
    '("Debug/Pytest"
      ["Debug" :enable nil]
      ["Launch debugger" dape :keys "C-x C-a d"
       :help "Launch Dape debugger - ensure you have imported debugpy in your code."]
      "---"
      ["Test" :enable nil]
      ["Pytest options" python-pytest-dispatch :keys "C-c t t"
       :help "Display Pytest control panel in minibuffer."]
      ["Repeat test" python-pytest-repeat :keys "C-c t r"
       :help "Repeat the last pytest."])
    "Menu for running-related functions in `python-ts-mode'.")
  
;;;; running the code
  ;; these keys are already set in python mode. 
  ;; (keymap-set python-ts-mode-map "C-c C-c" #'eval-buffer)
  ;; (keymap-set python-ts-mode-map "C-c C-r" #'python-shell-send-region)
  ;; (keymap-set python-ts-mode-map "C-c C-l" #'python-shell-send-file)
  ;; (keymap-set python-ts-mode-map "C-c r p" #'run-python)                          ; run an inferior python process


  ;; keymaps for Pyvenv 
  (keymap-set python-ts-mode-map "C-c v w" #'pyvenv-workon)
  (keymap-set python-ts-mode-map "C-c v r" #'pyvenv-restart-python)
  (keymap-set python-ts-mode-map "C-c v s" #'my-lang-python/associate-env-with-project)
  (keymap-set python-ts-mode-map "C-c v a" #'pyvenv-activate)
  (keymap-set python-ts-mode-map "C-c v d" #'pyvenv-deactivate)
  (keymap-set python-ts-mode-map "C-c v c" #'pyvenv-create)

  (defvar my-custom-menus/python-running-menu
    '("Inferior process"
      "---"
      ["Inferior process" :enable nil]
      ["Eval Region" python-shell-send-region :help "Evaluate the marked region"]
      ["Eval Buffer" python-shell-send-buffer :help "Evaluate the entire buffer"]
      ["Eval file" python-shell-send-file :help "Evaluate a selected file"]
      "---"
      ["Evaluate" :enable nil]
      ["Run Python Process" run-python
       :help "Start an inferior Python process"]
      ["Restart Python Process" pyvenv-restart-python
       :help "Restart an inferior Python process"]
      "---"
      ["Environment" :enable nil]
      ["Select Environment" pyvenv-workon
       :help "Select a new active Python environment"]
      ["Associate project env"
       my-lang-python/associate-env-with-project
       :help "Creates .dir-locals.el in root of current project to start the current env automatically henceforth"]
      ["Activate an environment" pyvenv-activate
       :help "Activate a named Python environment"]
      ["Deactivate environment" pyvenv-deactivate
       :help "Deactivate the current Python environment"]
      ["Create an environment" pyvenv-create
       :help "Create a new Python environment"])
    "Menu for running-related functions in `python-ts-mode'.")

;;;; document thing at point:
  (keymap-set python-ts-mode-map "C-c h p" #'eldoc-box-help-at-point)             ; Key for hover docs
  (keymap-set python-ts-mode-map "C-c h b" #'eldoc-doc-buffer)                    ; Override default Eldoc
  (keymap-set python-ts-mode-map "C-c h h" #'eldoc)                               ; Trigger hover/signature help from eglot
  
  ;; menu
  (defvar my-custom-menus/python-documentation-menu
    '("Documentation"
      ["Show Docs at Point" eldoc-box-help-at-point :keys "C-c h p"
       :help "Display documentation for thing at point"]
      ["Show Docs in Buffer" eldoc-doc-buffer :keys "C-c h b"
       :help "Show documentation in a dedicated buffer"]
      ["Hover/Signature help" eldoc :keys "C-c h h"
       :help "Trigger signature help"]
      )
    "Menu for documentation-related functions in `python-ts-mode'.")

;;;; Errors/linting
  (keymap-set python-ts-mode-map "C-c e b" #'flymake-show-buffer-diagnostics)     ; list errors in buffer
  (keymap-set python-ts-mode-map "C-c e m" #'consult-flymake)                     ; list errors in minibuffer
  (keymap-set
   python-ts-mode-map "C-c e p" #'flymake-show-project-diagnostics)               ; list errors in project
  ;; formatting errors (not applicable)
  ;; (keymap-set python-ts-mode-map "C-c C-n" )
  (keymap-set python-ts-mode-map "C-c e n" #'flymake-goto-next-error)             ; go to next error
  (keymap-set python-ts-mode-map "C-c e l" #'flymake-goto-prev-error)             ; go to previous error.

  (defvar my-custom-menus/python-errors-menu
    '("Errors/Linting"
      ["Display errors" :enable nil]
      ["Error buffer" flymake-show-buffer-diagnostics :keys "C-c e b"
       :help "Show buffer errors in a buffer"]
      ["Project error buffer" flymake-show-project-diagnostics :keys "C-c e p"
       :help "Show project errors in a buffer"]
      ["Error list" consult-flymake :keys "C-c e m"
       :help "Show errors in the mini-buffer"]
      "---"
      ["Navigate errors" :enable nil]
      ["Next error" flymake-goto-next-error :keys "C-c e n"
       :help "Move to the next error."]
      ["Previous error" flymake-goto-prev-error :keys "C-c e l"
       :help "Move to the previous error."])
    "Menu for errors/linting-related functions in `python-ts-mode'.")

;;;; Navigation

  ;; (keymap-set python-ts-mode-map "C-c g s" #'consult-eglot-symbols)               ; show symbols in minibuffer
  ;; (keymap-set python-ts-mode-map "M-." #'eglot-find-definition)                   ; xref-find-definitions
  ;; (keymap-set python-ts-mode-map "M-?" #'xref-find-references)                    ; xref-find-references
  ;; (keymap-set python-ts-mode-map "C-c g t" #'eglot-find-type-definition)          ; Go to type definition
  ;; (keymap-set python-ts-mode-map "C-c g d" #'eglot-find-declaration)              ; Go to declaration
  ;; (keymap-set python-ts-mode-map "C-c g i" #'eglot-find-implementation)           ; Go to implementation
  ;; (keymap-set python-ts-mode-map "C-c g w" #'my-lang-python/find-symbol)          ; Workspace symbols

  ;; (defvar my-custom-menus/python-navigation-menu
  ;;   '("Navigate"
  ;;     "---"
  ;;     ;; start of def/class
  ;;     ;;end of def/class
  ;;     ;; mark def/class
  ;;     ;; jump to def/class
  ;;     ["Rename Symbol" eglot-rename :keys "C-c g r"
  ;;      :help "Rename the symbol at point"]
  ;;     ["Consult Symbols" consult-eglot-symbols :keys "C-c g s"
  ;;      :help "Show symbols in minibuffer"]
  ;;     "---"
  ;;     ["Find" :enable nil]
  ;;     ["Find Definition" eglot-find-definition :keys "M-."
  ;;      :help "Go to the definition of the symbol at point"]
  ;;     ["Find References" xref-find-references :keys "M-?"
  ;;      :help "Find all references to the symbol at point"]
  ;;     ["Find Type Definition" eglot-find-type-definition :keys "C-c g t"
  ;;      :help "Go to the type definition"]
  ;;     ["Find Declaration" eglot-find-declaration :keys "C-c g d"
  ;;      :help "Go to the declaration"]
  ;;     ["Find Implementation" eglot-find-implementation :keys "C-c g i"
  ;;      :help "Go to the implementation"]
  ;;     ["Workspace Symbols"  my-lang-python/find-symbol :keys "C-c g w"
  ;;      :help "Search for symbols in the workspace"])                              ; Workspace symbols
  ;;   "Menu for navigation-related functions in `python-ts-mode'.")
  
;;;; Variable/function references
  (defun my-lang-python/find-symbol ()
    (interactive)
    (eglot--request (eglot-current-server)
                    :workspace/symbol
                    (eglot--read-query "Workspace symbol: ")))

  (keymap-set python-ts-mode-map "C-c g s" #'consult-eglot-symbols)               ; show symbols in minibuffer
  (keymap-set python-ts-mode-map "C-c g m" #'consult-imenu)
  (keymap-set python-ts-mode-map "C-c g p" #'consult-imenu-multi)
  (keymap-set python-ts-mode-map "C-c g l" #'imenu-list)
  (keymap-set python-ts-mode-map "M-." #'xref-find-definitions)                   ; xref-find-definitions
  (keymap-set python-ts-mode-map "M-?" #'xref-find-references)                    ; xref-find-references
  (keymap-set python-ts-mode-map "C-c g t" #'eglot-find-typeDefinition)           ; Go to type definition
  (keymap-set python-ts-mode-map "C-c g d" #'eglot-find-declaration)              ; Go to declaration
  (keymap-set python-ts-mode-map "C-c g i" #'eglot-find-implementation)           ; Go to implementation
  (keymap-set python-ts-mode-map "C-c g w" #'my-lang-python/find-symbol)          ; Workspace symbols

  (defvar my-custom-menus/python-find-menu
    '("Find"
      ["Consult Symbols" consult-eglot-symbols :keys "C-c g s"
       :help "Show symbols in minibuffer"]
      ["Imenu minibuffer" consult-imenu :keys "C-c g m"
       :help "Search for symbols in the workspace"]
      ["Imenu project minibuffer" consult-imenu-multi :keys "C-c g p"
       :help "show a project-wide flattened Imenu-list in the minibuffer."]
      "--"
      ["Imenu" imenu-list :keys "C-c g l"
       :help "Show code structure in Imenu-list"]
      "--"
      ["locate" :enable nil]
      ["Find Definition" xref-find-definitions :keys "M-."
       :help "Go to the definition of the symbol at point"]
      ["Find References" xref-find-references :keys "M-?"
       :help "Find all references to the symbol at point"]
      ["Find Type Definition" eglot-find-typeDefinition :keys "C-c g t"
       :help "Go to the type definition"]
      ["Find Declaration" eglot-find-declaration :keys "C-c g d"
       :help "Go to the declaration"]
      ["Find Implementation" eglot-find-implementation :keys "C-c g i"
       :help "Go to the implementation"]
      ["Workspace Symbols"  my-lang-python/find-symbol :keys "C-c g w"
       :help "Search for symbols in the workspace"])                              ; Workspace symbols
    "Menu for navigation-related functions in `python-ts-mode'.")

;;;; add-missing-dependencies from Ruff + Eglot code related functions.
  ;; add format, import, remove import, sort import and fix import
  (keymap-set python-ts-mode-map "M-TAB" #'corfu-complete)
  (keymap-set python-ts-mode-map "C-c i b" #'my-lang-python/format-buffer)        ; Format whole buffer
  (keymap-set python-ts-mode-map "C-c i r" #'my-lang-python/format-region)        ; Format region or buffer
  (keymap-set python-ts-mode-map "C-c i n" #'eglot-rename)                        ; Rename symbol project wide
  (keymap-set python-ts-mode-map "C-c i o" #'my-lang-python/organize-imports)
  (keymap-set python-ts-mode-map "C-c i f" #'eglot-code-action-quickfix)

  (defvar my-custom-menus/python-fixes-menu
    '("Formats/Imports/Fixes"
      ["Format Buffer" my-lang-python/format-buffer :keys "C-c i b"
       :help "Apply full Ruff formatting to the buffer"]
      ["Format Region" my-lang-python/format-region :keys "C-c i r"
       :help "Apply Ruff formatting to the selected region"]
      "---"
      ["Rename Symbol" eglot-rename :keys "C-c i n"
       :help "Rename the symbol at point"]
      ["Complete symbol" corfu-complete :keys "M-TAB"
       :help "complete the symbol using the default choice"]
      "---"
      ["Organize Imports" my-lang-python/organize-imports :keys "C-c i o"
       :help "Organise imports in the buffer."]
      ["Quick Fix" eglot-code-action-quickfix :keys "C-c i f"
       :help "Apply quick fixes."])
    "Menu for imports and fixes-related functions in `python-ts-mode'.")

;;;; Eglot LSP management and additional features
  (defun my-lang-python/view-current-eglot-server ()
    (interactive)
    (switch-to-buffer
     (eglot-events-buffer (eglot-current-server))))

  (defun my-lang-python/view-current-eglot-stderr ()
    (interactive)
    (switch-to-buffer
     (eglot-stderr-buffer (eglot-current-server))))

  (keymap-set python-ts-mode-map "C-c l i" #'eglot-inlay-hints-mode)              ; Toggle inlay hints
  (keymap-set python-ts-mode-map "C-c l s" #'eglot)                               ; Start eglot
  (keymap-set python-ts-mode-map "C-c l r" #'eglot-reconnect)                     ; Reconnect to server
  (keymap-set python-ts-mode-map "C-c l q" #'eglot-shutdown)                      ; Shutdown server
  (keymap-set python-ts-mode-map "C-c l l"
              #'my-lang-python/view-current-eglot-server)                         ; Show events log buffer
  (keymap-set python-ts-mode-map "C-c l e"
              #'my-lang-python/view-current-eglot-stderr)                         ; Show stderr buffer

  (defvar my-custom-menus/python-lsp-menu
    '("Language server"
      ["Toggle inlay hints" eglot-inlay-hints-mode :keys "C-c l i"
       :help "Toggle inlay hints"]
      "---"
      ["Start" eglot :keys "C-c l s" :help "Start Eglot"]
      ["Reconnect" eglot-reconnect :keys "C-c l r" :help "Reconnect Eglot"]
      ["Shutdown" eglot-shutdown :keys "C-c l q" :help "Shutdown Eglot"]
      "---"
      ["Events log" my-lang-python/view-current-eglot-server :keys "C-c l l"
       :help "Show the eglot events log"]
      ["stderr log" my-lang-python/view-current-eglot-stderr :keys "C-c l e"
       :help "Show eglot errors log"])
    "Menu for Eglot management in `python-ts-mode'.")


  (keymap-set python-ts-mode-map "C-c d n" #'numpydoc-generate)
  (keymap-set python-ts-mode-map "C-c d s" #'my-lang-python/generate-stub)
  (defvar my-custom-menus/python-object-menu
    '("Python code helpers"
      ["NumpyDoc template" numpydoc-generate :keys "C-c d n"
       :help "Template for function/class doc strings."]
      "---"
      ["Generate stub" my-lang-python/generate-stub :keys "C-c d s"
       :help "Generate a stub file for the active buffer."])
    "Code writing helpers in `python-ts-mode'.")


;;; Construct menu map.
  ;; Integrate menus into the mode's menu-bar
  (easy-menu-add-item nil '("Tools") my-custom-menus/python-documentation-menu)
  (easy-menu-add-item nil '("Tools") "--")                                        ; Separator
  ;; (easy-menu-add-item nil '("Tools") my-custom-menus/python-testing-menu)
  (easy-menu-add-item nil '("Tools") my-custom-menus/python-running-menu)
  (easy-menu-add-item nil '("Tools") my-custom-menus/python-errors-menu)
  (easy-menu-add-item nil '("Tools") my-custom-menus/python-find-menu)
  (easy-menu-add-item nil '("Tools") my-custom-menus/python-fixes-menu)
  (easy-menu-add-item nil '("Tools") my-custom-menus/python-object-menu)
  (easy-menu-add-item nil '("Tools") my-custom-menus/python-lsp-menu)
  (easy-menu-add-item nil '("Tools") my-custom-menus/python-folding-menu)

  (defun my-lang-python/context-menu (menu click)
    "Build a custom context menu for Python mode from scratch.
MENU is the initial keymap (ignored here to override defaults).
CLICK is the mouse event (unused).
This creates a new keymap and populates it with specific items,
groups of submenus, and separators as per requirements."
    (let ((menu (make-sparse-keymap "Python Context")))
      ;; Add individual menu items for core actions.
      (easy-menu-add-item
       menu nil
       ["Format Region" my-lang-python/format-region
        :help "Apply Ruff formatting to the selected region"
        :keys "C-c i r"])
      (easy-menu-add-item
       menu nil
       ["Debug" dape
        :help "Start debugging with Dape"
        :keys "C-x C-a d"])
      (easy-menu-add-item
       menu nil
       ["Doc at Point" eldoc-box-help-at-point
        :help "Display documentation for thing at point"
        :keys "C-c h p"])
      (easy-menu-add-item
       menu nil
       ["Rename Symbol" eglot-rename
        :help "Rename the symbol at point project-wide"
        :keys "C-c g r"])
      (easy-menu-add-item
       menu nil
       ["Error Buffer" flymake-show-buffer-diagnostics
        :help "Show buffer diagnostics in a separate buffer"
        :keys "C-c e b"])
      (easy-menu-add-item
       menu nil
       ["Consult Symbols" consult-eglot-symbols
        :help "Show Eglot symbols in minibuffer"
        :keys "C-c g s"])
      (easy-menu-add-item
       menu nil
       ["Run Python" run-python
        :help "Start an inferior Python process"
        :keys "C-c r p"])
      (easy-menu-add-item
       menu nil
       ["NumpyDoc template" numpydoc-generate
        :help "Template for function/class doc strings."
        :keys "C-c d n"])
      (easy-menu-add-item
       menu nil
       ["Generate stub" my-lang-python/generate-stub
        :help "Generate a stub file for the active buffer."
        :keys "C-c d s"])
      (easy-menu-add-item
       menu nil
       ["Sort Imports" my-lang-python/organize-imports
        :help "Organise imports via Ruff-isort"
        :keys "C-c i o"])
      (easy-menu-add-item
       menu nil
       ["Fix" eglot-code-action-quickfix
        :help "Apply quick fixes via Eglot"
        :keys "C-c i f"])
      (easy-menu-add-item
       menu nil
       ["Toggle Fold" treesit-fold-toggle
        :help "Toggle folding at point"
        :keys "C-c f"])
      ;; Add separator after first group.
      (easy-menu-add-item menu nil "---")

      ;; Add the full custom submenus, separated by implied lines (using separators for visual space).
      (easy-menu-add-item menu nil my-custom-menus/python-fixes-menu)
      (easy-menu-add-item menu nil my-custom-menus/python-find-menu)
      (easy-menu-add-item menu nil my-custom-menus/python-errors-menu)
      (easy-menu-add-item menu nil my-custom-menus/python-documentation-menu)
      (easy-menu-add-item menu nil my-custom-menus/python-running-menu)
      (easy-menu-add-item menu nil my-custom-menus/diff-hl)
      (easy-menu-add-item menu nil my-custom-menus/python-pytest)
      (easy-menu-add-item menu nil my-custom-menus/python-folding-menu)
      (easy-menu-add-item menu nil my-custom-menus/python-lsp-menu)
      (easy-menu-add-item menu nil yas--minor-mode-menu)

      menu))

  (setq-local context-menu-functions '(my-lang-python/context-menu))

  (message
   "[%s ; DEBUG; my-lang/python-mode-setup]finished loading the defun ; ;"
   (current-time-string))
  )

;; update python interpreter paths after pyvenv activates a new environment. 
(add-hook
 'pyvenv-post-activate-hooks #'my-lang-python/update-python-path nil t)
;; restart eglot after pyvenv has changed environments. 
(add-hook 'pyvenv-post-activate-hooks #'my-lang-python/restart-eglot-on-env-change nil t)
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

(provide 'lang-python)
;;; lang-python.el ends here

;; LocalWords:  pyvenv isort numpydoc el CONDA WORKON ENV serviceEnv lang keymap
;; LocalWords:  eldoc defun minibuffer pycodestyle pycomplete gitlab melpa
;; LocalWords:  pythonic dape yasnippet debugpy adapter pytest customisations ui
                                                                                  ; LocalWords:  treesitter
