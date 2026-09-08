;;; system-window-panes.el --- IDE pane toggle and reallocation. -*- lexical-binding: t; -*-

;; Copyright (C) 2026 Simon Watson
;; SPDX-License-Identifier: MIT

;; Author: Simon Watson

;;; Commentary:

;; Piece of `system-window-management': pane toggle, bury, and
;; reallocation.  `--open-category' stays here; do not split at that
;; helper.  Required by the loader, not from `init.el' directly.
;;
;; Map:
;;   Feature:    system-window-panes
;;   Load-after: path-support logging-config system-window-helpers
;;   Load-phase: tools
;;   Keymaps:    none
;;   Docs:       docs/system-window-panes.org
;;   OS:         none

;;; Code:

(require 'cl-lib)
(require 'path-support)
(require 'logging-config)
(log/debug :fn 'system-window-panes
           :msg "Starting load of the system-window-panes module."
           :obj t)

(require 'system-window-helpers)

(defvar my-window-tools/category-map)
(defvar my-window-tools/category-fallback)
(defvar my-window-tools/default-occupants)
(defvar my-window-tools/ide-category-layout)
(defvar my-window-tools/ide-category-weight)
(defvar my-window-tools--inhibit-retag)
(defvar my-window-tools--in-toggle)

(declare-function my-window-tools/determine-buffer-category
                  "system-window-display")

;;;; Panes
;;   -----

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
  "For CATEGORY on FRAME, record BUFFER as the last occupant.
CATEGORY names the pane.  FRAME is the IDE frame.  BUFFER must be live."
  (when (and category (buffer-live-p buffer))
    (let ((alist (assq-delete-all
                  category
                  (copy-sequence (frame-parameter frame 'ide-last-buffers)))))
      (set-frame-parameter frame 'ide-last-buffers
                           (cons (cons category buffer) alist)))))

(defun my-window-tools--buffer-named (name)
  "Return a live buffer called NAME, allowing a uniquify suffix.

The `vc-dir' buffer is often renamed with a uniquify suffix so an exact
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
\(used in an earlier revision) make `push-window-buffer-onto-prev'
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
  "On WINDOW, append BUFFERS to the `previous-buffer' list.

Does not change the visible buffer.  BUFFERS that are WINDOW's current
buffer, already present in its history, or no longer live are skipped.
Each new history entry uses markers, as required by
`push-window-buffer-onto-prev'."
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
  "Return live windows tagged CATEGORY on FRAME.
CATEGORY is a pane symbol.  FRAME is the IDE frame."
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
  "Create a window for CATEGORY by splitting NEIGHBOUR on SIDE.
CATEGORY is the pane being created.  NEIGHBOUR is an existing window.
SIDE is above/below/left/right."
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
  "Return \(WINDOW . SIDE) for inserting CATEGORY into its combination on FRAME.

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
commit.  After finishing the commit both windows are preserved and
both show the `vc-dir' buffer.  This helper folds them back to the spatially
first window of that category.

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
  "Review window tags in FRAME, defaulting to the selected frame.
Display in a buffer for inspection, focusing on `window-category'.

Purpose: Diagnose tag persistence in IDE setups.
FRAME is the target frame; defaults to selected.
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

(log/debug :fn 'system-window-panes
           :msg "Finishing load of the system-window-panes module."
           :obj t)

(provide 'system-window-panes)
;;; system-window-panes.el ends here
