;;; custom-terminal-support.el --- functionality for terminal support  -*- lexical-binding: t; -*-

;; Copyright (C) 2022
;; SPDX-License-Identifier: MIT

;; Author: Simon Watson
;; Keywords: ansi-term term shell eshell vterm

;;; Commentary:

;; manage term ansi-term and the rest here. 

;;; Imports
(defvar vterm-mode-map)
(defvar vterm-send-key)

(declare-function vterm-undo vterm)
(declare-function vterm-send-string vterm)
(declare-function vterm-send-key vterm)

;;; Packages

(use-package vterm
  :straight (:type git
                   :flavor melpa
                   :files ("CMakeLists.txt"
                           "elisp.c"
                           "elisp.h"
                           "emacs-module.h"
                           "etc"
                           "utf8.c"
                           "utf8.h"
                           "vterm.el"
                           "vterm-module.c"
                           "vterm-module.h"
                           "vterm-pkg.el")
                   :host github
                   :repo "akermu/emacs-libvterm"))

;; (use-package eterm-256color
;;   :straight (:type git
;;                    :flavor melpa
;;                    :files (:defaults "eterm-256color.ti"
;;                                      "eterm-256color-pkg.el")
;;                    :host github
;;                    :repo "dieggsy/eterm-256color"))

;;; Code:

;; enable the use of  <C-backspace> to kill previous word in vterm.
(define-key vterm-mode-map (kbd "<C-backspace>")
            (lambda () (interactive) (vterm-send-key (kbd "C-w"))))

(advice-add 'counsel-yank-pop-action :around #'vterm-counsel-yank-pop-action)

;; If eterm-256color is installed, setting vterm-term-environment-variable to
;; eterm-color improves the rendering of colors in some systems.
(defvar vterm-term-environment-variable
  "xterm-256color"
  "Value for the TERM environment variable.
It defaults to xterm-256color.")  ;; use eterm-color to support eterm-256color-mode.
(setq vterm-term-environment-variable "xterm-256color")

(defvar vterm-shell
  "/bin/bash"
  "Shell to run in a new vterm. It defaults to $SHELL.")
(setq vterm-shell "/bin/bash")
;;(setq vterm-shell "/bin/bash --login -i")

(defun vterm-counsel-yank-pop-action (orig-fun &rest args)
  "Make counsel use the correct function to yank in vterm buffers."
  (if (equal major-mode 'vterm-mode)
      (let ((inhibit-read-only t)
            (yank-undo-function (lambda (_start _end) (vterm-undo))))
        (cl-letf (((symbol-function 'insert-for-yank)
                   (lambda (str) (vterm-send-string str t))))
          (apply orig-fun args)))
    (apply orig-fun args)))

(defun my-terminal/unset_bash_file_loader_flags ()
  "Unset the flags for .bashrc and .bash_profile.

This ensures the files are loaded when called from a new shell spawned from a
parent that has already run them (and so set these flags to 1). Note that
NOECHO is set to t to avoid this statement showing in the console. "

  (vterm-send-string
   "unset BASHRC_SOURCED_IN_INTERACTIVE_SHELL > /dev/null 2>&1; unset BASH_PROFILE_SOURCED_IN_INTERACTIVE_SHELL > /dev/null 2>&1; clear; source ~/.bashrc\n"
   t))

;;; Hooks:
(add-hook 'term-mode-hook #'my-terminal/unset_bash_file_loader_flags)
(add-hook 'vterm-mode-hook #'my-terminal/unset_bash_file_loader_flags)


(provide 'custom-terminal-support)
;;; custom-terminal-support.el ends here

                                        ; LocalWords:  color eterm
                                        ; LocalWords:  libvterm
