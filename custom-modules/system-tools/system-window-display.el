;;; system-window-display.el --- display-buffer advice and Ediff. -*- lexical-binding: t; -*-

;; Copyright (C) 2026 Simon Watson
;; SPDX-License-Identifier: MIT

;; Author: Simon Watson

;;; Commentary:

;; Piece of `system-window-management': `display-buffer' integration
;; and Ediff window advice.  Required by the loader, not from
;; `init.el' directly.
;;
;; Map:
;;   Feature:    system-window-display
;;   Load-after: path-support logging-config system-window-helpers system-window-panes
;;   Load-phase: tools
;;   Keymaps:    none
;;   Docs:       docs/system-window-display.org
;;   OS:         none

;;; Code:

(require 'cl-lib)
(require 'path-support)
(require 'logging-config)
(log/debug :fn 'system-window-display
           :msg "Starting load of the system-window-display module."
           :obj t)

(require 'system-window-helpers)
(require 'system-window-panes)

(defvar my-window-tools/category-map)
(defvar my-window-tools--inhibit-retag)
(defvar my-window-tools--in-toggle)
(defvar my-window-tools/in-ediff-session)

;;;; Display-buffer integration
;;   --------------------------

(defun my-window-tools/assign-category-advice (orig-fun buffer-or-name &optional action frame)
  "Advice to inject a category into the `DISPLAY-BUFFER' action alist.

This wraps the original `display-buffer' to assign a category based on the
buffer's name or mode, but only if the frame is tagged for custom window
management (i.e., IDE frames with `custom-window-management' t).

For non-IDE frames, skips custom logic, falling back to Emacs defaults.

When `dape-buffer-window-arrangement' is nil (defer to base actions), and
a category is determined, strips any existing Dape-specific category (e.g.,
'dape-info-N') from the action to prevent conflicts, then re-injects the
custom one.  This supplements Dape without overriding its arrangements.

ORIG-FUN is the original `display-buffer' function.
BUFFER-OR-NAME is a buffer or name.
ACTION is optional alist or function spec.
FRAME is target frame (defaults to selected).

Returns: Result of original or modified `display-buffer' call (window or nil).

Flow:
- Determine effective frame.
- If non-IDE, apply original unmodified.
- Get buffer and compute custom category.
- If category found and arrangement nil, strip Dape category from action.
- Process/inject new action with custom category.
- Apply original with new action.

Edge cases:
- Symbol action (e.g., 'other-window): Skip strip (not list).
- Nil arrangement: Override only if Dape category present.
- Non-nil arrangement: No strip/override—respects Dape.
- No category: Skip injection.
- Logs for traceability."
  (let* ((effective-frame (or frame (selected-frame)))                            ; Ensure locality to active frame if not specified.
         (use-custom
          (frame-parameter effective-frame 'custom-window-management)))           ; Check for IDE tag.
    (if (or (not use-custom) (my-window-tools--in-ediff-p))
        ;; Non-IDE: Skip all custom logic, apply original display-buffer with
        ;; unmodified action.
        ;; This ensures default behavior, e.g., 'other-window' reuses or splits
        ;; in current frame.
        (progn
          (log/debug-window-management :fn 'my-window-tools/assign-category-advice
                                       :msg "Non-IDE frame detected, skipping category assignment and using default display"
                                       :obj (list :buffer buffer-or-name
                                                  :frame effective-frame
                                                  :action action))
          (my-window-tools--stabilize-ide-window
           (apply orig-fun buffer-or-name action frame)))
      ;; IDE: Proceed with category assignment and modified action.
      (let* ((buffer (get-buffer buffer-or-name))                                 ; Get buffer for category check.
             (category
              (when buffer
                (my-window-tools/determine-buffer-category buffer))))             ; Use map for category.
        (when category
          (log/debug-window-management :fn 'my-window-tools/assign-category-advice
                                       :msg "IDE frame: Category computed"
                                       :obj (list :category category :buffer buffer-or-name)))
        ;; Conditional override only if dape-buffer-window-arrangement
        ;; has value set to nil
        (let
            ((new-action
              (if (and category (eq dape-buffer-window-arrangement nil)
                       (consp action) (assq 'category action))                    ; Dape injected?
                  ;; if Dape buffers are found with Dape category tags when
                  ;; dape-buffer-window-arrangement is nil then do this:
                  (let ((stripped-action (assoc-delete-all 'category action)))    ; Strip the Dape category so we can use the custom version.
                    (log/debug-window-management :fn 'my-window-tools/assign-category-advice
                                                 :msg "Stripped Dape category, re-injecting custom."
                                                 :obj (list :original-action action
                                                            :category category
                                                            :buffer buffer-or-name))
                    (my-window-tools/process-display-action
                     stripped-action category))
                ;; else it is a simple category assignment.
                (my-window-tools/process-display-action action category))))

          (my-window-tools--stabilize-ide-window
           (apply orig-fun buffer-or-name (or new-action action) frame)))))))

(defun display-buffer-in-category-window (buffer alist)
  "Display BUFFER in a window according to its category from ALIST.

The `window-category' of the window matches a category in ALIST.
If no exact match is found, fall back to the default `edit' window.
If neither is available, pop up a new window and tag it with the category.

BUFFER is the buffer to display.
ALIST is the action alist, expected to contain `(category . SYMBOL)'.

