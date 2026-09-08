;;; lang-python-menus.el --- Python Tools menu and context menu. -*- lexical-binding: t; -*-

;; Copyright (C) 2026 Simon Watson
;; SPDX-License-Identifier: MIT

;; Author: Simon Watson

;;; Commentary:

;; Piece of `lang-python': Tools menu entries and the Python context
;; menu.  `easy-menu-add-item', remaining `keymap-set', and
;; `context-menu-functions' run from `my-lang-python/menus-setup',
;; called by the loader hook.
;;
;; Map:
;;   Feature:    lang-python-menus
;;   Load-after: path-support logging-config
;;   Load-phase: lang
;;   Keymaps:    none
;;   Docs:       docs/lang-python-menus.org
;;   OS:         none

;;; Code:

(require 'path-support)
(require 'logging-config)
(log/debug :fn 'lang-python-menus
           :msg "Starting load of the lang-python-menus module."
           :obj t)

(defvar python-ts-mode-map)
(declare-function eglot--request "eglot")
(declare-function eglot--read-query "eglot")
(declare-function eglot-current-server "eglot")
(declare-function eglot-events-buffer "eglot")
(declare-function eglot-stderr-buffer "eglot")

(defvar my-custom-menus/python-folding-menu
  '("Folding"
    ["Toggle Fold" treesit-fold-toggle :keys "C-c f"
     :help "Toggle folding at point"])
  "Menu for folding-related functions in `python-ts-mode'.")

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
    ["Activate an environment" pyvenv-activate
     :help "Activate a named Python environment"]
    ["Deactivate environment" pyvenv-deactivate
     :help "Deactivate the current Python environment"]
    ["Create an environment" pyvenv-create
     :help "Create a new Python environment"])
  "Menu for running-related functions in `python-ts-mode'.")

(defvar my-custom-menus/python-project-menu
  '("Project"
    "---"
    ["Project Buffers" consult-project-buffer :help "Switch project buffers using consult"]
    ["Show diagnostics" flymake-show-project-diagnostics :help "Show diagnostics for all visited files in the project"]
    "---"
    ["Associate project env" my-lang-python/save-env-to-project
     :help "Creates .dir-locals.el in root of current project to start the current env automatically"]
    ["Create project dictionary" my-prog-mode/set-project-dictionary
     :help "Creates project dictionary and sets variable to point at it in .dir-locals.el"]
    "---"
    ["Vterm: visit current" my-vterm/cd-to-current-dir
     :help "Visits the directory associated with the active buffer in vterm."]
    "---"
    ["Find other project sources" consult-project-extra-find
     :help "Find other project sources"])
  "Menu for project related functions in `python-ts-mode'.")

(defvar my-custom-menus/python-documentation-menu
  '("Documentation"
    ["Show Docs at Point" eldoc-box-help-at-point
     :help "Display documentation for thing at point"]
    ["Show Docs in Buffer" eldoc-doc-buffer
     :help "Show documentation in a dedicated buffer"]
    ["Hover/Signature help" eldoc :help "Trigger signature help"]
    "---"
    ["Pydoc at Point" pydoc-at-point :help "Full pydoc for symbol at point"]
    ["Pydoc Search" pydoc :help "Interactive pydoc search for any object"]
    ["Pydoc in Browser" pydoc-browse :help "Browse pydoc in web server"])
  "Menu for documentation-related functions in `python-ts-mode'.")

(defvar my-custom-menus/python-errors-menu
  '("Errors/Linting"
    ["Display errors" :enable nil]
    ["Visit Project Buffers" my-flymake/preload-project-for-diagnostics
     :help "Visit project buffers without selecting them."]
    ["Error buffer" flymake-show-buffer-diagnostics
     :help "Show buffer errors in a buffer"]
    ["Project error buffer" my-flymake/show-project-diagnostics
     :help "Show project errors in a buffer"]
    ["Error list" consult-flymake
     :help "Show errors in the mini-buffer"]
    "---"
    ["Navigate errors" :enable nil]
    ["Next error" flymake-goto-next-error
     :help "Move to the next error."]
    ["Previous error" flymake-goto-prev-error
     :help "Move to the previous error."])
  "Menu for errors/linting-related functions in `python-ts-mode'.")

(defun my-lang-python/find-symbol ()
  "Search workspace symbols via the current Eglot server."
  (interactive)
  (eglot--request (eglot-current-server)
                  :workspace/symbol
                  (eglot--read-query "Workspace symbol: ")))

