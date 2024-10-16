;;; early-init.el --- Emacs early initialization for Crafted Emacs  -*- lexical-binding: t; -*-

;;; Commentary:
;;  Work that is done before Emacs can be initialised.
;;  Mainly setting up the packagemanagement process (with straight) and
;;  then setting a few variables needed to initialise the ide.
;;

;;; Code:

;; disable package.el - we will use straight
(defvar package-enable-at-startup nil "package.el is disabled at startup by setting to nil. Use straight instead.")
(setq package-enable-at-startup nil)

;;; Base file paths needed for package management
;;  ---------------------------------------------
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

(defvar no-littering-var-directory nil "Create the path `no-littering-var-directory`.")
(setq no-littering-var-directory
  (expand-file-name (concat "var/"  envvar/SYSTEM_NAME "/")
    		    user-emacs-directory))


(defvar no-littering-etc-directory nil "Create the path `no-littering-etc-directory`.")
(setq no-littering-etc-directory
  (expand-file-name (concat "etc/"  envvar/SYSTEM_NAME "/")
    		    user-emacs-directory))

;; set the eln cache early. 
(defvar my-filepaths/eln-cache nil)
;; set the eln cache early. 
(setq my-filepaths/eln-cache
  (expand-file-name
   "eln-cache/" no-littering-etc-directory))

;; Ensure the eln-cache directory exists
(make-directory my-filepaths/eln-cache t)

(startup-redirect-eln-cache my-filepaths/eln-cache)

;; force the loadpath as the starup-redirect thing
;; seems to fail sometimes. 
(setq native-comp-eln-load-path
      (list my-filepaths/eln-cache
    	    "/usr/local/lib/emacs/29.2/native-lisp/"))

;; Set the cache directory for compiled files
(setq comp-eln-load-path (list my-filepaths/eln-cache))

;; set up logging
;; --------------

(load (expand-file-name
       "custom-modules/custom-logging-config.el" user-emacs-directory))
