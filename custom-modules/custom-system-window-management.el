;;; custom-system-window-management.el --- Window management for multi-project IDE -*- mode: emacs-lisp; lexical-binding: t; -*-

;;; License
;; Copyright (C) 2022
;; SPDX-License-Identifier: MIT

;; Author: Simon Watson

;;; Commentary:
;; This script provides a mechanism for managing windows in Emacs, supporting
;; multiple projects each in different frames. It uses a hash table to store
;; window references keyed by a combination of frame and window tags, allowing
;; efficient matching of buffers to the appropriate frame and window.
;;
;; Summary: Objects and Their Intended Workflows
;; ---------------------------------------------
;; 2. my-window-tools/add-window:
;; Adds a window to the hash table with the given frame and window tag.
;; Used in the workflow for storing windows.
;;
;; 4. my-window-tools/get-project-root:
;; Retrieves the project root directory for a buffer.
;; Used for matching buffers to frames based on project roots.
;;
;; 5. my-window-tools/buffer-project-root:
;; Gets the project root or default directory for a buffer.
;; Used for determining the appropriate frame for a buffer.
;;
;; 6. my-window-tools/assign-buffer-to-window:
;; Assigns a buffer to the appropriate window based on its project root or
;; origin.
;; Used in the workflow for assigning buffers.
;;
;; 7. my-window-tools/find-frame-by-project-root:
;; Finds the frame associated with a given project root.
;; Used for matching buffers to frames.
;;
;; 8. my-window-tools/frame-project-root:
;; Retrieves the project root associated with a frame.
;; Used for finding the correct frame for a buffer.
;;
;; 9. my-window-tools/set-frame-project-root:
;; Sets the project root for a frame.
;; Used for setting up frames with the correct project root.
;;
;; 10. my-window-tools/get-buffer-tag:
;; Placeholder function to get the tag associated with the current buffer.
;; Used for determining the buffer tag for assignment purposes.
;;
;;
;; Workflows:
;; ----------
;; 1. Storing a Window with a Tag in the Hash Table as It Is Created
;; Function: my-window-tools/add-window
;; Steps:
;;     Create the Window:
;;         When a window is created, determine its frame and the tag that
;;         describes its purpose.
;;     Store in Hash Table:
;;         Use the my-window-tools/add-window function to store the window
;;         reference in the hash table with the generated key.
;;
;; 2. Removing a Window from the Hash Table When It Is Removed
;; Function: my-window-tools/remove-window
;; Steps:
;;     Identify the Window:
;;         Determine the frame and tag of the window being removed.
;;     Generate the Key:
;;         Use the my-window-tools/generate-key function to create the unique
;;         key.
;;     Remove from Hash Table:
;;         Remove the window reference from the hash table.
;;
;; 3. Assigning a New Buffer to a Window as It Is Created
;; Function: my-window-tools/assign-buffer-to-window
;; Steps:
;;     Determine Buffer Tag:
;;         Determine the tag associated with the buffer. This is done using
;;         the my-get-buffer-tag function.
;;     Find the Appropriate Frame:
;;         Determine the frame based on the buffer's project root or the frame
;;         from which it was called. Use my-buffer-project-root and
;;         my-find-frame-by-project-root.
;;     Generate the Key:
;;         Use the my-window-tools/generate-key function to create a unique
;;         key using the frame and buffer tag.
;;     Assign Buffer to Window:
;;         Use my-window-tools/assign-buffer-to-window to assign the buffer to
;;         the appropriate window.
;;
(require 'custom-system-objects)
(require 'custom-ui-config)
;;; Code:

(defvar my-window-tools/buffer-window-map
  '((:names   . (("*scratch*" . terminal)
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
                 ("*Crafted Emacs*" . edit)
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
                 ("*straight-byte-compilation*" . logs)
                 ("*projectile-files-errors*". logs)
                 ("*Async-native-compile-log*". logs)
                 ("*elisp-flymake-byte-compile*" . logs)
                 ("*Anaconda*". config)
                 ("conf.org" . config)
                 ("*eldoc*" . config)
                 ("*EGLOT workspace configuration*" . config)
                 ("*Help*" . config)
                 ("*info*" . config)
                 ("todos.org" . config)
                 (".gitignore" . vc)))
    (:regexps . (("^documentation$" . config)     ; exact match for `documentation'
                 ("^README.*" . config)           ; strings beginning upper or lower case `README'.
                 (".*\\.conf$" . config)          ; any number of characters followed by `.conf'.
                 (".*\\.dconf$" . config)         ; any number of characters followed by `.dconf'.
                 ("^\\*Customize.*" . config)     ; strings beginning with `*Customize' followed by any characters.
                 ("^magit.*" . vc)                ; strings beginning with `magit' followed by any characters.
                 ("^vc-.*" . vc)                  ; strings beginning with `vc' followed by any characters.
                 (".*Annotate .*" . vc)           ; strings with `Annotate\ ' somewhere in them. 
                 (".*ede-proj.*" . vc)            ; strings with `ede-proj'  somewhere in them. 
                 ("^\\*Flymake diagnostics.*"
                  . data)                         ; strings beginning with `Flymake-diagnostics' followed by any characters.
                 ("^flymake-*" . data)            ; strings beginning `flymake'.
                 (".*cell sheet.*" . data)        ; strings containing `cell\ sheet'.
                 ("^magit-process:*" . logs)      ; strings beginning `magit-process:'.
                 ("^\\*EGLOT.*" . logs)           ; strings beginning `*EGLOT'. 
                 (".*+sterr$" . logs)             ; strings ending `+sterr'. 
                 (".*\\.log" . logs)              ; strings ending `.log'. 
                 (".*-log.*" . logs)              ; strings with `-log' in them. 
                 (".*tramp.*" . logs)             ; strings with `tramp' in them.
                 ("^\\*ielm*" . terminal)         ; strings beginning `*ielm'.
                 ("^q-.*" . terminal)))           ; strings beginning `q-'. 
    (:modes   . ((vterm-mode . terminal)
                 (eshell-mode . terminal)
                 (shell-mode . terminal)
                 (term-mode . terminal)
                 (dired-mode . terminal)
                 (ielm-mode . terminal)
                 (calendar-mode . data)
                 (diary-mode . data)
                 (clojure-mode . edit)
                 (lisp-mode . edit)
                 (python-mode . edit)
                 (q-mode . edit)
                 (rust-mode . edit)
                 (scheme-mode . edit)
                 (systemd-mode . config)
                 (toml-mode . config)
                 (XML-mode . config)
                 (nXML-mode . config)
                 (json-mode . config)
                 (org-mode . config)
                 (csv-mode . config)
                 (ibuffer-mode . config)
                 (bufler-list-mode . config)
                 (bookmark-menu . config)
                 (imenu-list-mode . config)
                 (help-mode . config)
                 (helpful-mode . config)
                 (compilation-mode . logs)
                 (debugger-mode . logs)))
    )
  )


;; Preserve existing elements in display-buffer-alist
;; and append rules for the *Messages* and *Backtrace* buffers.
(add-to-list 'display-buffer-alist
             '("^\\*Messages\\*"
               (display-buffer-reuse-window
                display-buffer-pop-up-window)
               (inhibit-same-window . t)
               (window-height . 0.3)))

