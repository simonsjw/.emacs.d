;;; init.el -- Simon's Emacs user customization file -*- lexical-binding: t; -*-

;;; Commentary:
;; This file is generated from config.org.  If you want to edit the
;; configuration, DO NOT edit init.el, edit config.org, instead.  Note that by
;; default, init.el is the target of the tangle as specified by #+PROPERTY in
;; line 3.

;;; Code:

;;;; Set up package.el
;;(unless (package-installed-p 'use-package)
;;  (package-refresh-contents)
;; (package-install 'use-package))

;; (require 'package)
(require 'use-package)

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

;; Ensure files are compiled natively and byte-wise.
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
  (add-hook 'emacs-lisp-mode-hook #'compile-angel-on-save-local-mode))

(require 'use-package)

(eval-and-compile
  (setq
   use-package-always-ensure t                                                    ; once working - remove this and save elpa package store to git repo.
   use-package-expand-minimally t))

;; Install `no-littering' if necessary
;; (unless (package-installed-p 'no-littering)
;;   (unless package-archive-contents
;;     (package-refresh-contents))
;;   (package-install 'no-littering))

(use-package no-littering
  :ensure t
  :demand t
  :vc (:url "https://github.com/emacscollective/no-littering.git"))


;; Load `no-littering'
;;(require 'no-littering)

;; ensure we can control how minor modes are shown in the modeline. 
(use-package delight)

;;;; Set up logging
(require 'custom-logging-config)
(require 'system-tools)

(log/debug :fn 'early-init
           :msg (concat "collected base paths from env vars, defined "
                        "eln-cache, no-littering-var-directory & "
                        "no-littering-etc-directory.")
           :obj user-emacs-directory)

(when (file-exists-p log/init-log)
  (delete-file log/init-log))

(log/debug :fn 'early-init
           :msg "loaded system tools."
           :obj user-emacs-directory)


(defvar my/REPO_LIST nil"The path to a list of git projects on the system.")
(setq my/REPO_LIST (getenv"REPO_LIST"))

;; This is the way we define a custom variable and add it to a group.
;; (defcustom var-name default-value doc-string
;;  :type 'type
;;  :group 'group)

(log/debug :fn 'early-init
           :msg "no-littering etc directory set"
           :obj no-littering-etc-directory)

;;;; custom.el
(defvar custom-file nil"Set location of custom.el.")
(setq custom-file
      (expand-file-name"custom.el" no-littering-etc-directory))

(let
    ((obj
      (concat"\n   ("
             (replace-regexp-in-string
              ";"";\n     "
              (mapconcat 'identity load-path";")) ")" )))
  
  (log/debug :fn 'early-init
             :msg "Added custom-modules to load-path."
             :obj obj))


;;;; Settings to help compilation.
(defvar comp-speed nil "Set native compilation.")
(setq comp-speed 1)

(defvar package-native-compile)
(setq package-native-compile t)


;; Record the filepath settings in the log.
(let
    ((native-comp-eln-load-path-string
      (mapconcat 'identity native-comp-eln-load-path" ;\n     "))
     (user-dir-payload
      "\n   (package-user-dir: %s;")
     (eln-dir-list-payloads
      "\n   native-comp-eln-load-path-strings:\n      %s")
     (eln-dir-list-ending-payload")"))

  (log/info :fn 'early-init
            :msg "Set package-user-dir and eln-cache directory."
            :obj (format
                  (concat
                   user-dir-payload
                   eln-dir-list-payloads eln-dir-list-ending-payload)
                  package-user-dir
                  native-comp-eln-load-path-string)))


(use-package bind-key)
(use-package helpful :ensure t)

;;; imports and declarations
(require 'bind-key)                                                              ; if you use any :bind variant
;;(require 'custom-logging-config)
(require 'custom-path-support)
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

(let
    ((native-comp-eln-load-path-string
      (mapconcat 'identity native-comp-eln-load-path ";\n      "))
     (eln-cache-fp-payload
      "\n   custom eln-cache: %s;")
     (user-dir-payload
      "\n   (package-user-dir: %s;")
     (eln-dir-list-payloads
      "\n   native-comp-eln-load-path-strings:\n      %s")
     (eln-dir-list-ending-payload ")"))

  (log/info :fn 'init
            :msg "check values of  package-user-dir and eln-cache directory."
            :obj (format
                  (concat
                   user-dir-payload
                   eln-cache-fp-payload
                   eln-dir-list-payloads
                   eln-dir-list-ending-payload)
                  package-user-dir
                  my-filepaths/eln-cache
                  native-comp-eln-load-path-string)))

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
          :msg "----Begin loading base functionality.----"
          :obj t)

(require 'custom-defaults-config)
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
          :msg "----Initial configuration complete----"
          :obj t)

;; IDE configuration.
(require 'treesit-support)
(require 'custom-undo-tree-support)

;;; Configuration phase

(require 'theme-support)
(require 'project-support)
(require 'completion-support)

;; user interface
(require 'custom-ui-config)
(require 'ibuffer-support)
(require 'tabline-support)
(require 'custom-speedbar-support)
(require 'modeline-support)
(require 'custom-spreadsheet-support)

;; Flymake configuration
(require 'custom-flymake-config)

;; Base IDE configuration.
(require 'custom-ide-config)

;; Debugger support
(require 'custom-debugger-support)

;; Handle writing config (Latex and the like)
(require 'writing-config)

;; Additional file format support.
(require 'custom-fileFormat-support)

;; version control
(require 'vc-support)

;; programming languages
(require 'lang--prog-mode)
(require 'lang-lisp)
(require 'lang-rust)
(require 'lang-python)
(require 'lang-q)
(require 'lang-systemd)
(require 'lang-web)
(require 'lang-bash)
(require 'lang-docker)
(require 'lang-vega)

;; database integration and SQL support.
(require 'db-support)

(require 'custom-terminal-support)
(require 'summary-support)
(require 'system-window-management)
(require 'startup-config)
(require 'menu-keys-support)

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
(defun crafted-startup-example/display-startup-time ()
  "Display the startup time after Emacs is fully initialized."
  (let*
      ((init-time (emacs-init-time))
       (logMessage (format "Crafted Emacs loaded in %s." init-time)))
    (progn
      (message (concat "\n" logMessage "\n"))
      (log/info :fn 'init
                :msg logMessage
                :obj t))))

(add-hook
 'emacs-startup-hook #'crafted-startup-example/display-startup-time)

;; start the server if its not already running.
;; To shutdown the server use the below: 
;;   M-x server-edit
;;   C-x C-c
;; (unless
;;     (server-running-p)
;;   (server-start))

(recentf-mode 1)
(recentf-cleanup)
(savehist-mode 1)

(provide 'init)
;;; init.el ends here
(custom-set-variables
 ;; custom-set-variables was added by Custom.
 ;; If you edit it by hand, you could mess it up, so be careful.
 ;; Your init file should contain only one such instance.
 ;; If there is more than one, they won't work right.
 '(package-vc-selected-packages
   '((no-littering :url
		   "https://github.com/emacscollective/no-littering.git"))))
(custom-set-faces
 ;; custom-set-faces was added by Custom.
 ;; If you edit it by hand, you could mess it up, so be careful.
 ;; Your init file should contain only one such instance.
 ;; If there is more than one, they won't work right.
 )
