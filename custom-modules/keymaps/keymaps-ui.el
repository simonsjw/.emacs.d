;;; keymaps-ui.el --- Window and UI layout keymaps for ui-config. -*- lexical-binding: t; -*-

;; Copyright (C) 2026 Simon Watson
;; SPDX-License-Identifier: MIT

;; Author: Simon Watson

;;; Commentary:

;; Keymap module for `ui-config' (and window toggles from
;; `system-window-management').  Prefixes: Windows (`C-c w') and UI /
;; Layout (`C-c i').  Load after `keymaps-core'.  Menus last in
;; `keymaps-menus.el'.
;;
;; Map:
;;   Feature:    keymaps-ui
;;   Load-after: keymaps-core logging-config
;;   Load-phase: keymaps
;;   Keymaps:    keymaps-ui.el
;;   Docs:       docs/keymaps-ui.org
;;   OS:         none

;;; Code:

(require 'keymaps-core)
(require 'logging-config)

(log/debug :fn 'keymaps-ui
           :msg "Starting load of the keymaps-ui module."
           :obj t)

;;;; Customisation groups
;;   --------------------

(defgroup custom-windows ()
  "Window related configuration for Custom Emacs."
  :tag "Custom Windows"
  :group 'custom)

(defcustom custom-windows-prefix-key "C-c w"
  "Prefix key for window movement and sizing bindings."
  :group 'custom-windows
  :type 'string)

(defgroup custom-ui ()
  "UI / layout related configuration for Custom Emacs."
  :tag "Custom UI"
  :group 'custom)

(defcustom custom-ui-prefix-key "C-c i"
  "Prefix key for useful UI maps (breadcrumbs, whitespace, tidy, \ldots)."
  :group 'custom-ui
  :type 'string)

;;;; Windows map (C-c w)
;;   -------------------

(define-prefix-command 'my-key-maps/windows)

(keymap-set my-key-maps/windows "u" #'winner-undo)
(keymap-set my-key-maps/windows "r" #'winner-redo)
(keymap-set my-key-maps/windows "n" #'windmove-down)
(keymap-set my-key-maps/windows "p" #'windmove-up)
(keymap-set my-key-maps/windows "b" #'windmove-left)
(keymap-set my-key-maps/windows "f" #'windmove-right)
(keymap-set my-key-maps/windows "^" #'enlarge-window)
(keymap-set my-key-maps/windows "v" #'shrink-window)
(keymap-set my-key-maps/windows ">" #'enlarge-window-horizontally)
(keymap-set my-key-maps/windows "<" #'shrink-window-horizontally)

(define-prefix-command 'my-key-maps/windows-toggle)

(with-eval-after-load 'system-window-management
  (keymap-set my-key-maps/windows-toggle "e" #'my-window-tools/toggle-edit)
  (keymap-set my-key-maps/windows-toggle "d" #'my-window-tools/toggle-data)
  (keymap-set my-key-maps/windows-toggle "c" #'my-window-tools/toggle-config)
  (keymap-set my-key-maps/windows-toggle "l" #'my-window-tools/toggle-logs)
  (keymap-set my-key-maps/windows-toggle "v" #'my-window-tools/toggle-vc)
  (keymap-set my-key-maps/windows-toggle "s" #'my-window-tools/toggle-terminal)
  (keymap-set my-key-maps/windows "t" #'my-key-maps/windows-toggle))

(keymap-global-set custom-windows-prefix-key 'my-key-maps/windows)

(with-eval-after-load 'which-key
  (which-key-add-key-based-replacements custom-windows-prefix-key "Windows")
  (which-key-add-key-based-replacements
   (concat custom-windows-prefix-key " t") "Toggle pane"))

;;;; UI / Layout map (C-c i)
;;   -----------------------

(define-prefix-command 'my-key-maps/ui)

;; These bindings are installed after the functions are known to exist.
(with-eval-after-load 'startup-config
  (keymap-set my-key-maps/ui "d" #'IDE-refresh)

  (keymap-set my-key-maps/ui "b l" #'breadcrumb-local-mode)
  (keymap-set my-key-maps/ui "b g" #'breadcrumb-mode)

  (keymap-set my-key-maps/ui "w c" #'whitespace-cleanup)
  (keymap-set my-key-maps/ui "w v" #'whitespace-mode)
  (keymap-set my-key-maps/ui "w r" #'whitespace-report)

  (when (fboundp 'my-window-tools/tidy-window)
    (keymap-set my-key-maps/ui "t d" #'my-window-tools/tidy-window))

  (keymap-global-set custom-ui-prefix-key 'my-key-maps/ui))

(with-eval-after-load 'which-key
  (keymaps-core/add-titles my-key-maps/ui
                           "b" "Breadcrumbs"
                           "w" "Whitespace"
                           "t" "Tidy"))

(log/debug :fn 'keymaps-ui
           :msg "Ending load of the keymaps-ui module."
           :obj t)

(provide 'keymaps-ui)
;;; keymaps-ui.el ends here
