;;; debugger-support.el --- Provide Dape debugging -*- lexical-binding: t; -*-

;; Copyright (C) 2023
;; SPDX-License-Identifier: MIT

;; Author: Simon Watson

;;; Commentary:

;; Provide Dape debugging with customisation.
;; General Configuration:
;; ----------------------
;; dape-adapter-dir: Directory for adapter files.
;; dape-configs: Defines configurations for various adapters or debug sessions.
;; dape-command: Base command used to start the debug adapter.

;; User Interface:
;; ---------------
;; dape-display-source-buffer-action: Controls how source buffers are displayed.
;; dape-buffer-window-arrangement: Manages window arrangement for dape buffers.
;; dape-info-buffer-window-groups: Manages grouping for info buffers.

;; Info Buffer Customisation:
;; -------------------------
;; dape-info-variable-table-aligned                 : Controls alignment in variable tables.
;; dape-info-variable-table-row-config              : Configures rows in variable tables.
;; dape-info-thread-buffer-verbose-names            : Customize the appearance and information displayed in thread buffers.
;; dape-info-thread-buffer-locations                : Customize the appearance and information displayed in thread buffers.
;; dape-info-thread-buffer-addresses                : Customise the appearance and information displayed in thread buffers.
;; dape-info-stack-buffer-locations                 : Similar settings for stack buffers.
;; dape-info-stack-buffer-modules                   : Similar settings for stack buffers.
;; dape-info-stack-buffer-addresses                 : Similar settings for stack buffers.
;; dape-info-buffer-variable-format                 : Formatting options for variables in the info buffer.

;; REPL Settings:
;; ---------------------
;; dape-repl-use-shorthand                          : Enables shorthand commands in the REPL.
;; dape-repl-commands                               : Define custom commands available in the REPL.

;; Memory View Customisation:
;; -------------------------
;; dape-memory-page-size                            : Page size for memory views.
;; dape-info-hide-mode-line                         : Hides the mode line in specific buffers.

;; Miscellaneous Options:
;; ----------------------
;; dape-breakpoint-margin-string                    : Sets the string for breakpoints.
;; dape-request-timeout                             : Timeout for requests to the debugger.
;; dape-debug                                       : Enables debugging for dape itself.
;; dape-inlay-hints                                 : Enables inlay hints in code views.

;; Hooks
;; -----
;; dape provides various hooks that you can use to add custom behaviors:

;; Debug Session Hooks:
;; dape-start-hook                                  : Runs when a debug session starts.
;; dape-stopped-hook                                : Runs when a debug session stops.
;; dape-update-ui-hook                              : Runs when the UI updates (e.g., on new data or view refreshes).
;; dape-display-source-hook                         : Executes before displaying a source buffer.

;; UI and Completion:
;; completion-at-point-functions                    : Several instances in dape where this hook is used to handle in-buffer completion.

;; managing buffers and file operations
;; kill-buffer-hook
;; find-file-hook

;; Keymaps
;; -------
;; The dape package defines several keymaps, with the primary ones being:

;; dape-memory-mode-map                             ; Keybindings specific to the memory viewing mode.
;; dape-info-watch-mode-map                         : Keybindings for managing watched variables.

