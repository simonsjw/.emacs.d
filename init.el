;; init.el -- Simon's Emacs user customization file -*- lexical-binding: t; -*-

;;; Commentary:
;; This file is generated from config.org.  If you want to edit the
;; configuration, DO NOT edit init.el, edit config.org, instead.  Note that by
;; default, init.el is the target of the tangle as specified by #+PROPERTY in
;; line 3.


;; (defvar no-littering-var-directory (expand-file-name (concat "var/"  (getenv "MY_NAME"))
;;                         	                     user-emacs-directory)
;;   "Define the path `no-littering-var-directory`.")
;; (defvar no-littering-etc-directory (expand-file-name (concat "etc/"  (getenv "MY_NAME"))
;;                         	                     user-emacs-directory)
;;   "Define the path `no-littering-etc-directory`.")

;;; Code

(use-package menu-keys-support
  :ensure nil  ; Local file, not a package
  :load-path "custom-modules/")

(use-package lang-prog-mode
  :ensure nil
  :load-path "custom-modules/prog-mode/")


;; Step 1: Define no-littering paths early
;; (eval-and-compile
;;   (defvar no-littering-var-directory
;;     (expand-file-name "data/" user-emacs-directory)
;;     "Directory for variable data, set early for compile-angel.")
;;   (defvar no-littering-etc-directory
;;     (expand-file-name "config/" user-emacs-directory)
;;     "Directory for configuration data, set early for compile-angel."))

;; Step 2: Function to check and clone no-littering
(defun my-ensure-no-littering ()
  "Check if no-littering exists at ~/.emacs.d/no-littering, clone if missing."
  (let ((no-littering-dir (expand-file-name "no-littering/" user-emacs-directory))
        (no-littering-file (expand-file-name "no-littering/no-littering.el" user-emacs-directory))
        (git-url "https://github.com/emacscollective/no-littering.git"))
    (if (file-exists-p no-littering-file)
        (message "no-littering found at %s" no-littering-dir)
      (progn
        (message "no-littering not found, attempting to clone...")
        (if (executable-find "git")
            (progn
              (shell-command (format "git clone %s %s" git-url no-littering-dir))
              (if (file-exists-p no-littering-file)
                  (message "Successfully cloned no-littering to %s" no-littering-dir)
                (error "Failed to clone no-littering: %s not found" no-littering-file)))
          (error "Git not found on system, cannot clone no-littering"))))
    ;; Ensure the directory is added to load-path
    (add-to-list 'load-path no-littering-dir)))

;; Step 3: Ensure no-littering directories exist
(dolist (dir (list no-littering-var-directory no-littering-etc-directory))
  (unless (file-directory-p dir)
    (make-directory dir t)))

;; Step 4: Check and clone no-littering, then compile and load
(my-ensure-no-littering)
;; Optionally native compile no-littering after cloning
(let ((no-littering-el (expand-file-name "no-littering/no-littering.el" user-emacs-directory)))
  (when (file-exists-p no-littering-el)
    (native-compile no-littering-el)))
(require 'no-littering)
;; Log directories for debugging
(message "no-littering var directory set: %s" no-littering-var-directory)
(message "no-littering etc directory set: %s" no-littering-etc-directory)

;; Step 5: Configure compile-angel
(use-package compile-angel
  :ensure t
  :demand t
  :config
  ;; Set `compile-angel-verbose' to nil to silence compile-angel.
  (setq compile-angel-verbose t)
  
  ;; Enable native-compilation only
  (setq compile-angel-enable-byte-compile nil)
  (setq compile-angel-enable-native-compile t)   ; ensure we native compile only. 

  (compile-angel-on-load-mode)
  (add-hook 'emacs-lisp-mode-hook #'compile-angel-on-save-local-mode)
  (add-hook 'after-init-hook
            (lambda ()
              (when (get-buffer "*Compile-Log*")
                (bury-buffer "*Compile-Log*")))))

;; Step 6: Load custom-path-support.el
(load-file (expand-file-name "custom-modules/path-support.el" user-emacs-directory))

(defvar comp-speed 1 "Set native compilation.")
(setq comp-speed 1)

;; Ensure that quitting only occurs once Emacs finishes native compiling,
;; preventing incomplete or leftover compilation files in `/tmp`.
(defvar native-comp-async-query-on-exit t "Ensure that quitting only occurs once Emacs finishes native compiling.")
(setq native-comp-async-query-on-exit t)
(setq confirm-kill-processes t)

;; Non-nil means to native compile packages as part of their installation.
(setq package-native-compile t)

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

(require 'use-package)

(eval-and-compile
  (setq
   use-package-always-ensure t                                                    ; once working - remove this and save elpa package store to git repo.
   use-package-expand-minimally t))

;; ensure we can control how minor modes are shown in the modeline. 
(use-package delight)

        ;;;; Set up logging
(require 'logging-config)
(require 'system-tools)

;;(when (file-exists-p log/init-log)
;;(delete-file log/init-log))

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
(recentf-cleanup)
(savehist-mode 1)

(provide 'init)
       ;;; init.el ends here
