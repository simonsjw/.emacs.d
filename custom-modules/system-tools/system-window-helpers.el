;;; system-window-helpers.el --- IDE window tagging helpers. -*- lexical-binding: t; -*-

;; Copyright (C) 2026 Simon Watson
;; SPDX-License-Identifier: MIT

;; Author: Simon Watson

;;; Commentary:

;; Piece of `system-window-management': tagging helpers, category
;; index, and `log/debug-window-management'.  Required by the loader,
;; not from `init.el' directly.
;;
;; Map:
;;   Feature:    system-window-helpers
;;   Load-after: path-support logging-config
;;   Load-phase: tools
;;   Keymaps:    none
;;   Docs:       docs/system-window-helpers.org
;;   OS:         none

;;; Code:

(require 'cl-lib)
(require 'path-support)
(require 'logging-config)
(log/debug :fn 'system-window-helpers
           :msg "Starting load of the system-window-helpers module."
           :obj t)

(defvar my-buffer-tools/category-map)
(defvar my-window-tools/category-map)
(defvar my-window-tools/category-fallback)
(defvar my-window-tools/keep-buffers)
(defvar my-window-tools--inhibit-retag)
(defvar my-window-tools/in-ediff-session)

;;;; Helpers
;;   -------

(defun my-window-tools/tidy-window ()
  "Clean the buffer history of the focused window only.

Other windows and the buffers they currently display are left
completely untouched.

The only buffers that belong to a window (apart from its current
buffer) are the ones recorded in that window's private history:

  - `window-prev-buffers'
  - `window-next-buffers'

This command therefore:

1. Does nothing when both history lists are empty (the window has
   never shown any other buffer).
2. Removes every buffer that is not the current buffer and whose
   name is not a member of `my-window-tools/keep-buffers' from the
   focused window's history lists.
3. Kills a buffer only when it is no longer displayed in any window
   on any frame.  Consequently no other window ever changes its
   visible buffer as a side-effect of this command.

`my-window-tools/keep-buffers' should be a list of buffer names
\(strings).  If the variable is unbound it is treated as the empty
list.  For convenience the code also accepts buffer objects in the
list.

The current buffer of the focused window is always preserved."
  (interactive)
  (let* ((win      (selected-window))
         (cur-buf  (window-buffer win))
         (keep     (and (boundp 'my-window-tools/keep-buffers)
                        my-window-tools/keep-buffers))
         (prev     (window-prev-buffers win))
         (next     (window-next-buffers win)))
    (when (or prev next)
      ;; Helper that decides whether a buffer may be kept in the
      ;; window's history.
      (cl-flet ((keep-p (buf)
                  (or (eq buf cur-buf)
                      (member buf keep)
                      (member (buffer-name buf) keep))))
        ;; 1. Kill any history buffer that is no longer displayed
        ;;    anywhere and is not protected by the keep list.
        (dolist (entry (append prev next))
          (let ((buf (car entry)))
            (when (and (buffer-live-p buf)
                       (not (keep-p buf))
                       (not (get-buffer-window buf t))) ; any frame
              (kill-buffer buf))))
        ;; 2. Rewrite the window's history so that only live, kept
        ;;    buffers remain.  Order is preserved.
        (set-window-prev-buffers
         win
         (cl-loop for entry in prev
                  for buf = (car entry)
                  when (and (buffer-live-p buf) (keep-p buf))
                  collect entry))
        (set-window-next-buffers
         win
         (cl-loop for entry in next
                  for buf = (car entry)
                  when (and (buffer-live-p buf) (keep-p buf))
                  collect entry))))))

(defun my-window-tools--in-ide-frame-p ()
  "Return t if current frame is an IDE frame."
  (eq (frame-parameter nil 'UI-TYPE) 'IDE))

(defun my-window-tools--in-ediff-p ()
  "Return t if we are currently in an Ediff session."
  (or my-window-tools/in-ediff-session
      (string-match-p "Ediff" (or (buffer-name) ""))))


;; Allow splitting small windows (default 80 too high for a 15-line 'vc)
(setq split-height-threshold 14)

;; window-persistent-parameters
;; t means the parameter is saved by current-window-configuration and,
;; provided its WRITABLE argument is nil, by window-state-get.
;; The symbol writable means the parameter is saved unconditionally by
;; both current-window-configuration and window-state-get.  Do not use
;; this value for parameters without read syntax (like windows or frames).

;; Parameters not saved by current-window-configuration or
;; window-state-get are left alone by set-window-configuration
;; respectively are not installed by window-state-put.
(add-to-list 'window-persistent-parameters '(window-category . writable))


;; Ensure the window manager never sends buffers to speedbar (which may have
;; been accidentally tagged).
(defun my-window-tools/tag-speedbar-window (&optional _)
  "Tag the speedbar window with a non-edit category so it is never chosen for normal buffers."
  (when-let* ((w (get-buffer-window "*SPEEDBAR*" t)))   ; t = include other frames if needed
    (unless (eq (window-parameter w 'window-category) 'sidebar)
      (set-window-parameter w 'window-category 'sidebar)
      (when log-window-management-flag
        (log/debug :fn 'my-window-tools/tag-speedbar-window
                   :msg "Tagged speedbar window as sidebar"
                   :obj (list :window w))))))

;; Hook it so it runs whenever speedbar appears or the window config changes
(add-hook 'speedbar-mode-hook #'my-window-tools/tag-speedbar-window)
(add-hook 'window-configuration-change-hook #'my-window-tools/tag-speedbar-window)

;; sr-speedbar equivalent.
(with-eval-after-load 'sr-speedbar
  (advice-add 'sr-speedbar-toggle :after #'my-window-tools/tag-speedbar-window))


(defvar log-window-management-flag nil
  "Non-nil means enable detailed logging for window management operations.
Set to nil to reduce overhead in production or when debugging other areas.")

(defmacro log/debug-window-management (&rest args)
  "Log using `LOG/DEBUG' only when `LOG-WINDOW-MANAGEMENT-FLAG' is non-nil.