;; Suggested additional keybindings
;; (with-eval-after-load "prog-mode"
;;   (keymap-set prog-mode-map "C-c e n" #'flymake-goto-next-error)
;;   (keymap-set prog-mode-map "C-c e p" #'flymake-goto-prev-error))

;;; Code:

(defvar dape-configs)
(declare-function dape "dape")


;; The below keymap and minor mode are used in place of
;; dape-breakpoint-global-mode-map. This mode is made local only so does not
;; override mouse settings as `dape-breakpoint-global-mode' would.

(defvar my-dape/breakpoint-mode-map
  (let ((map (make-sparse-keymap)))
    (define-key map [left-fringe mouse-1] 'dape-mouse-breakpoint-toggle)
    (define-key map [left-margin mouse-1] 'dape-mouse-breakpoint-toggle)
    (define-key map [left-fringe mouse-2] 'dape-mouse-breakpoint-expression)
    (define-key map [left-margin mouse-2] 'dape-mouse-breakpoint-expression)
    (define-key map [left-fringe mouse-3] 'dape-mouse-breakpoint-log)
    (define-key map [left-margin mouse-3] 'dape-mouse-breakpoint-log)
    map)
  "Keymap for `dape-breakpoint-mode'.")

(define-minor-mode my-dape/breakpoint-mode
  "Adds fringe and margin breakpoint controls in the current buffer."
  ;; :lighter " DapeBP"
  ;; The keymap is automatically associated with the mode
  )


;; The latest version of jsonrpc is needed. You need to swap it in the
;; existing Emacs files then rebuild. This issue will be resolved in Emacs 30.


;;(straight-pull-all)
;;(straight-rebuild-all)
;; https://github.com/emacs-straight/dape
(use-package dape
  ;;:preface
  ;; By default dape shares the same keybinding prefix as `gud'
  ;; If you do not want to use any prefix, set it to nil.
  ;; (setq dape-key-prefix "\C-x\C-a")

  ;;:hook
  ;; Save breakpoints on quit
  ;;((kill-emacs . dape-breakpoint-save)
  ;; Load breakpoints on startup
  ;; (after-init . dape-breakpoint-load))

  :config
  ;; Turn on global bindings for setting breakpoints with mouse
  ;;(dape-breakpoint-global-mode)

  ;; Timeout is 30 seconds.
  (setq dape-request-timeout 60)

  ;; Info buffers to the right
  (setq dape-buffer-window-arrangement 'right)

  ;; Automatically enable dape-breakpoint-global-mode with dape-active-mode
  (add-hook 'dape-active-mode-hook #'my-dape/breakpoint-mode)

  ;; Disable dape-breakpoint-global-mode when dape-active-mode is turned off
  ;; It should not be active anyway since we use a local version of the keymaps.
  ;; However, this provides a double check.
  ;; (add-hook 'dape-active-mode-hook
  ;;           (lambda ()
  ;;             (add-hook 'kill-buffer-hook
  ;;                       (lambda ()
  ;;                         (when (derived-mode-p 'dape-active-mode)
  ;;                           (dape-breakpoint-global-mode -1)))
  ;;                       nil t)))

  ;; ensure the dape menu is active.
  ;;(add-hook 'dape-active-mode-hook '(lambda ()(easy-menu-add dape-menu)))

  ;; Info buffers like gud (gdb-mi)
  ;; (setq dape-buffer-window-arrangement 'gud)
  ;; (setq dape-info-hide-mode-line nil)

  ;; Pulse source line (performance hit)
  (add-hook 'dape-display-source-hook 'pulse-momentary-highlight-one-line)

  ;; Save breakpoints on quit
  (add-hook 'kill-emacs-hook 'dape-breakpoint-save)
  
  ;; Load breakpoints on startup
  (add-hook 'after-init-hook 'dape-breakpoint-load)

  ;; Showing inlay hints
  (setq dape-inlay-hints t)

  ;; Save buffers on startup, useful for interpreted languages
  ;; (add-hook 'dape-start-hook (lambda () (save-some-buffers t t)))

  ;; Kill compile buffer on build success
  ;; (add-hook 'dape-compile-hook 'kill-buffer)

  ;; Ensure dape opens in the project root.
  (setq dape-cwd-fn (lambda () (expand-file-name (nth 2 (project-current))))))

;; add dape config for python (debugging)
;; note debugpy must be installed in the environment in use.
;; Add custom configurations to `dape-configs` after loading `dape`

;; (with-eval-after-load 'dape
;;   ;; Ensure only one `debugpy` entry in `dape-configs`
;;   (assq-delete-all 'debugpy dape-configs)

;;   ;; Add a properly formatted `debugpy` entry
;;   (add-to-list 'dape-configs
;;                `(debugpy
;;                  modes (python-ts-mode python-mode)
;;                  command ,(or "python" (error "Command not set"))
;;                  command-args ["-m" "debugpy.adapter"]
;;                  :type "python"                                                ; other choice is "executable"
;;                  :request "launch"
;;                  :cwd dape-cwd-fn
;;                  :program (lambda () (buffer-file-name)) )))

;; (add-to-list 'dape-configs
;;              `(bash-debug-custom
;;                modes (bash-ts-mode)
;;                command "node"
;;                command-args (,(file-name-concat "~/.emacs.d/debug-adapters/bash-debug/extension/out/bashDebug.js"))
;;                :request "launch"
;;                :type "bash"
;;                :program ,(lambda () (buffer-file-name))
;;                :cwd ,default-directory
;;                fn (lambda (config)
;;                     (let ((bashdb-dir (file-name-concat "~/.emacs.d/debug-adapters/bash-debug/extension/bashdb_dir")))
;;                       (thread-first config
;;                                     (plist-put :pathBashdbLib bashdb-dir)
;;                                     (plist-put :pathBashdb (file-name-concat bashdb-dir "bashdb"))
;;                                     (plist-put :env `(:BASHDB_HOME ,bashdb-dir)))))))

(add-hook 'dape-start-hook
          (lambda ()
            ;; Ensure all necessary settings are in place
            (when (not (assoc 'debugpy dape-configs))
              (message "debugpy configuration missing in dape-configs"))))


(defun my-dape/get-dape-adapter-names()
  "This function provides a list of available adapter setup names.
The names are sourced from dape-configs written to messages and saved to
variable my-dape/adapter-names as well as returned by the function."
  (interactive)
  (require 'dape)
  (setq my-dape/adapter-names (mapcar #'car dape-configs))
  (message "\nList of Debug Tools:\n") ; Header
  (let ((index 1))
    (dolist (str my-dape/adapter-names)
      (message "%2d. %s" index str)
      (setq index (1+ index))))
  my-dape/adapter-names)


;; Define the variable if it doesn't exist
(defvar my-dape/current-config nil
  "Stores the current Dape configuration settings.")

(defun get-dape-config-settings (key)
  "Retrieve settings for a Dape configuration by KEY."
  (interactive
   (list
    (completing-read "Select Dape configuration: "
                     (mapcar #'car dape-configs) nil t)))
  (require 'dape)
  (let* ((symbol-key (intern key)) ; Convert string to symbol
         (config (assoc symbol-key dape-configs)))
    (if config
        (let ((settings (cdr config)))
          (setq my-dape/current-config settings)
          (message "Settings for %s: %s" key settings)
          settings)
      (message "No settings found for %s" key)
      nil)))

;; (straight-rebuild-package "dape")
(provide 'debugger-support)
;;; debugger-support.el ends here

                                                                                  ; LocalWords:  Keymaps dape repl