(defvar my-custom-menus/python-find-menu
  '("Navigation"
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
    ["Find Type Definition" eglot-find-type-definition :keys "C-c g t"
     :help "Go to the type definition"]
    ["Find Declaration" eglot-find-declaration :keys "C-c g d"
     :help "Go to the declaration"]
    ["Find Implementation" eglot-find-implementation :keys "C-c g i"
     :help "Go to the implementation"]
    ["Workspace Symbols"  my-lang-python/find-symbol :keys "C-c g w"
     :help "Search for symbols in the workspace"])
  "Menu for navigation-related functions in `python-ts-mode'.")

(defvar my-custom-menus/python-fixes-menu
  '("Formats/Imports/Fixes"
    ["Format Buffer" my-lang-python/format-buffer
     :help "Apply full Ruff formatting to the buffer"]
    ["Format Region" my-lang-python/format-region
     :help "Apply Ruff formatting to the selected region"]
    "---"
    ["Rename Symbol" eglot-rename
     :help "Rename the symbol at point"]
    ["Complete symbol" corfu-complete :keys "M-TAB"
     :help "complete the symbol using the default choice"]
    "---"
    ["Organize Imports" my-lang-python/organize-imports
     :help "Organise imports in the buffer."]
    ["Quick Fix" eglot-code-action-quickfix
     :help "Apply quick fixes."])
  "Menu for imports and fixes-related functions in `python-ts-mode'.")

(defun my-lang-python/view-current-eglot-server ()
  "Switch to the Eglot events buffer for the current server."
  (interactive)
  (switch-to-buffer
   (eglot-events-buffer (eglot-current-server))))

(defun my-lang-python/view-current-eglot-stderr ()
  "Switch to the Eglot stderr buffer for the current server."
  (interactive)
  (switch-to-buffer
   (eglot-stderr-buffer (eglot-current-server))))

(defvar my-custom-menus/python-lsp-menu
  '("Language server"
    ["Toggle inlay hints" eglot-inlay-hints-mode
     :help "Toggle inlay hints"]
    "---"
    ["Start" eglot :help "Start Eglot"]
    ["Reconnect" eglot-reconnect :help "Reconnect Eglot"]
    ["Shutdown" eglot-shutdown :help "Shutdown Eglot"]
    "---"
    ["Events log" my-lang-python/view-current-eglot-server
     :help "Show the eglot events log"]
    ["stderr log" my-lang-python/view-current-eglot-stderr
     :help "Show eglot errors log"])
  "Menu for Eglot management in `python-ts-mode'.")

(defvar my-custom-menus/python-object-menu
  '("Python code helpers"
    ["NumpyDoc template" numpydoc-generate :keys "C-c d n"
     :help "Template for function/class doc strings."]
    "---"
    ["Generate stub" my-lang-python/generate-stub :keys "C-c d s"
     :help "Generate a stub file for the active buffer."]
    ["Generate dir stubs" my-lang-python/generate-dir-stubs :keys "C-c d d"
     :help "Generate stub files for the active buffer directory."])
  "Code writing helpers in `python-ts-mode'.")

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
      :help "Apply Ruff formatting to the selected region"])
    (easy-menu-add-item
     menu nil
     ["Debug" dape
      :help "Start debugging with Dape"])
    (easy-menu-add-item
     menu nil
     ["Doc at Point" eldoc-box-help-at-point
      :help "Display documentation for thing at point"])
    (easy-menu-add-item
     menu nil
     ["Rename Symbol" eglot-rename
      :help "Rename the symbol at point project-wide"])
    (easy-menu-add-item
     menu nil
     ["Error Buffer" flymake-show-buffer-diagnostics
      :help "Show buffer diagnostics in a separate buffer"])
    (easy-menu-add-item
     menu nil
     ["Consult Symbols" consult-eglot-symbols
      :help "Show Eglot symbols in minibuffer"])
    (easy-menu-add-item
     menu nil
     ["Run Python" run-python
      :help "Start an inferior Python process"])
    (easy-menu-add-item
     menu nil
     ["NumpyDoc template" numpydoc-generate
      :help "Template for function/class doc strings."])
    (easy-menu-add-item
     menu nil
     ["Generate stub" my-lang-python/generate-stub
      :help "Generate a stub file for the active buffer."])
    (easy-menu-add-item
     menu nil
     ["Generate dir stubs" my-lang-python/generate-dir-stubs
      :help "Generate stub files (all files in the active buffers directory)."])
    (easy-menu-add-item
     menu nil
     ["Sort Imports" my-lang-python/organize-imports
      :help "Organise imports via Ruff-isort"])
    (easy-menu-add-item
     menu nil
     ["Fix" eglot-code-action-quickfix
      :help "Apply quick fixes via Eglot"])
    (easy-menu-add-item
     menu nil
     ["Toggle Fold" treesit-fold-toggle
      :help "Toggle folding at point"])
    (easy-menu-add-item
     menu nil
     ["New chat" my-llm/new-chat
      :help "Open a chat buffer."])
    (easy-menu-add-item
     menu nil
     ["Start Aidermacs" my-llm/aidermacs-menu
      :help "Start Aidermacs in the project."])

    ;; separator after the one-shot items
    (easy-menu-add-item menu nil "---")

    ;; submenus belong on THIS context map, not on python-ts-mode-map
    (easy-menu-add-item menu nil my-custom-menus/python-fixes-menu)
    (easy-menu-add-item menu nil my-custom-menus/python-find-menu)
    (easy-menu-add-item menu nil my-custom-menus/python-errors-menu)
    (easy-menu-add-item menu nil my-custom-menus/python-documentation-menu)
    (easy-menu-add-item menu nil my-custom-menus/python-running-menu)
    (easy-menu-add-item menu nil my-custom-menus/diff-hl)
    (easy-menu-add-item menu nil my-custom-menus/python-project-menu)
    (easy-menu-add-item menu nil my-custom-menus/python-pytest)
    (easy-menu-add-item menu nil my-custom-menus/python-folding-menu)
    (easy-menu-add-item menu nil my-custom-menus/python-lsp-menu)
    (when (and (boundp 'yas-minor-mode-map)
               (keymapp yas-minor-mode-map))
      (let ((yas-menu (or (lookup-key yas-minor-mode-map [menu-bar yasnippet])
                          (and (boundp 'yas--minor-mode-menu)
                               (keymapp yas--minor-mode-menu)
                               yas--minor-mode-menu))))
        (when (keymapp yas-menu)
          (define-key menu [snippets] (cons "Snippets" yas-menu)))))

    menu))

