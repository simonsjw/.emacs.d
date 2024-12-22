;;; custom-menus-config.el --- Menu configuration  -*- lexical-binding: t; -*-

;; Copyright (C) 2024
;; SPDX-License-Identifier: MIT

;; Author: Simon Watson
;; Keywords: UI, menu

;;; Commentary:

;; Better menu organisation

;;; Code:

;; define the master menu toggle. 
(define-key input-decode-map [C-tab] [control-tab])
(global-set-key [control-tab] 'menu-bar-mode)



(easy-menu-define my-menus/outline-mode nil
  "Menu for outline-mode"
  '("Outline"
    ["Option 1" (message "Option 1 selected") t]
    ["Option 2" (message "Option 2 selected") t]))

(easy-menu-define my-mode-menu2 nil
  "Menu for mode 2"
  '("Mode2Menu"
    ["Option A" (message "Option A selected") t]
    ["Option B" (message "Option B selected") t]))



(provide 'custom-menus-config)
;;; custom-menus-config.el ends here
