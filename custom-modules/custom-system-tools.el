;;; custom-system-tools.el --- useful functionality for emacs -*- mode: emacs-lisp; lexical-binding: t; -*-

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

(defvar org-link-abbrev-alist)
(declare-function speedbar-refresh "speedbar")

(declare-function sr-speedbar-exist-p "sr-speedbar")
(declare-function sr-speedbar-open "sr-speedbar")
(declare-function sr-speedbar-refresh "sr-speedbar")
(declare-function image-supported-file-p "image")

(declare-function org-link-abbrev-alist "ol")

(require 'custom-system-objects)


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Emacs Lisp logging helpers
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

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


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Dired tools
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
(defun my-interactive-tools/select-directory-using-dired ()
  "Open a Dired buffer for directory selection and return the selected path."
  (interactive)
  (let ((selected-dir (dired-get-file-for-visit)))
    (if (file-directory-p selected-dir) ;; Check if it's a directory
        selected-dir
      (user-error "Not a directory"))))

;; end of Dired tools.
;; ---------------------------

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Image processing
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

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
;; ---------------------------


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; String processing
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
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
    (string-to-number (substring string 0 (- (length string) 1))))
   )
  )

(defun my-strings/bytes-to-human-readable-file-sizes (bytes)
  "Convert number of BYTES to human-readable file size.
This is the companion of `my-strings/human-readable-file-sizes-to-bytes', a
function which converts a string showing a number as  a human readable size
into a given amount of bytes."
  (interactive)
  (cond
   ((> bytes 1000000000) (format "%10.1fG" (/ bytes 1000000000.0)))
   ((> bytes 100000000) (format "%10.0fM" (/ bytes 1000000.0)))
   ((> bytes 1000000) (format "%10.1fM" (/ bytes 1000000.0)))
   ((> bytes 100000) (format "%10.0fk" (/ bytes 1000.0)))
   ((> bytes 1000) (format "%10.1fk" (/ bytes 1000.0)))
   (t (format "%10d" bytes)))
  )

;; end of String processing
;; ---------------------------


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Window management
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
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
  (message "Window state with properties saved."))


(defun my-window-tools/mouse-delete-window-confirmation (click)
  "Ask for confirmation before deleting the window from a CLICK  mouse event."

  (interactive (list last-nonmenu-event))
  (mouse-minibuffer-check click)
  ;;(interactive "e")  ; The 'e' here tells Emacs this function expects a mouse event.
  (let ((window (posn-window (event-start click))))
    (when (and (windowp window)  ; Checks if the target is a window.
               (y-or-n-p "Are you sure you want to delete this window?"))
      (delete-window window))))

;; end of Window management
;; ---------------------------

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; BUFFER management
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

(defun my-buffer-tools/open-temp-org-buffer ()
  "Open a temporary `org-mode' buffer."
  (interactive)
  (let ((buffer (generate-new-buffer "*temp-org*")))
    (with-current-buffer buffer
      (org-mode))
    (switch-to-buffer buffer)))

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
  (interactive (list last-nonmenu-event))                                      ; Enable the function to handle a mouse event.
  (message "triggered")                                                        ; Give feedback when function is triggered.
  (mouse-minibuffer-check click)                                               ; Prevent triggering if click is in the minibuffer.
  (let* ((window (posn-window (event-start click)))                            ; Get the window where click occurred.
         (buf (window-buffer window))                                          ; Get the buffer from that window.
         (temp-rule '(".*" (display-buffer-pop-up-frame))))                    ; Temporary display rule for opening in a new frame.
    (message "Selected window: %s" window)                                     ; Display selected window as feedback.
    (setq display-buffer-alist (cons temp-rule display-buffer-alist))          ; Temporarily add the new frame rule to `display-buffer-alist`.
    (display-buffer buf)                                                       ; Display the buffer in a new frame.
    (setq display-buffer-alist (cdr display-buffer-alist))))                   ; Restore the original `display-buffer-alist`.



;;; TOOLS FOR USE IN BUFFER
;;  -----------------------
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


;;; TOOLS FOR THE FILE SYSTEM
;;  -------------------------
;; Function to ensure directory exists
(defun my-on-disk-tools/ensure-directory-exists (dir)
  "Ensure the directory DIR exists, create it if it does not."
  (unless (file-directory-p dir)
    (message "creating %s" dir)
    (make-directory dir t)))

;; ---end of TOOLS FOR THE FILE SYSTEM---


;;; TOOLS FOR THEME SUPPORT
;;  -----------------------

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

;;; TOOLS USING ORG-MODE
;;  ------------------
;; Create abbreviations
(defun my-org/org-link-abbreviations-create ()
  "Replace all long form links in current file.
Use their corresponding abbreviations in `org-link-abbrev-alist'."

  (interactive)
  (dolist (pair org-link-abbrev-alist)
    (save-excursion
      (goto-char (point-min))
      (while (search-forward (concat "[[" (cdr pair)) nil t)
        (replace-match (concat "[[" (car pair) ":"))))))

;; (add-hook 'org-mode-hook
;;          (lambda ()
;;            (add-to-list 'write-file-functions 'my/org-link-abbreviations-create)))

;; Remove abbreviations
(defun my-org/org-link-abbreviations-remove ()
  "Replace all link abbreviations in current file.
Use their long form counterparts in `org-link-abbrev-alist'."
  (interactive)
  (dolist (pair org-link-abbrev-alist)
    (save-excursion
      (goto-char (point-min))
      (while (search-forward (concat "[[" (car pair) ":") nil t)
        (replace-match (concat "[[" (cdr pair)))))))

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

;; TOOLS FOR LANGUAGE & DICTIONARIES
;; ---------------------------------
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


(provide 'custom-system-tools)
;;; custom-system-tools.el ends here

                                        ; LocalWords:  LISTB sr ol
                                        ; LocalWords:  netstat isn
                                        ; LocalWords:  minibuffer