(defun my-lang-python/menus-setup ()
  "Install Python Tools menus, remaining keys, and the context menu.
Do not call this at `require'; the loader hook invokes it."
  (keymap-set python-ts-mode-map "C-c h p" #'eldoc-box-help-at-point)
  (keymap-set python-ts-mode-map "C-c h b" #'eldoc-doc-buffer)
  (keymap-set python-ts-mode-map "C-c h h" #'eldoc)
  (keymap-set python-ts-mode-map "C-c h d" #'pydoc-at-point)
  (keymap-set python-ts-mode-map "C-c h s" #'pydoc)
  (keymap-set python-ts-mode-map "C-c h w" #'pydoc-browse)
  (keymap-set python-ts-mode-map "C-c g s" #'consult-eglot-symbols)
  (keymap-set python-ts-mode-map "C-c g m" #'consult-imenu)
  (keymap-set python-ts-mode-map "C-c g p" #'consult-imenu-multi)
  (keymap-set python-ts-mode-map "C-c g l" #'imenu-list)
  (keymap-set python-ts-mode-map "M-." #'xref-find-definitions)
  (keymap-set python-ts-mode-map "M-?" #'xref-find-references)
  (keymap-set python-ts-mode-map "C-c g t" #'eglot-find-type-definition)
  (keymap-set python-ts-mode-map "C-c g d" #'eglot-find-declaration)
  (keymap-set python-ts-mode-map "C-c g i" #'eglot-find-implementation)
  (keymap-set python-ts-mode-map "C-c g w" #'my-lang-python/find-symbol)
  (keymap-set python-ts-mode-map "M-TAB" #'corfu-complete)
  (keymap-set python-ts-mode-map "C-c d n" #'numpydoc-generate)
  (keymap-set python-ts-mode-map "C-c d s" #'my-lang-python/generate-stub)
  (keymap-set python-ts-mode-map "C-c d d" #'my-lang-python/generate-dir-stubs)

  (easy-menu-add-item python-ts-mode-map '("Tools") my-custom-menus/python-documentation-menu)
  (easy-menu-add-item python-ts-mode-map '("Tools") "--")
  (easy-menu-add-item python-ts-mode-map '("Tools") my-custom-menus/python-running-menu)
  (easy-menu-add-item python-ts-mode-map '("Tools") my-custom-menus/python-errors-menu)
  (easy-menu-add-item python-ts-mode-map '("Tools") my-custom-menus/python-find-menu)
  (easy-menu-add-item python-ts-mode-map '("Tools") my-custom-menus/python-fixes-menu)
  (easy-menu-add-item python-ts-mode-map '("Tools") my-custom-menus/python-object-menu)
  (easy-menu-add-item python-ts-mode-map '("Tools") my-custom-menus/python-lsp-menu)
  (easy-menu-add-item python-ts-mode-map '("Tools") my-custom-menus/python-folding-menu)

  (setq-local context-menu-functions '(my-lang-python/context-menu)))

(log/debug :fn 'lang-python-menus
           :msg "Finishing load of the lang-python-menus module."
           :obj t)

(provide 'lang-python-menus)
;;; lang-python-menus.el ends here
