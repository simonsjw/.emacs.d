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
    (:whitelist-names . ("*Completions*"                                          ; Completion dropdowns
                         "*Echo Area 0*"                                          ; Minibuffer echo areas
                         "*Echo Area 1*"
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
    (:names . (("dape-shell" . terminal)
               ("scratch" . terminal)
               ("*MATLAB*" . terminal)
               ("Checkdoc Status" . data)                                         ; Note: Appears twice in original; consolidated here
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
               ("vc-diff" . data)
               ("Emacs" . edit)
               ("config.el" . edit)
               ("early-config.el" . edit)
               (".bashrc" . edit)
               (".bash_history" . edit)
               (".bashrc_profile" . edit)
               (".LESS_TERMCAP" . edit)
               (".profile" . edit)
               (".zshrc" . edit)
               ("*vc-diff*" . edit)
               ("*Messages*" . logs)
               ("*Warnings*" . logs)
               ("blacken-error" . logs)
               ("straight-process" . logs)
               ("ruff-format errors" . logs)
               ("straight-byte-compilation" . logs)
               ("projectile-files-errors" . logs)
               ("Async-native-compile-log" . logs)
               ("elisp-flymake-byte-compile" . logs)
               ("log-edit-files" . logs)                                          ; Note: Duplicate in original with .vc; using .logs here—resolve if needed
               ("Org Babel Results" . logs)
               ("vc" . logs)
               ("*Load-History*" . logs)
               ("RE-Builder" . config)
               ("Anaconda" . config)
               ("conf.org" . config)
               ("eldoc" . config)
               ("EGLOT workspace configuration" . config)
               ("Help" . config)
               ("info" . config)
               ("todos.org" . config)
               ("Ediff Config" . config)
               ("Ilist" . config)
               ("*Projects View*" . config)
               (".gitignore" . vc)
               ("*vc*" . vc)
               ("*vc-dir*" . vc)
               ("*vc-log-edit-files*" . vc)
               ("*vc-log*" . vc)
               ("*log-edit-files*" . vc)))                                        ; Note: If conflicting with above, choose one
    (:regexps . (("^documentation$" . config)                                     ; Exact match for "documentation"
                 ("^README.*" . config)                                           ; Starting with "README" + any chars
                 (".*\\.conf$" . config)                                          ; Any chars + literal ".conf" at end
                 (".*\\.dconf$" . config)                                         ; Any chars + literal ".dconf" at end
                 ("^\\*Customize.*" . config)                                     ; Starting with literal "*Customize" + any chars
                 ("^\\*Ibuffer.*" . config)                                       ; Starting with literal "*Ibuffer" + any chars
                 (".*_types.py" . config)                                         ; Any chars + "_types.py"
                 ("^magit.*" . vc)                                                ; Starting with "magit" + any chars
                 ("^vc-.*" . vc)                                                  ; Starting with "*vc-" + any chars
                 (".*Annotate .*" . vc)                                           ; Any chars + "Annotate " + any chars
                 (".*ede-proj.*" . vc)                                            ; Any chars + "ede-proj" + any chars
                 (".*\\.pdf$" . data)                                             ; Any chars + literal ".pdf" at end
                 ("^\\*Flymake diagnostics.*" . data)                             ; Starting with literal "*Flymake diagnostics" + any chars
                 ("^flymake-.*" . data)                                           ; Starting with "flymake-" + any chars
                 (".*cell sheet.*" . data)                                        ; Any chars + "cell sheet" + any chars
                 ("^Ediff A\\:.*" . data)                                         ; Starting with "Ediff A:" + any chars (escaped :)
                 ("^Ediff B\\:.*" . data)                                         ; Starting with "Ediff B:" + any chars (escaped :)
                 ("^magit-process:.*" . logs)                                     ; Starting with "magit-process:" + any chars
                 ("^\\*EGLOT.*" . logs)                                           ; Starting with literal "*EGLOT" + any chars
                 (".*+sterr$" . logs)                                             ; Any chars + "+sterr" at end
                 (".*\\.log" . logs)                                              ; Any chars + literal ".log"
                 (".*-log.*" . logs)                                              ; Any chars + "-log" + any chars
                 (".*tramp.*" . logs)                                             ; Any chars + "tramp" + any chars
                 ("^\\*vc-git :.*" . logs)                                        ; Starting with literal "*vc-git :" + any chars
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
  "Mapping of buffer properties to window categories.")


;; temp as we move to frame specific assignment.
(setq my-window-tools/frame-map
      `((:IDE . ,my-buffer-tools/category-map)))


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


(defun my-window-tools/tag-windows-by-list (frame tag-list)
  "Tag each window in FRAME from TAG-LIST based on an ordered window list.
The window list is ordered by position.  If there are more windows than tags,
the tags will be reused cyclically."
  (with-selected-frame frame
    (let* ((windows (my-window-tools/sorted-window-list frame))
           (tag-count (length tag-list)))
      (cl-loop for win in windows
               for idx from 0 do
               (let ((tag-to-apply (nth (mod idx tag-count) tag-list)))
                 (set-window-parameter win 'window-category tag-to-apply)
                 (message "Assigned tag %s to window %s" tag-to-apply win))))))


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


(defun my-assign-category-advice (orig-fun buffer-or-name &optional action frame)
  "Advice to inject a category into the `DISPLAY-BUFFER' action alist.
This function wraps the original `DISPLAY-BUFFER' function to assign a category
based on the buffer\'s name or mode, but only if the frame is tagged for custom
window management (i.e., IDE frames with `custom-window-management' t).

For non-IDE frames, skips custom logic entirely, falling back to Emacs' default
display behavior (e.g., 'other-window' opens in another window in the current
frame without category injection or tagged reuse).

ORIG-FUN is the original `display-buffer' function.
BUFFER-OR-NAME is either a buffer object or its name.
ACTION is an optional action alist or function specification.
FRAME is the target frame, defaulting to the selected frame if nil.

Returns: The result of the original or modified `display-buffer' call
 (typically a window).

Edge cases:
- If FRAME is nil, uses `selected-frame' — ensuring locality to the active
  frame.
- Non-IDE: No category determination or injection; pure default (e.g., for        ;
  rgrep links, behaves like `find-file-other-window').
- IDE: Injects category from `my-buffer-tools/category-map', enabling tagged
  window reuse.
- Logs skips and assignments for debug.

Historical context: Advices like this became common post-Emacs 24 to customize
displays without globals, but frame checks (added in evolutions like Emacs 27)
prevent interference in multi-frame setups, avoiding issues seen in early CEDET
or ECB where defaults broke across frames."
  (let* ((effective-frame (or frame (selected-frame)))                            ; Ensure locality to active frame if not specified.
         (use-custom
          (frame-parameter effective-frame 'custom-window-management)))           ; Check for IDE tag.
    (if (not use-custom)
        ;; Non-IDE: Skip all custom logic, apply original display-buffer with
        ;; unmodified action.
        ;; This ensures default behavior, e.g., 'other-window' reuses or splits
        ;; in current frame.
        (progn
          (log/debug :fn 'my-assign-category-advice
                     :msg "Non-IDE frame detected, skipping category assignment and using default display"
                     :obj (list :buffer buffer-or-name
                                :frame effective-frame :action action))
          (apply orig-fun buffer-or-name action frame))
      ;; IDE: Proceed with category assignment and modified action.
      (let* ((buffer (get-buffer buffer-or-name))                                 ; Get buffer for category check.
             (category (when buffer (my-determine-buffer-category buffer))))      ; Use map for category.
        (when category
          (log/debug :fn 'my-assign-category-advice
                     :msg "IDE frame: Assigned category"
                     :obj (list :category category
                                :buffer buffer-or-name :action action)))
        ;; Process action with category injection.
        (let ((new-action (my-process-display-action action category)))
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

Returns: The window where BUFFER is displayed, or nil on failure.

Edge cases:
- If category is nil, logs and falls back to pop-up (though advice should
  prevent this).
- Dedicated windows are skipped to avoid conflicts.
- New pop-up windows inherit the category for future reuse.
- Debug logs trace the decision process for troubleshooting.

Historical context: Custom display functions like this extend Emacs' base
`display-buffer` API (evolved since Emacs 24) to support tagged windows,
common in packages like `perspective` or `tab-bar`.  Without fallback, it
risks frame clutter, as seen in early ECB implementations."
  (let* ((category (cdr (assq 'category alist)))
         (frame (selected-frame))                                                 ; Use current frame for IDE consistency.
         (target-window
          (when category
            (my-window-tools/get-window-for-window-category category frame))))
    (log/debug :fn 'display-buffer-in-category-window
               :msg "Searching for window"
               :obj (list :category category
                          :buffer (buffer-name buffer) :frame frame))
    (if target-window
        (progn
          ;; Reuse found window (exact or default fallback).
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
      (let ((new-window (display-buffer-pop-up-window buffer alist)))             ; Alternative: display-buffer-in-child-frame if preferred.
        (when new-window
          (set-window-parameter new-window 'window-category category)
          (log/debug :fn 'display-buffer-in-category-window
                     :msg "Created and tagged new window"
                     :obj (list :new-window new-window :category category)))
        new-window))))


(defun my-determine-buffer-category (buffer)
  "Determine the category for BUFFER based on its properties.
Returns a symbol (e.g., `edit', `logs') or nil if no category applies.
BUFFER is the buffer to categorize.

The category is derived from:
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
      (log/debug :fn 'my-determine-buffer-category
                 :msg "Computing category"
                 :obj (list :buffer-name buf-name :major-mode buf-mode))

      ;; Check if buffer should be ignored based on whitelists
      (if (or (member buf-name whitelist-names)                                   ; Exact match in whitelist names
              (seq-some (lambda (re) (string-match-p re buf-name))
                        whitelist-regexps))                                       ; Regex match
          (progn
            (log/debug :fn 'my-determine-buffer-category
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
            (log/debug :fn 'my-determine-buffer-category
                       :msg "Matched by exact name"
                       :obj (list :match name-match))
            (cdr name-match))                                                     ; Return category from name match
           ((seq-some (lambda (pair)                                              ; Check regex matches
                        (when (string-match-p (car pair) buf-name)
                          (log/debug :fn 'my-determine-buffer-category
                                     :msg "Matched by regex"
                                     :obj (list :regex (car pair)
                                                :category (cdr pair)))
                          (cdr pair)))
                      regexps))
           ((if-let ((mode-match (assoc buf-mode modes)))                         ; Check mode match
                (progn
                  (log/debug :fn 'my-determine-buffer-category
                             :msg "Matched by mode"
                             :obj (list :mode buf-mode
                                        :category (cdr mode-match)))
                  (cdr mode-match))))
           (t
            (log/debug :fn 'my-determine-buffer-category
                       :msg "No match found, falling back to default category"
                       :obj (list :buffer-name buf-name))
            my-window-tools/default-tag)                                          ; Returns 'edit
           )
          )
        )
      )
    )
  )


(defun my-process-display-action (action category)
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
    (log/debug :fn 'my-process-display-action
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
      (log/debug :fn 'my-process-display-action
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

(advice-add 'display-buffer :around #'my-assign-category-advice)

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


(provide 'system-window-management)

;;; system-window-management.el ends here

;; LocalWords:  Customize vc repl alists listp shorthands advices rgrep
;; LocalWords:  elisp tabline defun eldoc
