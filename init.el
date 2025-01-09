;;; init.el -- Simon's Crafted Emacs user customization file -*- lexical-binding: t; -*-

;;; Commentary:
;; This file is generated from config.org. If you want to edit the
;; configuration, DO NOT edit init.el, edit config.org, instead.
;; Note that by default, init.el is the target of the tangle as
;; specified by #+PROPERTY in line 3.

;;; Code



;;; imports and declarations
(require 'custom-logging-config)
(require 'recentf)
(require 'custom-path-support)
(require 'elisp-packages)

 ;; Don't log files touched in the init process. 
(recentf-mode -1)

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
     (straight-dir-payload
      "\n   straight-base-dir: %s;")
     (eln-dir-list-payloads
      "\n   native-comp-eln-load-path-strings:\n      %s")
     (eln-dir-list-ending-payload ")"))

  (log/info :fn 'init
            :msg "check values of  package-user-dir, eln-cache directory and straight-base-dir."
            :obj (format
                  (concat
                   user-dir-payload
                   straight-dir-payload
                   eln-cache-fp-payload
                   eln-dir-list-payloads
                   eln-dir-list-ending-payload)
                  package-user-dir
                  straight-base-dir
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

(require 'custom-init-config)
(require 'custom-defaults-config);
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
(require 'custom-tree-sitter-support)
(require 'custom-undo-tree-support)

;;; Configuration phase

(require 'custom-theme-support)
(require 'custom-project-support)
(require 'custom-completion-support)

;; user interface
(require 'custom-ui-config)
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
(require 'custom-writing-config)

;; Additional file format support.
(require 'custom-fileFormat-support)

;; version control
(require 'custom-vc-support)

;; programming languages
(require 'custom-lang--prog-mode)
(require 'custom-lang-lisp)
(require 'custom-lang-rust)
(require 'custom-lang-python)
(require 'custom-lang-q)
(require 'custom-lang-systemd)
(require 'custom-lang-web)
(require 'custom-lang-bash)
(require 'custom-lang-docker)
(require 'custom-lang-vega)

;; database integration and SQL support.
(require 'custom-db-support)

;;(require 'custom-hydra-config)
(require 'custom-terminal-support)
(require 'summary-support)
(require 'system-window-management)
(require 'custom-startup-config)
(require 'menu-keys-support)

;; All the autoloaded packages are now loaded.
;; set elisp-flymake-byte-compile-load-path
(setq elisp-flymake-byte-compile-load-path load-path)
(let  ((elisp-flymake-byte-compile-load-path-string
        (mapconcat 'identity elisp-flymake-byte-compile-load-path ";\n      ")))
  (log/info :fn 'init
            :msg (concat
                  "set elisp-flymake-byte-compile-load-path:\n   ("
                  elisp-flymake-byte-compile-load-path-string
                  ")")
            :obj t))

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

(provide 'init)
;;; init.el ends here
