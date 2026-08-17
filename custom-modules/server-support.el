;;; server-support.el --- Emacs server support -*- lexical-binding: t; -*-

;; Copyright (C) 2025
;; SPDX-License-Identifier: MIT

;; Author: Simon Watson
;; Keywords: emacs server daemon client

;;; Commentary:

;; Modern daemon-aware server setup (2026 best practice).
;; • Starts server only if not already running.
;; • Simple client frames (emacsclient -c) are single-window, untagged.
;; • All visual customisations (thick blue dividers, pretty speedbar icons,
;;   fringes, etc.) are re-applied via my-visual/apply-all-customisations
;;   so every frame looks identical to the IDE frame.
;; • No face resetting — the unified visual function is the single source of truth.

;;; Code:

(require 'path-support)
(require 'logging-config)
(log/debug :fn 'server-support
           :msg "Starting load of the server-support module."
           :obj t)
;; ----------------------------------------------------------------------
;; 1. Start server
;; ----------------------------------------------------------------------
(defun my-server/start-if-not-running ()
  "Start the Emacs server if it is not already running.

Efficiency: short-circuit early using `server-running-p'.
Works identically in normal and --fg-daemon sessions.
Historical note: redundant server-start calls were a common cause of
warnings in systemd user units pre-2024."
  (when (and (fboundp 'server-running-p)
             (not (server-running-p)))
    (server-start)
    (log/info :fn 'my-server/start-if-not-running
              :msg "Emacs server started."
              :obj t)
    ))

(my-server/start-if-not-running)

;; ----------------------------------------------------------------------
;; 2. Simple client frame creator (clean, no face resets)
;; ----------------------------------------------------------------------
(defun my-server/display-simple-frame (buffer)
  "Display BUFFER in a new, simple, single-window frame.
No IDE tagging, no category routing, no residual previous buffers."
  (let* ((frame-params `((UI-TYPE . nil)
                         (custom-window-management . nil)
                         (name . "Simple Client Frame")
                         (width . 120)
                         (height . 40)))
         (frame (make-frame frame-params))
         (win   (frame-selected-window frame)))
    (select-frame frame)
    ;; Force the requested buffer and erase history so the previous file cannot reappear
    (set-window-buffer win buffer)
    (set-window-prev-buffers win nil)
    (set-window-next-buffers win nil)
    (delete-other-windows win)

    ;; Visuals only – never layout.  Protect against errors so the client frame stays alive.
    (condition-case err
        (my-visual/apply-all-customisations)   ; ideally a faces/fringes/icons-only path when UI-TYPE is nil
      (error
       (log/error :fn 'my-server/display-simple-frame
                  :msg "Visual apply failed (non-fatal)."
                  :obj err)))

    ;; Re-assert single window *after* the hook may have run
    (delete-other-windows)
    (set-window-buffer (selected-window) buffer)

    (log/info :fn 'my-server/display-simple-frame
              :msg "Simple client frame created."
              :obj (buffer-name buffer))
    (selected-window)))   ; return the window, not the frame

;; Wire it in — this is what makes `emacsclient -c` use the simple frame
(setq server-window #'my-server/display-simple-frame)

;; ----------------------------------------------------------------------
;; 3. Extra daemon safety (runs for every new client frame)
;; ----------------------------------------------------------------------
;; Already covered by the hook added in startup-config, but we make
;; absolutely sure here too (idempotent, harmless to call twice).
(when (daemonp)
  (add-hook 'server-after-make-frame-hook #'my-visual/apply-all-customisations t))



;; ----------------------------------------------------------------------
;; 4. Cleaning buffers when the last frame disappears
;; ----------------------------------------------------------------------
;; Make each new frame created from a daemon a new clean slate.  Only do this if
;; you really want a clean-slate from the daemon.  Most people leave this out;
;; the daemon is more useful when it remembers what you were working on.
(defun my-server/cleanup-on-last-frame (frame)
  "When the last ordinary frame is deleted, bury or kill non-essential buffers."
  (when (and (daemonp)
             (= 1 (length (frame-list))))   ; only the (now-deleted) frame was left
    (dolist (buf (buffer-list))
      (with-current-buffer buf
        (unless (or (buffer-modified-p)
                    (get-buffer-process buf)
                    (string-match-p "\\` \\|\\*\\(Messages\\|scratch\\|Warnings\\|Completions\\)" (buffer-name)))
          (bury-buffer)   ; or (kill-buffer) if you are more aggressive
          )))))

(add-hook 'after-delete-frame-functions #'my-server/cleanup-on-last-frame)


(log/debug :fn 'server-support
           :msg "Ending load of the server-support module."
           :obj t)

(provide 'server-support)
;;; server-support.el ends here