(require 'custom-logging-config)
(load (expand-file-name
       "custom-modules/custom-system-objects.el" user-emacs-directory))
(require 'custom-system-objects)
(load (expand-file-name
       "custom-modules/custom-system-tools.el" user-emacs-directory))
(require 'custom-system-tools)

(log/debug :fn 'early-init
    	   :msg "collected base paths from env vars, defined eln-cache, no-littering-var & -etc."
    	   :obj user-emacs-directory)

(log/info :fn 'early-init         
    	  :msg "----Begun early-init.el processing----"
    	  :obj t)

(load (expand-file-name
       "custom-modules/custom-system-tools.el" user-emacs-directory))

(when (file-exists-p log/init-log)
  (delete-file log/init-log))

(log/debug :fn 'early-init
    	   :msg "loaded system tools."
    	   :obj user-emacs-directory)


(defvar my/REPO_LIST nil "The path to a list of git projects on the system.")
(setq my/REPO_LIST (getenv "REPO_LIST"))

;; Use this to rebuild packages with straight
;;(straight-rebuild-package "tree-sitter-langs")

;; This is the way we define a custom variable and add it to a group.
;; (defcustom var-name default-value doc-string
;;  :type 'type
;;  :group 'group)


(log/debug :fn 'early-init
    	   :msg "no-littering etc directory set"
    	   :obj no-littering-etc-directory)

;; Set up package management paths
;; -------------------------------
;; ** NOT NEEDED NOW AS THIS DIRECTORY IS USED TO DOWNLOAD AND
;; VARIFY PACKAGES FROM GNUELPA BY PACKAGE.EL **
;; Set the gnupg directory path needed for package management.
;; (defconst package-gnupghome-dir
;;   (expand-file-name
;;    "gnupg/" no-littering-etc-directory)
;;   "Define the package management directory.")

;; Set the elpa directory needed for package management.
;; ** NOT NEEDED NOW AS THIS DIRECTORY IS USED TO STORE
;; DOWNLOADED PACKAGES BY PACKAGE.EL *
;; (setq package-user-dir
;;       (expand-file-name
;;        "elpa/" no-littering-etc-directory))

(defvar straight-base-dir nil "Define the straight directory so compilation is in the right location.")
(setq straight-base-dir no-littering-etc-directory)

;; treesitter scripts
;; (defconst tree-sitter-load-path
;;   (list (concat straight-base-dir
;;     		"/straight/build/tree-sitter-langs/bin/"))
;;   "Define the location of treesitter language grammars.

;;     		      At present, emacs insists on checking in the .emacs.d home directory so I have
;;     		      a shortcut to allow this directory to be in two places at once. ")

;; ;; elpaca not used
;; now but maybe will be ??
;;(defconst elpaca-directory
;;  (expand-file-name "elpaca/" no-littering-etc-directory))


;; custom.el
(defvar custom-file nil "Set location of custom.el")
(setq custom-file
 (expand-file-name "custom.el" no-littering-etc-directory))

(add-to-list
 'load-path
 (expand-file-name "custom-modules/" user-emacs-directory))

;; (add-to-list 'load-path package-gnupghome-dir)  ; not needed since we are not using package.el
(add-to-list 'load-path package-user-dir)
(add-to-list 'load-path straight-base-dir)
(add-to-list 'load-path my-filepaths/eln-cache)

;; With straight-base-dir defined, ensure our straight.el setup is loaded.
(load (expand-file-name
       "custom-modules/straight-early-init.el" user-emacs-directory))

(let
    ((obj
      (concat "\n   (" (replace-regexp-in-string
    			";" ";\n      "
    			(mapconcat 'identity load-path ";")) ")" )))
  (log/debug :fn 'early-init
    	     :msg "Added custom-modules to load-path."
    	     :obj obj))

;;; Settings to help compilation.
;;  -----------------------------

;; 
(defvar comp-speed nil "set native compilation")
(setq comp-speed 1)

(defvar package-native-compile)
(setq  package-native-compile t)
;; Garbage collection

(defvar gc-cons-threshold nil "Increase the GC threshold for faster startup. The default is 800 kilobytes.  Measured in bytes.")
(setq  gc-cons-threshold (* 50 1000 1000))

;;; Emacs lisp source/compiled preference
;; Prefer loading newest compiled .el file
(defvar load-prefer-newer nil "loading preference")
(setq load-prefer-newer t)

;; Record the filepath settings in the log. 
(let
    ((native-comp-eln-load-path-string
      (mapconcat 'identity native-comp-eln-load-path ";\n      "))
     (user-dir-payload
      "\n   (package-user-dir: %s;")
     (straight-dir-payload
      "\n   straight-base-dir: %s;")
     (eln-dir-list-payloads
      "\n   native-comp-eln-load-path-strings:\n      %s")
     (eln-dir-list-ending-payload ")"))

  (log/info :fn 'early-init
    	    :msg "Set package-user-dir, eln-cache directory and straight-base-dir."
    	    :obj (format
    		  (concat
    		   user-dir-payload straight-dir-payload
    		   eln-dir-list-payloads eln-dir-list-ending-payload)
    		  package-user-dir
    		  straight-base-dir
    		  native-comp-eln-load-path-string)))
(eval-when-compile
  (require 'use-package))

;; ensure we always ensure! (with use-package)
(require 'use-package-ensure)                               ; This is equivalent to setting :ensure t
(setq use-package-always-ensure t)

;; delight enables us to manage mode interactions with the modeline via
;; use-package and the :delight key. 
(use-package delight
  :straight (:type git
    		   :host github
    		   :repo "emacs-straight/delight"
    		   :files ("*" (:exclude ".git"))))

(use-package bind-key
  :straight (:type git
                   :flavor melpa
                   :files ("bind-key.el" "bind-key-pkg.el")
                   :host github
                   :repo "jwiegley/use-package"))

(use-package helpful
  :straight (:type git
  		   :flavor melpa
  		   :host github
  		   :repo "Wilfred/helpful"))

(require 'delight)                                          ; if you use :delight
(require 'bind-key)                                         ; if you use any :bind variant

;;; UI configuration
;;  ----------------
;; Remove some unneeded UI elements
;;(the user can turn back on anything they wish)
(setq inhibit-startup-message t)

(push '(tool-bar-lines . nil) default-frame-alist)
;; (push '(menu-bar-lines . nil) default-frame-alist)
;; (push '(vertical-scroll-bars) default-frame-alist)
;; (push '(mouse-color . "white") default-frame-alist)

;; Make the initial buffer load faster by setting its mode to fundamental-mode
(customize-set-variable 'initial-major-mode 'fundamental-mode)

;; Set size of the initial emacs window.
(add-to-list 'default-frame-alist '(height . 150))
(add-to-list 'default-frame-alist '(width  . 300))

(log/debug :fn 'early-init
    	   :msg "Preloaded some settings for UI configuration."
    	   :obj t)

(log/info :fn 'early-init
    	  :msg "----Early init complete----"
    	  :obj t)

(provide 'early-init)
;;; early-init.el ends here
