;;; system-buffer-tools.el --- Buffer and in-buffer helpers. -*- lexical-binding: t; -*-

;; Copyright (C) 2026 Simon Watson
;; SPDX-License-Identifier: MIT

;; Author: Simon Watson

;;; Commentary:

;; Piece of `system-tools': buffer management and in-buffer editing
;; helpers (comment alignment, brackets, temp buffers).  Required by
;; the loader, not from `init.el' directly.
;;
;; Map:
;;   Feature:    system-buffer-tools
;;   Load-after: path-support logging-config
;;   Load-phase: bootstrap
;;   Keymaps:    none
;;   Docs:       docs/system-buffer-tools.org
;;   OS:         none

;;; Code:

(require 'path-support)
(require 'logging-config)
(log/debug :fn 'system-buffer-tools
           :msg "Starting load of the system-buffer-tools module."
           :obj t)

(require 'cl-lib)

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
  "On BUFFER, set ATTRIBUTE to VALUE."
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
  (let ((inhibit-read-only t))                                                    ; Temporarily disable read-only mode
    (save-excursion                                                               ; Preserve point position
      (goto-char (point-min))                                                     ; Move to the start of the buffer
      (open-line 1))))                                                            ; Insert a blank line


(defun my-in-buffer-tools/line-is-blank-or-pure-comment-p ()
  "Return t if the current line is blank or consists only of a comment.
Uses the major mode's `comment-start' (and Tree-sitter when available for extra accuracy)."
  (save-excursion
    (beginning-of-line)
    (skip-chars-forward " \t")
    (or (eolp)                                      ; blank line
        ;; Tree-sitter check (most accurate when available)
        (my-in-buffer-tools/line-is-pure-comment-treesit-p)
        ;; Classic fallback — works everywhere
        (and comment-start
             (not (string-empty-p comment-start))
             (looking-at-p (regexp-quote comment-start))))))

(defun my-in-buffer-tools/line-is-pure-comment-treesit-p ()
  "Helper: Tree-sitter aware check for pure comment lines."
  (when (and (treesit-available-p)
             (treesit-parser-list))
    (let ((node (treesit-node-at (point))))
      (and node
           (string-match-p "comment" (treesit-node-type node))))))

(defun my-in-buffer-tools/previous-code-line-indent ()
  "Generalised: return indentation of nearest previous *code* line.
Skips all blank lines and pure comment lines (Python #, C++ //, Lisp ;, etc.).
This is the robust heuristic used by most Emacs formatting tools."
  (save-excursion
    (forward-line -1)
    (while (and (not (bobp))
                (my-in-buffer-tools/line-is-blank-or-pure-comment-p))
      (forward-line -1))
    (current-indentation)))

(defun my-in-buffer-tools/treesit-indent-standalone-comment ()
  "Indent the current standalone comment line.
Now fully language-agnostic and reliable even inside large functions with section comments."
  (indent-line-to (my-in-buffer-tools/previous-code-line-indent)))

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



(defun my-in-buffer-tools/comment-align-buffer (beg end)
  "Align ONLY inline comments (code # comment) to `comment-column'.

All standalone comments (# on its own line, including section
headings such as \"# 1.\" or \"##+\") are left completely untouched.
This is the most reliable behaviour for users who use visual
sectioning inside functions.  Works in any mode that sets
`comment-start' (Python, C++, JS/TS, Lisp, Rust, Go, etc.).
Preserves point and plays nicely with Apheleia/Ruff.
BEG and END denote the region being formatted."
  (interactive (if (use-region-p)
                   (list (region-beginning) (region-end))
                 (list (point-min) (point-max))))
  (when (not comment-start)
    (cl-return-from my-in-buffer-tools/comment-align-buffer))

  (let ((beg-marker (copy-marker beg))
        (end-marker (copy-marker end t)))
    (save-excursion
      (goto-char beg-marker)
      (while (and (comment-search-forward end-marker t)
                  (< (point) end-marker))
        (let ((comment-pos (point)))
          (save-excursion
            (beginning-of-line)
            (skip-chars-forward " \t")
            ;; Only touch lines that have NON-WHITESPACE code before the comment
            (unless (looking-at-p (regexp-quote comment-start))
              (goto-char comment-pos)
              (comment-indent))))
        (comment-forward 1)))
    (set-marker beg-marker nil)
    (set-marker end-marker nil)))

(defun my-in-buffer-tools/my-comment-align-region-or-line ()
  "Align inline comments in the active region or the current line.
This function checks if a region is active.  If so, it applies
`my-in-buffer-tools/comment-align-buffer' to the region.  Otherwise,
it applies the function to the current line only."
  (interactive)
  (let ((beg (if (use-region-p)
                 (region-beginning)
               (line-beginning-position)))
        (end (if (use-region-p)
                 (region-end)
               (line-end-position))))
    (my-in-buffer-tools/comment-align-buffer beg end)))

;; ---end of TOOLS FOR USE IN BUFFER---

(log/debug :fn 'system-buffer-tools
           :msg "Finishing load of the system-buffer-tools module."
           :obj t)

(provide 'system-buffer-tools)
;;; system-buffer-tools.el ends here
