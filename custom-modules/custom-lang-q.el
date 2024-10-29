;;; custom-lang-q.el --- KDB/Q Language configuration      -*- lexical-binding: t; -*-

;; Copyright (C) 2022
;; SPDX-License-Identifier: MIT

;; Author: Simon Watson
;; Keywords: KDB/Q

;;; Commentary:

;; Suggested additional keybindings for python-mode
;; (with-eval-after-load "python"
;;   (define-key python-mode-map (kbd "C-c C-n") #'numpydoc-generate)
;;   (define-key python-mode-map (kbd "C-c e n") #'flymake-goto-next-error)
;;   (define-key python-mode-map (kbd "C-c e p") #'flymake-goto-prev-error))

;; Suggested keybindings for pyvenv mode
;; (with-eval-after-load "pyvenv"
;;   (define-key pyvenv-mode-map (kbd "C-c p a") #'pyvenv-activate)
;;   (define-key pyvenv-mode-map (kbd "C-c p d") #'pyvenv-deactivate)
;;   (define-key pyvenv-mode-map (kbd "C-c p w") #'pyvenv-workon))

;;; Packages:

;; (use-package q-mode
;;   :straight ( :type git
;;               :host github
;;               :repo "psaris/q-mode"))

(load-file
 (expand-file-name
  "custom-packages/q-loadbalancer/q-loadbalancer.el" user-emacs-directory))

(load-file
 (expand-file-name
  "custom-packages/q-loadbalancer/process-groups.el" user-emacs-directory))

(load-file
 (expand-file-name
  "custom-packages/q-loadbalancer/q-parse.el" user-emacs-directory))

;;; Code:

;;; File associations
;; (.k and .q)
(add-to-list 'auto-mode-alist '("\\.[kq]\\'" . q-script-mode))


;; Set default port. 
(customize-set-variable 'q-init-port 6060
                        "set the default port to run kdb/q. ")

(defun my-lang/q-script-mode-setup ()
  (message
   "[%s ; DEBUG; my-lang/q-script-mode-setup]starting loading the defun ; ;"
   (current-time-string))

  (my-programming-mode/set-fill-column-indicator 140)
  
  )

;; ess-mode attempts to associate the .q extension with S-mode.
;; remove-ess-q-extn prevents that association.

(defun remove-ess-q-extn ()
  (when (assoc "\\.[qsS]\\'" auto-mode-alist)
    (setq auto-mode-alist
          (remassoc "\\.[qsS]\\'" auto-mode-alist))))



;; Hooks
(add-hook 'ess-mode-hook 'remove-ess-q-extn)
(add-hook 'inferior-ess-mode-hook 'remove-ess-q-extn)
(add-hook 'q-script-mode-hook #'my-lang/q-mode-setup)

(require 'custom-logging-config)


;;; Provision
(provide 'custom-lang-q)
;;; custom-lang-q.el ends here
