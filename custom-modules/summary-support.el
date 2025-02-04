;;; summary-support.el --- Emacs splash screen  -*- lexical-binding: t -*-

;; Copyright (C) 2025
;; SPDX-License-Identifier: MIT

;; Author: Simon Watson

;;; Commentary:

;; Provide a fancy splash screen.

;;; Code:

;; [[https://github.com/emacs-dashboard/emacs-dashboard][Dashboard]]

(declare-function dashboard-setup-startup-hook "dashboard")

(use-package dashboard
  :ensure t
  :init
  (setq
   dashboard-navigation-cycle t
   dashboard-heading-shorcut-format " [%s]"
   dashboard-items '((agenda    . 5)
                     (recents   . 5)
                     (projects  . 5)
                     (bookmarks . 5)
                     (registers . 5))
   dashboard-item-shortcuts '((agenda    . "a")
                              (recents   . "r")
                              (bookmarks . "m")
                              (projects  . "p")
                              (registers . "e"))
   dashboard-navigator-buttons
   `(;; line1
     (
      ("🏠" "HOME" "Go to Home Directory"
       (lambda (&rest _) (dired "~/")))
      ("📂" "WORKSPACE" "Open Workspace Directory"
       (lambda (&rest _) (dired "/mnt/HDD04_WDD_08TB/workspace")))
      ("📦" "EMACS" "Open Emacs Configuration"
       (lambda (&rest _) (dired user-emacs-directory)))
      )
     ;; line 2
     (;; define nerd-font icon (github)
      (#("" 0 1 (face (:family "Symbols Nerd Font Mono" :height 1.0)
                       font-lock-face
                       (:family "Symbols Nerd Font Mono" :height 1.0)
                       display (raise 0.0) rear-nonsticky t))
       "GITHUB"
       "Open GitHub"
       (lambda (&rest _) (browse-url "https://github.com/")))
      )
     ;; line 3
     (
      (#("󰒓" 0 1 (face (:family "Symbols Nerd Font Mono" :height 1.0)
                       font-lock-face
                       (:family "Symbols Nerd Font Mono" :height 1.0)
                       display (raise 0.0) rear-nonsticky t))
       ".bashrc"
       "Open .bashrc file"
       (lambda (&rest _) (find-file "~/.bashrc")))
      (#("󰒓" 0 1 (face (:family "Symbols Nerd Font Mono"
                                :height 1.0
                                :foreground "white")
                       font-lock-face
                       (:family "Symbols Nerd Font Mono"
                                :height 1.0
                                :foreground "white")
                       display (raise 0.0) 
                       rear-nonsticky t))
       #(".bash_profile" 0 13 `(face (:foreground ,info-theme-light-blue)))
       "Open .bash_profile"
       (lambda (&rest _) (find-file "~/.bash_profile")))
      )
     )

   dashboard-startupify-list '(dashboard-insert-banner
                               dashboard-insert-newline
                               dashboard-insert-banner-title
                               dashboard-insert-newline
                               dashboard-insert-navigator
                               dashboard-insert-newline
                               dashboard-insert-init-info
                               dashboard-insert-items
                               dashboard-insert-newline
                               dashboard-insert-footer)

   dashboard-buffer-name "*Emacs*"
   dashboard-display-icons-p t                                                    ; display icons on both GUI and terminal
   dashboard-icon-type 'nerd-icons                                                ; use `nerd-icons' package
   dashboard-set-heading-icons t
   dashboard-set-file-icons t)
  :config
  (dashboard-setup-startup-hook))


(provide 'summary-support)
;;; summary-support.el ends here.

                                                                                  ; LocalWords:  bashrc
