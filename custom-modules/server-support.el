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
    (message "[INFO; server] Emacs server started")))

(my-server/start-if-not-running)

;; ----------------------------------------------------------------------
;; 2. Simple client frame creator (clean, no face resets)
;; ----------------------------------------------------------------------
(defun my-server/display-simple-frame (buffer)
  "Display BUFFER in a new, simple, single-window frame.

Purpose:
  Used by `server-window' for plain `emacsclient -c' (no IDE layout).
  Creates an untagged frame, switches to BUFFER, ensures single window.

Variables:
  None required.

Output: new frame (selected).
Flow:
  1. Create frame with explicit nil UI-TYPE and no custom management.
  2. Switch to BUFFER and delete other windows.
  3. Re-apply ALL visual customisations (thick blue dividers, icons, fringes).
Efficiency: single make-frame + apply call, no recursion, <40 lines."
  (let* ((frame-params `((UI-TYPE . nil)                  ; no IDE tag
                         (custom-window-management . nil) ; bypass your window tools
                         (name . "Simple Client Frame")
                         (width . 120)
                         (height . 40)))
         (frame (make-frame frame-params)))
    (select-frame frame)
    (switch-to-buffer buffer)
    (delete-other-windows)

    ;; === Re-apply visuals so dividers stay thick blue ===
    ;; === Crash protection (prevents client window closing on visual error) ===
    (condition-case err
        (my-visual/apply-all-customisations)
      (error
       (log/error :fn 'my-server/display-simple-frame
                  :msg "Visual apply failed (non-fatal)."
                  :obj err)))

    (log/info :fn 'my-server/display-simple-frame
        :msg "Simple client frame created."
        :obj (buffer-name buffer))
        
    frame))

;; Wire it in — this is what makes `emacsclient -c` use the simple frame
(setq server-window #'my-server/display-simple-frame)

;; ----------------------------------------------------------------------
;; 3. Extra daemon safety (runs for every new client frame)
;; ----------------------------------------------------------------------
;; Already covered by the hook added in startup-config, but we make
;; absolutely sure here too (idempotent, harmless to call twice).
(when (daemonp)
  (add-hook 'server-after-make-frame-hook #'my-visual/apply-all-customisations t))

(provide 'server-support)
;;; server-support.el ends here