(add-to-list 'display-buffer-alist
             '("^\\*Backtrace\\*"
               (display-buffer-reuse-window
                display-buffer-pop-up-window)
               (inhibit-same-window . t)
               (window-height . 0.3)))


(defvar my-window-tools/window-hash (make-hash-table :test 'equal)
  "Hash table to store window references keyed by window-tag.")


(defvar my-window-tools/known-buffers nil
  "List of buffers known to the system. Used to detect newly created buffers.")

(defconst my-window-tools/default-tag 'edit
  "The default tag assigned to non-system buffers when no tag is found. ")


(defun my-window-tools/add-window (window window-tag)
  "Add WINDOW with WINDOW-TAG to the hash table.
FRAME is the frame in which the window resides.
WINDOW is the window to be added.
WINDOW-TAG is the tag describing the window's purpose."
  (let ((key window-tag))
    (message "Adding window with key: %s" key) ; Add this line
    (puthash key window my-window-tools/window-hash)))


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


(defun my-window-tools/assign-buffer-to-window (buffer &optional output-only)
  "Assign BUFFER to the appropriate window based on its purpose.

This function assigns the buffer to the window tagged with the
appropriate purpose. If the tag is `no-tag, and the buffer is a system buffer,
a message is printed and the buffer is not assigned to any window. Note that
system buffers are matched to a tag using the buffer name directly or via
regexp. Unlike standard buffers, they are not matched by mode.  

Unmatched buffers that are not system buffers are assigned to the value
defined by `my-window-tools/default-tag'.

If no window with the required tag exists, it is created. "
  
  (let*
      (
       (buffer-name (buffer-name buffer))
       (special-buffers '("*Messages*" "*Backtrace*"))
       (tag
        (with-current-buffer buffer
          (my-window-tools/get-buffer-tag buffer)))
       (original-window (get-buffer-window buffer)))

    (if (member buffer-name special-buffers)
        ;; if the buffer is one of the listed special buffers, 
        (let ((target-window (gethash tag my-window-tools/window-hash)))
          (when (window-live-p target-window)
            (set-window-buffer target-window buffer)))
      
      (if tag
          (progn
            (message "Tag for the buffer is: %s" tag)
            ;; If the tag is 'no-tag, check if it is a system buffer and if so, leave
            ;; it unassigned. Otherwise, assign it to the default tag in 
            ;; my-window-tools/default-tag.
            (if (eq tag 'no-tag)
                (if (string-prefix-p "*" (buffer-name buffer))
                    (message
                     "No suitable tag found for system buffer %s. Not assigning to any window."
                     (buffer-name buffer))
                  (progn
                    (setq tag my-window-tools/default-tag)
                    (message
                     "Buffer %s assigned to default tab '%s. "
                     (buffer-name buffer) my-window-tools/default-tag))))
            
            ;; If a tag was found, assign the buffer to the first window with that
            ;; tag. 
            (let* ((key tag)
                   (window (gethash key my-window-tools/window-hash)))
              
              ;; Check if a window was found and if that window is live
              (if window
                  (progn
                    (message "Found window %s in look-ups with tag %s." window key)
                    (if (window-live-p window)
                        (progn
                          (message "Window is live, assigning buffer.")
                          ;; don't assign the buffer to a window if it is being
                          ;; 'moved' from that window. 
                          (if (eq window original-window)
                              (message "Target window is the window the buffer is in. No changes made.")
                            (progn
                              (message
                               "Using set-window-buffer with buffer %s and window %s"
                               buffer window)
                              (if (not output-only)                            ; output only is the flag determining if the buffer is moved according to the tag or whether the point is simply to find the relevant tag. 
                                  (progn
                                    (set-window-buffer window buffer)
                                    (with-current-buffer buffer (tab-line-mode 1))
                                    (if original-window
                                        (my-tab-line/tab-line-close-tab-given-buffer
                                         buffer original-window)))
                                
                                (message
                                 "Function set for message output-only. No changes made.")
                                )))
                          )
                      
                      (message
                       "Window in look-ups is no longer live. No assignment made.")))
                (message
                 "No window found in look-ups with tag %s. No assignment made." key)
                )))
        (message "The buffer is a system buffer and didn't match to a tag.
No assignment made.")
        ))))


(defun my-window-tools/find-frame-by-project-root (project-root)
  "Find the frame associated with the given PROJECT-ROOT.
PROJECT-ROOT is the root directory of the project to find the frame for."
  (catch 'found
    (dolist (frame (frame-list))
      (when (string= (my-window-tools/frame-project-root frame) project-root)
        (throw 'found frame)))))


(defun my-window-tools/frame-project-root (frame)
  "Get the project root associated with FRAME."
  (frame-parameter frame 'project-root))

(defun my-window-tools/set-frame-project-root (frame project-root)
  "Set the project root for FRAME to PROJECT-ROOT.

This parameter is used to identify the frame corresponding to a particular
project."
  (set-frame-parameter frame 'project-root project-root))


(defun my-window-tools/get-buffer-tag (buffer)
  "Get the tag for the given BUFFER.

Return `nil' if the buffer is a system buffer without a match by name or
regexp. Return `no-tag' if the buffer is not a system buffer but isn't matched
by name, regexp or mode.

 The process works as follows:
 1. Checks the buffer's name against the `:names' in
    `my-window-tools/buffer-window-map'. If a match is found, it is returned
    in `tag'.
 2. Checks the buffer's name against the regex patterns in `:regexps' and
 3. Checks if the buffer is a system buffer (name starts with `*'). If not,
    check for a match on buffer mode against `:modes'.
 4. Returns `no-tag' if no matches are found in any of the checks.
    (Recall system buffers are not matched to a tag by mode.)"

  (let ((buffer-name (buffer-name buffer))
        (buffer-mode (buffer-local-value 'major-mode buffer))
        (map my-window-tools/buffer-window-map)
        tag)

    (message "Buffer name: %s" buffer-name)

    ;; Step 1: check for match by buffer name.
    (dolist (name (cdr (assoc :names map)))
      (when (string-match-p (car name) buffer-name)
        (message "Found by name: %s" (cdr name))
        (setq tag (cdr name))))

    ;; Step 2: Check regexps if no match found in names
    (unless tag
      (dolist (regexp (cdr (assoc :regexps map)))
        (when (string-match-p (car regexp) buffer-name)
          (message "Found by regexp: %s" (cdr regexp))
          (setq tag (cdr regexp)))))

    ;; Step 3: If it's not a system buffer, check for match by buffer mode.
    (unless tag
      (if (not (string-prefix-p "*" buffer-name))
          (dolist (mode (cdr (assoc :modes map)))
            (when (eq buffer-mode (car mode))
              (message "Found by mode: %s" (cdr mode))
              (setq tag (cdr mode))))))

    ;; Step 4: Return 'no-tag if no match found
    (unless tag
      (setq tag 'no-tag))

    ;; Return the final tag value
    tag))


;; Example usage
;; (my-window-tools/get-buffer-tag (current-buffer))

;;; Usage example:
;; (my-window-tools/add-window some-frame some-window "code")
;; (my-window-tools/add-window some-frame another-window "log")
;; (my-window-tools/set-frame-project-root some-frame "/path/to/project")
;; (my-window-tools/assign-buffer-to-window (get-buffer "some-buffer"))

(defun my-window-tools/show-window-assignment-for-buffer-name (buffer-name)
  "Show the window assignment tag for a buffer given its BUFFER-NAME.

The function prompts the user for a buffer name, retrieves the buffer, and
passes it to `my-window-tools/get-buffer-tag`, returning the tag it produces.
It is handy for checking you have the right assignment being carried out by
the window assignment algorithm here. "
  (interactive "BBuffer name: ")
  (let ((buffer (get-buffer buffer-name)))
    (with-current-buffer buffer
      (my-window-tools/assign-buffer-to-window buffer t))
    )
  )


(defun my-window-tools/detect-new-buffer ()
  "Detect if a new buffer has been created and trigger assignment logic."
  (let ((current-buffers (buffer-list)))
    ;; Compare current buffers to known buffers to detect new ones
    (dolist (buffer current-buffers)
      (unless (memq buffer my-window-tools/known-buffers)
        (message "new buffer %s detected" buffer)
        ;; Update the known buffers list as soon as a new buffer is detected
        (setq my-window-tools/known-buffers current-buffers)
        ;; Ensure the buffer is live and not internal (starting with a space)
        (when (and (buffer-live-p buffer)
                   (not (string-prefix-p " " (buffer-name buffer))))
          ;; Call the buffer assignment function here
          (my-window-tools/assign-buffer-to-window buffer))))))

(defun my-window-tools/reassign-buffer-to-default-window (buffer)
  "Reassign BUFFER to its default window based on the buffer's tag,
  remove it from the original window, and update the tab-line."
  (my-window-tools/assign-buffer-to-window buffer))

(defun my-window-tools/set-window-purpose (tag)
  "Given a TAG, apply it to the window around the active buffer."
  (interactive
   (list (completing-read
          "Select tag: "
          '("edit" "vc" "terminal" "logs" "config" "data"))))
  (let* ((target-buffer (current-buffer))
         (name-of-buffer (buffer-name target-buffer))
         (current-window (get-buffer-window target-buffer)))
    (my-window-tools/add-window current-window tag)
    (message "Window on buffer '%s' tagged as '%s'" name-of-buffer tag)))

(defun my-window-tools/reassign-all-buffers-to-default-windows ()
  "Reassign all buffers in the current frame to their default windows,
  except for the buffer named *SPEEDBAR*."
  (interactive)
  (dolist (buffer (buffer-list (selected-frame)))
    (unless (string= (buffer-name buffer) "*SPEEDBAR*")
      (my-window-tools/reassign-buffer-to-default-window buffer))))


(defun my-window-tools/reassign-current-buffer-to-default-window ()
  "Reassign the current buffer to its default window based on the buffer's tag
and remove it from the original window, updating the tab-line."
  (interactive)
  (my-window-tools/reassign-buffer-to-default-window (current-buffer)))


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

(defun my-window-tools/get-window-with-tag (tag)
  "Get a window by its tag.

Utility function takes a TAG and returns the first window object it finds
with that tag. It is envisioned there will never be more than one window
per tag."
  (catch 'window
    (dolist (win (window-list))
      (when (equal (window-parameter win 'tag) tag)
        (throw 'window win)))
    nil))


(defun my-window-tools/get-tag-given-window ()
  "Get the tag corresponding to the current window.

Utility function shows the tag associated with the current selected window. "
  (let ((current-window (selected-window)))
    (catch 'tag
      (maphash (lambda (key value)
                 (when (equal value current-window)
                   (throw 'tag key)))
               my-window-tools/window-hash)
      nil))) 


;; ----------------------------------------------------------------------------
;; BELOW FUNCTIONS ARE ALTERNATIVES TO ASSIGNING A BUFFER TO A WINDOW (IN
;; THIS CASE USING THE display-buffer-alist MECHANISM.)

;; (defun my-ui/display-buffer (buffer alist)
;;   "Display BUFFER in the appropriate window based on the configuration map."
;;   (let ((window (my-ui/find-window-for-buffer buffer)))
;;     (if window
;;         (set-window-buffer window buffer)
;;       (display-buffer buffer alist))))


;; ;; Override display-buffer to use the custom display function
;; (setq display-buffer-alist
;;       '((".*" . (my-ui/display-buffer . nil))))
;; ----------------------------------------------------------------------------

(provide 'custom-system-window-management)

;;; custom-system-window-management.el ends here

                                        ; LocalWords:  Customize
