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


(defvar sr-speedbar-window)                                                       ; variable defined in sr-speedbar - the current window of sr-speedbar.

(defvar my-window-tools/buffer-window-map)
(declare-function my-tab-line/tab-line-close-tab-given-buffer "tabline-support")
(declare-function sr-speedbar-exist-p "sr-speedbar")
(declare-function sr-speedbar-refresh-turn-off "sr-speedbar")
(declare-function sr-speedbar-close "sr-speedbar")

(declare-function log/debug "system-window-management")

(require 'ui-config)

;;; Code:

(defvar switch-to-buffer-obey-display-actions t
  "Use custom window management if t.")

(defvar my-buffer-tools/category-map
  '(
    (:whitelist-names . ("*Speedbar*"
                         "*SPEEDBAR*"
                         "*SR-SPEEDBAR*"
                         "*Completions*"                                          ; Completion dropdowns
                         "*Echo Area 0*"                                          ; Minibuffer echo areas
                         "*Echo Area 1*"                                          ; Minibuffer echo areas
                         "*Minibuf-0*"                                            ; Minibuffer internals
                         "*Minibuf-1*"
                         "*LV*"                                                   ; Temporary overlay buffers (e.g., from Hydra or similar)
                         "*company-documentation*"                                ; Company mode popups
                         "*corfu-popup*"                                          ; Corfu completion overlays
                         "*posframe-buffer*"                                      ; Posframe child frame buffers
                         ))
    (:whitelist-regexps . ("^\\*temp.*"                                           ; Temporary buffers starting with *temp
                           "^\\*ivy-.*"                                           ; Ivy/Counsel dropdowns
                           "^\\*helm.*"                                           ; Helm completion lists
                           "^\\*vertico.*"                                        ; Vertico minibuffer extensions
                           "^\\*transient.*"                                      ; Transient (Magit-like) popups
                           "^\\*Embark.*"                                         ; Embark action menus
                           ))
    (:names . (("spreadsheet-support.el" . edit)
               ("flymake-config.el" . edit)
               ("*dape-memory*" . data)                                           ; Add missing (memory viewer)
               ("Checkdoc Status" . data)
               ("SQL Results" . data)
               ("Backtrace" . data)
               ("grep" . data)
               ("xref" . data)
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
                 ("^\\*dape-info.*" . data)  ; Starting with *dape-info" + any chars
                 ("^\\*undo-tree.*" data)                                         ; Starting with *undo-tree" + any chars
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
               (compilation-mode . logs)
               (debugger-mode . logs)
               (vc-dir . vc))))
  "Mapping of buffer properties to window categories.  Any name beginning with a space is white listed automatically.")


