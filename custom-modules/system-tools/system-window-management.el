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
               ("MATLAB" . terminal)
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
  "The default tag assigned to non-system buffers when no tag is found.")

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
Return the first matching window, or nil if none are found."
  (let ((windows (window-list frame 'no-minibuffer)))
    (or (cl-loop for win in windows
                 when (equal target-tag (window-parameter win 'tag))
                 return win)
        (cl-loop for win in windows
                 when (equal my-window-tools/default-tag
                             (window-parameter win 'window-category))
                 return win))))


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
  ;;(interactive "e")  ; The 'e' here tells Emacs this function expects a mouse event.
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
  "Find the window with the 'Name' parameter equal to NAME."
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
  "Select the window with a custom 'name parameter matching NAME."
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
;; '("edit" "vc" "terminal" "logs" "config" "data"))))

(defun my-assign-category-advice (orig-fun buffer-or-name &optional action frame)
  "Advice to inject a category into DISPLAY-BUFFER's action alist.
This function wraps the original DISPLAY-BUFFER function to assign a category
based on the buffer's name or mode, but only if the frame is tagged for custom
window management.

ORIG-FUN is the original `display-buffer' function.
BUFFER-OR-NAME is either a buffer object or its name.
ACTION is an optional action alist or function specification.
FRAME is the target frame, defaulting to the selected frame if nil."
  (let* ((effective-frame (or frame (selected-frame)))                            ; Use selected frame if none specified
         (use-custom
          (frame-parameter effective-frame 'custom-window-management)))           ; Check if custom management is enabled
    (if (not use-custom)
        ;; Skip custom logic for non-IDE frames, log and apply original function
        (progn
          (log/debug :fn 'my-assign-category-advice
                     :msg "Non-IDE frame detected, skipping category assignment"
                     :obj (list :buffer buffer-or-name :frame effective-frame))
          (apply orig-fun buffer-or-name action frame))
      ;; For IDE frames, proceed with custom category assignment
      (let* ((buffer (get-buffer buffer-or-name))                                 ; Get or create the buffer
             (category (when buffer (my-determine-buffer-category buffer))))      ; Determine category
        (when category
          (log/debug :fn 'my-assign-category-advice
                     :msg "Assigned category"
                     :obj (list :category category :buffer buffer-or-name
                                :action action)))
        ;; Process action and apply with the category
        (let ((new-action (my-process-display-action action category)))
          (apply orig-fun buffer-or-name (or new-action action) frame))))))

(defun my-determine-buffer-category (buffer)
  "Determine the category for BUFFER based on its properties.
Returns a symbol (e.g., 'edit, 'logs) or nil if no category applies.
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
                       :msg "No match found, no category assigned"
                       :obj (list :buffer-name buf-name))
            nil)))))))                                                            ; Default to nil if no match

(defun my-process-display-action (action category)
  "Process the DISPLAY-BUFFER action and inject the CATEGORY if applicable.
Returns a new action structure or the original action if no change is needed.
ACTION is the original action (function list, alist, or special value like t).
CATEGORY is the buffer category to inject (e.g., 'logs)."
  ;; Extract the functions and alist from the action
  (let* ((action-functions
          (cond
           ((consp action)
            (let ((car-action (car action)))
              (if (listp car-action)
                  car-action                                                      ; Already a list of functions; e.g., action = ((display-buffer-reuse-window display-buffer-pop-up-window) . ((inhibit-same-window . t)))
                (list car-action))))                                              ; Single function: wrap in list; e.g., action = (display-buffer-pop-up-window . ((inhibit-same-window . t)))
           (t nil)))                                                              ; No functions if not a cons; e.g., action = nil or action = t or action = ((inhibit-same-window . t)) (pure alist)
         (action-alist
          (cond
           ((consp action) (cdr action))                                          ; Use cdr if action is a cons; e.g., action = ((display-buffer-reuse-window) . ((window-height . 0.3))), returns ((window-height . 0.3))
           ((eq action t) nil)                                                    ; Special case: Treat t as empty alist; e.g., action = t (default display, often from find-file-other-window), returns nil to start fresh
           (action action)                                                        ; Use action as alist if present; e.g., action = ((inhibit-same-window . t)), returns the alist directly (non-cons but assumed alist)
           (t nil)))                                                              ; Default to empty alist if invalid; e.g., action = some-symbol (rare error case), returns nil to avoid crashes
         (new-alist (if (and category (not (assq 'category action-alist)))
                        (cons `(category . ,category) action-alist)               ; Inject category; e.g., if category = 'edit and action-alist = ((window-height . 0.3)), returns ((category . edit) (window-height . 0.3))
                      action-alist)))                                             ; No change if category exists; e.g., if already ((category . logs)), returns unchanged
    ;; Construct new action
    (if action-functions
        (cons action-functions new-alist)                                         ; (functions-list . alist); e.g., returns ((display-buffer-reuse-window) . ((category . edit)))
      (if new-alist
          (cons nil new-alist)                                                    ; (nil . alist) to force pure alist with default functions; e.g., returns (nil . ((category . edit)))
        nil))))                                                                   ; No action if empty; e.g., if no category and empty alist, returns nil to use Emacs defaults

(advice-add 'display-buffer :around #'my-assign-category-advice)


(defun display-buffer-in-category-window (buffer alist)
  "Display a BUFFER in a window according to its category,

The 'window-category' of the window matches a category in ALIST."
  (let* ((category (cdr (assq 'category alist)))
         (target-window
          (seq-find (lambda (win)
                      (and (eq (window-parameter win 'window-category) category)
                           (not (window-dedicated-p win))))
                    (window-list))))
    (log/debug :fn 'display-buffer-in-category-window
               :msg "Searching for window"
               :obj (list :category category :buffer (buffer-name buffer)))
    (if target-window
        (progn
          (log/debug :fn 'display-buffer-in-category-window
                     :msg "Found matching window"
                     :obj (list
                           :window target-window
                           :category (window-parameter target-window
                                                       'window-category)))
          (set-window-buffer target-window buffer)                                ; Reuse matching window
          target-window)
      ;; No match: Fallback to popup
      (log/debug :fn 'display-buffer-in-category-window
                 :msg "No matching window found, falling back to pop-up"
                 :obj (list :category category))
      (let ((new-window (display-buffer-pop-up-window buffer alist)))             ; Alternative: display-buffer-in-child-frame if preferred
        (when new-window
          (set-window-parameter new-window 'window-category category)
          new-window)))))                                                         ; Return the window


;; Configure display-buffer-alist
;;   ------------------------------
;; the below object controls how new buffers are assigned to windows in Emacs.
;; This is central to managing the relationship between buffers and windows.


(setq display-buffer-alist
      '(
        ;; (Show Ilist or dictionary definition on the left)
        ("^\\*\\(Dictionary\\|Ilist\\)\\*"
         (display-buffer-in-side-window)
         (side . right)
         (window-width . 50)                                                      ; change to 0.5 to make it half the size of the buffer it is next to.
         (window-parameters . ((no-delete-other-windows . t))))

        ((category . edit)
         display-buffer-in-category-window)
        ((category . vc)
         display-buffer-in-category-window)
        ((category . terminal)
         display-buffer-in-category-window)
        ((category . logs)
         display-buffer-in-category-window)
        ((category . config)
         display-buffer-in-category-window)
        ((category . data)
         display-buffer-in-category-window)
        )
      )

(defun my-window-tools/with-temporary-display-buffer-settings (settings &rest body)
  "Execute BODY with temporary DISPLAY-BUFFER-ALIST settings.

SETTINGS is a list of settings to apply, including 'display-buffer-alist' and
other variables like 'switch-to-buffer-obey-display-actions', 'pop-up-windows',
and 'pop-up-frames'.  The original values are restored afterwards."
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

;; LocalWords:  Customize vc repl
;; LocalWords:  elisp
;; LocalWords:  tabline
;; LocalWords:  defun
;; LocalWords:  eldoc
