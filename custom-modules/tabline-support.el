;;; tabline-support.el --- Tab-line configuration  -*- lexical-binding: t -*-

;; Copyright (C) 2025
;; SPDX-License-Identifier: MIT

;; Author: Simon Watson
;; Keywords: tabline ui

;;; Commentary:

;; This module configures and extends Emacs' built-in tab-line functionality
;; to manage buffers and window workspaces effectively.
;; It defines custom variables for styling, exceptions, and behaviours,
;; and provides utility functions for tab management, such as closing tabs
;; while preserving buffers in other windows where appropriate.
;; The tab-line is customised for appearance and usability, drawing inspiration
;; from external resources like blog posts on emulating Atom-like tabs.
;; Key features include dynamic tab sizing, mode-based exclusions, and
;; specific buffer enabling.

;;; Code:

(declare-function my-buffer-tools/switch-to-buffer-in-current-window
                  "system-tools")

(require 'tab-line)                                                               ; Built-in package for tab-line functionality.

;; Theme-related variables: These store colours derived from the current theme
;; for consistent styling across the tab-line elements.
(defvar info-theme-dark-blue nil
  "Colour used from the current theme for dark backgrounds.")
(defvar info-theme-flat-yellow nil
  "Colour used from the current theme for highlights like modifications.")
(defvar info-theme-blue-steel nil
  "Colour used from the current theme for foregrounds and accents.")
(defvar info-theme-dark-green nil
  "Colour used from the current theme for mouse-over effects.")
(defvar info-theme-white-grey nil
  "Colour used from the current theme for focused elements.")

;; Sorting flag: Intended for future implementation to sort tabs by recency.
(defvar my-tab-line/tab-line-sort-by-most-recent nil
  "Flag to sort tabs by most recently opened (not yet implemented).")

;; Exception lists: Define buffers where tab-line should always be active,
;; overriding general exclusions.
(defvar my-tab-line/enabled-buffers
  '("*Async-native-compile-log*" "*Messages*" "*Window Names*")
  "List of buffer names where `tab-line-mode` should always be enabled.")

(defvar my-tab-line/enabled-prefixes
  '("*EGLOT" "*vc-git-staged" "*vTable")
  "List of buffer name prefixes where `tab-line-mode` should be enabled.")

;; Customisable variables: These defcustoms allow user configuration via
;; Customise interface, grouped under 'tab-line for organisation.
(defcustom my-tab-line/tab-min-width 10
  "Minimum width of a tab in characters.
This ensures tabs do not become too narrow for readability."
  :type 'integer
  :group 'tab-line)

(defcustom my-tab-line/tab-max-width 30
  "Maximum width of a tab in characters.
This caps tab size to prevent excessive space usage."
  :type 'integer
  :group 'tab-line)

(defcustom my-tab-line/tab-line-height 150
  "Height of the tab-line in the buffer.
Affects the visual prominence of the tab bar."
  :type 'integer
  :group 'tab-line)

(defcustom my-tab-line/foreground-color info-theme-blue-steel
  "Foreground colour of the tab-line bar.
Used for text and borders in active states."
  :type 'string
  :group 'tab-line)

(defcustom my-tab-line/background-color info-theme-dark-blue
  "Background colour of the tab-line bar.
Provides the base colour for inactive areas."
  :type 'string
  :group 'tab-line)

(defcustom my-tab-line/modified-tab-foreground-color info-theme-flat-yellow
  "Foreground colour for tabs of modified (unsaved) buffers.
Highlights changes to draw attention."
  :type 'string
  :group 'tab-line)

(defcustom my-tab-line/focus-tab-foreground-color info-theme-white-grey
  "Foreground colour for the focused tab.
Distinguishes the currently active buffer."
  :type 'string
  :group 'tab-line)

(defcustom my-tab-line/mouse-over-color info-theme-dark-green
  "Background colour for tabs under mouse hover.
Provides visual feedback for interaction."
  :type 'string
  :group 'tab-line)

(defcustom my-tab-line/tab-box-outline-h 2
  "Width of horizontal lines for the box around a tab.
Controls border thickness for visual separation."
  :type 'integer
  :group 'tab-line)

(defcustom my-tab-line/tab-box-outline-v 2
  "Width of vertical lines for the box around a tab.
Controls border thickness for visual separation."
  :type 'integer
  :group 'tab-line)

;; Faces for tab-line: These set-face-attribute calls define the visual
;; styles for various tab states, ensuring consistency with theme colours.
;; Flow: Each face is configured for font, colours, height, weight, and borders
;; to create a cohesive, modern look inspired by Atom editor tabs.

(set-face-attribute 'tab-line nil                                                 ; Background strip behind all tabs.
                    :family "source code pro"                                     ; Monospace font for alignment.
                    :background my-tab-line/background-color                      ; Dark base.
                    :foreground my-tab-line/foreground-color                      ; Steel text.
                    :height my-tab-line/tab-line-height                           ; Scaled height.
                    :weight 'bold                                                 ; Bold for emphasis.
                    :box `(:line-width (,my-tab-line/tab-box-outline-h
                                        . ,my-tab-line/tab-box-outline-v)
                                       :color ,my-tab-line/foreground-color))     ; Border box.

(set-face-attribute 'tab-line-highlight nil                                       ; Tab under mouse hover.
                    :family "source code pro"
                    :background my-tab-line/mouse-over-color                      ; Green highlight.
                    :weight 'bold
                    :height 110                                                   ; Slightly smaller than main bar.
                    :box `(:line-width (,my-tab-line/tab-box-outline-h
                                        . ,my-tab-line/tab-box-outline-v)
                                       :color ,my-tab-line/foreground-color))     ; Consistent border.

(set-face-attribute 'tab-line-tab nil                                             ; Active tab in another window.
                    :family "source code pro"
                    :foreground my-tab-line/background-color                      ; Inverted colours.
                    :background my-tab-line/foreground-color
                    :height 110
                    :weight 'bold
                    :box `(:line-width (,my-tab-line/tab-box-outline-h
                                        . ,my-tab-line/tab-box-outline-v)
                                       :color ,my-tab-line/foreground-color)
                    :extend t)                                                    ; Extend background to edges.

(set-face-attribute 'tab-line-tab-current nil                                     ; Active tab with focus.
                    :family "source code pro"
                    :foreground my-tab-line/focus-tab-foreground-color            ; White-grey text.
                    :background my-tab-line/foreground-color                      ; Steel background.
                    :height 110
                    :weight 'bold
                    :box `(:line-width (,my-tab-line/tab-box-outline-h
                                        . ,my-tab-line/tab-box-outline-v)
                                       :color ,my-tab-line/foreground-color)
                    :extend t)                                                    ; Extend for full coverage.

(set-face-attribute 'tab-line-tab-inactive nil                                    ; Inactive tabs.
                    :family "source code pro"
                    :foreground my-tab-line/foreground-color                      ; Steel text.
                    :background my-tab-line/background-color                      ; Dark background.
                    :height 110
                    :inherit nil                                                  ; No inheritance to avoid conflicts.
                    :box `(:line-width (,my-tab-line/tab-box-outline-h
                                        . ,my-tab-line/tab-box-outline-v)
                                       :color ,my-tab-line/foreground-color)
                    :weight 'bold)                                                ; Bold for visibility.

(set-face-attribute 'tab-line-tab-inactive-alternate nil                          ; Alternate inactive style (unused variant).
                    :family "source code pro"
                    :foreground my-tab-line/foreground-color
                    :background my-tab-line/background-color
                    :height 110
                    :inherit nil
                    :box `(:line-width (,my-tab-line/tab-box-outline-h
                                        . ,my-tab-line/tab-box-outline-v)
                                       :color ,my-tab-line/foreground-color)
                    :weight 'bold)

(set-face-attribute 'tab-line-tab-modified nil                                    ; Modified (unsaved) tabs.
                    :family "source code pro"
                    :foreground my-tab-line/modified-tab-foreground-color         ; Yellow highlight.
                    :height 110)                                                  ; No background/box to overlay on other faces.

;; ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
;; Tab-line functionality enhancements.
;; ---------------------
;; The following functions improve tab-line interactions, such as safe closing
;; of tabs without unnecessarily killing buffers. Inspired by a blog post on
;; emulating Atom tabs in
;; Emacs[]
;; (https://andreyor.st/posts/2020-05-10-making-emacs-tabs-look-like-in-atom/).
;; Integrates with bookmark-view for layout control.
;; General flow: Functions handle tab closing by checking buffer presence
;; across windows, burying or killing as needed, and potentially deleting
;; empty windows to maintain a clean workspace.

(defun my-tab-line/tab-line-close-tab-given-buffer (buffer
                                                    &optional given-window)
  "Close the tab for BUFFER in GIVEN-WINDOW (defaults to selected window).

Purpose: Safely remove a tab while preserving the buffer if it's open elsewhere.
Variables:
- BUFFER: The buffer to close.
- GIVEN-WINDOW: Optional window to operate on; defaults to selected.
Output: No explicit return; modifies window and buffer states.
Flow:
1. Select the given window.
2. Gather all buffers across all windows.
3. If buffer appears in multiple windows, bury it in this window.
4. If unique to this window, kill the buffer.
5. If no tabs remain, delete the window.
This function is optimised for IDE setups by minimising buffer loss."

  (interactive)                                                                   ; Allow interactive call, though typically programmatic.
  (unless given-window                                                            ; Default to current window if not provided.
    (setq given-window (selected-window)))
  (with-selected-window given-window                                              ; Temporarily switch to target window.
    (let ((tab-list (tab-line-tabs-window-buffers))                               ; Local tabs in this window.
          (buffer-list                                                            ; Flatten buffers from all windows.
           (flatten-list
            (seq-reduce
             (lambda (list window)
               (select-window window t)                                           ; Switch to each window briefly.
               (cons (tab-line-tabs-window-buffers) list))                        ; Collect tabs.
             (window-list) nil))))
      (select-window given-window)                                                ; Restore original window.
      (if (> (seq-count (lambda (b) (eq b buffer)) buffer-list) 1)                ; Buffer in multiple places?
          (progn                                                                  ; Bury to hide without killing.
            (if (eq buffer (current-buffer))                                      ; If current, bury directly.
                (bury-buffer)
              (set-window-prev-buffers                                            ; Remove from history lists.
               given-window
               (assq-delete-all buffer (window-prev-buffers)))
              (set-window-next-buffers
               given-window
               (delq buffer (window-next-buffers))))
            (unless (cdr tab-list)                                                ; No more tabs? Delete window.
              (ignore-errors (delete-window given-window))))
        (and (kill-buffer buffer)                                                 ; Kill if unique.
             (unless (cdr tab-list)
               (ignore-errors (delete-window given-window))))))))                 ; Clean up window.




(defun my-tab-line/tab-line-name-buffer (buffer &rest _buffers)
  "Generate formatted name for BUFFER tab, with padding and truncation.

Purpose: Ensure uniform tab widths for aesthetic and usability.
Variables:
- BUFFER: The buffer to name.
- _BUFFERS: Ignored rest args for compatibility.
Output: String of formatted tab name.
Flow:
1. Calculate available width per tab based on window size and tab count.
2. Clamp width between min and max.
3. Truncate or pad buffer name to fit.
4. Add ellipsis if truncated.
This dynamically adjusts for window resizing."

  (with-current-buffer buffer                                                     ; Switch to buffer for name access.
    (let* ((window-width (window-width (get-buffer-window)))                      ; Current window width.
           (tab-amount (length (tab-line-tabs-window-buffers)))                   ; Number of tabs.
           (window-max-tab-width                                                  ; Compute max per-tab width.
            (if (>= (* (+ my-tab-line/tab-max-width 3) tab-amount)                ; Account for buttons.
                    window-width)
                (/ window-width tab-amount)
              my-tab-line/tab-max-width))
           (tab-width                                                             ; Final width, minus button compensation.
            (- (cond ((> window-max-tab-width my-tab-line/tab-max-width)
                      my-tab-line/tab-max-width)
                     ((< window-max-tab-width my-tab-line/tab-min-width)
                      my-tab-line/tab-min-width)
                     (t window-max-tab-width))
               3))                                                                ; Subtract for ' x ' close button.
           (buffer-name (string-trim (buffer-name)))                              ; Clean name.
           (name-width (length buffer-name)))                                     ; Length for padding calc.

      (if (>= name-width tab-width)                                               ; Too long? Truncate.
          (concat " "
                  (truncate-string-to-width buffer-name (- tab-width 2)) "…")
        (let* ((padding (make-string (+ (/ (- tab-width name-width) 2) 1) ?\s))   ; Centre padding.
               (buffer-name (concat padding buffer-name)))                        ; Pad left.
          (concat buffer-name
                  (make-string (- tab-width (length buffer-name)) ?\s)))))))      ; Pad right.

;; Enable global mode after definitions to apply customisations.
(global-tab-line-mode t)

;;; Tab-line setup: Configure global variables for buttons and naming.
;; Flow: Set visibility, separators, and navigation buttons with Unicode
;; fallbacks for compatibility. Custom name function ensures dynamic sizing.

(setq tab-line-close-button-show t                                                ; Display close buttons.
      tab-line-new-button-show nil                                                ; Hide new tab button.
      tab-line-separator ""                                                       ; No separators for clean look.
      tab-line-tab-name-function #'my-tab-line/tab-line-name-buffer               ; Use custom naming.
      tab-line-right-button                                                       ; Right scroll button.
      (propertize (if (char-displayable-p ?▶) " ▶ " " > ")
                  'keymap tab-line-right-map
                  'mouse-face 'tab-line-highlight
                  'help-echo "Click to scroll right")
      tab-line-left-button                                                        ; Left scroll button.
      (propertize (if (char-displayable-p ?◀) " ◀ " " < ")
                  'keymap tab-line-left-map
                  'mouse-face 'tab-line-highlight
                  'help-echo "Click to scroll left")
      tab-line-close-button                                                       ; Close button with Unicode fallback.
      (propertize (if (char-displayable-p ?×) "  ×  " "  x  ")
                  'keymap tab-line-tab-close-map
                  'mouse-face 'tab-line-close-highlight
                  'help-echo "Click to close tab"))

;; Exclude modes: Add modes where tab-line should not appear.
(dolist (mode '(speedbar-mode
                corfu-mode
                corfu-popupinfo-mode))
  (add-to-list 'tab-line-exclude-modes mode))
;; Additional exclusions can be added here as needed.

(defun my-tab-line/enable-tab-line-mode-for-specific-buffers ()
  "Enable `tab-line-mode' selectively for specified buffers.

Purpose: Override exclusions for important buffers.
Variables: Uses `my-tab-line/enabled-buffers' and
           `my-tab-line/enabled-prefixes'.
Output: Enables mode if buffer matches criteria.
Flow:
1. Get current buffer name.
2. Check against exact names or prefixes.
3. Enable mode if match found.
This ensures key buffers like Messages always have tabs."

  (let ((buffer-name (buffer-name)))                                              ; Current buffer name.
    (when (or (member buffer-name my-tab-line/enabled-buffers)                    ; Exact match?
              (cl-some (lambda (prefix) (string-prefix-p prefix buffer-name))     ; Prefix match?
                       my-tab-line/enabled-prefixes))
      (tab-line-mode 1))))                                                        ; Enable if yes.

(add-hook 'fundamental-mode-hook                                                  ; Hook into base mode for broad application.
          #'my-tab-line/enable-tab-line-mode-for-specific-buffers)

(defun my-tab-line/tab-line-tabs-window-buffers--removed-nameless-buffers ()
  "Return filtered list of window buffers for tab-line, excluding nameless ones.

Purpose: Customise tab candidates by removing hidden or special buffers.
Variables: None explicit; uses window buffers.
Output: List of valid buffers.
Flow:
1. Gather prev, current, and next buffers for the window.
2. Combine and filter live buffers.
3. Remove those with leading spaces or specific patterns
   (e.g., corfu, speedbar).
This overrides the default `tab-line-tabs-function' for cleaner tabs."

  (let ((buflist                                                                  ; Build combined buffer list.
         (let* ((window (selected-window))                                        ; Current window.
                (buffer (window-buffer window))                                   ; Current buffer.
                (next-buffers (seq-remove (lambda (b) (eq b buffer))              ; Exclude current from next.
                                          (window-next-buffers window)))
                (next-buffers (seq-filter #'buffer-live-p next-buffers))          ; Live only.
                (prev-buffers
                 (seq-remove (lambda (b) (eq b buffer))                           ; Exclude from prev.
                             (mapcar #'car (window-prev-buffers window))))
                (prev-buffers (seq-filter #'buffer-live-p prev-buffers))          ; Live only.
                (prev-buffers (seq-difference prev-buffers next-buffers)))        ; De-duplicate.
           (append (reverse prev-buffers) (list buffer) next-buffers))))          ; Ordered list.

    (delq nil                                                                     ; Remove nils from filtered list.
          (mapcar
           (lambda (buf)
             (let ((name (buffer-name buf)))                                      ; Buffer name.
               (unless (or (string-prefix-p " " name)                             ; Hidden buffers.
                           (string-match-p "\\` \\*corfu\\*\\'" name)             ; Corfu popups.
                           (string-match-p "\\` \\*speedbar\\*\\'" name)          ; Speedbar.
                           (string-match-p "\\` \\*Marginalia\\*\\'" name))       ; Marginalia.
                 buf)))                                                           ; Keep if not excluded.
           buflist))))


(defun my-tab-line/tab-line-close-tab (&optional e)
  "Close the tab under mouse event E or the current tab.

Purpose: Handle mouse-clicked tab closure safely, mirroring
`my-tab-line/tab-line-close-tab-given-buffer' but for interactive events.
This ensures buffers shared across windows are buried (hidden) rather than
killed, while unique buffers are killed.  If the window ends up with no tabs,
it is deleted to clean up the workspace.

Variables:
- E: Optional mouse event (from `interactive \"e\"`); if provided, extracts
  the clicked position, window, and buffer. If nil, falls back to current
  window and buffer (though typically called with event).

Output: No explicit return value; side-effects include modifying window
configurations, buffer lists, and potentially killing buffers or deleting
windows.

Flow:
1. If E is provided, extract the click position (posnp), target window, and
   buffer from the tab's text property.
2. Temporarily select the target window using `with-selected-window`.
3. Collect the local tab-list (buffers in this window's tabs).
4. Build a global buffer-list by iterating over all windows, collecting their
   tab buffers, and flattening the result.
5. Check if the target buffer appears in multiple windows (shared):
   - If yes, bury it if current, or remove from prev/next buffer histories.
   - Force window update to refresh the tab-line immediately.
   - If no more tabs remain, delete the window.
6. If unique to this window, kill the buffer and delete the window if empty.

Note on Empty buffer-list: If this is empty, it means no tabs were found
across *any* windows—possible if `tab-line-mode` is disabled, custom
`tab-line-tabs-function` filters everything out (e.g., your nameless buffer
remover), or no prev/next buffers exist. In multi-window setups, verify
`tab-line-tabs-window-buffers` returns at least the current buffer per window
if not, check exclusions in `tab-line-exclude-modes` or custom filters."
  (interactive "e")                                                               ; Mark as interactive; expects mouse event E for tab clicks.
  (let* ((posnp (event-start e))                                                  ; Extract start position of event (detailed list: window, coords, etc.).
         (window (posn-window posnp))                                             ; Get window object from position (where click occurred).
         (buffer (get-pos-property 1 'tab (car (posn-string posnp)))))            ; Extract buffer from `tab' text property in the clicked string (nil if not on a tab).
    (when buffer                                                                  ; Guard: Skip if no buffer extracted (e.g., click not on valid tab).
      (with-selected-window window                                                ; Temporarily select target window; body executes in its context, restores after.
        (let ((tab-list (tab-line-tabs-window-buffers))                           ; Local tabs: Buffers for this window's tab-line (calls custom `tab-line-tabs-function`).
              (buffer-list                                                        ; Global list: Flatten tabs from *all* windows.
               (flatten-list                                                      ; Combine nested lists into one.
                (seq-reduce                                                       ; Accumulate over windows.
                 (lambda (acc win)                                                ; Lambda: For each window, collect its tabs.

                   ;; (log/debug :fn 'my-tab-line/tab-line-close-tab
                   ;;            :msg "Closing tab with mouse event on tab-line."
                   ;;            :obj (list :window window
                   ;;                       :buffer buffer
                   ;;                       :tabs (tab-line-tabs-window-buffers)))

                   (select-window win t)                                          ; Select temporarily (t: no-record in history).
                   (cons (tab-line-tabs-window-buffers) acc))                     ; Prepend its tabs to accumulator.
                 (window-list) nil))))                                            ; All windows; start with empty acc.

          ;; No need for (select-window window) here —
          ;; `with-selected-window` already ensures this.
          (if (> (seq-count (lambda (b) (eq b buffer)) buffer-list) 1)            ; Count buffer occurrences; >1 means shared across windows.
              (progn                                                              ; Shared case: Hide without killing.
                (if (eq buffer (current-buffer))                                  ; If active in this window.
                    (bury-buffer)                                                 ; Move to end of buffer list (hides it).
                  (set-window-prev-buffers
                   window                                                         ; Remove from prev history.
                   (assq-delete-all buffer (window-prev-buffers window)))
                  (set-window-next-buffers
                   window                                                         ; Remove from next list.
                   (delq buffer (window-next-buffers window))))
                (force-window-update window)                                      ; Force redisplay to update tab-line immediately.
                (unless (cdr tab-list)                                            ; If no other tabs left (cdr nil means single-item list).
                  (ignore-errors (delete-window window))))                        ; Delete window, ignore errors (e.g., last window).
            (and (kill-buffer buffer)                                             ; Unique case: Kill buffer (t if success).
                 (unless (cdr tab-list)
                   (ignore-errors (delete-window window))))                       ; Clean up if empty.
            ))))))



(defalias 'tab-line-close-tab 'my-tab-line/tab-line-close-tab
  "Alias to use custom close function for safe tab closure.")

(setq tab-line-tabs-function                                                      ; Override built-in with custom filter.
      'my-tab-line/tab-line-tabs-window-buffers--removed-nameless-buffers)

(defun my-tab-line/close-specific-buffer (buffer-name)
  "Close buffer named BUFFER-NAME from current window safely.

Purpose: Targeted buffer closure with preservation logic.
Variables:
- BUFFER-NAME: String name of buffer to close.
Output: No return; modifies state.
Flow:
1. Get buffer object.
2. Switch to it if exists.
3. Use close-tab function to handle burial/kill/window deletion.
Interactive for user input."

  (interactive "sBuffer name: ")                                                  ; Prompt for name.
  (let ((buffer (get-buffer buffer-name)))                                        ; Retrieve buffer.
    (when buffer                                                                  ; If exists:
      (my-buffer-tools/switch-to-buffer-in-current-window buffer-name)            ; Switch to it.
      (my-tab-line/tab-line-close-tab-given-buffer buffer))))                     ; Close safely.

(provide 'tabline-support)
;;; tabline-support.el ends here

;; LocalWords: Dired ediff customisations ui
