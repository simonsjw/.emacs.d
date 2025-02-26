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

;; (defvar my-window-tools/buffer-window-map nil
;;   "Create the map of buffers to windows.")

(setq my-window-tools/IDE-buffer-window-map
      '((:names   . (("*dape-shell*" . terminal)
                     ("*scratch*" . terminal)
                     ("*Checkdoc Status*" . data)
                     ("*SQL Results*" . data)
                     ("*Backtrace*" . data)
                     ("*grep*" . data)
                     ("*xref*" . data)
                     ("*Org Agenda*" . data)
                     ("*docker-images*" . data)
                     ("*docker-contexts*" . data)
                     ("*docker-networks*" . data)
                     ("*docker-containers*" . data)
                     ("*docker-volumes*" . data)
                     ("*vc-diff*" . data)
                     ("*Emacs*" . edit)
                     ("config.el" . edit)
                     ("early-config.el" . edit)
                     (".bashrc" . edit)
                     (".bash_history" . edit)
                     (".bashrc_profile" . edit)
                     (".LESS_TERMCAP" . edit)
                     (".profile" . edit)
                     (".zshrc" . edit)
                     ("*Messages*" . logs)
                     ("*Warnings*" . logs)
                     ("*blacken-error*" . logs)
                     ("*straight-process*" . logs)
                     ("*ruff-format errors*" . logs)
                     ("*straight-byte-compilation*" . logs)
                     ("*projectile-files-errors*". logs)
                     ("*Async-native-compile-log*". logs)
                     ("*elisp-flymake-byte-compile*" . logs)
                     ("*log-edit-files*" . logs)
                     ("*Org Babel Results*" . logs)
                     ("*vc*" . logs)
                     ("*Checkdoc Status*" . data)
                     ("*RE-Builder*" . config)
                     ("*Anaconda*". config)
                     ("conf.org" . config)
                     ("*eldoc*" . config)
                     ("*EGLOT workspace configuration*" . config)
                     ("*Help*" . config)
                     ("*info*" . config)
                     ("todos.org" . config)
                     ("*Ediff Config*" . config)
                     ("*Ilist*" .config)
                     (".gitignore" . vc)
                     ("*vc-dir*" . vc)
                     ("*log-edit-files*" . vc)
                     ))
        (:regexps . (("^documentation$" . config)                                 ; exact match for `documentation'
                     ("^README.*" . config)                                       ; strings beginning upper or lower case `README'.
                     (".*\\.conf$" . config)                                      ; any number of characters followed by `.conf'.
                     (".*\\.dconf$" . config)                                     ; any number of characters followed by `.dconf'.
                     ("^\\*Customize.*" . config)                                 ; strings beginning with `*Customize' followed by any characters.
                     ("^\\*Ibuffer.*" . config)                                   ; strings beginning with `*Ibuffer' followed by any characters.
                     (".*_types.py" . config)                                     ; strings ending `_type.py' - a Python file defining custom type hints. 
                     ("^magit.*" . vc)                                            ; strings beginning with `magit' followed by any characters.
                     ("^vc-.*" . vc)                                              ; strings beginning with `vc' followed by any characters.
                     (".*Annotate .*" . vc)                                       ; strings with `Annotate\ ' somewhere in them.
                     (".*ede-proj.*" . vc)                                        ; strings with `ede-proj'  somewhere in them.
                     (".*\\.pdf$" . data)                                         ; any number of characters followed by `.pdf'.
                     ("^\\*Flymake diagnostics.*" . data)                         ; strings beginning with `Flymake-diagnostics' followed by any characters.
                     ("^flymake-.*" . data)                                       ; strings beginning `flymake'.
                     (".*cell sheet.*" . data)                                    ; strings containing `cell\ sheet'.
                     ("^Ediff A\\:.*" . data)                                     ; strings beginning `Ediff A:' followed by any characters.
                     ("^Ediff B\\:.*" . data)                                     ; strings beginning `Ediff B:' followed by any characters.
                     ("^magit-process:.*" . logs)                                 ; strings beginning `magit-process:' followed by any characters.
                     ("^\\*EGLOT.*" . logs)                                       ; strings beginning `*EGLOT' followed by any characters.
                     (".*+sterr$" . logs)                                         ; strings ending `+sterr'.
                     (".*\\.log" . logs)                                          ; strings ending `.log'.
                     (".*-log.*" . logs)                                          ; strings with `-log' in them.
                     (".*tramp.*" . logs)                                         ; strings with `tramp' in them.
                     ("^\\*vc-git :.*" . logs)                                    ; strings beginning `*vc-git :'               
                     ("^\\*ielm*" . terminal)                                     ; strings beginning `*ielm' followed by any characters.
                     ("^\\*Q PROC.*" . terminal)                                  ; strings beginning `*Q PROC' followed by any characters.
                     ("^\\*vterm.*" . terminal)                                   ; strings beginning `*vterm' followed by any characters.
                     ("^\\*eshell.*" . terminal)                                  ; strings beginning `*eshell' followed by any characters.
                     ))
        (:modes   . ((vterm-mode . terminal)
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
                     ;;       (org-mode . config)
                     (csv-mode . config)
                     (ibuffer-mode . config)
                     (bufler-list-mode . config)
                     (bookmark-menu . config)
                     (imenu-list-mode . config)
                     (help-mode . config)
                     (helpful-mode . config)
                     (compilation-mode . logs)
                     (debugger-mode . logs)
                     (vc-dir . vc))
                  )
        )
      )


