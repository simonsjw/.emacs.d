;;; keymaps-prog.el --- Comments and Errors / Diagnostics keymaps -*- lexical-binding: t; -*-

;; Copyright (C) 2026 Simon Watson
;; SPDX-License-Identifier: MIT

;;; Commentary:
;;
;; Shared programming-related keymaps:
;;   - Comments (C-c c)
;;   - Errors / Diagnostics (C-c e) on prog-mode-map
;;
;; Language files should call `keymaps-core/activate-comments' (or rely
;; on the prog-mode hook) rather than re-defining these maps.

;;; Code:

(require 'keymaps-core)
(require 'logging-config)

(log/debug :fn 'keymaps-prog
           :msg "Starting load of the keymaps-prog module."
           :obj t)

;; ----------------------------------------------------------------------
;;; Comments map (C-c c)
;; ----------------------------------------------------------------------

(defgroup custom-comment-keymaps ()
  "Comment formatting keymaps."
  :tag "Custom comment formatting"
  :group 'custom)

(defcustom my-custom-prefix-keys/comment "C-c c"
  "Key prefix for comment formatting functions (available in prog-mode)."
  :group 'custom-comment-keymaps
  :type 'string)

(defvar my-key-maps/comments (make-sparse-keymap "Comments")
  "Keymap for comment commands in programming modes.")

(define-prefix-command 'my-key-maps/comments)

(keymap-set my-key-maps/comments "h"   #'my-in-buffer-tools/insert-section-header)
(keymap-set my-key-maps/comments "TAB" #'comment-indent)
(keymap-set my-key-maps/comments "f"   #'fill-comment-paragraph)
(keymap-set my-key-maps/comments "a"   #'my-in-buffer-tools/comment-align-buffer)
(keymap-set my-key-maps/comments "b"   #'comment-box)
(keymap-set my-key-maps/comments ";"   #'comment-dwim)
(keymap-set my-key-maps/comments "l"   #'comment-line)
(keymap-set my-key-maps/comments "r"   #'comment-region)
(keymap-set my-key-maps/comments "u"   #'uncomment-region)
(keymap-set my-key-maps/comments "k"   #'comment-kill)
(keymap-set my-key-maps/comments "RET" #'comment-indent-new-line)

(with-eval-after-load 'which-key
  (which-key-add-key-based-replacements my-custom-prefix-keys/comment "Comments"))

;; ----------------------------------------------------------------------
;;; Errors / Diagnostics (C-c e) – installed on prog-mode-map
;; ----------------------------------------------------------------------

(with-eval-after-load "prog-mode"
  ;; Standardised navigation (n/p preferred over the mixed n/l that
  ;; previously appeared in the Python module).
  (keymap-set prog-mode-map "C-c e n" #'flymake-goto-next-error)
  (keymap-set prog-mode-map "C-c e p" #'flymake-goto-prev-error)

  ;; Show diagnostics
  (keymap-set prog-mode-map "C-c e b" #'flymake-show-buffer-diagnostics)
  (keymap-set prog-mode-map "C-c e m" #'consult-flymake)

  ;; Project-level and preload helpers (from flymake-config.el)
  (when (fboundp 'my-flymake/show-project-diagnostics)
    (keymap-set prog-mode-map "C-c e a" #'my-flymake/show-project-diagnostics))
  (when (fboundp 'my-flymake/preload-directory-for-diagnostics)
    (keymap-set prog-mode-map "C-c e l" #'my-flymake/preload-directory-for-diagnostics))
  (when (fboundp 'my-flymake/preload-project-for-diagnostics)
    (keymap-set prog-mode-map "C-c e d" #'my-flymake/preload-project-for-diagnostics))
  (when (fboundp 'my-flymake/preload-directory-recursive)
    (keymap-set prog-mode-map "C-c e D" #'my-flymake/preload-directory-recursive)))

(with-eval-after-load 'which-key
  ;; Title the C-c e prefix when it appears under prog-mode-map.
  ;; which-key discovers it via the keymap; we give it a friendly name.
  (which-key-add-key-based-replacements
    "C-c e" "Errors"))

;; ----------------------------------------------------------------------
;;; Activation for prog-mode
;; ----------------------------------------------------------------------

(defun keymaps-prog/activate-in-prog-mode ()
  "Activate shared programming keymaps in the current buffer."
  (keymaps-core/activate-comments))

(add-hook 'prog-mode-hook #'keymaps-prog/activate-in-prog-mode)

(log/debug :fn 'keymaps-prog
           :msg "Ending load of the keymaps-prog module."
           :obj t)

(provide 'keymaps-prog)
;;; keymaps-prog.el ends here
