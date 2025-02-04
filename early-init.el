;;; early-init.el --- Emacs early initialization for Crafted Emacs  -*- lexical-binding: t; no-byte-compile: t -*-

;;; Commentary:
;;  Work that is done before Emacs can be initialised.
;;  Mainly setting up the package management process and
;;  then setting a few variables needed to initialise the ide.
;;
;;; Code:

;;; Base file paths needed for package management
;; set paths used in package management before no-littering is set up to
;; respect no-littering file paths.
;; Use the `MY_NAME` environment variable to set machine specific
;; locations for use with no littering.

(defvar user-emacs-directory nil "The Emacs base directory.")
(setq user-emacs-directory (getenv "USER_EMACS_DIRECTORY"))

(defvar envvar/SYSTEM_NAME nil
"The name of the system on which we are currently running Emacs.")
(setq envvar/SYSTEM_NAME (getenv "MY_NAME"))

;; Use the `envvar/SYSTEM_NAME` environment variable to set machine specific
;; locations for use with no littering.

(defvar no-littering-var-directory nil"Create the path `no-littering-var-directory`.")
(setq no-littering-var-directory
      (expand-file-name (concat "var/"  envvar/SYSTEM_NAME )
  		        user-emacs-directory))

(defvar no-littering-etc-directory nil "Create the path `no-littering-etc-directory'.")
(setq no-littering-etc-directory
      (expand-file-name (concat "etc/" envvar/SYSTEM_NAME)
  		        user-emacs-directory))

;; Define and add directories to load-path
(mapc (lambda (dir)
        (make-directory dir t)                                                    ; Ensure the directory exists.
        (add-to-list 'load-path dir))                                             ; Add the directories to the load-path.
      (list
       (setq modules-user-dir
             (expand-file-name "custom-modules/" user-emacs-directory))           ; set up the custom modules building emacs functionality.
       (setq modules-system-tools
	           (expand-file-name "system-tools/"modules-user-dir))                  ; set up the tools on which the custom modules rely.
       (setq modules-prog-mode
	           (expand-file-name "prog-mode/" modules-user-dir))                    ; set up the custom modules which are specific to languages under prog-mode.
       (setq my-filepaths/eln-cache
             (expand-file-name "eln-cache/" no-littering-etc-directory))          ; Set up the eln-cache path.
       (setq packages-custom-dir
             (expand-file-name "custom-packages/" user-emacs-directory))          ; set up the home directory for custom packages in package.el
       ;; Set up package.el
       (setq package-user-dir
             (expand-file-name "package/" no-littering-etc-directory))
       (setq package-gnupghome-dir (concat package-user-dir "gnupg/"))
       )
      )

(setq epg-gpg-program "/usr/bin/gpg")                                             ; set up the path to the encryption application on the system.


;;;; Garbage collection, font & eln caching:
;; Increase the GC threshold for faster startup
;; The default is 800 kilobytes.  Measured in bytes.
(setq gc-cons-threshold (* 50 1000 1000))
(startup-redirect-eln-cache my-filepaths/eln-cache)                               ; Set the eln-cache directory for compiled files to the defined path.
(setq inhibit-compacting-font-caches t)                                           ; Don't compact font caches during GC.


;;;; UI configuration
;; Remove some unneeded UI elements (the user can turn back on anything they wish)
(setq inhibit-startup-message t)                                                  ; stop the default splash screen
;; (setq initial-scratch-message nil)                                             ; remove the message in the scratch buffer.
(push '(tool-bar-lines . 0) default-frame-alist)
(push '(vertical-scroll-bars) default-frame-alist)
(push '(mouse-color . "white") default-frame-alist)
(menu-bar-mode -1)                                                                ; Turn off Menu-Bar and then bind it to C-TAB (Ctrl + <TAB>) to toggle on if needed.
(define-key input-decode-map [C-tab] [control-tab])
(global-set-key [control-tab] 'menu-bar-mode)

;; Make the initial buffer load faster by setting its mode to fundamental-mode
;; and set size of the initial emacs window.
(customize-set-variable 'initial-major-mode 'fundamental-mode)                    ; Make the initial buffer load faster by setting its mode to fundamental-mode
(add-to-list 'initial-frame-alist '(fullscreen . maximized))                      ; start the initial frame maximised
(add-to-list 'default-frame-alist '(fullscreen . maximized))                      ; start every frame maximised
;; Alternative - set the initial frame size default to a specific size.
;;     (add-to-list 'default-frame-alist '(height . 150))
;;     (add-to-list 'default-frame-alist '(width  . 300))


;;;; Set up package.el
(unless (package-installed-p 'use-package)
  (package-refresh-contents)
  (package-install 'use-package))

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
;; Initialize the package system if not already done
(unless (bound-and-true-p package--initialized)
  (setq package-enable-at-startup nil)                                            ; Prevent Emacs from initializing it again later
  (package-initialize))

(eval-and-compile
  (setq
   use-package-always-ensure t                                                    ; once working - remove this and save elpa package store to git repo.
   use-package-expand-minimally t))

;; Install `no-littering' if necessary
(unless (package-installed-p 'no-littering)
  (unless package-archive-contents
    (package-refresh-contents))
  (package-install 'no-littering))

;; Load `no-littering'
(require 'no-littering)


;;;; Set up logging
(require 'custom-logging-config)
(require 'system-tools)

(log/debug :fn 'early-init
           :msg (concat "collected base paths from env vars, defined "
                        "eln-cache, no-littering-var-directory & "
                        "no-littering-etc-directory.")
           :obj user-emacs-directory)

(log/info :fn 'early-init
          :msg "----Begun early-init.el processing----"
          :obj t)

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

;; custom.el
(defvar custom-file nil"Set location of custom.el.")
(setq custom-file
      (expand-file-name"custom.el" no-littering-etc-directory))

(let
    ((obj
      (concat"\n   ("
              (replace-regexp-in-string
              ";"";\n     "
                     (mapconcat 'identity load-path";"))")" )))
  
  (log/debug :fn 'early-init
             :msg "Added custom-modules to load-path."
             :obj obj))


;;;; Settings to help compilation.
(defvar comp-speed nil"Set native compilation.")
(setq comp-speed 1)

(defvar package-native-compile)
(setq  package-native-compile t)
;; Garbage collection

(defvar gc-cons-threshold nil
 "Increase the GC threshold for faster startup.
Default is 800 kilobytes.  Measured in bytes.")

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

(log/info :fn 'early-init
    	  :msg "----Early init complete----"
    	  :obj t)

(provide 'early-init)
;;; early-init.el ends here
