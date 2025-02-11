;;; early-init.el --- Emacs early initialization for Crafted Emacs  -*- lexical-binding: t; no-byte-compile: t -*-

 ;;; Commentary:
 ;;  Work that is done before Emacs can be initialised.
 ;;  Mainly setting up the package management process and
 ;;  then setting a few variables needed to initialise the ide.

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

 (defvar no-littering-var-directory nil
   "Create the path `no-littering-var-directory`.")
 (setq no-littering-var-directory
       (expand-file-name (concat "var/"  envvar/SYSTEM_NAME )
                    	user-emacs-directory))

 (defvar no-littering-etc-directory nil
   "Create the path `no-littering-etc-directory'.")
 (setq no-littering-etc-directory
       (expand-file-name (concat "etc/" envvar/SYSTEM_NAME)
                 	user-emacs-directory))

 ;; Define and add directories to load-path
 (mapc (lambda (dir)
         (make-directory dir t)           ; Ensure the directory exists.
         (add-to-list 'load-path dir))     ; Add the directories to the load-path.
       (list
        (setq modules-user-dir
              (expand-file-name "custom-modules/" user-emacs-directory))           ; set up the custom modules building emacs functionality.
        (setq modules-system-tools
              (expand-file-name "system-tools/"modules-user-dir))                  ; set up the tools on which the custom modules rely.
        (setq modules-prog-mode
              (expand-file-name "prog-mode/" modules-user-dir))                    ; set up the custom modules which are specific to languages under prog-mode.
        (setq my-filepaths/eln-cache
              (expand-file-name "eln-cache/" no-littering-etc-directory))          ; Set up the eln-cache path.
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
 ;; Garbage collection
 (defvar gc-cons-threshold nil
   "Increase the GC threshold for faster startup.
 Default is 800 kilobytes.  Measured in bytes.")

 (setq gc-cons-threshold (* 50 1000 1000))
 (startup-redirect-eln-cache my-filepaths/eln-cache)                               ; Set the eln-cache directory for compiled files to the defined path.
 (setq inhibit-compacting-font-caches t)                                           ; Don't compact font caches during GC.

 ;;; Emacs lisp source/compiled preference
 ;; Prefer loading newest compiled .el file.
 (defvar comp-speed nil "Set native compilation.")
 (setq comp-speed 1)

 (defvar package-native-compile)
 (setq  package-native-compile t)
 (defvar load-prefer-newer nil "loading preference.")
 (setq load-prefer-newer t)

 ;;;; UI configuration
 ;; Remove some unneeded UI elements (the user can turn back on anything they wish)
 (add-to-list 'default-frame-alist '(background-color . "#1B152D"))
 ;; (add-to-list 'default-frame-alist '(foreground-color . "#A8ACA4"))

 ;; (setq inhibit-startup-screen t                                                    ; stop the default splash screen
 ;;       inhibit-startup-message t
 ;;       inhibit-startup-echo-area-message t)
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
;; (add-to-list 'initial-frame-alist '(fullscreen . maximized))                      ; start the initial frame maximised
;; (add-to-list 'default-frame-alist '(fullscreen . maximized))                      ; start every frame maximised
 ;; Alternative - set the initial frame size default to a specific size.
 ;;     (add-to-list 'default-frame-alist '(height . 150))
 ;;     (add-to-list 'default-frame-alist '(width  . 300))

 (provide 'early-init)
 ;;; early-init.el ends here
                                                                                   ; LocalWords:  gnupg
