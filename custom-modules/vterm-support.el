;;; vterm-support.el --- Vterm shell and toggle helpers. -*- lexical-binding: t; -*-

;; Copyright (C) 2026 Simon Watson
;; SPDX-License-Identifier: MIT

;; Author: Simon Watson

;;; Commentary:

;; Vterm shell setup and directory/toggle helpers.  Keys live in
;; `keymaps-ui.el'.  Load from `init.el' after `logging-config'.  Do
;; not move path constants here (that is a later dedicated PR).
;;
;; Map:
;;   Feature:    vterm-support
;;   Load-after: path-support logging-config
;;   Load-phase: ui
;;   Keymaps:    keymaps-ui.el
;;   Docs:       docs/vterm-support.org
;;   OS:         libvterm bash

;;; Code:
(require 'path-support)
(require 'logging-config)
(log/debug :fn 'vterm-support
           :msg "Starting load of the vterm-support module."
           :obj t)

(defvar my-vterm/workspace-dir "/mnt/HDD04_WDD_08TB/workspace"
  "Default workspace directory for vterm sessions.")

;;; --- Core vterm settings ---
(with-eval-after-load 'vterm
  (setq vterm-shell "/bin/bash")
  (setq vterm-max-scrollback 10000)
  (setq vterm-kill-buffer-on-exit t)
  (setq vterm-buffer-name-string "vterm %s")
  (setq vterm-copy-exclude-prompt t)

  ;; === Keybindings ===
  (global-set-key (kbd "C-c g f") #'my-vterm/cd-to-current-dir)
  (global-set-key (kbd "C-c g p") #'my-vterm/cd-to-project-root)

  (define-key vterm-mode-map (kbd "C-c g h")
              (lambda () (interactive) (vterm-send-string "cd ~/\n")))

  (define-key vterm-mode-map (kbd "C-c g w")
              (lambda ()
                (interactive)
                (vterm-send-string (concat "cd "
                                           (shell-quote-argument my-vterm/workspace-dir)
                                           "\n"))))

  ;; Copy / Paste
  (define-key vterm-mode-map (kbd "C-y")   #'vterm-yank)
  (define-key vterm-mode-map (kbd "M-y")   #'vterm-yank-pop)
  (define-key vterm-mode-map (kbd "C-c C-t") #'vterm-copy-mode)
  (define-key vterm-mode-map (kbd "C-c C-c") #'vterm-send-C-c)

  ;; <C-backspace> kills previous word (very useful)
  (define-key vterm-mode-map (kbd "<C-backspace>")
              (lambda () (interactive) (vterm-send-key (kbd "C-w"))))

  ;; Counsel yank-pop support in vterm
  (advice-add 'counsel-yank-pop-action :around #'my-vterm/counsel-yank-pop-action))


;;; --- Helper functions ---

(defun my-vterm/cd-to-current-dir ()
  "Change the vterm buffer to the directory of the current buffer.
Creates a vterm if none exists."
  (interactive)
  (let* ((orig-buffer (current-buffer))
         (dir (if buffer-file-name
                  (file-name-directory buffer-file-name)
                default-directory))
         (vterm-buffer (get-buffer "*vterm*")))
    (unless vterm-buffer
      (vterm)
      (setq vterm-buffer (get-buffer "*vterm*")))
    (switch-to-buffer vterm-buffer)
    (vterm-send-string (concat "cd " (shell-quote-argument dir) "\n"))
    (switch-to-buffer orig-buffer)))

(defun my-vterm/cd-to-project-root ()
  "Change vterm to the current project's root directory.
Falls back to current directory if no project is active."
  (interactive)
  (let* ((orig-buffer (current-buffer))
         (proj (ignore-errors (project-current nil)))
         (dir (if proj (project-root proj) default-directory))
         (vterm-buffer (get-buffer "*vterm*")))
    (unless vterm-buffer
      (vterm)
      (setq vterm-buffer (get-buffer "*vterm*")))
    (switch-to-buffer vterm-buffer)
    (vterm-send-string (concat "cd " (shell-quote-argument dir) "\n"))
    (switch-to-buffer orig-buffer)))

(defun my-vterm/counsel-yank-pop-action (orig-fun &rest args)
  "Make `counsel-yank-pop' work correctly inside vterm buffers.
ORIG-FUN is the original command.  ARGS are passed through."
  (if (equal major-mode 'vterm-mode)
      (let ((inhibit-read-only t)
            (yank-undo-function (lambda (_start _end) (vterm-undo))))
        (cl-letf (((symbol-function 'insert-for-yank)
                   (lambda (str) (vterm-send-string str t))))
          (apply orig-fun args)))
    (apply orig-fun args)))

(use-package vterm-toggle
  :ensure t
  :bind (("C-c t" . vterm-toggle)
         :map vterm-mode-map
         ("C-c t" . vterm-toggle)))
;; Then use `vterm-toggle-cd` if you want auto-cd on toggle.


(log/debug :fn 'vterm-support
           :msg "Finishing load of the vterm-support module."
           :obj t)

(provide 'vterm-support)
;;; vterm-support.el ends here
