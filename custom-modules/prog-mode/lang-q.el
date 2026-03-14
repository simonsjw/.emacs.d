;;; lang-q.el --- KDB/Q Language configuration      -*- lexical-binding: t; -*-

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



;;; Code:

(require 'path-support)
(require 'logging-config)
(log/debug :fn 'lang-q
           :msg "Starting load of the lang-q module."
           :obj t)

(defvar my-paths/q-load-balancer-folder)
(defvar my-ide/comment-delimiter-char)

(declare-function aggressive-indent-mode "aggressive-indent-mode")
(declare-function gnus-remassoc "gnus-util")
(declare-function yas-minor-mode "yasnippet")

;;; Packages:

(add-to-list 'load-path my-paths/q-load-balancer-folder)
(require 'q-loadbalancer)

;;; File associations (.k and .q)
(add-to-list 'auto-mode-alist '("\\.[kq]\\'" . q-script-mode))

(defun my-lang/q-mode-setup ()
  "The setup function hooked to be loaded on opening a .q or .k file."
  (message
   "[%s ; DEBUG; my-lang-q/mode-setup]starting loading the defun ; ;"
   (current-time-string))

  (setq-local display-fill-column-indicator-column 140) ; Use COLUMN or 80 if COLUMN is nil
  (display-fill-column-indicator-mode 1)

  ;; Custom configurations for KDB/Q mode to define comment syntax.
  ;; Define the comment syntax for KDB/Q
  (setq-local comment-start "/ ")
  (setq-local comment-end "")
  (setq-local comment-start-skip "/+\\s-*")
  (setq-local comment-end-skip "")
  ;; Set the column for comment alignment
  (setq-local comment-column 142)
  ;; Use the default comment indentation function
  (setq-local comment-indent-function #'comment-indent-default)
  ;; Ensure that comment commands work properly
  (comment-normalize-vars)

  (defun my-comment-indent-or-tab ()
    "Indent the current line or align comment if on an inline comment."
    (interactive)
    (if (nth 4 (syntax-ppss))
        (comment-indent)
      (indent-for-tab-command)))

  ;; Replace `kdb-q-mode-map` with the actual keymap for KDB/Q mode
  ;; (define-key kdb-q-mode-map (kbd "TAB") 'my-comment-indent-or-tab)

  ;; Enable Ya-snippets.
  (yas-minor-mode))

;; ess-mode attempts to associate the .q extension with S-mode.
;; remove-ess-q-extn prevents that association.

(defun remove-ess-q-extn ()
  "Ensure that the file suffix .q is associated with kdb/q."
  (when (assoc "\\.[qsS]\\'" auto-mode-alist)
    (setq auto-mode-alist
          (gnus-remassoc "\\.[qsS]\\'" auto-mode-alist))))


;; Hooks
(add-hook 'ess-mode-hook #'remove-ess-q-extn)
(add-hook 'inferior-ess-mode-hook #'remove-ess-q-extn)
(add-hook 'q-script-mode-hook #'my-lang/q-mode-setup)

(log/debug :fn 'lang-q
           :msg "Ending load of the lang-q module."
           :obj t)


;;; Provision
(provide 'lang-q)
;;; lang-q.el ends here

                                                                                 ; LocalWords:  loadbalancer
                                                                                 ; LocalWords:  util