;; temp as we move to frame specific assignment.
(setq my-window-tools/frame-map
      `((:IDE . ,my-buffer-tools/category-map)))

(setq my-window-tools/category-map
      `((:IDE . ,(list 'edit 'data 'config 'logs 'vc 'terminal))))

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
Flow: Check IDE frame, get sorted windows, tag by list."
  (when (eq (frame-parameter nil 'UI-TYPE) 'IDE)                                  ; Limit to IDE
    (let ((frame (selected-frame))
          (tag-list '(edit data config logs vc terminal)))
      (my-window-tools/tag-windows-by-list frame tag-list t)
      (log/debug :fn 'my-window-tools/retag-on-config-change
                 :msg "Re-tagged on config change"
                 :obj frame))))

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

Edge cases:
- Empty TAG-LIST: No tags applied; logs but no errors.
- More windows than tags: Cycles (e.g., 7th gets first tag).
- Untaggable: Skipped, preserving nil category."
  (let ((windows (my-window-tools/sorted-window-list frame))  ; Sorted list
        (tag-count (length tag-list))
        (tag-index 0))
    (dolist (window windows)
      (if (my-window-tools/is-untaggable-window window)
          (log/debug :fn 'my-window-tools/tag-windows-by-list
                     :msg "Skipped untaggable window"
                     :obj (list :window window :buffer (buffer-name (window-buffer window))))
        (let ((tag (nth (mod tag-index tag-count) tag-list)))
          (set-window-parameter window 'window-category tag)
          (when set-quit-restore
            (set-window-parameter window 'quit-restore nil))
          (log/debug :fn 'my-window-tools/tag-windows-by-list
                     :msg "Tagged window"
                     :obj (list :window window :tag tag))
          (setq tag-index (1+ tag-index)))))))

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

(defun my-window-tools/get-window-for-window-category (target-window-category frame)
  "Retrieve the first window in FRAME associated with TARGET-WINDOW-CATEGORY.
If no window is found, check for a window with `my-window-tools/default-tag'.
Return the first matching window, or nil if none are found.

TARGET-WINDOW-CATEGORY is the symbol (e.g., `edit', `logs') to search for.
FRAME is the frame to search within (defaults to selected if nil).

This function supports the principle of falling back to a default window
to avoid popping up new ones unnecessarily, aligning with IDE workflows
where buffers should consolidate into tagged windows.  It iterates over
windows excluding mini-buffers.

Edge cases:
- If multiple windows match, returns the first (order from `window-list`).
- If no `default-tag' window, returns nil (caller should handle pop-up).
- Logs debug info for traceability in custom management frames.

Returns: Window object or nil."
  (let ((windows (window-list frame 'no-minibuffer)))
    ;; First, search for exact category match to prioritize specific tagging.
    (or (cl-loop for win in windows
                 when (equal target-window-category
                             (window-parameter win 'window-category))
                 return win)
        ;; Fallback to default tag if no exact match, preventing pop-ups.
        (cl-loop for win in windows
                 when (equal my-window-tools/default-tag
                             (window-parameter win 'window-category))
                 return win)
        ;; If neither found, return nil and log for debugging.
        (progn
          (log/debug :fn 'my-window-tools/get-window-for-window-category
                     :msg "No matching or default window found"
                     :obj (list :category target-window-category :frame frame))
          nil))))


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
  (log/debug :fn 'my-window-tools/save-window-state-with-properties
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
    (if (not use-custom)
        ;; Non-IDE: Skip all custom logic, apply original display-buffer with
        ;; unmodified action.
        ;; This ensures default behavior, e.g., 'other-window' reuses or splits
        ;; in current frame.
        (progn
          (log/debug :fn 'my-window-tools/assign-category-advice
                     :msg "Non-IDE frame detected, skipping category assignment and using default display"
                     :obj (list :buffer buffer-or-name
                                :frame effective-frame
                                :action action))
          (apply orig-fun buffer-or-name action frame))
      ;; IDE: Proceed with category assignment and modified action.
      (let* ((buffer (get-buffer buffer-or-name))                                 ; Get buffer for category check.
             (category
              (when buffer
                (my-window-tools/determine-buffer-category buffer))))             ; Use map for category.
        (when category
          (log/debug :fn 'my-window-tools/assign-category-advice
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
                    (log/debug :fn 'my-window-tools/assign-category-advice
                               :msg "Stripped Dape category, re-injecting custom."
                               :obj (list :original-action action
                                          :category category
                                          :buffer buffer-or-name))
                    (my-window-tools/process-display-action
                     stripped-action category))
                ;; else it is a simple category assignment. 
                (my-window-tools/process-display-action action category))))
          
          (apply orig-fun buffer-or-name (or new-action action) frame))))))

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
- If found: Check dedication; unset if Dape buffer; set new buffer.               ; ;
- If not: Pop new window, tag it.
- Log decisions.  

Edge cases:
- Dedicated non-Dape: Skip unset to preserve (error as before).
- No category: Log/fallback to pop-up.
- New window: Inherits category for reuse.
- Historical: Aligns with Emacs 24+ quit-restore for stability."
  (let* ((category (cdr (assq 'category alist)))
         (frame (selected-frame))
         (target-window
          (when category
            (my-window-tools/get-window-for-window-category category frame))))
    (log/debug :fn 'display-buffer-in-category-window
               :msg "Searching for window"
               :obj (list :category category
                          :buffer (buffer-name buffer) :frame frame))
    (if target-window
        (progn
          ;; Check and unset dedication if current buffer is Dape- or VC-related.
          ;; This prevents "stuck" windows from packages like Dape or VC/log-edit.
          (let ((current-buf (window-buffer target-window)))
            (when
                (window-dedicated-p target-window)
              ;; (and
              ;;  (window-dedicated-p target-window)
              ;;  (or (string-match-p "^\\*dape-" (buffer-name current-buf))
              ;;      (string-match-p "^\\*\\(vc-\\|log-edit-\\)"
              ;;                      (buffer-name current-buf))))                 ; Broad match for VC/log-edit variants.
              (set-window-dedicated-p target-window nil)
              (log/debug :fn 'display-buffer-in-category-window
                         :msg (format "Unset dedication for %s window"
                                      (cond
                                       ((string-match-p
                                         "^\\*dape-" (buffer-name current-buf))
                                        "Dape")
                                       (t "vc")))                                 ; Dynamic msg for traceability.
                         :obj (list :window target-window
                                    :buffer current-buf))))
          (log/debug :fn 'display-buffer-in-category-window
                     :msg "Found matching or default window"
                     :obj (list :window target-window
                                :category (window-parameter
                                           target-window 'window-category)))
          (set-window-buffer target-window buffer)
          target-window)
      ;; No match or default: Fallback to pop-up and tag the new window.
      (log/debug :fn 'display-buffer-in-category-window
                 :msg "No matching or default window found, falling back to pop-up"
                 :obj (list :category category :frame frame))
      (let ((new-window (display-buffer-pop-up-window buffer alist)))
        (when new-window
          (set-window-parameter new-window 'window-category category)
          (log/debug :fn 'display-buffer-in-category-window
                     :msg "Created and tagged new window"
                     :obj (list :new-window new-window :category category)))
        new-window))))

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
  (with-current-buffer buffer
    (let* ((buf-name (buffer-name))                                               ; Get the buffer's name
           (buf-mode major-mode)                                                  ; Get the current major mode
           (whitelist-names
            (cdr (assq :whitelist-names my-buffer-tools/category-map)))           ; Fetch whitelist names
           (whitelist-regexps
            (cdr (assq :whitelist-regexps my-buffer-tools/category-map))))        ; Fetch whitelist regexps
      (log/debug :fn 'my-window-tools/determine-buffer-category
                 :msg "Computing category"
                 :obj (list :buffer-name buf-name :major-mode buf-mode))

      ;; Check if buffer should be ignored based on whitelists
      (if (or
           (string-prefix-p " " buf-name)                                         ; Auto-whitelist if starts with space
           (member buf-name whitelist-names)                                      ; Exact match in whitelist names
           (seq-some (lambda (re) (string-match-p re buf-name))
                     whitelist-regexps))                                          ; Regex match
          (progn
            (log/debug :fn 'my-window-tools/determine-buffer-category
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
            (log/debug :fn 'my-window-tools/determine-buffer-category
                       :msg "Matched by exact name"
                       :obj (list :match name-match))
            (cdr name-match))                                                     ; Return category from name match
           ((seq-some (lambda (pair)                                              ; Check regex matches
                        (when (string-match-p (car pair) buf-name)
                          (log/debug :fn 'my-window-tools/determine-buffer-category
                                     :msg "Matched by regex"
                                     :obj (list :regex (car pair)
                                                :category (cdr pair)))
                          (cdr pair)))
                      regexps))
           ((if-let ((mode-match (assoc buf-mode modes)))                         ; Check mode match
                (progn
                  (log/debug :fn 'my-window-tools/determine-buffer-category
                             :msg "Matched by mode"
                             :obj (list :mode buf-mode
                                        :category (cdr mode-match)))
                  (cdr mode-match))))
           (t
            (log/debug :fn 'my-window-tools/determine-buffer-category
                       :msg "No match found, falling back to default category"
                       :obj (list :buffer-name buf-name))
            my-window-tools/default-tag)                                          ; Returns 'edit
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
    (log/debug :fn 'my-window-tools/process-display-action
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
      (log/debug :fn 'my-window-tools/process-display-action
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
                 (reusable-frames . visible)))))                                  ; Limit scope


(add-hook 'vc-checkin-hook 'vc-dir-refresh)                                       ; ensure the window layout is refreshed after check-in. 

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
  (message "Window category set to %s" tag)
  (log/debug :fn 'my-window-tools/set-ide-category
             :msg "Set active window tag. "
             :obj (list :tag tag)))

(provide 'system-window-management)

;;; system-window-management.el ends here

;; LocalWords:  Customize vc repl alists listp shorthands advices rgrep gracie
;; LocalWords:  elisp tabline defun eldoc evie Checkdoc dape pydoc
