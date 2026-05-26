;;; speedbar-pinning.el --- Directory pinning and click protection -*- lexical-binding: t; -*-

;; Copyright (C) 2026 Simon Watson
;; SPDX-License-Identifier: MIT

;; Author: Simon Watson

;;; Commentary:
;; Advanced directory protection and pinning system for Speedbar.
;; Prevents accidental root directory changes when working on projects.

;;; Code:

(require 'speedbar)
(require 'dframe)
(require 'logging-config)

(defvar my-speedbar/protect-directory-clicks-p t
  "When non-nil, clicking directory *names* expands instead of following.
Ideal for keeping Speedbar pinned to a project root.")

(defvar my-speedbar/pinned-directory nil
  "If non-nil, Speedbar refuses to follow directory name clicks away from this path.")

(defvar my-speedbar--divert-message-shown nil
  "Internal flag to avoid spamming the user with pinned messages.")

(defun my-speedbar--ide-frame-p ()
  "Return non-nil if the current frame is an IDE frame."
  (string-prefix-p "IDE:" (frame-parameter nil 'name)))

;;;; Core advice on speedbar-dir-follow
(defun my-speedbar/dir-follow-advice (orig-fun text token indent)
  "Protect pinned/protected directories by diverting name clicks to expand.
When protection or pinning is active, clicking a directory *name* will
expand/collapse instead of changing speedbar's root."
  (cond
   ((and my-speedbar/pinned-directory
         (not (string-equal (expand-file-name default-directory)
                            (expand-file-name my-speedbar/pinned-directory))))
    (unless my-speedbar--divert-message-shown
      (message "🔒 Pinned directory — name clicks now expand instead of follow")
      (setq my-speedbar--divert-message-shown t))
    (speedbar-toggle-line-expansion)
    nil)

   (my-speedbar/protect-directory-clicks-p
    (speedbar-toggle-line-expansion)
    nil)

   (t
    (funcall orig-fun text token indent))))

(advice-add 'speedbar-dir-follow :around #'my-speedbar/dir-follow-advice)

;;;; Secondary safety net
(defun my-speedbar--current-line-is-directory-p ()
  "Return t if current line looks like a directory (works with pretty icons)."
  (condition-case nil
      (let ((line (buffer-substring-no-properties
                   (line-beginning-position) (line-end-position))))
        (or (string-match-p "<[-+?]>]\\|[\uf07b\uf07c\uebb4\uebb5]" line)
            (string-match-p "folder\\|directory" line)))
    (error nil)))

(defun my-speedbar--dframe-click-advice (orig-fun event)
  "Extra safety net. Blocks directory name clicks at the dframe level."
  (if (and my-speedbar/protect-directory-clicks-p
           (with-selected-window (posn-window (event-start event))
             (save-excursion
               (mouse-set-point event)
               (my-speedbar--current-line-is-directory-p))))
      (progn
        (message
         "🔒 Directory name click BLOCKED (dframe level) — use icon or SPC")
        nil)
    (funcall orig-fun event)))

(advice-add 'dframe-click :around #'my-speedbar--dframe-click-advice)

;;;; User commands
(defun my-speedbar/toggle-directory-protection ()
  "Toggle protection against clicking directory names.
When enabled, name clicks expand/collapse instead of changing root."
  (interactive)
  (setq my-speedbar/protect-directory-clicks-p
        (not my-speedbar/protect-directory-clicks-p))
  (message (if my-speedbar/protect-directory-clicks-p
               "🔒 Directory protection ON — name clicks now expand (not follow)"
             "🔓 Directory protection OFF — name clicks will change root")))

(defun my-speedbar/pin-current-directory ()
  "Pin Speedbar to the current directory.
Future directory name clicks will be blocked until you unpin."
  (interactive)
  (setq my-speedbar/pinned-directory (expand-file-name default-directory))
  (setq my-speedbar/protect-directory-clicks-p t)
  (message "🔒 Speedbar pinned to: %s" my-speedbar/pinned-directory))

(defun my-speedbar/unpin-directory ()
  "Remove any pinned directory restriction."
  (interactive)
  (setq my-speedbar/pinned-directory nil)
  (message "🔓 Speedbar unpinned"))

(defun my-speedbar/go-workspace ()
  "Switch Speedbar to the workspace directory and automatically pin it."
  (interactive)
  (when (and (bound-and-true-p speedbar-frame)
             (eq speedbar-frame (selected-frame))
             (eq speedbar-buffer (current-buffer))
             (string-equal speedbar-initial-expansion-list-name "files"))
    (my-speedbar/set-speedbar-directory-and-pin
     "/mnt/HDD04_WDD_08TB/workspace/")))

(defun my-speedbar/go-home ()
  "Switch Speedbar to home directory and automatically pin it."
  (interactive)
  (when (and (bound-and-true-p speedbar-frame)
             (eq speedbar-frame (selected-frame))
             (eq speedbar-buffer (current-buffer))
             (string-equal speedbar-initial-expansion-list-name "files"))
    (my-speedbar/set-speedbar-directory-and-pin (expand-file-name "~/"))))

(provide 'speedbar-pinning)
;;; speedbar-pinning.el ends here