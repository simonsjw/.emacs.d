;;; speedbar-support.el --- Loader for the Speedbar feature. -*- lexical-binding: t; -*-

;; Copyright (C) 2026 Simon Watson
;; SPDX-License-Identifier: MIT

;; Author: Simon Watson

;;; Commentary:

;; MAP feature and `provide' of this tree's Speedbar setup.  Load it
;; from `init.el' with:
;;
;;   (require 'speedbar-support)
;;
;; or
;;
;;   (use-package speedbar-support
;;     :load-path my-paths/speedbar-support
;;     :demand t)
;;
;; Do not `(require 'speedbar)' as this feature.  Built-in `speedbar'
;; is a different library; this file only pulls in the first-party
;; pieces:
;;
;;   speedbar-config    — settings, faces, pretty-speedbar
;;   speedbar-icons     — file-type and folder icons
;;   speedbar-pinning   — per-frame project-root pinning
;;   speedbar-commands  — interactive navigation
;;   speedbar-sort      — file/directory sort
;;   speedbar-keys      — mode-map bindings
;;
;; The three pinning variables are global (see `speedbar-pinning.el').
;; Do not reset them in `after-make-frame-functions' on every new
;; frame: that disabled pinning in the existing IDE session.
;;
;; Map:
;;   Feature:    speedbar-support
;;   Load-after: path-support logging-config
;;   Load-phase: ui
;;   Keymaps:    none
;;   Docs:       docs/speedbar-support.org
;;   OS:         none

;;; Code:

(require 'path-support)
(require 'logging-config)
(log/debug :fn 'speedbar-support
           :msg "Starting load of the speedbar-support module."
           :obj t)

(defvar my-speedbar/use-pretty-icons t
  "If non-nil, use pretty-speedbar icons.
Otherwise use native ezimage icons with file-type support.")

(require 'speedbar-config)
(require 'speedbar-icons)
(require 'speedbar-pinning)
(require 'speedbar-commands)
(require 'speedbar-sort)
(require 'speedbar-keys)

;; NOTE: The three pinning variables are deliberately global (see
;; speedbar-pinning.el).  Resetting them here on every new frame
;; (including simple emacsclient frames) disabled pinning in the
;; existing IDE session.  Do not re-introduce a setq of these
;; variables inside after-make-frame-functions.

;; Ensure frame-local variables are initialized on new frames
;; (add-hook 'after-make-frame-functions
;;           (lambda (frame)
;;             (with-selected-frame frame
;;               (setq my-speedbar/pin-project-root nil
;;                     my-speedbar/current-file nil
;;                     my-speedbar/file-tree-root nil))))

(log/debug :fn 'speedbar-support
           :msg "Ending load of the speedbar-support module."
           :obj t)

(provide 'speedbar-support)
;;; speedbar-support.el ends here
