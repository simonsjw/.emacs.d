;;; speedbar-keys.el --- Speedbar mode-map bindings. -*- lexical-binding: t; -*-

;; Copyright (C) 2026 Simon Watson
;; SPDX-License-Identifier: MIT

;; Author: Simon Watson

;;; Commentary:

;; Piece of `speedbar-support': mode hooks and key bindings for the
;; Speedbar buffer and file keymap.  Required by the loader, not from
;; `init.el' directly.
;;
;; Map:
;;   Feature:    speedbar-keys
;;   Load-after: speedbar-pinning speedbar-commands
;;   Load-phase: ui
;;   Keymaps:    none
;;   Docs:       docs/speedbar-keys.org
;;   OS:         none

;;; Code:

(require 'path-support)
(require 'logging-config)
(log/debug :fn 'speedbar-keys
           :msg "Starting load of the speedbar-keys module."
           :obj t)

(require 'speedbar)
(require 'speedbar-pinning)
(require 'speedbar-commands)

(add-hook 'speedbar-mode-hook
          (lambda ()
            (visual-line-mode 0)
            (setq-local truncate-lines t)
            (text-scale-adjust -0.25)
            (setq-local auto-hscroll-mode 'current-line)
            (setq-local hscroll-margin 0)
            (define-key speedbar-mode-map "." #'my-speedbar/toggle-filter)))

(with-eval-after-load 'speedbar
  (define-key speedbar-file-key-map (kbd "l") #'my-speedbar/toggle-pin-project-root)
  (define-key speedbar-file-key-map (kbd "w") #'my-speedbar/go-workspace)
  (define-key speedbar-file-key-map (kbd "r") #'my-speedbar/set-speedbar-to-project-root)
  (define-key speedbar-file-key-map (kbd "h") #'my-speedbar/go-home)
  (define-key speedbar-file-key-map (kbd "o") #'my-speedbar/open-in-file-explorer)
  (define-key speedbar-file-key-map (kbd "I") #'my-speedbar/toggle-pretty-icons)
  (define-key speedbar-mode-map "b" (lambda ()
                                      (interactive)
                                      (my-speedbar/switch-speedbar-view "quick buffers")))
  (define-key speedbar-mode-map "i" (lambda ()
                                      (interactive)
                                      (my-speedbar/switch-speedbar-view "Info")))
  (define-key speedbar-mode-map "v" #'my-speedbar/open-vterm-in-dir))

(global-set-key (kbd "C-c s") #'my-speedbar/toggle)

(log/debug :fn 'speedbar-keys
           :msg "Ending load of the speedbar-keys module."
           :obj t)

(provide 'speedbar-keys)
;;; speedbar-keys.el ends here
