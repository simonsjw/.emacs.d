;;; system-window-management.el --- Window management for multi-project IDE -*- mode: emacs-lisp; lexical-binding: t; -*-

;;; License
;; Copyright (C) 2022
;; SPDX-License-Identifier: MIT

;; Author: Simon Watson

;;; Commentary:
;; This script provides a mechanism for managing windows in Emacs, supporting
;; multiple window collections each in different frames.
;;
;; Principle 1:
;; Collections are mapped using relationships between tags in objects defined
;; here and then tagged Frames and Windows are used to capture buffers which
;; are mapped to tags using either buffer name, a regexp using the name or the
;; buffer mode.  Also important is the frame and window active when the mapping
;; event occurs.
;;
;; Principle 2:
;; Buffers are not tagged.  In Emacs, buffers run free.  This framework
;; explicitly does not interfere with buffers themselves.  It only impacts
;; where they are shown.
;;
;; Principle 3:
;; If the window or frame isn't tagged and a buffer
;; being processed isn't impacted by the maps, then Emacs should behave exactly
;; as it would was this functionality not present.
;;
;; Principle 4:
;; IDE panes other than `edit' may be closed.  Buffers that would have been
;; shown in a missing pane follow `my-window-tools/category-fallback' and are
;; only sent to `edit' when no alternative pane is open.  The edit pane cannot
;; be closed.
;;

(require 'cl-lib)
(require 'path-support)
(require 'logging-config)
(log/debug :fn 'system-window-management
           :msg "Starting load of the system-window-management module."
           :obj t)



(require 'ui-config)

;;; Code:


(defvar switch-to-buffer-obey-display-actions t
  "Use custom window management if t.")

(defvar my-buffer-tools/category-map
  '(
    (:whitelist-names . ("*Speedbar*"
                         " SPEEDBAR"
                         "*SPEEDBAR*"
                         "*SR-SPEEDBAR*"
                         "*Ilist*"
                         "*Dictionary*"
                         "*Completions*"                                          ; Completion dropdowns
                         "*Echo Area 0*"                                          ; Minibuffer echo areas
                         "*Echo Area 1*"                                          ; Minibuffer echo areas
                         "*Minibuf-0*"                                            ; Minibuffer internals
                         "*Minibuf-1*"
                         "*LV*"                                                   ; Temporary overlay buffers (e.g., from Hydra or similar)
                         "*company-documentation*"                                ; Company mode popups
                         "*corfu-popup*"                                          ; Corfu completion overlays
                         "*posframe-buffer*"                                      ; Posframe child frame buffers
                         "*Ediff Control Panel*"
                         ))
    (:whitelist-regexps . ("^\\*temp.*"                                           ; Temporary buffers starting with *temp
                           "^\\*ivy-.*"                                           ; Ivy/Counsel dropdowns
                           "^\\*helm.*"                                           ; Helm completion lists
                           "^\\*vertico.*"                                        ; Vertico minibuffer extensions
                           "^\\*transient.*"                                      ; Transient (Magit-like) popups
                           "^\\*Embark.*"                                         ; Embark action menus
                           "^\\*Ediff.*"                                          ; Ediff windows
                           "^\\*?\\(ediff\\|Ediff\\|dired-diff\\|vc-diff\\|smerge\\)"
                           ".*\\(ediff\\|diff\\|smerge\\).*"
                           ))
    (:names . (("WINDOW_EDIT" . edit)
               ("WINDOW_DATA" . data)
               ("WINDOW_CONFIG" . data)
               ("WINDOW_TERMINAL" .terminal)
               ("WINDOW_VC" . vc)
               ("WINDOW_LOGS" . logs)
               ("spreadsheet-support.el" . edit)
               ("flymake-config.el" . edit)
               ("*dape-memory*" . data)                                           ; Add missing (memory viewer)
               ("Checkdoc Status" . data)
               ("SQL Results" . data)
               ("Backtrace" . data)
               ("*grep*" . data)
               ("xref" . data)
               ("xAI Chat" . data)
               ("Org Agenda" . data)
               ("docker-images" . data)
               ("docker-contexts" . data)
               ("docker-networks" . data)
               ("docker-containers" . data)
               ("docker-volumes" . data)
               ("spreadsheet.ses" . data)
               ("spreadsheet.ses<simon>" . data)
               ("Emacs" . edit)
               ("vc-support.el" . edit)
               ("config.el" . edit)
               ("early-config.el" . edit)
               (".bashrc" . edit)
               (".bash_history" . edit)
               (".bashrc_profile" . edit)
               (".LESS_TERMCAP" . edit)
               (".profile" . edit)
               (".zshrc" . edit)
               ("*dape-connection events*" . logs)
               ("*Messages*" . logs)
               ("*Warnings*" . logs)
               ("blacken-error" . logs)
               ("straight-process" . logs)
               ("ruff-format errors" . logs)
               ("straight-byte-compilation" . logs)
               ("projectile-files-errors" . logs)
               ("Async-native-compile-log" . logs)
               ("elisp-flymake-byte-compile" . logs)
               ("log-edit-files" . vc)
               ("*log-edit-files*" . vc)
               ("Org Babel Results" . logs)
               ("vc" . logs)
               ("*Load-History*" . logs)
               ("RE-Builder" . config)
               ("Anaconda" . config)
               ("conf.org" . config)
               ("todos.org" . config)
               ("gracie.org" . config)
               ("evie.org" . config)
               ("*eldoc*" . config)
               ("*pydoc*" . config)
               ("EGLOT workspace configuration" . config)
               ("Help" . config)
               ("info" . config)
               ("Ediff Config" . config)
               ("Ilist" . config)
               ("*Projects View*" . config)
               ("*dape-repl*" . config)
               (".gitignore" . vc)
               ("*vc*" . vc)
               ("*vc-dir*" . vc)
               ("*vc-log*" . vc)
               ("*vc-log-edit*" . vc)
               ("*vc-diff*" . vc)
               ("*log-edit-files*" . vc)
               ("*vc-change-log*" . vc)
               ("*VC-log*" . vc)
               ("*VC-change-log*" . vc)
               ("*Flymake log*" . vc)
               ("*dape-shell*" . terminal)
               ("*scratch*" . terminal)
               ("*MATLAB*" . terminal)
               ))                                                                 ; Note: If conflicting with above, choose one
    (:regexps . (("^documentation$" . config)                                     ; Exact match for "documentation"
                 ("^README.*" . config)                                           ; Starting with "README" + any chars
                 (".*\\.conf$" . config)                                          ; Any chars + literal ".conf" at end
                 (".*\\.dconf$" . config)                                         ; Any chars + literal ".dconf" at end
                 ("^\\*Customize.*" . config)                                     ; Starting with literal "*Customize" + any chars
                 ("^\\*Ibuffer.*" . config)                                       ; Starting with literal "*Ibuffer" + any chars
                 (".*_types.py" . config)                                         ; Any chars + "_types.py"
                 (".*\\.pdf$" . config)                                           ; Any chars + literal ".pdf" at end
                 ("^magit.*" . vc)                                                ; Starting with "magit" + any chars
                 ("^vc-.*" . vc)                                                  ; Starting with "vc-" + any chars
                 ("^\\*vc-.*" . vc)                                               ; Starting with "*vc-" + any chars
                 ("^\\*log-edit.*" . vc)                                          ; Containing log-edit (for vc mode)
                 ("^\\*VC-.*" . vc)                                               ; Containing *VC- (for vc mode)
                 (".*Annotate .*" . vc)                                           ; Any chars + "Annotate " + any chars
                 (".*ede-proj.*" . vc)                                            ; Any chars + "ede-proj" + any chars
                 ("^\\*dape-info.*" . data)                                       ; Starting with *dape-info" + any chars
                 ("^\\*undo-tree.*" . data)                                       ; Starting with *undo-tree" + any chars
                 ("^\\*Flymake diagnostics.*" . data)                             ; Starting with literal "*Flymake diagnostics" + any chars
                 ("^flymake-.*" . data)                                           ; Starting with "flymake-" + any chars
                 (".*cell sheet.*" . data)                                        ; Any chars + "cell sheet" + any chars
                 (".*spreadsheet.*" . data)                                       ; Any chars + "spreadsheet" + any chars
                 ("*\\.bib" . data)                                               ; Any chars + literal ".bib" at end
                 ("^Ediff A\\:.*" . data)                                         ; Starting with "Ediff A:" + any chars (escaped :)
                 ("^Ediff B\\:.*" . data)                                         ; Starting with "Ediff B:" + any chars (escaped :)
                 ("^magit-process:.*" . logs)                                     ; Starting with "magit-process:" + any chars
                 ("^\\*EGLOT.*" . logs)                                           ; Starting with literal "*EGLOT" + any chars
                 (".*+sterr$" . logs)                                             ; Any chars + "+sterr" at end
                 (".*\\.log" . logs)                                              ; Any chars + literal ".log"
                 (".*-log.*" . logs)                                              ; Any chars + "-log" + any chars
                 (".*tramp.*" . logs)                                             ; Any chars + "tramp" + any chars
                 ("^\\*vc-git :.*" . logs)                                        ; Starting with literal "*vc-git :" + any chars
                 ("^\\*.*output\\*$" . logs)                                      ; starting with a star then any chars + "tramp" + ending with output* (latex compilation file)
                 ("^Vterm:" . terminal)                                           ; Starting with literal "Vterm:"
                 ("^\\*ielm" . terminal)                                          ; Starting with literal "*ielm"
                 ("^\\*Q PROC.*" . terminal)                                      ; Starting with literal "*Q PROC" + any chars
                 ("^\\*vterm.*" . terminal)                                       ; Starting with literal "*vterm" + any chars
                 ("^\\*eshell.*" . terminal)))                                    ; Starting with literal "*eshell" + any chars
    (:modes . ((vterm-mode . terminal)
               (eshell-mode . terminal)
               (shell-mode . terminal)
               (term-mode . terminal)
               (dired-mode . terminal)
               (ielm-mode . terminal)
               (inferior-python-mode . terminal)
               (flymake-diagnostics-buffer-mode . data)
               (calendar-mode . data)
               (diary-mode . data)
               (clojure-mode . edit)
               (lisp-mode . edit)
               (python-ts-mode . edit)
               (q-script-mode . edit)
               (rust-mode . edit)
               (scheme-mode . edit)
               (systemd-mode . config)
               (toml-ts-mode . config)
               (XML-mode . config)
               (nXML-mode . config)
               (json-mode . config)
               ;; (org-mode . config)  ; Commented as in original
               (csv-mode . config)
               (ibuffer-mode . config)
               (bufler-list-mode . config)
               (bookmark-menu . config)
               (imenu-list-mode . config)
               (help-mode . config)
               (helpful-mode . config)
               (log-view-mode . logs)
               (compilation-mode . logs)
               (debugger-mode . logs)
               (vc-dir . vc))))
  "Mapping of buffer properties to window categories.  Any name beginning with a space is white listed automatically.")


(defvar my-window-tools/category-map
  '((:IDE . (edit data config logs vc terminal))))

(defconst my-window-tools/category-fallback
  '((edit)
    (data logs vc config terminal edit)
    (config logs vc data terminal edit)
    (logs vc config data terminal edit)
    (vc logs config data terminal edit)
    (terminal logs vc config data edit))
  "Alist of CATEGORY -> ordered lookup chain.

The first element of each list is the home category.  `get-window-for-window-category'
tries each entry in order until an open, live window of that category exists
on the frame.  `edit' has no alternative: it cannot be redirected or closed.")

(defconst my-window-tools/default-occupants
  '((edit . "*Emacs*")
    (data . "xAI Chat")
    (config . "*Ibuffer*")
    (logs . "*Warnings*")
    (vc . "*vc-dir*")
    (terminal . "*scratch*"))
  "Default buffer names shown when a category pane is (re)created.")

(defconst my-window-tools/ide-category-weight
  '((edit . 0.639)
    (data . 0.500)
    (config . 0.500)
    (logs . 0.320)
    (vc . 0.344)
    (terminal . 0.336))
  "Relative weights used when splitting a neighbour to reopen a pane.")

(defconst my-window-tools/ide-category-layout
  '((data     . (:group right  :axis vertical   :order 0 :edit-side right :edit-frac 0.361))
    (config   . (:group right  :axis vertical   :order 1 :edit-side right :edit-frac 0.361))
    (logs     . (:group bottom :axis horizontal :order 0 :edit-side below :edit-frac 0.237))
    (vc       . (:group bottom :axis horizontal :order 1 :edit-side below :edit-frac 0.237))
    (terminal . (:group bottom :axis horizontal :order 2 :edit-side below :edit-frac 0.237)))
  "Canonical combination metadata used to place a reopened category window.")

(defvar my-window-tools--inhibit-retag nil
  "Non-nil suppresses `my-window-tools/retag-on-config-change'.")