This function enforces IDE-like behavior: Prioritize reuse of tagged windows
to maintain frame structure.  It uses
`my-window-tools/get-window-for-window-category` for the search and fallback
logic.

Before reusing a window, checks if it is dedicated (e.g., to a Dape buffer)
and unsets dedication if so, allowing buffer switch.  This releases 'sticky'
windows from debuggers like Dape without affecting non-Dape cases.

Returns: The window where BUFFER is displayed, or nil on failure.

Flow:
- Extract category from alist.
- Get current frame.
- Find target window (exact or default).
- If found: Check dedication; unset if Dape buffer; set new buffer.
- If not: Pop new window, tag it.
- Log decisions.

Edge cases:
- Dedicated non-Dape: Skip unset to preserve (error as before).
- No category: Log/fallback to pop-up.
- New window: Inherits category for reuse.
- Historical: Aligns with Emacs 24+ quit-restore for stability."
  (when (my-window-tools--in-ide-frame-p)
    (let* ((category (cdr (assq 'category alist)))
           (frame (selected-frame))
           (target-window
            (when category
              (my-window-tools/get-window-for-window-category category frame))))
      (log/debug-window-management :fn 'display-buffer-in-category-window
                                   :msg "Searching for window"
                                   :obj (list :category category
                                              :buffer (buffer-name buffer) :frame frame))
      (if target-window
          (progn
            ;; Check and unset dedication if current buffer is Dape- or VC-related.
            ;; This prevents "stuck" windows from packages like Dape or VC/log-edit.
            (let ((current-buf (window-buffer target-window)))
              (when (and (window-dedicated-p target-window)
                         (or (string-match-p "^\\*dape-" (buffer-name current-buf))
                             (string-match-p "^\\*\\(vc-\\|log-edit-\\)" (buffer-name current-buf))))
                (set-window-dedicated-p target-window nil)
                (log/debug-window-management
                 :fn 'display-buffer-in-category-window
                 :msg (format "Unset dedication for %s window to allow category reuse"
                              (if (string-match-p "^\\*dape-" (buffer-name current-buf))
                                  "Dape" "VC/log-edit"))
                 :obj (list :window target-window :buffer current-buf))))
            (log/debug-window-management :fn 'display-buffer-in-category-window
                                         :msg "Found matching or default window"
                                         :obj (list :window target-window
                                                    :category (window-parameter
                                                               target-window 'window-category)))
            (set-window-buffer target-window buffer)
            (my-window-tools--stabilize-ide-window target-window)
            target-window)
        ;; No match or default: Fallback to pop-up and tag the new window.
        (log/debug-window-management :fn 'display-buffer-in-category-window
                                     :msg "No matching or default window found, falling back to pop-up"
                                     :obj (list :category category :frame frame))
        (let ((new-window (display-buffer-pop-up-window buffer alist)))
          (when new-window
            ;; Never tag a pop-up with a category the user has closed; that
            ;; would resurrect the pane through the back door.
            (let ((tag (if (memq category
                                 (frame-parameter frame 'ide-closed-categories))
                           my-window-tools/default-tag
                         category)))
              (set-window-parameter new-window 'window-category tag)
              (my-window-tools--stabilize-ide-window new-window)
              (my-window-tools/rebuild-category-index frame)
              (log/debug-window-management
               :fn 'display-buffer-in-category-window
               :msg "Created and tagged new window"
               :obj (list :new-window new-window :category tag))))
          new-window)))))

(defun my-window-tools/determine-buffer-category (buffer)
  "Determine the category for BUFFER based on its properties.
Returns a symbol (e.g., `edit', `logs') or nil if no category applies.
BUFFER is the buffer to categorise.

The category is derived from:
- Buffers with names starting with a space are automatically whitelisted.
- Whitelisted names or regexps (ignored if matched).
- Exact buffer name matches.
- Regex patterns on buffer names.
- Major mode associations.
Logs the decision process at debug level."
  (when (my-window-tools--in-ide-frame-p)
    (with-current-buffer buffer
      (let* ((buf-name (buffer-name))                                               ; Get the buffer's name
             (buf-mode major-mode)                                                  ; Get the current major mode
             (whitelist-names
              (cdr (assq :whitelist-names my-buffer-tools/category-map)))           ; Fetch whitelist names
             (whitelist-regexps
              (cdr (assq :whitelist-regexps my-buffer-tools/category-map))))        ; Fetch whitelist regexps
        (log/debug-window-management
         :fn 'my-window-tools/determine-buffer-category
         :msg "Computing category"
         :obj (list :buffer-name buf-name :major-mode buf-mode))

        ;; Check if buffer should be ignored based on whitelists
        (if (or
             (string-prefix-p " " buf-name)                                         ; Auto-whitelist if starts with space
             (member buf-name whitelist-names)                                      ; Exact match in whitelist names
             (seq-some (lambda (re) (string-match-p re buf-name))
                       whitelist-regexps))                                          ; Regex match
            (progn
              (log/debug-window-management
               :fn 'my-window-tools/determine-buffer-category
               :msg "Buffer whitelisted, no category assigned"
               :obj (list :buffer-name buf-name))
              nil)                                                                  ; No category if whitelisted
          ;; Proceed with category matching
          (let* ((names (cdr (assq :names my-buffer-tools/category-map)))           ; Name-to-category mappings
                 (regexps (cdr (assq :regexps my-buffer-tools/category-map)))       ; Regex-to-category mappings
                 (modes (cdr (assq :modes my-buffer-tools/category-map)))           ; Mode-to-category mappings
                 (name-match (assoc buf-name names)))                               ; Check for exact name match
            (cond
             (name-match
              (log/debug-window-management
               :fn 'my-window-tools/determine-buffer-category
               :msg "Matched by exact name"
               :obj (list :match name-match))
              (cdr name-match))                                                     ; Return category from name match
             ((seq-some (lambda (pair)                                              ; Check regex matches
                          (when (string-match-p (car pair) buf-name)
                            (log/debug-window-management
                             :fn 'my-window-tools/determine-buffer-category
                             :msg "Matched by regex"
                             :obj (list :regex (car pair)
                                        :category (cdr pair)))
                            (cdr pair)))
                        regexps))
             ((if-let ((mode-match (assoc buf-mode modes)))                         ; Check mode match
                  (progn
                    (log/debug-window-management
                     :fn 'my-window-tools/determine-buffer-category
                     :msg "Matched by mode"
                     :obj (list :mode buf-mode
                                :category (cdr mode-match)))
                    (cdr mode-match))))
             (t
              (log/debug-window-management
               :fn 'my-window-tools/determine-buffer-category
               :msg "No match found, falling back to default category"
               :obj (list :buffer-name buf-name))
              my-window-tools/default-tag)                                          ; Returns 'edit
             )
            )
          )
        )
      )
    )
  )


(defun my-window-tools/process-display-action (action category)
  "Process ACTION for `display-buffer' and inject CATEGORY.
Returns a new action structure or the original action if no change is needed.
ACTION is the original action (function list, alist, or special value like t).
CATEGORY is the buffer category to inject (e.g., `logs').

This function handles various forms of ACTION:
- Nil or t: Treated as no specific functions or alist.
- Symbol: If it is a function (e.g., `display-buffer-same-window'), wrap it as
  a single-function list.
- Cons: If car is a symbol/function, treat as (function . alist); if car
  is a list, treat as (function-list . alist); if not, assume pure alist.
Special symbols like `other-window' are translated to standard actions
  (e.g., '(display-buffer-use-some-window (inhibit-same-window . t)))
  to ensure compatibility across Emacs versions and avoid type errors in alist
  operations.

The category is injected into the alist only if not already present.  Debugging
logs are added for traceability.

To prevent errors in Emacs internal action combination
 (e.g., 'wrong-type-argument listp SYMBOL' from appending improper lists),
always reconstruct as (functions . alist), with functions as nil (empty list)
if absent.  This ensures car is a proper list, avoiding misinterpretation of
pure alists as function lists.

Historical context: Emacs `display-buffer' actions evolved
 (e.g., post-Emacs 27), shorthands like `other-window' are often translated in
`pop-to-buffer', but advices or older versions may pass them directly, leading
to mismatches.  This robust parsing prevents errors like 'wrong-type-argument
listp symbol' by ensuring action-alist is always a list or nil.  The explicit
 (nil . alist) format aligns with best practices in packages like `consult' or
`embark' to handle alist-only cases without append failures during action
merging in `display-buffer'."

  ;; Handle special shorthand symbols early to standardize the action format.
  ;; This prevents downstream type errors when symbols are mistakenly treated
  ;; as alists.
  (when (eq action 'other-window)
    (setq action '(display-buffer-use-some-window (inhibit-same-window . t)))
    (log/debug-window-management
     :fn 'my-window-tools/process-display-action
     :msg "Translated 'other-window' to standard action"
     :obj action))

  ;; Parse into functions and alist with robust type checks to handle diverse
  ;; action formats.
  ;; Ensures action-functions is a list of callable functions or nil, and
  ;; action-alist is a proper alist or nil.
  (let ((action-functions
         (cond
          ((null action) nil)                                                     ; No action: default to nil functions.
          ((eq action t) nil)                                                     ; Special t: implies default behavior, no specific functions.
          ((symbolp action)
           (when (functionp action) (list action)))                               ; Single symbol: wrap if it's a valid display function.
          ((consp action)
           (let ((first (car action)))
             (cond
              ((symbolp first)
               (when (functionp first) (list first)))                             ; (function . alist) form.
              ((consp first)
               (when (and (cl-every #'symbolp first)
                          (cl-every #'functionp first))
                 first))                                                          ; (function-list . alist) form.
              (t nil))))                                                          ; Invalid: default to nil.
          (t nil)))                                                               ; Fallback for unexpected types.
        (action-alist
         (cond
          ((null action) nil)                                                     ; No action: empty alist.
          ((eq action t) nil)                                                     ; Special t: empty alist.
          ((symbolp action) nil)                                                  ; Single symbol: no alist.
          ((consp action)
           (if (or (symbolp (car action)) (consp (car action)))
               (cdr action)                                                       ; Extract alist from (functions . alist).
             action))                                                             ; Pure alist case.
          (t nil))))                                                              ; Fallback.

    ;; Inject category if needed and log the processing for debug traceability.
    ;; This ensures the category is added only once, preserving existing alist
    ;; entries.
    (let ((new-alist (if (and category (not (assq 'category action-alist)))
                         (cons `(category . ,category) action-alist)
                       action-alist))

          (new-functions (if category
                             '(display-buffer-in-category-window)                 ; Prioritize category reuse
                           action-functions)))                                    ; Else keep original
      (log/debug-window-management
       :fn 'my-window-tools/process-display-action
       :msg "Processed action"
       :obj (list :original-action action :category category
                  :functions new-functions :new-alist new-alist))       ; Log new-functions
      ;; Reconstruct the final action: Always (functions . alist) if either
      ;; non-nil, with functions as nil (empty list) if absent.
      ;; This prevents pure alist returns, avoiding Emacs' append errors on
      ;; improper lists during action merging.
      ;; If both nil, return nil for default behaviour.
      (if (or new-functions new-alist)
          (cons new-functions new-alist)
        nil))))

(advice-add 'display-buffer :around #'my-window-tools/assign-category-advice)

;; Ensure tags are inherited on splitting windows.
(defun my-window-tools/split-window-with-category-inherit (orig-fun &rest args)
  "Copy `window-category' when splitting a window.
ORIG-FUN is the original `split-window' command.  ARGS are passed through.
Around advice for `split-window' (and transitively `split-window-below',
`split-window-right', and the split-window key commands) that copies the
`window-category' parameter from the window being split to the newly created
window.

Purpose:
  When a user manually splits a window to obtain two simultaneous views of the
  same buffer (or same category), both resulting windows should retain the
  original category.  This prevents the later re-tagging pass from
  mis-assigning categories and keeps `display-buffer-in-category-window'
  routing stable.

  Without this, the new window starts untagged; the configuration-change hook
  then assigns it (and shifts all subsequent windows) according to sorted
  position, destroying the semantic layout.

Arguments:
  ORIG-FUN  The original `split-window' function (or wrapper).
  ARGS      The argument list passed to `split-window' (WINDOW, optional SIZE,
            SIDE, PIXELWISE).  The first element is the window being split.

Returns:
  The newly created window object (the return value of ORIG-FUN), after
  possibly setting its `window-category' parameter.

Edge cases & considerations:
  - Works for both horizontal and vertical splits.
  - If the parent had no category (rare after initial tagging), nothing is
    copied.
  - Internal window splits (e.g. some package helpers) are also covered.
  - Complements the updated `tag-windows-by-list' logic below; together they
    make the hook mostly a no-op after the initial layout."
  (let* ((old-window (car args))
         (old-category (window-parameter old-window 'window-category))
         (new-window (apply orig-fun args)))
    (when old-category
      (set-window-parameter new-window 'window-category old-category)
      (log/debug-window-management
       :fn 'my-window-tools/split-window-with-category-inherit
       :msg "Inherited window-category across manual split for stable routing"
       :obj (list :old-window old-window
                  :new-window new-window
                  :category old-category)))
    new-window))

(advice-add 'split-window
            :around #'my-window-tools/split-window-with-category-inherit)

(defun my-window-tools--stabilize-ide-window (window)
  "Keep IDE category WINDOW from being treated as a temporary pop-up.

`display-buffer' records a `quit-restore' parameter after the display
action returns.  For `log-edit' / vc-log that parameter tells
`quit-window' to delete the window when the commit finishes, which then
hit `delete-window' advice and closed the whole vc pane.

Clearing `quit-restore' (and `dedicated') on tagged IDE windows makes
`quit-window' and `kill-buffer' fall back to the previous buffer
instead of destroying the pane."
  (when (and (window-live-p window)
             (eq (frame-parameter (window-frame window) 'UI-TYPE) 'IDE)
             (window-parameter window 'window-category))
    (set-window-parameter window 'quit-restore nil)
    (set-window-parameter window 'no-delete-other-windows t)
    (set-window-dedicated-p window nil))
  window)

(defconst my-window-tools/explicit-delete-commands
  '(delete-window
    delete-other-windows
    my-window-tools/mouse-delete-window-confirmation
    my-window-tools/toggle
    my-window-tools/toggle-edit
    my-window-tools/toggle-data
    my-window-tools/toggle-config
    my-window-tools/toggle-logs
    my-window-tools/toggle-vc
    my-window-tools/toggle-terminal)
  "Commands that mean the user asked to remove a pane, not a transient buffer.")

(defun my-window-tools--user-initiated-window-delete-p ()
  "Return non-nil when the current command is an explicit pane-close."
  (memq this-command my-window-tools/explicit-delete-commands))

(defun my-window-tools--preserve-ide-window (window)
  "Keep WINDOW and show its previous or default occupant instead of deleting it."
  (when (window-live-p window)
    (my-window-tools--sanitize-window-history window)
    (let* ((cat (window-parameter window 'window-category))
           (current (window-buffer window))
           (fallback
            (or (cl-loop for entry in (window-prev-buffers window)
                         for buf = (car-safe entry)
                         when (and (buffer-live-p buf)
                                   (not (eq buf current)))
                         return buf)
                (and cat (my-window-tools--default-occupant cat))
                (get-buffer "*scratch*"))))
      (when (and fallback (not (eq fallback current)))
        (set-window-buffer window fallback))
      (my-window-tools--stabilize-ide-window window)))
  window)

(defun my-window-tools/delete-window-advice (orig-fun &optional window)
  "Keep the IDE closed-set in sync when ORIG-FUN deletes a tagged WINDOW.

Inside a toggle the work has already been done, so ORIG-FUN is called
unmodified.  Deleting the last `edit' window is refused.

An extra split of the same category (the usual leftover from
`log-edit-show-files') is deleted as a normal window: the category
stays open on the remaining pane.  Closing the *last* window of a
category is a real pane-close only when the user asked for it
\(`delete-window', mode-line click, pane toggle).  Package teardown
such as `log-edit-done' on that last pane is not a pane-close: the
window is kept and the previous buffer (usually the `vc-dir' buffer) is restored."
  (let ((window (or window (selected-window))))
    (if (or my-window-tools--in-toggle
            my-window-tools--inhibit-retag
            (not (window-live-p window))
            (not (eq (frame-parameter (window-frame window) 'UI-TYPE) 'IDE)))
        (funcall orig-fun window)
      (let* ((frame (window-frame window))
             (cat (window-parameter window 'window-category)))
        (cond
         ((eq cat 'edit)
          (if (<= (length (my-window-tools--windows-of-category 'edit frame)) 1)
              (progn
                (message "The edit window cannot be closed")
                window)
            (funcall orig-fun window)))
         (cat
          (let ((count (length (my-window-tools--windows-of-category cat frame))))
            (cond
             ((> count 1)
              (let ((result (funcall orig-fun window)))
                (my-window-tools/rebuild-category-index frame)
                result))
             ((my-window-tools--user-initiated-window-delete-p)
              (my-window-tools--close-category cat frame))
             (t
              (my-window-tools--preserve-ide-window window)))))
         (t
          (funcall orig-fun window)))))))

(advice-add 'delete-window :around #'my-window-tools/delete-window-advice)

(defun my-window-tools/delete-other-windows-advice (orig-fun &rest args)
  "Mark every non-edit category closed when `delete-other-windows' runs.
ORIG-FUN is the original command.  ARGS are passed through."
  (if (or my-window-tools--in-toggle
          my-window-tools--inhibit-retag
          (not (my-window-tools--in-ide-frame-p)))
      (apply orig-fun args)
    (let ((frame (selected-frame)))
      (dolist (cat (my-window-tools/ide-categories))
        (unless (eq cat 'edit)
          (when (my-window-tools/window-open-p cat frame)
            (my-window-tools--close-category cat frame))))
      (my-window-tools/rebuild-category-index frame)
      (force-mode-line-update t)
      (selected-window))))

(advice-add 'delete-other-windows :around #'my-window-tools/delete-other-windows-advice)

(defun my-window-tools/winner-sync-advice (&rest _)
  "Rebuild the closed-category set after Winner restores a configuration."
  (when (my-window-tools--in-ide-frame-p)
    (my-window-tools/sync-closed-set-from-windows)))

(with-eval-after-load 'winner
  (advice-add 'winner-undo :after #'my-window-tools/winner-sync-advice)
  (advice-add 'winner-redo :after #'my-window-tools/winner-sync-advice))

;; Configure display-buffer-alist
;;   ------------------------------
;; the below object controls how new buffers are assigned to windows in Emacs.
;; This is central to managing the relationship between buffers and windows.
(setq display-buffer-alist
      '(;; Keep only valid, like Dictionary/Ilist
        ("^\\*\\(Dictionary\\|Ilist\\)\\*"
         (display-buffer-in-side-window)
         (side . right)
         (window-width . 50)                                                      ; change to 0.5 to make it half the size of the buffer it is next to.
         (window-parameters . ((no-delete-other-windows . t))))))

(setq display-buffer-alist
      (append display-buffer-alist
              '(("\\*vc\\(-dir\\|-log\\|-diff\\|-change-log\\)?\\*\\|\\*log-edit.*\\*"
                 (display-buffer-in-category-window)                              ; Functions first: Your custom handler injects 'vc category
                 (inhibit-same-window . nil)                                      ; Allow same if matches
                 (pop-up-windows . nil)                                           ; Stop popup behaviour
                 (dedicated . nil)                                                ; Ensure the buffer doesn't capture the window
                 (reusable-frames . visible)
                 (window-parameters . ((quit-restore . nil)
                                       (no-delete-other-windows . t)))))))

(defun my-window-tools--vc-dir-busy-p (buffer)
  "Return non-nil if BUFFER is a live `vc-dir' buffer already refreshing."
  (and (buffer-live-p buffer)
       (with-current-buffer buffer
         (and (derived-mode-p 'vc-dir-mode)
              (fboundp 'vc-dir-busy)
              (vc-dir-busy)))))

(defun my-window-tools/refresh-vc-dir-if-idle (&optional buffer)
  "Call `vc-dir-refresh' in BUFFER only when no update is already running.

Calling `vc-dir-refresh' from `vc-checkin-hook' while Emacs is already
resynching the directory signals:
  \"Another update process is in progress, cannot run two at a time\"."
  (let ((buf (or buffer (my-window-tools--buffer-named "*vc-dir*"))))
    (when (and (buffer-live-p buf)
               (not (my-window-tools--vc-dir-busy-p buf)))
      (with-current-buffer buf
        (when (derived-mode-p 'vc-dir-mode)
          (ignore-errors (vc-dir-refresh)))))))

(defun my-window-tools/restore-vc-dir-after-checkin (&rest _)
  "After a VC check-in, keep a single vc pane showing the `vc-dir' buffer.

`log-edit-show-files' splits the vc pane.  Finishing the commit then
used to leave both halves showing that buffer.  Collapse those extras,
put the `vc-dir' buffer in the remaining pane, and clear `quit-restore'
so a later quit cannot delete it.

Does not call `vc-dir-refresh' here: the check-in path already starts
an update, and a second refresh is what produced the busy error."
  (when (my-window-tools--in-ide-frame-p)
    (let* ((frame (selected-frame))
           (win (or (my-window-tools--collapse-extra-category-windows 'vc frame)
                    (my-window-tools/get-window-for-window-category 'vc frame)))
           (dir (my-window-tools--buffer-named "*vc-dir*")))
      (when (and (window-live-p win) (buffer-live-p dir))
        (unless (eq (window-buffer win) dir)
          (set-window-buffer win dir))
        (my-window-tools--stabilize-ide-window win)
        (my-window-tools/rebuild-category-index frame)))))

(defun my-window-tools/after-log-edit-done (&rest _)
  "Restore the vc pane after `log-edit-done', then refresh if idle.

Deferred so `log-edit' can finish tearing down its buffers and so any
refresh Emacs already started on check-in can claim the process slot."
  (when (my-window-tools--in-ide-frame-p)
    (run-at-time 0 nil
                 (lambda ()
                   (my-window-tools/restore-vc-dir-after-checkin)
                   (run-at-time 0.4 nil #'my-window-tools/refresh-vc-dir-if-idle)))))

;; Drop the raw refresh on check-in: it races Emacs' own vc-dir resynch
;; and was also invoked with current-buffer still the log-edit buffer.
(remove-hook 'vc-checkin-hook #'vc-dir-refresh)
(remove-hook 'vc-checkin-hook 'vc-dir-refresh)
(add-hook 'vc-checkin-hook #'my-window-tools/restore-vc-dir-after-checkin)
(advice-add 'log-edit-done :after #'my-window-tools/after-log-edit-done)

(defun my-window-tools/with-temporary-display-buffer-settings (settings &rest body)
  "Apply SETTINGS temporarily while executing BODY.

SETTINGS is a list of settings to apply, including `display-buffer-alist' and
other variables like `switch-to-buffer-obey-display-actions', `pop-up-windows',
and `pop-up-frames'.  The original values are restored afterwards."
  (let* ((original-display-buffer-alist (copy-sequence display-buffer-alist))
         (original-switch-to-buffer-obey-display-actions
          switch-to-buffer-obey-display-actions)
         (original-pop-up-windows pop-up-windows)
         (original-pop-up-frames pop-up-frames)
         (new-settings settings))
    (unwind-protect
        (progn
          ;; Apply temporary settings
          (when (assq 'display-buffer-alist new-settings)
            (setq display-buffer-alist
                  (cdr (assq 'display-buffer-alist new-settings))))
          (when (assq 'switch-to-buffer-obey-display-actions new-settings)
            (setq switch-to-buffer-obey-display-actions
                  (cdr (assq 'switch-to-buffer-obey-display-actions
                             new-settings))))
          (when (assq 'pop-up-windows new-settings)
            (setq pop-up-windows (cdr (assq 'pop-up-windows new-settings))))
          (when (assq 'pop-up-frames new-settings)
            (setq pop-up-frames (cdr (assq 'pop-up-frames new-settings))))
          ;; Execute the body
          (apply body))
      ;; Restore original settings
      (setq display-buffer-alist original-display-buffer-alist
            switch-to-buffer-obey-display-actions
            original-switch-to-buffer-obey-display-actions
            pop-up-windows original-pop-up-windows
            pop-up-frames original-pop-up-frames))))


(defun my-window-tools/set-ide-category (tag)
  "Set the 'window-category parameter of the current window to TAG.
TAG must be one of the symbols defined in the :IDE entry of
`my-window-tools/category-map'."
  (interactive
   (let* ((ide-entry (assoc :IDE my-window-tools/category-map))
          (ide-symbols (cdr ide-entry))
          (chosen (completing-read "Choose IDE category tag: "
                                   ide-symbols nil t)))
     (list (intern chosen))))
  (set-window-parameter (selected-window) 'window-category tag)
  (my-window-tools/rebuild-category-index)
  (message "Window category set to %s" tag)
  (log/debug-window-management :fn 'my-window-tools/set-ide-category
                               :msg "Set active window tag. "
                               :obj (list :tag tag)))

;;;; Ediff
;;   -----

(with-eval-after-load 'ediff
  (defun my-window-tools/ediff-setup-windows-advice (orig-fun &rest args)
    "Let Ediff manage its windows cleanly inside IDE frames."
    (let ((use-custom (frame-parameter nil 'custom-window-management)))
      (if (or (not use-custom)
              (bound-and-true-p my-window-tools/in-ediff-session))
          (apply orig-fun args)
        (let ((my-window-tools/in-ediff-session t)
              (display-buffer-alist nil)
              (switch-to-buffer-obey-display-actions nil))
          (apply orig-fun args)
          (run-with-timer 0.2 nil #'my-window-tools/retag-on-config-change)))))

  (advice-add 'ediff-setup-windows-plain
              :around #'my-window-tools/ediff-setup-windows-advice)
  (advice-add 'ediff-setup-windows-multi
              :around #'my-window-tools/ediff-setup-windows-advice))

(log/debug :fn 'system-window-display
           :msg "Finishing load of the system-window-display module."
           :obj t)

(provide 'system-window-display)
;;; system-window-display.el ends here
