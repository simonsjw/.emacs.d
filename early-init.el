;; early-init.el --- Emacs early initialization -*- lexical-binding: t; no-byte-compile: t -*-

;;; Commentary:
;; Work that is done before Emacs can be initialised.
;; Mainly setting up paths, no-littering directories, eln-cache redirection,
;; package management, GC, native-comp, and early UI.

;;; Code:

;; === Base file paths + MY_NAME support (exactly as you had) ===
(defvar user-emacs-directory nil "The Emacs base directory.")
(setq user-emacs-directory
      (or (getenv "USER_EMACS_DIRECTORY")
          (expand-file-name "~/.emacs.d/")))

(defvar envvar/SYSTEM_NAME nil
  "The name of the system on which we are currently running Emacs.")
(setq envvar/SYSTEM_NAME
      (or (getenv "MY_NAME") "INFODYNAMICS"))

;; === NO-LITTERING paths — defined EARLY (before any package or .eln writes) ===
(defvar no-littering-var-directory nil
  "Create the path `no-littering-var-directory`.")
(setq no-littering-var-directory
      (expand-file-name (concat "var/" envvar/SYSTEM_NAME "/")
                        user-emacs-directory))

(defvar no-littering-etc-directory nil
  "Create the path `no-littering-etc-directory`.")
(setq no-littering-etc-directory
      (expand-file-name (concat "etc/" envvar/SYSTEM_NAME "/")
                        user-emacs-directory))

;; Load your custom path definitions VERY early (this gives us my-paths/eln-cache)
(load-file (expand-file-name "custom-modules/path-support.el" user-emacs-directory))

;; Redirect native-comp cache into YOUR path (exactly as you had)
(when (and (fboundp 'startup-redirect-eln-cache)
           (boundp 'my-paths/eln-cache))
  (startup-redirect-eln-cache my-paths/eln-cache))

(setq epg-gpg-program "/usr/bin/gpg")   ; your original

;;;; Garbage collection, font & eln caching (your original values kept)
(setq gc-cons-threshold (* 50 1000 1000))
(setq inhibit-compacting-font-caches t)

;; Emacs lisp source/compiled preference (your original)
(setq comp-speed 1)
(setq load-prefer-newer t)
(setq package-native-compile t)
(setq native-comp-async-report-warnings-errors nil)

;; Stop package.el from running again in init.el
(setq package-enable-at-startup nil)

;;;; UI configuration (100 % of your original settings preserved)
(add-to-list 'default-frame-alist '(background-color . "#1B152D"))
(add-to-list 'default-frame-alist '(foreground-color . "#EEEEEC"))

(push '(tool-bar-lines . 0) default-frame-alist)
(push '(vertical-scroll-bars) default-frame-alist)
(push '(mouse-color . "white") default-frame-alist)

(menu-bar-mode -1)                                                                ; Turn off Menu-Bar and then bind it to C-TAB
(define-key input-decode-map [C-tab] [control-tab])
(global-set-key [control-tab] 'menu-bar-mode)

(customize-set-variable 'initial-major-mode 'fundamental-mode)                    ; your original

(provide 'early-init)
;;; early-init.el ends here