(defvar my-window-tools--in-toggle nil
  "Non-nil while a pane toggle or category close is rewriting the layout.")

(defvar my-window-tools/in-ediff-session nil
  "Non-nil when inside an Ediff session (frame-local).")

(defvar my-window-tools/keep-buffers
  '("*emacs*" "*Emacs*" "*scratch*" "*Ibuffer*" "*SPEEDBAR*"
    "*Warnings*" "*vc-dir*" "*vc-dir<.emacs.d>*" "xAI Chat")
  "Do not delete these buffers when carrying out aggregate buffer deletes.
Each element must be a string that exactly matches a `buffer-name'.")

;; ----------------------------------------------------------------------
;;; Helpers
;; ----------------------------------------------------------------------

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
  "Retrieve a window on FRAME for TARGET-WINDOW-CATEGORY.

Tries the home category first, then each alternative listed in
`my-window-tools/category-fallback', skipping categories that are marked
closed or whose cached window is dead.  Rebuilds the frame index once if
it is missing.

TARGET-WINDOW-CATEGORY is the symbol (e.g., `edit', `logs') to search for.
FRAME is the frame to search within (defaults to selected if nil).

Returns a live window object, or nil if no open pane on the chain exists
(the caller may pop up a new window)."
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


;; ----------------------------------------------------------------------------
;;; Pane toggle, bury, and reallocation
;; ----------------------------------------------------------------------------

(defun my-window-tools--placeholder-buffer-p (buffer)
  "Return non-nil if BUFFER is a WINDOW_* placeholder."
  (and (bufferp buffer)
       (buffer-live-p buffer)
       (string-prefix-p "WINDOW_" (buffer-name buffer))))

(defun my-window-tools--last-buffer (category frame)
  "Return the last recorded occupant of CATEGORY on FRAME, if live."
  (let ((buf (cdr (assq category (frame-parameter frame 'ide-last-buffers)))))
    (and (buffer-live-p buf) buf)))

(defun my-window-tools--set-last-buffer (category frame buffer)
  "Record BUFFER as the last occupant of CATEGORY on FRAME."
  (when (and category (buffer-live-p buffer))
    (let ((alist (assq-delete-all
                  category
                  (copy-sequence (frame-parameter frame 'ide-last-buffers)))))
      (set-frame-parameter frame 'ide-last-buffers
                           (cons (cons category buffer) alist)))))

(defun my-window-tools--buffer-named (name)
  "Return a live buffer called NAME, allowing a uniquify suffix.

`*vc-dir*' is often renamed to `*vc-dir*<project>' so an exact
`get-buffer' miss would skip restoring the vc pane after a commit."
  (or (get-buffer name)
      (cl-loop with prefix = (regexp-quote name)
               for buf in (buffer-list)
               when (string-match-p (concat "\\`" prefix "\\(<[^>]*>\\)?\\'")
                                    (buffer-name buf))
               return buf)))

(defun my-window-tools--default-occupant (category)
  "Return the live default occupant buffer for CATEGORY, or nil."
  (let ((name (cdr (assq category my-window-tools/default-occupants))))
    (and name (my-window-tools--buffer-named name))))

(defun my-window-tools--window-history-buffers (window)
  "Return live buffers stored in WINDOW including its current buffer."
  (let ((bufs (and (window-live-p window)
                   (list (window-buffer window)))))
    (when window
      (dolist (entry (append (window-prev-buffers window)
                             (window-next-buffers window)))
        (when (and (consp entry) (buffer-live-p (car entry)))
          (cl-pushnew (car entry) bufs :test #'eq))))
    bufs))

(defun my-window-tools--frame-candidate-buffers (frame)
  "Buffers that belong to FRAME for reallocation purposes.
Union of each window's current buffer and its prev/next histories, plus
any recorded last-occupants.  Never walks the global buffer list."
  (let ((bufs '()))
    (dolist (win (window-list frame 'no-minibuffer))
      (setq bufs (append (my-window-tools--window-history-buffers win) bufs)))
    (dolist (cell (frame-parameter frame 'ide-last-buffers))
      (when (buffer-live-p (cdr cell))
        (push (cdr cell) bufs)))
    (cl-delete-duplicates bufs :test #'eq)))

(defun my-window-tools--history-entry (buffer)
  "Return a `window-prev-buffers' entry for BUFFER.

Emacs requires WINDOW-START and POS to be markers.  Integer positions
(used in an earlier revision) make `push-window-buffer-onto-prev'
signal `wrong-type-argument markerp'."
  (when (buffer-live-p buffer)
    (with-current-buffer buffer
      (list buffer
            (copy-marker (point-min) t)
            (copy-marker (point))))))

(defun my-window-tools--sanitize-history-list (entries)
  "Rewrite ENTRIES so every start/point value is a live marker."
  (let ((out '()))
    (dolist (entry entries)
      (let ((buf (car-safe entry))
            (start (nth 1 entry))
            (pos (nth 2 entry)))
        (when (buffer-live-p buf)
          (push (if (and (markerp start) (markerp pos)
                         (eq (marker-buffer start) buf)
                         (eq (marker-buffer pos) buf))
                    entry
                  (my-window-tools--history-entry buf))
                out))))
    (nreverse out)))

(defun my-window-tools--sanitize-window-history (window)
  "Repair WINDOW's prev/next histories so they only contain marker entries."
  (when (window-live-p window)
    (set-window-prev-buffers
     window (my-window-tools--sanitize-history-list (window-prev-buffers window)))
    (set-window-next-buffers
     window (my-window-tools--sanitize-history-list (window-next-buffers window)))))

(defun my-window-tools--sanitize-frame-histories (frame)
  "Repair prev/next histories on every window of FRAME."
  (dolist (win (window-list frame 'no-minibuffer))
    (my-window-tools--sanitize-window-history win)))

(defun my-window-tools--bury-buffers-on (window buffers)
  "Append BUFFERS to WINDOW's previous-buffer list without changing the visible buffer.

Buffers that are WINDOW's current buffer, already present in its history,
or no longer live are skipped.  Each new history entry uses markers, as
required by `push-window-buffer-onto-prev'."
  (when (window-live-p window)
    (my-window-tools--sanitize-window-history window)
    (let* ((current (window-buffer window))
           (prev (window-prev-buffers window))
           (known (cons current (mapcar #'car prev))))
      (dolist (buf buffers)
        (when (and (buffer-live-p buf)
                   (not (memq buf known)))
          (let ((entry (my-window-tools--history-entry buf)))
            (when entry
              (setq prev (cons entry prev)
                    known (cons buf known))))))
      (set-window-prev-buffers window prev))))

(defun my-window-tools--mark-category-closed (category frame)
  "Add CATEGORY to FRAME's closed set.  `edit' is never recorded."
  (unless (eq category 'edit)
    (let ((closed (copy-sequence
                   (frame-parameter frame 'ide-closed-categories))))
      (cl-pushnew category closed)
      (set-frame-parameter frame 'ide-closed-categories closed))))

(defun my-window-tools--mark-category-open (category frame)
  "Remove CATEGORY from FRAME's closed set."
  (set-frame-parameter
   frame 'ide-closed-categories
   (delq category (copy-sequence
                   (frame-parameter frame 'ide-closed-categories)))))

(defun my-window-tools/sync-closed-set-from-windows (&optional frame)
  "Rebuild FRAME's closed set from the categories actually present.

Used after `winner-undo' / `winner-redo' so menu checks stay honest.
`edit' is never marked closed."
  (let ((frame (or frame (selected-frame))))
    (when (eq (frame-parameter frame 'UI-TYPE) 'IDE)
      (let* ((present (mapcar #'car (my-window-tools/rebuild-category-index frame)))
             (closed (cl-remove-if
                      (lambda (cat)
                        (or (eq cat 'edit) (memq cat present)))
                      (my-window-tools/ide-categories))))
        (set-frame-parameter frame 'ide-closed-categories closed)
        (force-mode-line-update t)
        closed))))

(defun my-window-tools--windows-of-category (category frame)
  "Return live windows on FRAME tagged CATEGORY."
  (cl-loop for win in (window-list frame 'no-minibuffer)
           when (eq category (window-parameter win 'window-category))
           collect win))

(defun my-window-tools--fallback-destination (category frame)
  "Window that should receive buffers when CATEGORY is closed on FRAME."
  (cl-loop for cat in (my-window-tools--fallback-chain category t)
           for win = (my-window-tools--index-window cat frame)
           when (and win
                     (not (memq cat (frame-parameter frame
                                                     'ide-closed-categories))))
           return win))

(defun my-window-tools--pick-buffer-for-category (category frame)
  "Choose a buffer to show when CATEGORY is reopened on FRAME."
  (or (my-window-tools--last-buffer category frame)
      (cl-loop for buf in (my-window-tools--frame-candidate-buffers frame)
               when (eq category
                        (with-selected-frame frame
                          (my-window-tools/determine-buffer-category buf)))
               return buf)
      (my-window-tools--default-occupant category)
      (get-buffer-create
       (format "WINDOW_%s" (upcase (symbol-name category))))))

(defun my-window-tools--step-window-back (window)
  "Show WINDOW's previous history buffer, or its category default."
  (when (window-live-p window)
    (let* ((prev (window-prev-buffers window))
           (next-buf (cl-loop for entry in prev
                              for buf = (car entry)
                              when (and (buffer-live-p buf)
                                        (not (eq buf (window-buffer window))))
                              return buf))
           (cat (window-parameter window 'window-category)))
      (cond
       (next-buf
        (set-window-buffer window next-buf))
       ((and cat (my-window-tools--default-occupant cat))
        (set-window-buffer window (my-window-tools--default-occupant cat)))))))

(defun my-window-tools--split-from-edit (category frame)
  "Create a window for CATEGORY by splitting the edit pane on FRAME."
  (let* ((edit (or (my-window-tools--index-window 'edit frame)
                   (frame-root-window frame)))
         (meta (cdr (assq category my-window-tools/ide-category-layout)))
         (side (or (plist-get meta :edit-side) 'below))
         (frac (or (plist-get meta :edit-frac) 0.3))
         (vertical (memq side '(above below)))
         (total (if vertical (window-total-height edit) (window-total-width edit)))
         (new-size (max 4 (round (* total frac)))))
    (split-window edit (- new-size) side)))

(defun my-window-tools--split-from-neighbour (category neighbour side)
  "Split NEIGHBOUR on SIDE to create a window for CATEGORY."
  (let* ((ncat (window-parameter neighbour 'window-category))
         (w-c (or (cdr (assq category my-window-tools/ide-category-weight)) 1.0))
         (w-n (or (cdr (assq ncat my-window-tools/ide-category-weight)) 1.0))
         (vertical (memq side '(above below)))
         (total (if vertical
                    (window-total-height neighbour)
                  (window-total-width neighbour)))
         (new-size (max 4 (round (* total (/ w-c (+ w-c w-n)))))))
    (split-window neighbour (- new-size) side)))

(defun my-window-tools--insertion-neighbour (category frame)
  "Return (WINDOW . SIDE) for inserting CATEGORY into its combination.

Chooses the adjacent open sibling in canonical order so a reopened
terminal lands to the right of vc (logs | vc | terminal), not between
logs and vc."
  (let* ((meta (cdr (assq category my-window-tools/ide-category-layout)))
         (group (plist-get meta :group))
         (order (or (plist-get meta :order) 0))
         (axis (plist-get meta :axis))
         (left nil)
         (right nil))
    (dolist (cell my-window-tools/ide-category-layout)
      (let* ((cat (car cell))
             (spec (cdr cell))
             (win (and (not (eq cat category))
                       (eq group (plist-get spec :group))
                       (my-window-tools--index-window cat frame))))
        (when (window-live-p win)
          (let ((s-order (or (plist-get spec :order) 0)))
            (cond
             ((< s-order order)
              (when (or (null left)
                        (> s-order (plist-get left :order)))
                (setq left (list :order s-order :win win))))
             ((> s-order order)
              (when (or (null right)
                        (< s-order (plist-get right :order)))
                (setq right (list :order s-order :win win)))))))))
    (cond
     (left
      (cons (plist-get left :win)
            (if (eq axis 'vertical) 'below 'right)))
     (right
      (cons (plist-get right :win)
            (if (eq axis 'vertical) 'above 'left)))
     (t nil))))

(defun my-window-tools--place-window (category frame)
  "Create and tag a window for CATEGORY on FRAME.  Return the new window."
  (let* ((insert (my-window-tools--insertion-neighbour category frame))
         (new
          (condition-case err
              (if insert
                  (my-window-tools--split-from-neighbour
                   category (car insert) (cdr insert))
                (my-window-tools--split-from-edit category frame))
            (error
             (log/debug-window-management
              :fn 'my-window-tools--place-window
              :msg "Neighbour split failed, falling back to edit"
              :obj err)
             (my-window-tools--split-from-edit category frame)))))
    (when (window-live-p new)
      (set-window-parameter new 'window-category category)
      (set-window-parameter new 'quit-restore nil)
      (set-window-dedicated-p new nil))
    new))

(defun my-window-tools/reallocate-frame (&optional frame)
  "Bury frame-local buffers onto the highest-priority open pane that owns them.

Only buffers already associated with FRAME (visible or in window histories)
are considered.  Visible buffers are left in place; this pass only attaches
them to the correct pane's history.  Reclaim of a visible buffer when its
home pane reopens is handled by `my-window-tools--open-category'."
  (interactive)
  (let ((frame (or frame (selected-frame))))
    (unless (eq (frame-parameter frame 'UI-TYPE) 'IDE)
      (user-error "Not an IDE frame"))
    (my-window-tools/rebuild-category-index frame)
    (my-window-tools--sanitize-frame-histories frame)
    (let ((seen (make-hash-table :test #'eq)))
      (with-selected-frame frame
        (dolist (buf (my-window-tools--frame-candidate-buffers frame))
          (when (and (buffer-live-p buf)
                     (not (gethash buf seen)))
            (puthash buf t seen)
            (let* ((cat (my-window-tools/determine-buffer-category buf))
                   (target (and cat
                                (my-window-tools/get-window-for-window-category
                                 cat frame))))
              (when (and target
                         (not (eq (window-buffer target) buf)))
                (my-window-tools--bury-buffers-on target (list buf))))))))))

(defun my-window-tools--collapse-extra-category-windows (category frame)
  "Delete surplus windows tagged CATEGORY on FRAME, keeping one pane.

`log-edit-show-files' splits the vc pane to list the files in the
commit.  After C-c C-c both windows are preserved and both show
`*vc-dir*'.  This helper folds them back to the spatially first
window of that category.

Returns the surviving window, or nil."
  (let ((windows (my-window-tools--windows-of-category category frame)))
    (cond
     ((null windows) nil)
     ((null (cdr windows)) (car windows))
     (t
      (let ((my-window-tools--in-toggle t)
            (my-window-tools--inhibit-retag t)
            (keep (cl-find-if (lambda (w) (memq w windows))
                              (my-window-tools/sorted-window-list frame))))
        (dolist (win windows)
          (when (and (window-live-p win) (not (eq win keep)))
            (set-window-dedicated-p win nil)
            (ignore-errors (delete-window win))))
        (my-window-tools/rebuild-category-index frame)
        keep)))))

(defun my-window-tools--close-category (category frame)
  "Close every CATEGORY window on FRAME and bury its buffers on a fallback.

`edit' is refused.  Returns the destination window, or nil."
  (if (eq category 'edit)
      (progn
        (message "The edit window cannot be closed")
        nil)
    (let ((my-window-tools--in-toggle t)
          (my-window-tools--inhibit-retag t))
      (my-window-tools/rebuild-category-index frame)
      (let* ((windows (my-window-tools--windows-of-category category frame))
             (dest (or (my-window-tools--fallback-destination category frame)
                       (my-window-tools--index-window 'edit frame)))
             (collected '()))
        (dolist (win windows)
          (my-window-tools--set-last-buffer category frame (window-buffer win))
          (setq collected
                (append (my-window-tools--window-history-buffers win) collected))
          (set-window-dedicated-p win nil))
        (when (and dest (window-live-p dest))
          (my-window-tools--bury-buffers-on dest collected)
          (when (or (my-window-tools--placeholder-buffer-p (window-buffer dest))
                    (not (window-buffer dest)))
            (let ((show (or (my-window-tools--last-buffer category frame)
                            (car collected))))
              (when (buffer-live-p show)
                (set-window-buffer dest show)))))
        (dolist (win windows)
          (when (and (window-live-p win)
                     (not (eq win dest)))
            (ignore-errors (delete-window win))))
        (my-window-tools--mark-category-closed category frame)
        (my-window-tools/rebuild-category-index frame)
        (my-window-tools/reallocate-frame frame)
        (force-mode-line-update t)
        dest))))

(defun my-window-tools--open-category (category frame)
  "Reopen CATEGORY on FRAME, restore an occupant, and reclaim matching buffers."
  (if (my-window-tools/window-open-p category frame)
      (let ((existing (my-window-tools--index-window category frame)))
        (when (window-live-p existing)
          (select-window existing))
        existing)
    (let ((my-window-tools--in-toggle t)
          (my-window-tools--inhibit-retag t))
      (my-window-tools--mark-category-open category frame)
      (my-window-tools/rebuild-category-index frame)
      (let ((new (my-window-tools--place-window category frame)))
        (unless (window-live-p new)
          (user-error "Unable to reopen the %s window" category))
        (let ((pick (my-window-tools--pick-buffer-for-category category frame)))
          (when (buffer-live-p pick)
            (dolist (win (window-list frame 'no-minibuffer))
              (when (and (not (eq win new))
                         (eq (window-buffer win) pick))
                (my-window-tools--step-window-back win)))
            (set-window-buffer new pick)
            (my-window-tools--set-last-buffer category frame pick)))
        (set-window-parameter new 'window-category category)
        (my-window-tools/rebuild-category-index frame)
        (my-window-tools/reallocate-frame frame)
        (force-mode-line-update t)
        new))))

(defun my-window-tools/toggle (window-name &optional frame)
  "Toggle the IDE pane named WINDOW-NAME on FRAME.

WINDOW-NAME is a symbol or string matching an entry in the :IDE list of
`my-window-tools/category-map' (`edit', `data', `config', `logs', `vc',
`terminal').  FRAME defaults to the selected frame.

The edit pane cannot be closed; toggling it is a documented no-op.
On a non-IDE frame, or during Ediff, signal `user-error'.

After a successful close or open, buffers already associated with the
frame are reallocated according to category tags and
`my-window-tools/category-fallback'."
  (interactive
   (list (intern (completing-read
                  "Toggle IDE pane: "
                  (mapcar #'symbol-name (my-window-tools/ide-categories))
                  nil t))))
  (let* ((frame (or frame (selected-frame)))
         (category (my-window-tools--normalize-category window-name)))
    (unless (eq (frame-parameter frame 'UI-TYPE) 'IDE)
      (user-error "Pane toggle is only available in an IDE frame"))
    (when (my-window-tools--in-ediff-p)
      (user-error "Pane toggle is disabled during Ediff"))
    (unless category
      (user-error "Unknown IDE pane: %s" window-name))
    (cond
     ((eq category 'edit)
      (message "The edit window cannot be closed")
      (my-window-tools--index-window 'edit frame))
     ((my-window-tools/window-open-p category frame)
      (my-window-tools--close-category category frame)
      (message "Closed the %s pane" category))
     (t
      (my-window-tools--open-category category frame)
      (message "Opened the %s pane" category)))))

(defun my-window-tools/toggle-edit ()
  "No-op toggle for the immortal edit pane."
  (interactive)
  (my-window-tools/toggle 'edit))

(defun my-window-tools/toggle-data ()
  "Toggle the data pane in the current IDE frame."
  (interactive)
  (my-window-tools/toggle 'data))

(defun my-window-tools/toggle-config ()
  "Toggle the config pane in the current IDE frame."
  (interactive)
  (my-window-tools/toggle 'config))

(defun my-window-tools/toggle-logs ()
  "Toggle the logs pane in the current IDE frame."
  (interactive)
  (my-window-tools/toggle 'logs))

(defun my-window-tools/toggle-vc ()
  "Toggle the vc pane in the current IDE frame."
  (interactive)
  (my-window-tools/toggle 'vc))

(defun my-window-tools/toggle-terminal ()
  "Toggle the terminal pane in the current IDE frame."
  (interactive)
  (my-window-tools/toggle 'terminal))

;; ----------------------------------------------------------------------------
;; END OF Buffer assignment to windows
;; ############################################################################


(defun my-window-tools/find-frame-by-project-root (project-root-of-frame)
  "Find the frame associated with the given PROJECT-ROOT-OF-FRAME.
PROJECT-ROOT-OF-FRAME is the root directory of the project to find the
frame for."
  (catch 'found
    (dolist (frame (frame-list))
      (when (string=
             (my-window-tools/frame-project-root frame) project-root-of-frame)
        (throw 'found frame)))))


(defun my-window-tools/frame-project-root (frame)
  "Get the project root associated with FRAME."
  (frame-parameter frame 'project-root))

(defun my-window-tools/set-frame-project-root (frame project-root)
  "Set the project root for FRAME to PROJECT-ROOT.

This parameter is used to identify the frame corresponding to a particular
project."
  (set-frame-parameter frame 'project-root project-root)
  (set-frame-parameter frame 'custom-window-management t))                        ; Mark as using custom management

(defun my-window-tools/get-tag-given-window ()
  "Get the tag corresponding to the current window.

Utility function shows the tag associated with the current selected window."
  (interactive)
  (let ((window-tag (window-parameter (selected-window) 'tag)))
    (message "tag: %s" window-tag)
    window-tag))

(defvar my-window-tools/window-state nil
  "Saved window state including custom properties.")

(defun my-window-tools/save-window-state-with-properties ()
  "Save the current window state along with custom properties."
  (interactive)
  (setq
   my-window-tools/window-state
   (list
    :state (window-state-get nil t)
    :properties (mapcar (lambda (win)
                          (list :window (window-parameter win 'window-id)
                                :name (buffer-name (window-buffer win))))
                        (window-list))))
  (log/debug-window-management :fn 'my-window-tools/save-window-state-with-properties
                          :msg "Window state with properties saved."
                          :obj t))


(defun my-window-tools/mouse-delete-window-confirmation (click)
  "Ask for confirmation before deleting the window from a CLICK  mouse event."

  (interactive (list last-nonmenu-event))
  (mouse-minibuffer-check click)
  (let ((window (posn-window (event-start click))))
    (when (and (windowp window)                                                   ; Checks if the target is a window.
               (y-or-n-p "Are you sure you want to delete this window?"))
      (delete-window window))))

;; set up the delete window confirmation. -- this is for >= Emacs 30.
(global-set-key [mode-line mouse-3]
                #'my-window-tools/mouse-delete-window-confirmation)


(defun my-window-tools/review-frame-tags (&optional frame)
  "Review window tags (parameters) in FRAME, defaulting to selected.
Display in a buffer for inspection, focusing on 'window-category'.

Purpose: Diagnose tag persistence in IDE setups.
Variables:
- FRAME: Target frame (symbol or object); defaults to selected.                   ;
Output: Displays buffer with table of windows and tags.
Flow:
1. Select frame.
2. Collect sorted windows.
3. Build tag data.
4. Display in table."
  (interactive)
  (let* ((frame (or frame (selected-frame)))                                      ; Default to current
         (windows (my-window-tools/sorted-window-list frame))                     ; Reuse your sorter
         (buf-name "*Window Tags Review*")
         (buf (get-buffer-create buf-name)))
    (with-current-buffer buf
      (erase-buffer)
      (insert "| Window | Category | Other Params |\n|--------|----------|--------------|\n")
      (dolist (win windows)
        (let ((cat (window-parameter win 'window-category))
              (others (remove (assq 'window-category (window-parameters win))
                              (window-parameters win))))
          (insert (format "| %s | %s | %s |\n" win cat others))))
      (markdown-mode)                                                             ; For table rendering
      (goto-char (point-min)))
    (display-buffer buf '(display-buffer-in-side-window . ((side . right))))))


(defun my-window-tools/list-window-names ()
  "List all windows and their names."
  (interactive)
  (let ((output-buffer (get-buffer-create "*Window Names*")))                     ; Create or get the buffer
    (with-current-buffer output-buffer
      (erase-buffer)                                                              ; Clear the previous contents
      (insert "List of all window names:\n\n"))
    (walk-windows
     (lambda (w)
       (let ((name (window-parameter w 'name)))
         (with-current-buffer output-buffer
           (insert (format "Window: %s, name: %s\n" w
                           (or name "unnamed"))))))
     nil 'visible)
    (display-buffer output-buffer)))

(defun my-window-tools/find-window-by-name (name)
  "Find the window with the `Name' parameter equal to NAME."
  (let ((found-window nil))
    (walk-windows
     (lambda (window)
       (when (equal (window-parameter window 'name) name)
         (setq found-window window)))
     nil t)
    found-window))

(defun my-window-tools/list-window-tags (window)
  "List all parameters for the given WINDOW."
  (let ((params (window-parameters window)))
    (mapcar (lambda (param)
              (message "Parameter: %s, Value: %s" (car param) (cdr param)))
            params)))

(defun my-window-tools/select-window-by-name (name)
  "Select the window with a custom `name' parameter matching NAME."
  (let ((target-window (my-window-tools/find-window-by-name name)))
    (when target-window
      (select-window target-window))))



;; BACKTRACE AND MESSAGES HANDLED BY WINDOW MANAGEMENT FUNCTIONS NOW.
;; THESE ARE KEPT TO SHOW HOW DISPLAY-BUFFER-ALIST CAN BE USED.

;; (add-to-list 'display-buffer-alist
;;              '("^\\*Messages\\*"
;;                (display-buffer-reuse-window
;;                 display-buffer-pop-up-window)
;;                (inhibit-same-window . t)
;;                (window-height . 0.3)))

;; (add-to-list 'display-buffer-alist
;;              '("^\\*Backtrace\\*"
;;                (display-buffer-reuse-window
;;                 display-buffer-pop-up-window)
;;                (inhibit-same-window . t)
;;                (window-height . 0.3)))
;; ----------------------------------------------------------------------------

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
  "Process the DISPLAY-BUFFER ACTION and inject the CATEGORY if applicable.
Returns a new action structure or the original action if no change is needed.
ACTION is the original action (function list, alist, or special value like t).
CATEGORY is the buffer category to inject (e.g., `logs').

This function handles various forms of ACTION:
- Nil or t: Treated as no specific functions or alist.
- Symbol: If it is a function (e.g., `display-buffer-same-window'), wrap it as
  a single-function list.
- Cons: If car is a symbol/function, treat as (function . alist); if car is a     ;
  list, treat as (function-list . alist); if not, assume pure alist.              ;
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
  "Around advice for `split-window' (and transitively `split-window-below',
`split-window-right', and the `C-x 2' / `C-x 3' commands) that copies the
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
  "Keep an IDE category window from being treated as a temporary pop-up.

`display-buffer' records a `quit-restore' parameter after the display
action returns.  For log-edit / vc-log that parameter tells `quit-window'
to delete the window when C-c C-c finishes the commit, which then hit
`delete-window' advice and closed the whole vc pane.

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
  "Keep the IDE closed-set in sync when a tagged window is deleted.

Inside a toggle the work has already been done, so ORIG-FUN is called
unmodified.  Deleting the last `edit' window is refused.

An extra split of the same category (the usual leftover from
`log-edit-show-files') is deleted as a normal window: the category
stays open on the remaining pane.  Closing the *last* window of a
category is a real pane-close only when the user asked for it
(`delete-window', mode-line click, pane toggle).  Package teardown
such as `log-edit-done' on that last pane is not a pane-close: the
window is kept and the previous buffer (usually `*vc-dir*') is restored."
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
  "Mark every non-edit category closed when `delete-other-windows' runs in an IDE frame."
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

(defun my-window-tools/restore-vc-dir-after-checkin (&rest _)
  "After a VC check-in, keep a single vc pane showing `*vc-dir*'.

`log-edit-show-files' splits the vc pane.  C-c C-c then used to leave
both halves showing `*vc-dir*'.  Collapse those extras, put `*vc-dir*'
in the remaining pane, and clear `quit-restore' so a later quit cannot
delete it."
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
  "Run vc-pane cleanup after `log-edit-done' has finished tearing down buffers."
  (when (my-window-tools--in-ide-frame-p)
    (run-at-time 0 nil #'my-window-tools/restore-vc-dir-after-checkin)))

(add-hook 'vc-checkin-hook #'my-window-tools/restore-vc-dir-after-checkin)
(add-hook 'vc-checkin-hook #'vc-dir-refresh)
(advice-add 'log-edit-done :after #'my-window-tools/after-log-edit-done) 

(defun my-window-tools/with-temporary-display-buffer-settings (settings &rest body)
  "Execute BODY with temporary DISPLAY-BUFFER-ALIST settings.

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

;; ----------------------------------------------------------------------
;;; Ediff Support
;; ----------------------------------------------------------------------

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



(log/debug :fn 'system-window-management
           :msg "Finishing load of the system-window-management module."
           :obj t)
(provide 'system-window-management)

;;; system-window-management.el ends here


