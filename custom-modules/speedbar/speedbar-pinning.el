;;; speedbar-pinning.el --- Directory pinning, click protection, and smart project-aware file layout (internal + external) -*- lexical-binding: t; -*-

;; Copyright (C) 2026 Simon Watson
;; SPDX-License-Identifier: MIT

;; Author: Simon Watson

;;; Commentary:
;; Directory protection, pinning system, and smart file following for Speedbar.
;; Prevents accidental root directory changes via directory name clicks.
;; When the pinning lock is engaged (`my-speedbar/pinned-directory' non-nil),
;; BOTH internal Speedbar file clicks AND external file operations
;; (C-x C-f, buffer switches, clicking other file buffers, etc.) trigger the
;; same intelligent behavior:
;;   1. Determine the project root for the file
;;      (project.el → file's own directory).
;;   2. Switch Speedbar's root to that project root (if different),
;;      using smart expansion.
;;   3. Expand every ancestor directory so the file is visible in its full
;;      nested context.
;;
;; When the lock is not engaged, Speedbar behaves normally without overhead.
;; Directory name clicks remain independently protected by
;; `my-speedbar/protect-directory-clicks-p'.
;;
;; This gives a true "project explorer that follows you" experience while
;; still protecting against accidental navigation.  The implementation is
;; non-intrusive (advice + standard hooks) and has been designed with full
;; awareness of Speedbar's internal functions
;; (`speedbar-find-file', `speedbar-update-contents',
;; `speedbar-smart-directory-expand-flag', `speedbar-directory-line', etc.).

;;; Code:

(require 'speedbar)
(require 'dframe)
(require 'logging-config)

(defvar my-speedbar/protect-directory-clicks-p t
  "When non-nil, clicking directory *names* expands instead of following.  

Keeps Speedbar pinned to a project root without accidental navigation away.")

(defvar my-speedbar/pinned-directory nil
  "If non-nil, Speedbar refuses to follow directory name clicks away from path.

When non-nil (the 'lock'), file clicks AND external file/buffer operations
trigger smart project-root detection + tree expansion to the file.")

(defvar my-speedbar--divert-message-shown nil
  "Internal flag to avoid spamming the user with pinned messages.")

(defun my-speedbar--ide-frame-p ()
  "Return non-nil if the current frame is an IDE frame.  

This predicate checks the frame name prefix for IDE-specific frames where
Speedbar pinning is typically active."
  (string-prefix-p "IDE:" (frame-parameter nil 'name)))

;;;; Core advice on speedbar-dir-follow (unchanged)

(defun my-speedbar/dir-follow-advice (orig-fun text token indent)
  "Protect pinned/protected directories by diverting name clicks to expand.  

When protection or pinning is active, clicking a directory *name* will
expand/collapse instead of changing speedbar's root.  

TEXT is the directory name text.  TOKEN is the unused token argument required
by the handler.  INDENT is the current indentation level of the line."
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

;;;; Shared smart file layout logic (used by internal clicks and external hooks)
(defun my-speedbar/find-project-root (file)
  "Native-only project root detection (with debug)."
  (let* ((dir (file-name-directory (expand-file-name file)))
         (root nil))
    (message "🔍 find-project-root: file=%s  dir=%s" file dir)

    (when (fboundp 'project-current)
      (let ((proj (condition-case nil
                      (project-current nil dir)
                    (wrong-number-of-arguments
                     (condition-case nil
                         (let ((default-directory dir))
                           (project-current nil))
                       (error nil)))
                    (error nil))))
        (message "   project-current returned: %S" proj)
        (when proj
          (setq root
                (condition-case nil
                    (if (fboundp 'project-root)
                        (project-root proj)
                      (if (consp proj) (cdr proj) proj))
                  (error nil))))))

    (unless root
      (when (fboundp 'vc-root-dir)
        (setq root (condition-case nil
                       (let ((default-directory dir))
                         (vc-root-dir))
                     (error nil)))
        (message "   vc-root-dir fallback gave: %s" root)))

    (message "   FINAL root for %s → %s" file (or root dir))
    (or root dir)))
;; (defun my-speedbar/find-project-root (file)
;;   "Return project root directory for FILE using built-in Emacs functionality.

;; Uses `project.el' (project-current + project-root) with full compatibility
;; shims for older Emacs versions.  Falls back to `vc-root-dir' (excellent for
;; git repositories opened via vc-dir) and finally to the file's own directory.

;; This is the native-only implementation aligned with your preference to avoid
;; third-party packages like Projectile."
;;   (let* ((dir (file-name-directory (expand-file-name file)))
;;          (root nil))
;;     ;; Primary: built-in project.el
;;     (when (fboundp 'project-current)
;;       (let ((proj (condition-case nil
;;                       (project-current nil dir)
;;                     (wrong-number-of-arguments
;;                      ;; Older Emacs versions: set default-directory
;;                      ;; instead of passing dir
;;                      (condition-case nil
;;                          (let ((default-directory dir))
;;                            (project-current nil))
;;                        (error nil)))
;;                     (error nil))))
;;         (when proj
;;           (setq root
;;                 (condition-case nil
;;                     (if (fboundp 'project-root)
;;                         (project-root proj)
;;                       ;; Very old project.el used cons cells: (root . backend)
;;                       (if (consp proj) (cdr proj) proj))
;;                   (error nil))))))

;;     ;; Strong native fallback: vc-root-dir (perfect for git repos via vc-dir)
;;     (unless root
;;       (when (fboundp 'vc-root-dir)
;;         (setq root (condition-case nil
;;                        (let ((default-directory dir))
;;                          (vc-root-dir))
;;                      (error nil)))))

;;     (or root dir)))

(defun my-speedbar/expand-to-file (file)
  "Expand all ancestor directories in the Speedbar tree from the current root
down to the directory containing FILE, making the file's location visible in
the nested structure.  

FILE is the full path to the target file.  

The function computes the relative path from the current `default-directory'
(Speedbar's root) to FILE's directory, splits it into components, and
iteratively locates each ancestor directory line using
`speedbar-directory-line' before calling `speedbar-expand-line' on it.  This
implements the requested smart file layout, leveraging
`speedbar-smart-directory-expand-flag' semantics for in-place expansion where
possible.  After expansion, it attempts to highlight the file using
`speedbar-find-selected-file' and `speedbar-selected-face' if available, and
updates `speedbar-last-selected-file'."
  (let* ((root (expand-file-name default-directory))
         (file-dir (file-name-directory (expand-file-name file)))
         (rel (file-relative-name file-dir root))
         (ancestors (if (or (string= rel ".") (string= rel "")) '()
                      (split-string rel "/" t))))
    (dolist (anc ancestors)
      (setq root (expand-file-name anc root))
      (save-excursion
        (when (speedbar-directory-line root)
          (speedbar-expand-line)))))

  (when (fboundp 'speedbar-find-selected-file)
    (speedbar-with-writable
      (when (speedbar-find-selected-file file)
        (put-text-property (match-beginning 1) (match-end 1)
                           'face 'speedbar-selected-face))))

  (setq speedbar-last-selected-file file))

(defun my-speedbar/apply-smart-file-layout (file)
  "Core function that applies the smart project-root + expansion logic when
the lock is active.  

FILE is the full path to the target file.  This function is shared by both
Speedbar-internal clicks and external file/buffer operations.  It only acts
when `my-speedbar/pinned-directory' is non-nil, safely switches to the Speedbar
buffer, updates the root if needed (using smart expansion), and expands the
path to FILE."
  (message "my-speedbar/apply-smart-file-layout : pinned directdory: %s" my-speedbar/pinned-directory)
  (message "my-speedbar/apply-smart-file-layout : file: %s" file)
  (when (and my-speedbar/pinned-directory file)
    (let* ((project-root (my-speedbar/find-project-root file))
           (sb-buf (when (boundp 'speedbar-buffer) speedbar-buffer)))
      (when (and sb-buf (buffer-live-p sb-buf))
        (with-current-buffer sb-buf
          (let ((current-root (expand-file-name default-directory))
                (new-root (expand-file-name project-root)))
            (unless (string-equal current-root new-root)
              (setq default-directory (file-name-as-directory new-root))
              (let ((speedbar-smart-directory-expand-flag t))
                (speedbar-update-contents)))
            (my-speedbar/expand-to-file file)))))))

;;;; Advice on speedbar-find-file (internal Speedbar clicks)

(defun my-speedbar/find-file-advice (orig-fun text token indent)
  "Enhance file clicks with project-aware smart layout when the pinning lock
is engaged.  

When `my-speedbar/pinned-directory' is non-nil, a click on a file name (TEXT)
triggers the shared smart layout logic via
`my-speedbar/apply-smart-file-layout', then delegates to the original handler
(ORIG-FUN) to visit the file.  TOKEN and INDENT are the standard Speedbar click
arguments.  If the lock is not engaged, the original `speedbar-find-file'
behavior is used unchanged."
  (if my-speedbar/pinned-directory
      (let* ((line-dir (speedbar-line-directory indent))
             (file-path (concat line-dir text)))
        (my-speedbar/apply-smart-file-layout file-path)
        (funcall orig-fun text token indent))
    (funcall orig-fun text token indent)))

(advice-add 'speedbar-find-file :around #'my-speedbar/find-file-advice)

;;;; External file / buffer handling (the missing piece you reported)

(defun my-speedbar/handle-external-file-visit ()
  "Hook function attached to `find-file-hook' and `buffer-list-update-hook'.

When the pinning lock (`my-speedbar/pinned-directory') is active, this applies
the same smart project-root + expansion logic to any newly opened file or
buffer switch.  It only acts on real files and safely operates on the Speedbar
buffer regardless of which frame or window the user is currently in.  When the
lock is not engaged, this function does nothing."
  (when my-speedbar/pinned-directory
    (let ((file (buffer-file-name)))
      (when file
        (my-speedbar/apply-smart-file-layout file)))))

(add-hook 'find-file-hook #'my-speedbar/handle-external-file-visit)
(add-hook 'buffer-list-update-hook #'my-speedbar/handle-external-file-visit)

;;;; Secondary safety net (unchanged)

(defun my-speedbar--current-line-is-directory-p ()
  "Return t if current line looks like a directory (works with pretty icons).  

This helper inspects the current line's text properties and content for
directory indicators such as <+>, folder icons, or the words
'folder'/'directory'.  Used by the dframe-level click blocker."
  (condition-case nil
      (let ((line (buffer-substring-no-properties
                   (line-beginning-position) (line-end-position))))
        (or (string-match-p "<[-+?]>]\\|[\uf07b\uf07c\uebb4\uebb5]" line)
            (string-match-p "folder\\|directory" line)))
    (error nil)))

(defun my-speedbar--dframe-click-advice (orig-fun event)
  "Extra safety net.  Blocks directory name clicks at the dframe level.  

If `my-speedbar/protect-directory-clicks-p' is active and the clicked line
(determined via EVENT's window and point) appears to be a directory, the click
is blocked with a message suggesting use of the icon or SPC instead; otherwise
the original handler (ORIG-FUN) is called.  EVENT is the mouse event from
dframe."
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

;;;; User commands (docstrings updated)

(defun my-speedbar/toggle-directory-protection ()
  "Toggle protection against clicking directory names.  

When enabled, name clicks expand/collapse instead of changing root.  This
command affects the `my-speedbar/protect-directory-clicks-p' variable directly
and provides user feedback via message.  No arguments."
  (interactive)
  (setq my-speedbar/protect-directory-clicks-p
        (not my-speedbar/protect-directory-clicks-p))
  (message
   (if my-speedbar/protect-directory-clicks-p
       "🔒 Directory protection ON — name clicks now expand (not follow)"
     "🔓 Directory protection OFF — name clicks will change root")))

(defun my-speedbar/pin-current-directory ()
  "Pin Speedbar to the current directory.  

Future directory name clicks will be blocked (or diverted) until you unpin.
This sets both `my-speedbar/pinned-directory' and
`my-speedbar/protect-directory-clicks-p' to t, and displays the pinned path.
No arguments.  Ideal for locking to a project root after navigating to it
manually."
  (interactive)
  (setq my-speedbar/pinned-directory (expand-file-name default-directory))
  (setq my-speedbar/protect-directory-clicks-p t)
  (message "🔒 Speedbar pinned to: %s" my-speedbar/pinned-directory))

(defun my-speedbar/unpin-directory ()
  "Remove any pinned directory restriction.  

Clears `my-speedbar/pinned-directory' (the lock) and notifies the user.
Directory protection may remain if `my-speedbar/protect-directory-clicks-p' is
still t.  No arguments."
  (interactive)
  (setq my-speedbar/pinned-directory nil)
  (message "🔓 Speedbar unpinned"))

(defun my-speedbar/set-speedbar-directory-and-pin (dir)
  "Set the Speedbar display root to DIR and immediately pin it.  

DIR is the directory path (string) to switch to and lock as the pinned root.
This updates `default-directory' in the Speedbar buffer context, refreshes the
display with `speedbar-update-contents', and then invokes
`my-speedbar/pin-current-directory' to engage the lock.  Intended for use by
`my-speedbar/go-workspace' and `my-speedbar/go-home'."
  (when (and (boundp 'speedbar-buffer) (buffer-live-p speedbar-buffer))
    (with-current-buffer speedbar-buffer
      (setq default-directory (file-name-as-directory (expand-file-name dir)))
      (speedbar-update-contents)
      (my-speedbar/pin-current-directory))))

(defun my-speedbar/set-speedbar-to-project-root ()
  "Set the SPEEDBAR display root to the root of the current PROJECT.
If no PROJECT is found via `project-current' then DEFAULT-DIRECTORY is used
instead.  This function is bound to the 'r' key in Speedbar file mode for
convenient navigation to the project root folder."
  (interactive)
  (let* ((root (or (when (fboundp 'project-current)
                     (let ((proj (project-current nil)))
                       (when proj
                         (if (fboundp 'project-root)
                             (project-root proj)
                           ;; Fallback for older project.el API where the root
                           ;; is the CDR of the project object.
                           (cdr proj)))))
                   default-directory)))
    (my-speedbar/set-speedbar-directory-and-pin root)))

(provide 'speedbar-pinning)
;;; speedbar-pinning.el ends here
