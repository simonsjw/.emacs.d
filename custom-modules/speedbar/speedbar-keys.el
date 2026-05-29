;;; speedbar-keys.el --- Key bindings for Speedbar -*- lexical-binding: t; -*-

;; Copyright (C) 2026 Simon Watson
;; SPDX-License-Identifier: MIT

;; Author: Simon Watson

;;; Commentary:
;; All key bindings and mode hooks for the Speedbar package.

;;; Code:

(require 'speedbar)

(add-hook 'speedbar-mode-hook
          (lambda ()
            (visual-line-mode 0)
            (setq-local truncate-lines t)
            (text-scale-adjust -0.25)
            (setq-local auto-hscroll-mode 'current-line)
            (setq-local hscroll-margin 0)
            (define-key speedbar-mode-map "." #'my-speedbar/toggle-filter)))

(with-eval-after-load 'speedbar
  (define-key speedbar-file-key-map (kbd "l") #'my-speedbar/toggle-directory-protection)
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

(provide 'speedbar-keys)
;;; speedbar-keys.el ends here
