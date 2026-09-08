;;; lang-python-eglot.el --- Eglot / Pyrefly / pyvenv for Python. -*- lexical-binding: t; -*-

;; Copyright (C) 2026 Simon Watson
;; SPDX-License-Identifier: MIT

;; Author: Simon Watson

;;; Commentary:

;; Piece of `lang-python': Eglot + Pyrefly, pyvenv, Flymake, and
;; related buffer-local IDE wiring.  Forms run from
;; `my-lang-python/eglot-setup', called by the loader hook.  Do not
;; call `eglot-ensure' at `require'.
;;
;; Map:
;;   Feature:    lang-python-eglot
;;   Load-after: path-support logging-config
;;   Load-phase: lang
;;   Keymaps:    none
;;   Docs:       docs/lang-python-eglot.org
;;   OS:         pyrefly conda

;;; Code:

(require 'path-support)
(require 'logging-config)
(log/debug :fn 'lang-python-eglot
           :msg "Starting load of the lang-python-eglot module."
           :obj t)

(declare-function my-lang-python/update-python-path "lang-python")
(declare-function my-lang-python/restart-eglot-on-env-change "lang-python")
(declare-function eglot-ensure "eglot")
(declare-function pyrefly-setup-flymake-backend "flymake-pyrefly")
(defvar pyvenv-post-activate-hooks)

(defun my-lang-python/eglot-setup ()
  "Start Eglot/Pyrefly, pyvenv, and Flymake in a `python-ts-mode' buffer.
Do not call this at `require'; the loader hook invokes it."
  ;;;;;; === Performance tuning for Eglot + Pyrefly (typing lag fix) ===
  ;; These reduce server load during rapid typing.
  (setq-local eglot-send-changes-idle-time 0.8)   ; buffer-local override if you want per-project tuning
  (setq flymake-no-changes-timeout 1.5)           ; longer delay before Flymake re-runs

  ;; Optional but recommended: Install flymake-pyrefly from NonGNU ELPA
  ;; (M-x package-refresh-contents RET, then package-install flymake-pyrefly)
  ;; It provides a dedicated, very lightweight Pyrefly diagnostic backend.
  (when (require 'flymake-pyrefly nil 'noerror)
    (pyrefly-setup-flymake-backend)
    ;; Remove Eglot's general diagnostic backend to avoid duplication/overhead.
    ;; Keep Eglot for completion, navigation, hover, code actions, inlays, etc.
    (remove-hook 'flymake-diagnostic-functions 'eglot-flymake-backend t))

  ;;;;;; LSP with Pyrefly
  (eglot-ensure)
  ;; no need to enable inlay hints on the server since they are default enabled.

  ;; Environment
  (pyvenv-mode 1)
  (my-lang-python/update-python-path)
  (add-hook 'pyvenv-post-activate-hooks
            #'my-lang-python/update-python-path nil t)
  (add-hook 'pyvenv-post-activate-hooks
            #'my-lang-python/restart-eglot-on-env-change nil t)

  ;; Diagnostics: Solely from Pyrefly via Eglot (covers types + semantics)
  (flymake-mode 1)                                                                ; Eglot auto-adds its backend
  ;; Disable the built-in python-flymake backend (we rely exclusively on Pyrefly via Eglot)
  (remove-hook 'flymake-diagnostic-functions #'python-flymake t)

  ;; Ya-snippets
  (yas-minor-mode 1)

  ;; Python dataview
  (require 'python-view-data)

  ;; Layout and settings
  (setq display-fill-column-indicator-column 88
        fill-column 88
        comment-fill-column 250
        comment-column 90
        py-docstring-fill-column 250
        python-indent-offset 4)
  (display-fill-column-indicator-mode 1)

  ;; doc strings with numpydoc
  (setq numpydoc-insert-examples-block t                                          ; Add Examples if needed.
        numpydoc-prompt-for-input t)                                              ; Prompt for descriptions (wraps long input).
  (add-hook 'numpydoc-mode-hook 'auto-fill-mode))                                  ; Auto-wrap at fill-column=88.

(log/debug :fn 'lang-python-eglot
           :msg "Finishing load of the lang-python-eglot module."
           :obj t)

(provide 'lang-python-eglot)
;;; lang-python-eglot.el ends here
