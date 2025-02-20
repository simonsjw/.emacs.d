;;; system-tools.el --- useful functionality for emacs -*- mode: emacs-lisp; lexical-binding: t; -*-

;;; License
;; Copyright (C) 2022
;; SPDX-License-Identifier: MIT

;; Author: Simon Watson

;;; Commentary:

;; This file contains code to make additional functionality available for user
;; functions and external modules written in Emacs.  Some of this
;; functionality may be built by creating an Emacs wrapper to use underlying
;; system tools.

;; current known dependencies:
;; ss - a port scanning tool replacing netstat.


;;; Code:
(defvar ispell-dictionary)
(defvar org-link-abbrev-alist)
(declare-function speedbar-refresh "speedbar")

(declare-function sr-speedbar-exist-p "sr-speedbar")
(declare-function sr-speedbar-open "sr-speedbar")
(declare-function sr-speedbar-refresh "sr-speedbar")
(declare-function image-supported-file-p "image")

(declare-function org-link-abbrev-alist "ol")

(declare-function dired-get-file-for-visit "dired")

;;;; Emacs Lisp logging helpers

;; Define an advice function to be used for implicit logging.
(defun my-log/advice (log-message &rest args)
  "Log the a LOG-MESSAGE of any function by wrapping with an advice.
Additional ARGS are captured in a secondary field."
  (let ((feature (car args)))
    (log/info :fn 'init
              :msg (concat log-message (symbol-name feature))
              :obj (cdr args))))