;; temp as we move to frame specific assignment.
(setq my-window-tools/frame-map
      `((:IDE . ,my-window-tools/IDE-buffer-window-map)))


(defvar my-window-tools/whitelabel-buffers '("*SPEEDBAR*"
                                             "*dape-repl*"
                                             "*dape-info Scope*"
                                             "*dape-info Stack*"
                                             "*dape-info Breakpoints*"
                                             "*dape-shell*"
                                             "logs"
                                             "edit"
                                             "data"
                                             "terminal"
                                             "config"
                                             "vc")
  "Non-system buffers to be excluded from the window matching process.")

(defvar my-window-tools/known-buffers nil
  "List of buffers known to the system.  Used to detect newly created buffers.")


;; ******************* new window tools for new frame management.
(defun my-window-tools/sorted-window-list (frame)
  "Return a list of windows in FRAME sorted by their top-left position."
  (sort (window-list frame 'no-minibuffer)
        :lessp (lambda (w1 w2)
                 (let* ((edges1 (window-edges w1))
                        (edges2 (window-edges w2))
                        (y1 (nth 1 edges1))  ; top edge of w1
                        (y2 (nth 1 edges2))
                        (x1 (nth 0 edges1))  ; left edge of w1
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
                 (set-window-parameter win 'tag tag-to-apply)
                 (message "Assigned tag %s to window %s" tag-to-apply win))))))

;; *******************



;; ensure that our buffer list is updated when a buffer is killed.
(defun my-window-tools/update-known-buffers-on-kill ()
  "Update `my-window-tools/known-buffers` when a non-system buffer is killed."
  (unless (string-prefix-p " " (buffer-name))
    ;; Only update known buffers if it's not a system buffer.
    (setq my-window-tools/known-buffers (buffer-list))))

;; Add this function to `kill-buffer-hook`
(add-hook 'kill-buffer-hook #'my-window-tools/update-known-buffers-on-kill)

(defconst my-window-tools/default-tag 'edit
  "The default tag assigned to non-system buffers when no tag is found.")

(defconst my-window-tools/tag-list '(edit logs config data terminal vc)
  "The tags assigned to non-system buffers.")

(defun my-window-tools/get-project-root (buffer)
  "Get the project root directory for BUFFER using the project.el package."
  (with-current-buffer buffer
    (when (project-current)
      (expand-file-name (cdr (project-current))))))


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



;;;; Buffer assignment to windows

;; Here we implement the mechanics that, when given a buffer, can determine
;; the appropriate window for that buffer and move it if necessary.
;;
;; defun my-window-tools/display-buffer   (called from display-buffer-alist)
;;     |
;;     -- defun my-window-tools/get-buffer-tag-or-default buffer
;;     |      |
;;     |      -- my-window-tools/whitelabel-buffers
;;     |      |
;;     |      -- defun my-window-tools/get-buffer-tag buffer
;;     |
;;     -- my-window-tools/get-window-for-tag tag
;;
;; The steps in this process are:
;; 1) Call a function to determine the action needed to assign a given buffer
;;    to the right window. This function is:
;;    my-window-tools/assign-buffer-to-window
;; 3) Evaluate if the buffer is suitable to be matched to a tagged window.
;;    Use the function  my-window-tools/get-buffer-tag-or-default. If a tag
;;    is needed, it will proceed to step 2
;; 3) find the correct tag for the window.
;;    Use function my-window-tools/get-buffer-tag.
;; 4) having found a tag for the buffer, find the window that matches the tag.
;;    Use function my-window-tools/get-window-for-tag. (If the tag has no
;;    match, then the default window is selected.)
;; 5) When a move is needed, call my-window-tools/assign-buffer-to-window. Note
;;    that if the output-only flag is set to true, all these functions will
;;    still be called. Only the final move inside this function is inhibited.
;;    This ensures we have the opportunity to have the full function footprint
;;    in any testing.


(defun my-window-tools/assign-buffer-to-window (buffer
                                                &optional frame output-only)
  "Assign BUFFER to an appropriate window in FRAME based on its tag.

If OUTPUT-ONLY is non-nil, this function will only determine the target window
without moving the buffer.  Returns a cons cell (WINDOW . TAG) or nil if no
assignment is made."
  (let* ((frame (or frame (selected-frame)))                                      ; set the FRAME to the current frame if it is not specified. 
         (tag (my-window-tools/get-buffer-tag-or-default buffer frame))
         )                                   
    (if tag                                                                       ; If there is no tag, the buffer is whitelisted so no window assignment performed."
        (let* ((window (my-window-tools/get-window-for-tag tag frame))
               (original-window (get-buffer-window buffer)))
          (if window
              (progn
                (unless output-only
                  ;; Move the buffer to the target window
                  (my-window-tools/move-buffer-to-window
                   buffer window original-window output-only))
                ;; Return the window and tag as a cons cell
                (cons window tag))
            (progn
              (log/debug
               :fn 'my-window-tools/assign-buffer-to-window
               :msg (format "No window with tag '%s' was found."
                            my-window-tools/default-tag)
               :obj -1)
              nil))))))


(defun my-window-tools/get-buffer-tag-or-default (buffer &optional frame)
  "Determine and return the tag for BUFFER assuming FRAME.

This function uses the default tag if unassigned.  If no frame is specified,
the currently selected one is assumed.  If the buffer is whitelisted, no tag
will be assigned, and no window assignment will occur." 
  (let ((buffer-name-text (buffer-name buffer))
        (frame (or frame (selected-frame))))
    ;; Check if the buffer is whitelisted (skip assignment if true)
    (if (member buffer-name-text my-window-tools/whitelabel-buffers)
        (progn
          (log/debug
           :fn 'my-window-tools/get-buffer-tag-or-default
           :msg (format
                 "Buffer %s is whitelisted, no window assignment performed."
                 buffer-name-text)
           :obj t)
          nil)
      ;; Get the tag for the buffer, defaulting to
      ;; `my-window-tools/default-tag` if `no-tag`
      (let ((tag (with-current-buffer buffer
                   (my-window-tools/get-buffer-tag buffer frame))))
        (if (eq tag 'no-tag)
            ;; If no tag found, assign the default tag and log the action
            (progn
              (log/debug
               :fn 'my-window-tools/get-buffer-tag-or-default
               :msg (format
                     "Buffer %s does not map to a tag. Assigned to default tag '%s."
                     buffer-name-text my-window-tools/default-tag)
               :obj t)
              my-window-tools/default-tag)
          ;; Return the found tag if it is not 'no-tag'
          tag)))))


(defun my-window-tools/get-buffer-tag (buffer frame)
  "Get the tag for the given BUFFER and FRAME into which it is to be assigned.
Return nil if the buffer is a system buffer without a match by name or
regexp.  Return `no-tag' if the buffer is not a system buffer but isn't matched
by name, regexp or mode."
  (let ((buffer-name-text (buffer-name buffer)))
    ;; Step 0: Early return if the buffer is a system buffer.
    (if (string-prefix-p " " buffer-name-text)
        nil
      ;; Proceed to check for tag matches.
      (let* ((tag 'no-tag)
             (buffer-mode (buffer-local-value 'major-mode buffer))
             (ui-type (frame-parameter frame 'UI-TYPE))
             (key (intern (concat ":" (symbol-name ui-type))))
             (map (alist-get key my-window-tools/frame-map)))
        ;; (message "-------\nbuffer: %s\n---------\nbuffer-name-text: %s \nbuffer-mode: %s \nui_type: %s \n key: %s\n map: %s" tBuffer buffer-name-text buffer-mode ui-type key map)
        
        ;; Step 1: Check for match by buffer name.
        (dolist (name (cdr (assoc :names map)))
          (when (string-match-p (car name) buffer-name-text)
            (setq tag (cdr name))))

        ;; Step 2: Check regex patterns if no match was found.
        (when (eq tag 'no-tag)
          (dolist (regexp (cdr (assoc :regexps map)))
            (when (string-match-p (car regexp) buffer-name-text)
              (setq tag (cdr regexp)))))

        ;; Step 3: Match by buffer mode if still no match.
        (when (eq tag 'no-tag)
          (dolist (mode (cdr (assoc :modes map)))
            (when (eq buffer-mode (car mode))
              (setq tag (cdr mode)))))

        ;; Return the final tag value in the case where the buffer
        ;; does not begin with a space.
        tag))))


(defun my-window-tools/get-window-for-tag (target-tag frame)
  "Retrieve the first window in FRAME associated with TARGET-TAG.
If no window is found, check for a window with `my-window-tools/default-tag'.
Return the first matching window, or nil if none are found."
  (let ((windows (window-list frame 'no-minibuffer)))
    (or (cl-loop for win in windows
                 when (equal target-tag (window-parameter win 'tag))
                 return win)
        (cl-loop for win in windows
                 when (equal my-window-tools/default-tag
                             (window-parameter win 'tag))
                 return win))))

(defun my-window-tools/move-buffer-to-window (buffer window original-window
                                                     output-only)
  "Assign BUFFER to WINDOW.

if ORIGINAL-WINDOW is the same as WINDOW then the window does not need to be
moved.

If OUTPUT-ONLY is non-nil, only log the target window without moving the
buffer."
  (if output-only
      ;; Log only, do not perform buffer assignment
      (log/debug
       :fn 'my-window-tools/move-buffer-to-window 
       :msg  "Output-only flag is set. No buffer reassignment performed."
       :obj t)
    ;; Check if the buffer is already in the target window
    (if (eq window original-window)
        ;; If so, log a message and do nothing further
        (log/debug
         :fn 'my-window-tools/move-buffer-to-window 
         :msg  "Target window is the buffer's current window. No changes made."
         :obj t)
      ;; Otherwise, assign the buffer to the window and activate necessary modes
      (progn
        ;; Set the buffer in the target window
        (set-window-buffer window buffer)
        ;; Enable tab-line mode for better tab management
        (with-current-buffer buffer (tab-line-mode 1))
        ;; If the buffer was previously in a different window, close it there
        (when original-window
          (my-tab-line/tab-line-close-tab-given-buffer buffer original-window))
        ;; Log the successful assignment
        (log/debug
         :fn 'my-window-tools/move-buffer-to-window 
         :msg  (format "Buffer %s assigned to window %s."
                       (buffer-name buffer) window)
         :obj t)))))

;; ----------------------------------------------------------------------------
;; END OF Buffer assignment to windows
;; ############################################################################



;; (defun my-window-tools/assign-buffer-to-window (buffer &optional output-only)
;;   "Assign BUFFER to the appropriate window based on its purpose.

;; This function assigns the buffer to the window tagged with the appropriate
;; purpose.  If the tag is `no-tag, and the buffer is a system buffer,
;; a message is printed and the buffer is not assigned to any window.  Note that
;; system buffers are matched to a tag using the buffer name directly or via
;; regexp.  Unlike standard buffers, they are not matched by mode.

;; Unmatched buffers that are not system buffers are assigned to the value
;; defined by `my-window-tools/default-tag'.


(defun my-window-tools/find-frame-by-project-root (project-root-of-frame)
  "Find the frame associated with the given PROJECT-ROOT.
PROJECT-ROOT is the root directory of the project to find the frame for."
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
  (set-frame-parameter frame 'project-root project-root))


;; Example usage
;; (my-window-tools/get-buffer-tag (current-buffer))

;;; Usage example:
;; (my-window-tools/add-window some-frame some-window "code")
;; (my-window-tools/add-window some-frame another-window "log")
;; (my-window-tools/set-frame-project-root some-frame "/path/to/project")
;; (my-window-tools/assign-buffer-to-window (get-buffer "some-buffer"))


(defun my-window-tools/show-window-assignment-for-buffer-name (buffer-name)
  "Show the window details that a given buffer will be assigned to.

The function prompts the user for a BUFFER-NAME, retrieves the buffer, and
passes it to `my-window-tools/list-window-tags', where the window tag it
matches is found and returned assuming the map is for the currently selected
frame.  It then returns the tag for the window it matches.  This function is
intended to be useful for checking you have the right assignment being carried
out by the window assignment algorithm here."
  (interactive "BBuffer name: ")
  (let ((buffer (get-buffer buffer-name)))
    (with-current-buffer buffer
      (let ((result (my-window-tools/assign-buffer-to-window buffer t)))
        (if result
            (let ((window (car result)))
              (my-window-tools/list-window-tags window))
          (log/debug
           :fn 'my-window-tools/show-window-assignment-for-buffer-name
      	   :msg  (format
                  "No window assignment found for buffer '%s'"
                  buffer-name)
      	   :obj -1)
          (message
           "No window assignment found for buffer '%s'" buffer-name))))))


(defun my-window-tools/detect-new-non-system-buffer ()
  "Detect if a new non-system buffer has been created and use assignment logic."
  (dolist (buffer (buffer-list))
    ;; Check if the buffer is new and not already in the known list
    (unless (memq buffer my-window-tools/known-buffers)
      ;; Only add non-system buffers to known-buffers
      (when (and (buffer-live-p buffer)
                 (not (string-prefix-p " " (buffer-name buffer))))
        ;; Add to the known-buffers list
        (push buffer my-window-tools/known-buffers)
        ;; Indicate a new buffer has been found
        (log/debug :fn 'my-window-tools/detect-new-non-system-buffer
      	           :msg (format "New buffer %s detected" buffer)
      	           :obj buffer)
        ;; Call the buffer assignment function here
        (my-window-tools/assign-buffer-to-window buffer)))))

(defun my-window-tools/reassign-buffer-to-default-window (buffer frame)
  "This function reassigns a BUFFER to a window in FRAME.
The assignment is made based on finding a property in the window called `tag'.

  It is also removed from the original window and the tab-line is updated."
  (my-window-tools/assign-buffer-to-window buffer frame))


(defun my-window-tools/set-window-purpose (tag)
  "Given a TAG, apply it to the window around the active buffer."
  (interactive
   (list (completing-read
          "Select tag: "
          '("edit" "vc" "terminal" "logs" "config" "data"))))
  (let* ((target-buffer (current-buffer))
         (name-of-buffer (buffer-name target-buffer))
         (current-window (get-buffer-window target-buffer)))
    ;;(my-window-tools/add-window current-window tag)
    (log/debug :fn 'my-window-tools/set-window-purpose
      	       :msg (format "Window on buffer '%s' tagged as '%s'"
                            name-of-buffer tag)
      	       :obj tag)
    ))


(defun my-window-tools/reassign-all-buffers-to-default-windows ()
  "Reassign all buffers in the current frame.

The buffers will be assigned to their default windows, except for the buffer
named *SPEEDBAR*."
  (interactive)
  (dolist (buffer (buffer-list (selected-frame)))
    (unless (string= (buffer-name buffer) "*SPEEDBAR*")
      (my-window-tools/reassign-buffer-to-default-window buffer
                                                         (selected-frame)))))


(defun my-window-tools/reassign-current-buffer-to-default-window ()
  "Reassign the current buffer to its default window.

The reassignment is  based on the buffer's tag.  It will be removed from the
original window, updating the tab-line."
  (interactive)
  (my-window-tools/reassign-buffer-to-default-window (current-buffer)
                                                     (selected-frame)))


(defun my-window-tools/get-window-with-tag (tag &optional frame)
  "Get a window by its TAG.

Utility function takes a TAG and returns the first window object it finds
with that tag in the FRAME provided.  If no FRAME is provided, then the current
selected frame is used.  It is envisioned there will never be more than one
window per tag in each frame."
  (let ((frame (or frame (selected-frame))))
    (catch 'window
      (dolist (win (window-list))
        (when (equal (window-parameter win 'tag) tag)
          (throw 'window win)))
      nil)))


(defun my-window-tools/get-tag-given-window ()
  "Get the tag corresponding to the current window.

Utility function shows the tag associated with the current selected window."
  (interactive)
  (let ((window-tag (window-parameter (selected-window) 'tag)))
    (message "tag: %s" window-tag)
    window-tag))


;; ---------------------------
;; Magit window assignments
;; ---------------------------
;; The two functions below are used to set up magit to open in the vc buffer.
(defun my-window-tools/magit-display-buffer (buffer)
  "Display Magit BUFFER in a window with the tag `vc'."
  (let ((window (my-window-tools/get-window-with-tag 'vc)))
    (if window
        (progn
          (set-window-buffer window buffer)
          window)
      (display-buffer buffer))))

;; ----------------------------------------------------------------------------
;; ASSIGN BUFFERS TO A WINDOW USING display-buffer-alist MECHANISM.


(defun my-window-tools/display-buffer (buffer alist)
  "Display BUFFER in a window based on its tag and the current frame.

ALIST is a dummy variable to make the function conform to the expected
signature."
  (message "found buffer: %s" buffer)
  (let* ((frame (selected-frame))
         (tag (my-window-tools/get-buffer-tag-or-default buffer frame))
         (window (and tag (my-window-tools/get-window-for-tag tag frame)))
         (original-window (get-buffer-window buffer))
         (original-frame (window-frame original-window)))
    (cond
     ;; Whitelisted buffer; do not interfere.
     ((not tag)
      nil)
     ;; Display in the window matching the tag.
     ((and window (window-live-p window))
      (set-window-buffer window buffer)
      (when (and original-window (not (eq original-window window)))
        (with-selected-window original-window
          (quit-window)))
      window)
     ;; No matching window; fall back to default.
     (t
      nil))))


;;;; Other window tools
;;   ------------------

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
    (when (and (windowp window)  ; Checks if the target is a window.
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
      (erase-buffer)  ; Clear the previous contents
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
  "List all tags (parameters) for the given WINDOW."
  (let ((params (window-parameters window)))
    (mapcar (lambda (param)
              (message "Tag: %s, Value: %s" (car param) (cdr param)))
            params)))

(defun my-window-tools/select-window-by-name (name)
  "Select the window with a custom `\'name' parameter matching NAME."
  (let ((target-window (my-window-tools/find-window-by-name name)))
    (when target-window
      (select-window target-window))))

(defun my-window-tools/set-current-window-tag (tag-name)
  "Set a TAG-NAME for the current active window.

The tag name must be one of `my-window-tools/tag-list`."
  (interactive
   (list (completing-read "Select tag: " my-window-tools/tag-list nil t)))
  (let ((window-to-tag (selected-window)))
    (set-window-parameter window-to-tag 'tag tag-name)
    ;; (my-window-tools/add-window window-to-tag tag-name)
    (get-buffer-create (symbol-name tag-name))
    (with-current-buffer (symbol-name tag-name) (tab-line-mode 1))))


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



;;;; Configure display-buffer-alist
;;   ------------------------------
;; the below object controls how new buffers are assigned to windows in Emacs.
;; This is central to managing the relationship between buffers and windows.
(setq display-buffer-alist
      `(;; Rule for *Dictionary* and *Ilist* buffers
        ;; (Show Ilist or dictionary definition on the left)
        ("^\\*\\(Dictionary\\|Ilist\\)\\*"
         (display-buffer-in-side-window)
         (side . right)
         (window-width . 50)                                                      ; change to 0.5 to make it half the size of the buffer it is next to.
         (window-parameters . ((no-delete-other-windows . t))))

        
        ;; General rule using your custom function
        (".*" . (my-window-tools/display-buffer))))

(provide 'system-window-management)

;;; system-window-management.el ends here

                                                                                  ; LocalWords:  Customize vc repl
                                                                                  ; LocalWords:  elisp
                                                                                  ; LocalWords:  tabline
                                                                                  ; LocalWords:  defun
                                                                                  ; LocalWords:  eldoc
