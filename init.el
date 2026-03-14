;; init.el -- Simon's Emacs user customization file -*- lexical-binding: t; -*-

;;; Commentary:
;; This file is generated from config.org.  If you want to edit the
;; configuration, DO NOT edit init.el, edit config.org, instead.

;;; Code:

;; Load logging functionality
(require 'path-support)

(load-file (expand-file-name "custom-modules/system-tools/logging-config.el" user-emacs-directory))

(require 'logging-config)

;; === PACKAGE ARCHIVES (MELPA now guaranteed) ===
(require 'package)
(setq package-archives
      '(("gnu" . "https://elpa.gnu.org/packages/")
        ("nongnu" . "https://elpa.nongnu.org/nongnu/")
        ("melpa" . "https://melpa.org/packages/")
        ("elpa-devel" . "https://elpa.gnu.org/devel/")))
(setq package-archive-priorities
      '(("gnu" . 2)
        ("nongnu" . 1)
        ("melpa" . 0)
        ("elpa-devel" . 0)))
(package-initialize)

;; === Robust use-package bootstrap ===
(unless (package-installed-p 'use-package)
  (package-refresh-contents)
  (package-install 'use-package))
(require 'use-package)
(eval-and-compile
  (setq use-package-always-ensure t
        use-package-expand-minimally t))

(defvar epg-gpg-program "/usr/bin/gpg")

(menu-bar-mode -1)
(define-key input-decode-map [C-tab] [control-tab])
(global-set-key [control-tab] 'menu-bar-mode)

(customize-set-variable 'initial-major-mode 'fundamental-mode)

(use-package menu-keys-support
  :ensure nil
  :load-path "custom-modules/")

(use-package lang-prog-mode
  :ensure nil
  :load-path "custom-modules/prog-mode/")

;; 2. Compile-angel — must come immediately after the custom modules
;;    (this was the original Step 3 that you had before we moved paths)
(use-package compile-angel
  :demand t
  :config
  (setq compile-angel-verbose t
        compile-angel-enable-byte-compile nil
        compile-angel-enable-native-compile t)
  (compile-angel-on-load-mode 1)
  (add-hook 'emacs-lisp-mode-hook #'compile-angel-on-save-local-mode)
  (add-hook 'after-init-hook
            (lambda ()
              (when (get-buffer "*Compile-Log*")
                (bury-buffer "*Compile-Log*")))))

;; 3. Everything from your original Step 6 onward is unchanged
(defvar comp-speed 1 "Set native compilation.")
(setq comp-speed 1)

;; Ensure that quitting only occurs once Emacs finishes native compiling,
;; preventing incomplete or leftover compilation files in `/tmp`.
(defvar native-comp-async-query-on-exit t "Ensure that quitting only occurs once Emacs finishes native compiling.")
(setq native-comp-async-query-on-exit t)
(setq confirm-kill-processes t)

;; ensure we can control how minor modes are shown in the modeline. 
(use-package delight)

;;;; Set up logging
(require 'system-tools)

(log/debug :fn 'init
           :msg "loaded system tools."
           :obj user-emacs-directory)

(defvar my/REPO_LIST nil"The path to a list of git projects on the system.")
(setq my/REPO_LIST (getenv"REPO_LIST"))

;; This is the way we define a custom variable and add it to a group.
;; (defcustom var-name default-value doc-string
;;  :type 'type
;;  :group 'group)

(use-package bind-key)
(use-package helpful :ensure t)

;;; imports and declarations
(require 'bind-key)                                                              ; if you use any :bind variant
(require 'elisp-packages)

;; ensure the correct org-mode is sourced.
;; install the org package before it is used - otherwise it causes conflict.
;; (add-to-list
;;  'load-path
;;  (expand-file-name "custom-modules/org-support.el" user-emacs-directory))
(require 'org-support)

;; ensure tangling functionality is set up with org mode.
(add-hook
 'org-mode-hook
 (lambda ()
   (add-hook 'after-save-hook 'org-babel-tangle
             'run-at-end
             'only-in-org-mode)))

(log/info :fn 'init
          :msg "----Begin init.el processing----"
          :obj t)

;;; Load current environmental variables
  (defun load-environment-variables-from-file (file-path)
    "Load environment variables from a file specified by FILE-PATH."
    (with-temp-buffer
      (insert-file-contents file-path)
      (goto-char (point-min))
      (while (not (eobp))
        (let ((line
               (buffer-substring-no-properties
                (line-beginning-position) (line-end-position))))
          (when (string-match "\\([^=]+\\)=\\(.*\\)" line)
            (let ((key (match-string 1 line))
                  (value (match-string 2 line)))
              (setenv key value))))
        (forward-line 1))))

  (let ((envFile  (getenv "ENV_FILE")))
    (log/debug :fn 'init
               :msg "Load environmental variables from file."
               :obj envFile)
    (load-environment-variables-from-file envFile))

;;; Initial phase.
(log/info :fn 'init
          :msg "----Begin loading base functionality from defaults-config.----"
          :obj t)

(require 'defaults-config)
;; setup save histories.
(savehist-mode 1)
(setq history-length t)
(setq history-delete-duplicates t)
(setq savehist-save-minibuffer-history 1)
(setq savehist-additional-variables
      '(kill-ring search-ring regexp-search-ring))

;; Load the custom file if it exists.  Among other settings, this will
;; have the list `package-selected-packages', so we need to load that
;; before adding more packages.  The value of the `custom-file'
;; variable must be set appropriately, by default the value is nil.
;; This can be done here, or in the early-init.el file.
;; (filepath set to etc in no-littering config.)
(when (and custom-file (file-exists-p custom-file))
  (load custom-file nil 'nomessage))


(log/info :fn 'init
          :msg "----Load of base functionality complete----"
          :obj t)

;; IDE configuration.
(require 'treesit-support)
(require 'undo-tree-support)

;;; Configuration phase

(require 'theme-support)
(require 'project-support)
(require 'completion-support)

;; user interface
(require 'ui-config)
(require 'ibuffer-support)
(require 'tabline-support)
(require 'speedbar-support)
(require 'modeline-support)
(require 'vterm-support)
(require 'spreadsheet-support)

;; activate the logging view. 
(use-package logging-view-mode
  :ensure nil  ; Local file, not a package
  :load-path my-paths/logging-view-mode)

;; Flymake configuration
(require 'flymake-config)

;; Base IDE configuration.
(require 'ide-config)

;; Debugger support
(require 'debugger-support)

;; Handle writing config (Latex and the like)
(require 'writing-config)

;; Additional file format support.
(require 'fileFormat-support)

;; version control
(require 'vc-support)

;; programming languages
(require 'lang-prog-mode)
(require 'lang-bash)
(require 'lang-matlab)
(require 'lang-docker)
(require 'lang-lisp)
(require 'lang-python)
(require 'lang-q)
(require 'lang-rust)
(require 'lang-systemd)
(require 'lang-vega)
(require 'lang-web)

;; database integration and SQL support.
(require 'db-support)

(require 'terminal-support)
  (require 'summary-support)
  (require 'system-window-management)
  (require 'startup-config)
  (require 'LLM-support)
  (require 'menu-keys-support)
  (require 'server-support)

;; All the autoloaded packages are now loaded.
;; set elisp-flymake-byte-compile-load-path
(setq elisp-flymake-byte-compile-load-path load-path)
(let  ((elisp-flymake-byte-compile-load-path-string
        (mapconcat 'identity elisp-flymake-byte-compile-load-path ";\n      ")))
  (log/info :fn 'init
            :msg "Set elisp-flymake-byte-compile-load-path"
            :obj (concat "(" elisp-flymake-byte-compile-load-path-string ")")))

;; ---------------------------------------------
;; All config and support files are now loaded.

;; Profile emacs startup
(defun my-startup/display-startup-time ()
  "Display the startup time after Emacs is fully initialized."
  (log/info :fn 'init
            :msg (format "Emacs loaded in %s." (emacs-init-time))
            :obj t))

(add-hook
 'emacs-startup-hook #'my-startup/display-startup-time)

(setq inhibit-startup-screen nil                                                 ; stop the default splash screen
      inhibit-startup-message nil
      inhibit-startup-echo-area-message nil)

(setq initial-scratch-message nil)                                             ; remove the message in the scratch buffer.


(recentf-mode 1)
(savehist-mode 1)

(provide 'init)
;;; init.el ends here