Purpose: Provide conditional logging that skips argument evaluation for
performance when the flag is nil.

Inputs:
ARGS: &rest arguments to pass directly to `LOG/DEBUG'.  Typically a plist
      with keys like :fn, :msg and :obj.

Returns: The result of `LOG/DEBUG' if enabled, otherwise nil (from the
         `WHEN' expansion).

Flow: The macro expands to a `WHEN' form that checks the flag at runtime
      before calling `LOG/DEBUG'.  This is more efficient than a plain
      `WHEN' wrapper because the ARGS forms are not evaluated when
      disabled."
  `(when log-window-management-flag
     (log/debug ,@args)))


(defun my-window-tools/is-untaggable-window (window)
  "Determine if WINDOW should remain untagged based on buffer properties.
Purpose: Skip whitelisted buffers (e.g., speedbar, popups) in tagging.
Variables:
- WINDOW: Target window object.
Output: t if buffer matches whitelists or space-prefix, else nil.
Flow:
- Get buffer name.
- Fetch whitelists from category-map.
- Check space-prefix, exact names, or regex matches."
  (let* ((buf (window-buffer window))
         (buf-name (buffer-name buf))
         (whitelist-names
          (cdr (assq :whitelist-names my-buffer-tools/category-map)))
         (whitelist-regexps
          (cdr (assq :whitelist-regexps my-buffer-tools/category-map))))
    (or (string-prefix-p " " buf-name)                                             ; Auto-whitelist space-prefix
        (member buf-name whitelist-names)                                          ; Exact name match
        (seq-some (lambda (re) (string-match-p re buf-name)) whitelist-regexps)))) ; Regex match

(defun my-window-tools/retag-on-config-change ()
  "Retag IDE frame windows on config change.
Purpose: Restore categories post-splits/quits without per-split advice.
Variables: None (frame-local).
Output: Nil (side-effect).
Flow: Check IDE frame, get sorted windows, tag by list.

Closed categories are omitted from the assignment list so a newly created
untagged window cannot resurrect a pane the user has toggled off.  The hook
is a no-op while a toggle or layout restore is in progress."
  (unless my-window-tools--inhibit-retag
    (when (my-window-tools--in-ide-frame-p)                                       ; Limit to IDE
      (let* ((frame (selected-frame))
             (tag-list (my-window-tools/open-categories frame)))
        (my-window-tools/tag-windows-by-list frame tag-list t)
        (my-window-tools/rebuild-category-index frame)
        (log/debug-window-management :fn 'my-window-tools/retag-on-config-change
                                     :msg "Re-tagged on config change"
                                     :obj (list :frame frame :open tag-list))))))

(add-hook 'window-configuration-change-hook #'my-window-tools/retag-on-config-change)


(defun my-window-tools/sorted-window-list (frame)
  "Return a list of windows in FRAME sorted by their top-left position."
  (sort (window-list frame 'no-minibuffer)
        :lessp (lambda (w1 w2)
                 (let* ((edges1 (window-edges w1))
                        (edges2 (window-edges w2))
                        (y1 (nth 1 edges1))                                       ; top edge of w1
                        (y2 (nth 1 edges2))
                        (x1 (nth 0 edges1))                                       ; left edge of w1
                        (x2 (nth 0 edges2)))
                   (or (< y1 y2)
                       (and (= y1 y2) (< x1 x2)))))))

(defun my-window-tools/tag-windows-by-list (frame tag-list &optional set-quit-restore)
  "Tag each window in FRAME from TAG-LIST based on an ordered window list.

Tags applied in an IDE frame only.

The window list is sorted by top-left position for consistent assignment.
If there are more windows than tags, tags are reused cyclically.
Skip untaggable windows (e.g., whitelisted buffers) to leave them untagged.

When optional SET-QUIT-RESTORE is t, also set the 'quit-restore window
parameter to nil for each tagged window.  This prevents auto-deletion
of the window on buffer kill or `quit-window' calls, preserving IDE-like
layout stability by switching to a previous buffer instead.  Use this
flag judiciously to avoid persistent 'zombie' windows in non-IDE contexts.

