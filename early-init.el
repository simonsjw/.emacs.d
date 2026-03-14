;; early-init.el --- Emacs early initialization -*- lexical-binding: t; no-byte-compile: t -*-

;;; Commentary:
;; Work that is done before Emacs can be initialised.
;; All paths + package management + GC + native-comp now live here.

;;; Code:

;; === Base file paths + MY_NAME support ===
(setq user-emacs-directory
      (or (getenv "USER_EMACS_DIRECTORY")
          (expand-file-name "~/.emacs.d/")))
   

(defvar envvar/SYSTEM_NAME
  (or (getenv "MY_NAME") "INFODYNAMICS")
  "The name of the system on which we are currently running Emacs.")

;; === NO-LITTERING paths + PACKAGE SETUP (all early) ===

(defvar no-littering-var-directory
  (expand-file-name (concat "var/" envvar/SYSTEM_NAME "/")
                    user-emacs-directory))

(defvar no-littering-etc-directory
  (expand-file-name (concat "etc/" envvar/SYSTEM_NAME "/")
                    user-emacs-directory))

;; Force package.el to use our clean location from the VERY beginning
;; (Directory where ELPA/MELPA packages are installed.)
(setq package-user-dir
      (expand-file-name "elpa/" no-littering-var-directory))

;; Redirect native-comp cache
(setq my-paths/eln-cache
      (expand-file-name "eln-cache/" no-littering-etc-directory))
(when (and (fboundp 'startup-redirect-eln-cache)
           (boundp 'my-paths/eln-cache))
  (message "eln-cache file path set.")
  (startup-redirect-eln-cache my-paths/eln-cache))
  
  ;; Load path configuration (single source of truth)
(load-file (expand-file-name "custom-modules/path-support.el" user-emacs-directory))

;;;; UI configuration
(add-to-list 'default-frame-alist '(background-color . "#1B152D"))
(add-to-list 'default-frame-alist '(foreground-color . "#EEEEEC"))
(push '(tool-bar-lines . 0) default-frame-alist)
(push '(menu-bar-lines . 0) default-frame-alist)
(push '(vertical-scroll-bars) default-frame-alist)
(push '(mouse-color . "white") default-frame-alist)

;;;; Garbage collection, font & eln caching
(setq gc-cons-threshold (* 50 1000 1000))
(setq inhibit-compacting-font-caches t)
(setq comp-speed 1)
(setq load-prefer-newer t)
(setq package-native-compile t)
(setq native-comp-async-report-warnings-errors nil)
;;(setq package-enable-at-startup nil)


(provide 'early-init)
;;; early-init.el ends here