;; Add the advice to the `provide' function if required by settings
;; from log/log-table.
(if (eq  t
         (plist-get (log/get-log-type-by-index log/type-special-form-provide)
                    :active))
    (advice-add
     'provide
     :before (lambda (&rest args)
               (apply 'my-log/advice "provide: " args))))

(if (eq  t
         (plist-get (log/get-log-type-by-index log/type-function-message)
                    :active))
    (advice-add
     'message
     :before (lambda (&rest args)
               (apply 'my-log/advice "message: " args))))

;; Add the advice to the `use-package' function if required by settings
;; from log/log-table.
(if (eq  t
         (plist-get (log/get-log-type-by-index log/type-macro-use-package)
                    :active))
    (advice-add
     'use-package
     :before (lambda (&rest args)
               (apply 'my-log/advice "use-package: " args))))

;;;; Hash table management

;; utility for creating a hash table.
(defun my-hash-tools/define-hash-table
    (table-name cons-list &optional idx-name item-name)
  "Define a hash table and populate it with records.

TABLE-NAME is the name of the hash table to be created.
CONS-LIST is a list of cons cells, where the car of each cons cell is the index
and the cdr is a list of item data.
IDX-NAME and ITEM-NAME are optional names for the hash table columns.
If not supplied, the default names `idx' and `item' are used."
  (let ((idx-column (or idx-name :idx))
        (item-column (or item-name :item)))
    (set table-name (make-hash-table :test 'equal))
    (dolist (log cons-list)
      (let ((idx (car log))
            (item (cdr log)))
        (puthash idx
                 (list idx-column idx item-column (cadr item) :active nil)
                 (symbol-value table-name))))))

;; end of hash table management
;; ---------------------------


;;;; Dired tools

(defun my-interactive-tools/select-directory-using-dired ()
  "Open a Dired buffer for directory selection and return the selected path."
  (interactive)
  (let ((selected-dir (dired-get-file-for-visit)))
    (if (file-directory-p selected-dir) ;; Check if it's a directory
        selected-dir
      (user-error "Not a directory"))))

;; end of Dired tools.
;; -------------------


;;;; Image processing

(defun my-image-tools/create-image-icon (file &optional width height)
  "Create an image icon from FILE with optional WIDTH and HEIGHT."
  (let* ((type (image-supported-file-p file))  ; Automatically detect image type
         (image (create-image file type nil
                              :width width
                              :height height)))
    (if image
        (propertize " " 'display image)
      (message "Image creation failed for file: %s" file)
      "")))
;; end of Image processing
;; -----------------------


;;;; String processing

(defun my-strings/ensure-directory-path (path)
  "Ensure the directory PATH ends with a '/'."
  (if (string-suffix-p "/" path)
      path
    (concat path "/")))

(defun my-strings/current-time-with-milliseconds ()
  "Return the current time as a string with millisecond precision."
  (let*
      ((now (current-time))
       (seconds
        (float-time now))  ; Get the time as a floating-point number
       (milliseconds
        (truncate
         (mod (* seconds 1) 1000)  ))  ; Extract milliseconds
       (time-in-seconds
        (format-time-string
         "%Y-%m-%d %H:%M:%S" now)))  ; Get the standard time
    (format "%s.%03d"
            time-in-seconds   ; Get the formatted time
            milliseconds)))  ; Add milliseconds


(defun my-strings/human-readable-file-sizes-to-bytes (string)
  "Convert a human-readable file size so it is expressed in units of bytes.

The original number and the output are encoded as STRING..
This is the companion of `my-strings/bytes-to-human-readable-file-sizes', a
function which converts a given amount of bytes into a human readable size as
a STRING."
  (interactive)
  (cond
   ((string-suffix-p "G" string t)
    (* 1000000000
       (string-to-number (substring string 0 (- (length string) 1)))))
   ((string-suffix-p "M" string t)
    (* 1000000
       (string-to-number (substring string 0 (- (length string) 1)))))
   ((string-suffix-p "K" string t)
    (* 1000
       (string-to-number (substring string 0 (- (length string) 1)))))
   (t
    (string-to-number string )))
  )


(cl-defun my-strings/number-to-human-readable-string (number &optional (sigfigs 4) (prec 2) (strlength -1))
  "Convert NUMBER to human-readable string.

The NUMBER will have SIGFIGS significant figures to a precision of PREC if it is
small enough to fit in the allowed significant figures.

If STRLENGTH is a positive number, then white-space will be used to ensure a cc
minimum of that length string is returned with a letter at the end for large
numbers or else a space so the units column is aligned."
  (interactive)
  (let ((result
         (cond
          ((> number 1000000000) (format "%10.1fG" (/ number 1000000000.0)))
          ((> number 100000000) (format "%10.0fM" (/ number 1000000.0)))
          ((> number 1000000) (format "%10.1fM" (/ number 1000000.0)))
          ((> number 100000) (format "%10.0fk" (/ number 1000.0)))
          ((> number 1000) (format "%10.1fk" (/ number 1000.0)))
          (t (format "%10f" number)))))  ;; Raw number case
    (if (= (length result) 10)
        (concat result " ")                                                       ; Append space to make length 11
      result)))                                                                   ; Otherwise, return as is


(defun my-strings/bytes-to-human-readable-file-sizes (bytes)
  "Convert number of BYTES to human-readable file size.
Ensures the result is always of length 5 by adding a space if no unit is
present."
  (interactive)
  (let ((result
         (cond
          ((> bytes 1000000000) (format "%5.1fG" (/ bytes 1000000000.0)))
          ((> bytes 100000000) (format "%5.0fM" (/ bytes 1000000.0)))
          ((> bytes 1000000) (format "%5.1fM" (/ bytes 1000000.0)))
          ((> bytes 100000) (format "%5.0fk" (/ bytes 1000.0)))
          ((> bytes 1000) (format "%5.1fk" (/ bytes 1000.0)))
          (t (format "%4d" bytes)))))  ;; Raw bytes case
    (if (= (length result) 4)
        (concat " "  result)                                                      ; Append space to make length 11
      result)))                                                                   ; Otherwise, return as is


;; end of String processing
;; ---------------------------


;;;; Frame management

(defun my-frame-tools/delete-frame-by-name (frame-name)
  "Delete a frame by its name FRAME-NAME."
  (interactive "sEnter frame name to delete: ")  ; Prompt for frame name
  (let ((found nil))  ; Track if we found the frame
    (dolist (frame (frame-list))
      (when (string= (frame-parameter frame 'name) frame-name)
        (delete-frame frame)
        (setq found t)
        (message "Deleted frame named '%s'." frame-name)))
    (unless found
      (message "No frame named '%s' found." frame-name))))

(defun my-frame-tools/get-frame-by-name (frame-name)
  "Get a frame object when given its name FRAME-NAME."
  (defvar frame-object nil)
  (let ((found nil))  ; Track if we found the frame
    (dolist (frame (frame-list))
      (when (string= (frame-parameter frame 'name) frame-name)

        (setq found t)
        (setq frame-object frame)
        (message "found frame named '%s'." frame-name)))
    (unless found
      (message "No frame named '%s' found." frame-name))
    frame-object))


(defun my-frame-tools/set-current-frame-name (name)
  "Set the name of the current frame to NAME."
  (interactive "sEnter new frame name: ")                                         ; Prompt for the frame name interactively
  (set-frame-name name))


(defun my-frame-tools/close-all-windows-except-first (&optional frame)
  "Close all windows in FRAME except the first window.
If FRAME is nil, use the current frame."
  (let* ((target-frame (or frame (selected-frame)))
         (first-window (frame-first-window target-frame)))
    (select-window first-window) ; Select the first window
    (with-selected-frame target-frame
      (delete-other-windows)))) ; Close all other windows


;; end of Frame management
;; -----------------------


;;;; BUFFER management

(defun my-buffer-tools/show-buffer-from-first-line (buffer)
  "Show BUFFER starting from the first line."
  (when (buffer-live-p buffer)                                                    ; Ensure the buffer exists
    (with-current-buffer buffer
      (goto-char (point-min))                                                     ; Move point to the beginning of the buffer
      (set-window-start (get-buffer-window buffer) (point-min)))))

(defun my-buffer-tools/resize-window-vertically (buffer pct)
  "Resize the window displaying BUFFER by increasing its height by PCT.

Note that a 30% resize would be a pct of 0.3."
  (let* ((window (get-buffer-window buffer))
         (current-height (window-height window))
         (resize-amount (round (* current-height pct))))                          ; Calculate PCT% increase
    (if window
        (window-resize window resize-amount t)                                    ; Resize vertically (t = vertical)
      (message
       "Buffer %s is not displayed in any window" (buffer-name buffer)))))

(defun my-buffer-tools/open-temp-buffer (&optional buffer-name)
  "Open a temporary buffer, optionally naming it BUFFER-NAME.
If BUFFER-NAME is nil, the default name '*temp*' is used.
The buffer object is returned."
  (interactive "sEnter buffer name (default: *temp*): ")
  
  (let ((buffer (generate-new-buffer (or (and (not (string-empty-p buffer-name)) buffer-name)
                                         "*temp*"))))
    (switch-to-buffer buffer)
    buffer))

(defun my-buffer-tools/open-temp-org-buffer (&optional buffer-name)
  "Open a temporary `org-mode' buffer, optionally naming it BUFFER-NAME.
If BUFFER-NAME is nil, the default name '*temp-org*' is used.
The buffer object is returned."
  (interactive "sEnter buffer name (default: *temp-org*): ")
  
  (let ((buffer (generate-new-buffer (or (and (not (string-empty-p buffer-name)) buffer-name)
                                         "*temp-org*"))))
    (with-current-buffer buffer
      (org-mode))
    (switch-to-buffer buffer)
    buffer))


(global-set-key (kbd "C-c t") 'my-buffer-tools/open-temp-org-buffer)


(defun my-buffer-tools/switch-to-buffer-in-current-window (buffer-name)
  "Switch to BUFFER-NAME in the current window if it's present."
  (let ((buffer (get-buffer buffer-name)))
    (when buffer
      (set-window-buffer (selected-window) buffer))))

(defun my-buffer-tools/safe-kill-buffer (buffer-name)
  "Kill the buffer named BUFFER-NAME if it exists.

This function kills a buffer after checking it exists.
If the buffer does not exist, no action is taken and no error is raised.

BUFFER-NAME: The name of the buffer to be killed, as a string."
  (interactive "sEnter buffer name to kill: ")
  (let ((buffer (get-buffer buffer-name)))
    (when buffer
      (kill-buffer buffer))))

(defun my-buffer-tools/concatSortedDistinctList (listA listB)
  "Provide a distinct, sorted list given two lists.
LISTA: the first list
LISTB: the second list"
  (let ((merged (append listA listB)))
    (delete-dups (sort merged 'string<))))

(defun my-buffer-tools/append-string-to-file (message file-path)
  "Write a message to file, creating or appending as necessary.
MESSAGE:    A string to be appended to the file (string).
FILE-PATH:  A path to a file (string)"
  (with-temp-buffer
    (insert message "\n")
    (append-to-file (point-min) (point-max) file-path)))

(defun my-buffer-tools/keyboard-escape-quit ()
  "Exit the current \"mode\" (in a generalized sense of the word).
This command can exit an interactive command such as `query-replace', can
clear out a prefix argument or a region, can get out of the minibuffer or
other recursive edit or cancel the use of the current buffer for
special-purpose buffers.

Unlike the original built in function, it will not go back to just one window
by deleting all but the selected window. Loading it after the original has the
effect of overwriting it, removing this functionality.

If you want an Emacs frame with a single window, consider using
`tear-off-window'

This condition and body have been removed:
        ((not (one-window-p t))  (delete-other-windows))"
  (interactive)
  (cond
   ((eq last-command 'mode-exited) nil)
   ((region-active-p)  (deactivate-mark))
   ((> (minibuffer-depth) 0) (abort-recursive-edit))
   (current-prefix-arg  nil)
   ((> (recursion-depth) 0) (exit-recursive-edit))
   (buffer-quit-function (funcall buffer-quit-function))
   ((string-match "^ \\*" (buffer-name (current-buffer))) (bury-buffer))))

(defalias 'keyboard-escape-quit 'my-buffer-tools/keyboard-escape-quit
  "Use my-tools/keyboard-escape-quit to escape without wrecking the UI layout.")


(defun my-buffer-tools/copy-buffer-in-new-frame (click)
"Copy the active buffer in a selected window to a new frame.
CLICK: the mouse event."
(interactive (list last-nonmenu-event))                                         ; Enable the function to handle a mouse event.
(message "triggered")                                                           ; Give feedback when function is triggered.
(mouse-minibuffer-check click)                                                  ; Prevent triggering if click is in the minibuffer.
(let* ((window (posn-window (event-start click)))                               ; Get the window where click occurred.
       (buf (window-buffer window))                                             ; Get the buffer from that window.
       (display-buffer-alist '(("." (display-buffer-pop-up-frame)))))           ; Temporarily add the new frame rule to `display-buffer-alist`.

  (message "Selected window: %s" window)                                        ; Display selected window as feedback.
  (display-buffer buf)))                                                        ; Display the buffer in a new frame.


;; Define the customizable variable at the top level
(defcustom my-buffer-attributes nil
  "The attributes associated with the buffer."
  :local t
  :type '(alist :key-type symbol :value-type sexp)
  :group 'my-system-objects)


(defun my-buffer-tools/set-buffer-attribute (buffer attribute value)
  "Set an ATTRIBUTE with VALUE for the given BUFFER."
  (with-current-buffer buffer
    (setq my-buffer-attributes
          (assoc-delete-all attribute my-buffer-attributes))
    (add-to-list 'my-buffer-attributes (cons attribute value))))

(defun my-buffer-tools/get-buffer-attribute (buffer attribute)
  "Given a BUFFER, get the value of ATTRIBUTE for it."
  (with-current-buffer buffer
    (cdr (assoc attribute my-buffer-attributes))))

(defun my-buffer-tools/get-window-with-tag (tag)
  "Get a window by its TAG.
Used with my-buffer-tools/display-given-buffer to provide functionality to
my-buffer-tools/display-buffer-by-name-and-tag"
  (catch 'window
    (dolist (win (window-list))
      (when (equal (window-parameter win 'tag) tag)
        (throw 'window win)))
    nil))

;;;; TOOLS FOR USE IN BUFFER

(defun my-buffer-tools/insert-blank-line-at-start ()
  "Insert a blank line at the start of the current buffer, even if it's read-only."
  (let ((inhibit-read-only t))       ; Temporarily disable read-only mode
    (save-excursion                 ; Preserve point position
      (goto-char (point-min))       ; Move to the start of the buffer
      (open-line 1))))              ; Insert a blank line


(defun my-in-buffer-tools/get-matching-bracket-position (cursor-position)
  "Given a bracket at point in a buffer, return the matching bracket position.

Details returned are in a list containing line, column, absolute position, and
the matching bracket character.

The point (CURSOR-POSITION) can be on or next to a bracket to return.  If the
point is between two brackets, the match of the following bracket will be
returned.  Note that behavior is different from `show-paren-mode' since it will
attempt to match brackets found on a position next to the cursor as well as
at the cursor.

Returns a list containing the line number, column number, absolute buffer
position, and the matching bracket character if found, otherwise returns nil."
  (let ((direction
         (cond
          ;; If the character is an opening bracket, look forward
          ((member (char-after cursor-position) '(?\( ?\[ ?\{)) 1)
          ;; If the character is a closing bracket, look backward
          ((member (char-after cursor-position) '(?\) ?\] ?\})) -1)
          ;; If the cursor is immediately before an opening bracket
          ((member (char-after (+ cursor-position 1)) '(?\( ?\[ ?\{)) 1)
          ;; If the cursor is immediately after a closing bracket
          ((member (char-before cursor-position) '(?\) ?\] ?\})) -1)
          ;; Otherwise, do not search
          (t nil))))
    (when direction
      (save-excursion
        (let ((match-pos (condition-case nil
                             (scan-lists cursor-position direction 0)
                           (error nil))))
          (when match-pos
            ;; Adjust for forward searches to point to the matching bracket
            (when (> direction 0)
              (setq match-pos (1- match-pos)))
            ;; Construct the list with line, column, position, and character
            (let ((line (line-number-at-pos match-pos))
                  (column (save-excursion
                            (goto-char match-pos)
                            (current-column)))
                  (char (char-to-string (char-after match-pos))))
              (list line column match-pos char))))))))


(defun my-in-buffer-tools/length-longest-line-in-region (beg end)
  "Determine the length of the longest line in the region from BEG to END.

Note that `r' in the interactive expression means read beg end from the current
buffer.  This differs from `*r' since `*r' checks to ensure the buffer is
read/write.  We don't do that here as we don't attempt to write anything to
buffer."
  (interactive "r")
  (let ((max-length 0))
    (save-excursion
      ;; Narrow to the region to avoid processing outside lines
      (narrow-to-region beg end)
      (goto-char (point-min))
      ;; Iterate over each line in the region
      (while (not (eobp))
        (let ((line-length (save-excursion
                             (end-of-line)
                             (- (point) (line-beginning-position)))))
          (setq max-length (max max-length line-length)))
        (forward-line 1))
      ;; Restore the full buffer view
      (widen))
    (if (called-interactively-p 'interactive)
        (message "Longest line length in the region: %d" max-length))
    max-length))


(defun my-in-buffer-tools/comment-box-filled (beg end)
  "Comment out the BEG .. END region, inside a box extended to `fill-column'.

Note that `*r' in the interactive expression means read beg end from the current
buffer and ensure the buffer is writable or else exit.  This differs from `r'
since `r' does not check to ensure the buffer is writable.  Since we do write
to buffer here, the check needs to be made."
  (interactive "*r")
  (let* ((max-length
          (my-in-buffer-tools/length-longest-line-in-region beg end))
         (even-max-length (+ max-length (% max-length 2)))
         (pad (max 1
                   (round
                    (/
                     (float (- fill-column even-max-length)) 2)))))
    (comment-box beg end (- pad 2))))

;; ---end of TOOLS FOR USE IN BUFFER---


;;;; TOOLS FOR THE FILE SYSTEM
;;   -------------------------
;; Function to ensure directory exists
(defun my-on-disk-tools/ensure-directory-exists (dir)
  "Ensure the directory DIR exists, create it if it does not."
  (unless (file-directory-p dir)
    (message "creating %s" dir)
    (make-directory dir t)))

;; ---end of TOOLS FOR THE FILE SYSTEM---


;;;; TOOLS FOR THEME SUPPORT
;;   -----------------------

(defun my-theme-support/tone-down-fringes ()
  "Set the buffer fringes to be invisible.
This is the area inside the window margin which can hold icons."
  (set-face-attribute 'fringe nil
                      :foreground (face-foreground 'default)
                      :background (face-background 'default)))

(defun my-theme-tools/set-current-window-margins (left &optional right)
  "Set the left and optionally right margins of the current window.
LEFT is the left margin width, and RIGHT is the right margin width (optional)."
  (let ((win (selected-window)))
    (set-window-margins win left right)))


;; ---end of TOOLS FOR THEME SUPPORT---

;;;; TOOLS USING ORG-MODE
;;   --------------------

;; Create abbreviations
;; (defun my-org/org-link-abbreviations-create ()
;;   "Replace all long form links in current file.
;; Use their corresponding abbreviations in `org-link-abbrev-alist'."

;;   (interactive)
;;   (dolist (pair org-link-abbrev-alist)
;;     (save-excursion
;;       (goto-char (point-min))
;;       (while (search-forward (concat "[[" (cdr pair)) nil t)
;;         (replace-match (concat "[[" (car pair) ":"))))))

;; (add-hook 'org-mode-hook
;;          (lambda ()
;;            (add-to-list 'write-file-functions 'my/org-link-abbreviations-create)))

;; Remove abbreviations
;; (defun my-org/org-link-abbreviations-remove ()
;;   "Replace all link abbreviations in current file.
;; Use their long form counterparts in `org-link-abbrev-alist'."
;;   (interactive)
;;   (dolist (pair org-link-abbrev-alist)
;;     (save-excursion
;;       (goto-char (point-min))
;;       (while (search-forward (concat "[[" (car pair) ":") nil t)
;;         (replace-match (concat "[[" (cdr pair)))))))

;; ---end of TOOLS USING ORG-MODE---

;;; TOOLS USING THE OS
;;  ------------------
(defun my-os-tools/ports-found-by-ss (output)
  "Extract a list of port numbers from `ss -tuln` output.
OUTPUT:  the text string produced from ss -tuln."
  (let ((lines (split-string output "\n" t))  ; Split by newline
        (ports '()))
    (dolist (line lines ports)
      ;; Find lines that contain 'LISTEN'
      (when (string-match-p "LISTEN" line)
        ;; Extract the port number using regex
        (when (string-match ".*\\([0-9]+\\)$" line)
          (let ((port (match-string 1 line)))
            (push (string-to-number port) ports)))))
    ports))

(defun my-os-tools/get-ss-output ()
  "Get the output of `ss -tuln`.
If `ss` is not found, show an error
message."
  (if (executable-find "ss")
      (shell-command-to-string "ss -tuln")
    (progn
      (message
       "Error: The 'ss' command is not available on this system.")
      "")))  ;; Return an empty string when `ss` is not found

(defun my-os-tools/find-available-ports (start end used-ports)
  "Find available ports in a given range.
START:       the start of the port range.
END:         the end of the port range to be checked.
USED-PORTS:  the ports that are not available."
  (let ((available-ports '()))
    (dotimes (i (- end start) available-ports)  ; Iterate over range
      (let ((port (+ start i)))
        (unless (member port used-ports)
          (push port available-ports))))))

(defun my-os-tools/set-sr-speedbar-directory-to-file-path (file-path)
  "Set the sr-speedbar directory to FILE-PATH and refresh it.
If `sr-speedbar' is not open, open it first."
  (interactive "DDirectory: ")
  (let ((expanded-path (expand-file-name file-path)))
    (when (file-directory-p expanded-path)
      ;; Open sr-speedbar if it's not already open
      (unless
          (sr-speedbar-exist-p)
        (sr-speedbar-open))
      ;; Set the default directory
      (setq default-directory expanded-path)
      ;; Clear speedbar cache and force refresh
      (speedbar-refresh)
      (sr-speedbar-refresh)
      ;; Display a message indicating the new directory
      (message "sr-speedbar directory set to %s" expanded-path))))

;; ---end of TOOLS USING THE OS---

;;;; TOOLS FOR LANGUAGE & DICTIONARIES

(defun my-dictionary/use-american ()
  "Switch to American English dictionary."
  (interactive)
  (setq ispell-dictionary "American")
  (ispell-change-dictionary "American")
  (message "Switched to American English dictionary"))

(defun my-dictionary/use-british ()
  "Switch to British English dictionary."
  (interactive)
  (setq ispell-dictionary "British")
  (ispell-change-dictionary "British")
  (message "Switched to British English dictionary"))

(defun my-dictionary/use-australian ()
  "Switch to Australian English dictionary."
  (interactive)
  (setq ispell-dictionary "Australian")
  (ispell-change-dictionary "Australian")
  (message "Switched to Australian English dictionary"))

;; ---end of TOOLS FOR LANGUAGE & DICTIONARIES---


(provide 'system-tools)
;;; system-tools.el ends here

                                                                                  ; LocalWords:  LISTB sr ol dired
                                                                                  ; LocalWords:  netstat isn
                                                                                  ; LocalWords:  minibuffer
; LocalWords:  PREC SIGFIGS STRLENGTH