FRAME is the target frame (defaults to selected if nil, but explicit
passing is recommended for multi-frame setups).
TAG-LIST is a list of symbols (e.g., '(edit data config logs vc terminal)).
SET-QUIT-RESTORE is an optional boolean (default nil).

Returns: Nil (side-effect function for window parameters).

Flow:
- Select the frame.
- Get sorted windows (excluding minibuffers).
- Loop over windows, skip untaggables, assign tags modulo tag-count.
- If SET-QUIT-RESTORE t, set 'quit-restore nil post-tagging.
- Log assignments for debug.
- Windows that already have a non-nil `window-category' parameter are left
    untouched.  This preserves semantic layout after manual splits (when
    combined with the split-window inherit advice) and after other config
    changes.
  - Only windows that lack a category (and are not whitelisted/untaggable)
    receive a new tag.  They are assigned cyclically starting from the
    beginning of TAG-LIST in the order they appear in the sorted window list.
  - Consequence: after the initial IDE layout, the hook is usually a cheap
    no-op.  It only performs work for genuinely new untagged windows (which
    receive an 'edit'-biased assignment as a safe default).
  - This change, together with split inheritance and whitelisting of side
    panels, eliminates the tag-shifting bug you observed.

Edge cases:
- Empty TAG-LIST: No tags applied; logs but no errors.
- More windows than tags: Cycles (e.g., 7th gets first tag).
- Untaggable: Skipped, preserving nil category."
  (when (my-window-tools--in-ide-frame-p)
    (let ((windows (my-window-tools/sorted-window-list frame))
          (tag-count (length tag-list))
          (tag-index 0))
      (dolist (window windows)
        (cond
         ((my-window-tools/is-untaggable-window window)
          (log/debug-window-management
           :fn 'my-window-tools/tag-windows-by-list
           :msg "Skipped untaggable window (whitelist or space prefix)"
           :obj (list :window window :buffer (buffer-name (window-buffer window)))))
         ((window-parameter window 'window-category)
          (log/debug-window-management
           :fn 'my-window-tools/tag-windows-by-list
           :msg "Preserved existing category (stable after split or config change)"
           :obj (list :window window
                      :category (window-parameter window 'window-category))))
         ((and tag-list (> tag-count 0))
          (let ((tag (nth (mod tag-index tag-count) tag-list)))
            (set-window-parameter window 'window-category tag)
            (when set-quit-restore
              (set-window-parameter window 'quit-restore nil))
            (log/debug-window-management
             :fn 'my-window-tools/tag-windows-by-list
             :msg "Assigned category to previously untagged window"
             :obj (list :window window :tag tag))
            (setq tag-index (1+ tag-index)))))
      (my-window-tools/rebuild-category-index frame)))))

(defconst my-window-tools/default-tag 'edit
  "The default tag assigned to non-system buffers when no tag is found.

This constant defines the fallback category for windows when a specific
category match is not available.  In an IDE-like setup, this ensures that
uncategorized or unmatched buffers are directed to a central `edit' window,
preventing unnecessary pop-ups and maintaining frame organization.

Historical context: In Emacs window management, defaults like this help
mitigate issues from older versions (pre-27) where display actions often
led to fragmented frames without explicit fall-backs.")

(defconst my-window-tools/tag-list '(edit logs config data terminal vc)
  "The tags assigned to non-system buffers.")

(defun my-window-tools/get-project-root (buffer)
  "Get the project root directory for BUFFER using the project.el package."
  (with-current-buffer buffer
    (when (project-current)
      (expand-file-name (nth 2 (project-current))))))

(defun my-window-tools/buffer-project-root (buffer)
  "Get the project root for BUFFER, if it exists or return default directory."
  (with-current-buffer buffer
    (or (my-window-tools/get-project-root buffer)
        (buffer-local-value 'default-directory buffer))))

(defun my-window-tools/close-sr-speedbar-on-frame-delete (frame)
  "Close sr-speedbar if it's in the FRAME being deleted.

This function is needed since sr-speedbar has a timer that allows it to
periodically refresh the speedbar.  The issue here is that it tries to refresh
speedbar when the window that contains it no longer exists."
  (when (sr-speedbar-exist-p)
    (when (eq (window-frame sr-speedbar-window) frame)
      (sr-speedbar-refresh-turn-off)
      (sr-speedbar-close))))

;; close sr-speedbar when a frame is deleted.
;; This function is needed since sr-speedbar has a timer that allows it to
;; periodically refresh the speedbar.  The issue here is that it tries to
;; refresh speedbar when the window that contains it no longer exists.
(add-hook
 'delete-frame-functions #'my-window-tools/close-sr-speedbar-on-frame-delete)

(defun my-window-tools/ide-categories ()
  "Return the list of IDE window categories from `my-window-tools/category-map'."
  (cdr (assq :IDE my-window-tools/category-map)))

(defun my-window-tools--normalize-category (window-name)
  "Return WINDOW-NAME as a category symbol, or nil if it is not an IDE category.
WINDOW-NAME may be a symbol or a string."
  (let ((sym (cond
              ((symbolp window-name) window-name)
              ((stringp window-name) (intern (downcase window-name)))
              (t nil))))
    (and sym (memq sym (my-window-tools/ide-categories)) sym)))

(defun my-window-tools/open-categories (&optional frame)
  "Return IDE categories that are not marked closed on FRAME."
  (let ((closed (frame-parameter (or frame (selected-frame))
                                 'ide-closed-categories)))
    (cl-remove-if (lambda (cat) (memq cat closed))
                  (my-window-tools/ide-categories))))

(defun my-window-tools/reset-closed-categories (&optional frame)
  "Clear the closed-category set on FRAME and rebuild the lookup index.

Called from `IDE-refresh' / a brand-new IDE frame so every pane is eligible
again.  Does not itself restore geometry."
  (let ((frame (or frame (selected-frame))))
    (set-frame-parameter frame 'ide-closed-categories nil)
    (set-frame-parameter frame 'ide-last-buffers nil)
    (my-window-tools/rebuild-category-index frame)))

(defun my-window-tools/rebuild-category-index (&optional frame)
  "Rebuild the frame-local category -> window index for FRAME.

Only the first live window of each category (spatial order) is recorded.
Returns the new alist and stores it on the `ide-category-index' frame
parameter.  Intended for layout changes, not the `display-buffer' hot path."
  (let ((frame (or frame (selected-frame)))
        (index '()))
    (dolist (win (my-window-tools/sorted-window-list frame))
      (let ((cat (window-parameter win 'window-category)))
        (when (and cat (not (assq cat index)))
          (push (cons cat win) index))))
    (setq index (nreverse index))
    (set-frame-parameter frame 'ide-category-index index)
    index))

(defun my-window-tools--index-window (category frame)
  "Return the cached window for CATEGORY on FRAME, or nil."
  (let* ((index (frame-parameter frame 'ide-category-index))
         (win (cdr (assq category index))))
    (and (window-live-p win) win)))

(defun my-window-tools/window-open-p (window-name &optional frame)
  "Return non-nil if the WINDOW-NAME pane is present on FRAME.

WINDOW-NAME is a category symbol or string.  FRAME defaults to the selected
frame.  A category that is recorded as closed, or whose cached window is
dead, is treated as closed."
  (let* ((frame (or frame (selected-frame)))
         (category (my-window-tools--normalize-category window-name)))
    (and category
         (eq (frame-parameter frame 'UI-TYPE) 'IDE)
         (not (memq category (frame-parameter frame 'ide-closed-categories)))
         (or (my-window-tools--index-window category frame)
             (cl-loop for win in (window-list frame 'no-minibuffer)
                      when (eq category (window-parameter win 'window-category))
                      return win)))))

(defun my-window-tools--fallback-chain (category &optional skip-self)
  "Return the lookup chain for CATEGORY.
When SKIP-SELF is non-nil the home category is omitted (used when burying
buffers off a pane that is about to be deleted)."
  (let ((chain (copy-sequence
                (or (assq category my-window-tools/category-fallback)
                    (list category my-window-tools/default-tag)))))
    (if skip-self
        (delq category chain)
      chain)))

(defun my-window-tools/get-window-for-window-category (target-window-category frame)
  "Retrieve a window for TARGET-WINDOW-CATEGORY on FRAME.

Tries the home category first, then each alternative listed in
`my-window-tools/category-fallback', skipping categories that are marked
closed or whose cached window is dead.  Rebuilds the frame index once if
it is missing.

TARGET-WINDOW-CATEGORY is the symbol (e.g., `edit', `logs') to search for.
FRAME is the frame to search within (defaults to selected if nil).

Returns a live window object, or nil if no open pane on the chain exists
\(the caller may pop up a new window)."
  (let ((frame (or frame (selected-frame))))
    (unless (frame-parameter frame 'ide-category-index)
      (my-window-tools/rebuild-category-index frame))
    (or (cl-loop for cat in (my-window-tools--fallback-chain target-window-category)
                 for win = (my-window-tools--index-window cat frame)
                 when (and win
                           (not (memq cat (frame-parameter frame
                                                           'ide-closed-categories))))
                 return win)
        ;; Cache may be stale after a raw deletion; rebuild once and retry.
        (progn
          (my-window-tools/rebuild-category-index frame)
          (cl-loop for cat in (my-window-tools--fallback-chain target-window-category)
                   for win = (my-window-tools--index-window cat frame)
                   when (and win
                             (not (memq cat (frame-parameter frame
                                                             'ide-closed-categories))))
                   return win))
        (progn
          (log/debug-window-management
           :fn 'my-window-tools/get-window-for-window-category
           :msg "No matching or fallback window found"
           :obj (list :category target-window-category :frame frame
                      :closed (frame-parameter frame 'ide-closed-categories)))
          nil))))

(log/debug :fn 'system-window-helpers
           :msg "Finishing load of the system-window-helpers module."
           :obj t)

(provide 'system-window-helpers)
;;; system-window-helpers.el ends here
