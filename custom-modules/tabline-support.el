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

(require 'path-support)
(require 'logging-config)
(log/debug :fn 'tabline-support
           :msg "Starting load of the tabline-support module."
           :obj t)


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

(defcustom my-tab-line/tab-text-height 105   ; ≈ 30 % smaller than 150
  "Height of the text inside each tab.
A smaller value than `my-tab-line/tab-line-height' creates vertical padding."
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
                    :height my-tab-line/tab-text-height                           ; smaller text
                    :box `(:line-width (,my-tab-line/tab-box-outline-h
                                        . ,my-tab-line/tab-box-outline-v)
                                       :color ,my-tab-line/foreground-color))     ; Consistent border.

(set-face-attribute 'tab-line-tab nil                                             ; Active tab in another window.
                    :family "source code pro"
                    :foreground my-tab-line/background-color                      ; Inverted colours.
                    :background my-tab-line/foreground-color
                    :height my-tab-line/tab-text-height                           ; smaller text
                    :weight 'bold
                    :box `(:line-width (,my-tab-line/tab-box-outline-h
                                        . ,my-tab-line/tab-box-outline-v)
                                       :color ,my-tab-line/foreground-color)
                    :extend t)                                                    ; Extend background to edges.

(set-face-attribute 'tab-line-tab-current nil                                     ; Active tab with focus.
                    :family "source code pro"
                    :foreground my-tab-line/focus-tab-foreground-color            ; White-grey text.
                    :background my-tab-line/foreground-color                      ; Steel background.
                    :height my-tab-line/tab-text-height                           ; smaller text
                    :weight 'bold
                    :box `(:line-width (,my-tab-line/tab-box-outline-h
                                        . ,my-tab-line/tab-box-outline-v)
                                       :color ,my-tab-line/foreground-color)
                    :extend t)                                                    ; Extend for full coverage.

(set-face-attribute 'tab-line-tab-inactive nil                                    ; Inactive tabs.
                    :family "source code pro"
                    :foreground my-tab-line/foreground-color                      ; Steel text.
                    :background my-tab-line/background-color                      ; Dark background.
                    :height my-tab-line/tab-text-height                           ; smaller text
                    :inherit nil                                                  ; No inheritance to avoid conflicts.
                    :box `(:line-width (,my-tab-line/tab-box-outline-h
                                        . ,my-tab-line/tab-box-outline-v)
                                       :color ,my-tab-line/foreground-color)
                    :weight 'bold)                                                ; Bold for visibility.

(set-face-attribute 'tab-line-tab-inactive-alternate nil                          ; Alternate inactive style (unused variant).
                    :family "source code pro"
                    :foreground my-tab-line/foreground-color
                    :background my-tab-line/background-color
                    :height my-tab-line/tab-text-height                           ; smaller text
                    :inherit nil
                    :box `(:line-width (,my-tab-line/tab-box-outline-h
                                        . ,my-tab-line/tab-box-outline-v)
                                       :color ,my-tab-line/foreground-color)
                    :weight 'bold)

(set-face-attribute 'tab-line-tab-modified nil                                    ; Modified (unsaved) tabs.
                    :family "source code pro"
                    :foreground my-tab-line/modified-tab-foreground-color         ; Yellow highlight.
                    :height my-tab-line/tab-text-height                           ; smaller text
                    )                                                             ; No background/box to overlay on other faces.

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
(defun my-tab-line/buffer-in-window-history-p (buffer window)
  "Return non-nil when BUFFER is the current, a prev or a next buffer of WINDOW."
  (or (eq buffer (window-buffer window))
      (memq buffer (window-next-buffers window))
      (assq buffer (window-prev-buffers window))))

(defun my-tab-line/tab-line-close-tab-given-buffer (buffer &optional given-window)
  "Close the tab for BUFFER in GIVEN-WINDOW (defaults to selected window).

If BUFFER still appears in any other window's history it is only removed
from this window's prev/next lists (or buried).  Otherwise the buffer is
killed.  An empty window is deleted."
  (interactive)
  (unless given-window
    (setq given-window (selected-window)))
  (with-selected-window given-window
    (let* ((tab-list (tab-line-tabs-window-buffers))
           (shared   (> (seq-count
                         (lambda (w) (my-tab-line/buffer-in-window-history-p buffer w))
                         (window-list))
                        1)))
      (if shared
          (progn
            (if (eq buffer (current-buffer))
                (bury-buffer)
              (set-window-prev-buffers
               given-window
               (assq-delete-all buffer (window-prev-buffers given-window)))
              (set-window-next-buffers
               given-window
               (delq buffer (window-next-buffers given-window))))
            (force-window-update given-window)
            (unless (cdr tab-list)
              (ignore-errors (delete-window given-window))))
        (when (kill-buffer buffer)
          (force-window-update given-window)
          (unless (cdr tab-list)
            (ignore-errors (delete-window given-window))))))))

(defun my-tab-line/tab-line-close-tab (&optional e)
  "Close the tab under mouse event E or the current tab.
Same semantics as `my-tab-line/tab-line-close-tab-given-buffer'."
  (interactive "e")
  (let* ((posnp  (event-start e))
         (window (posn-window posnp))
         (buffer (get-pos-property 1 'tab (car (posn-string posnp)))))
    (when buffer
      (my-tab-line/tab-line-close-tab-given-buffer buffer window))))


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
  (let ((buffer-name (buffer-name)))
    (when (or (member buffer-name my-tab-line/enabled-buffers)
              (cl-some (lambda (prefix)
                         (string-prefix-p prefix buffer-name))
                       my-tab-line/enabled-prefixes))
      (tab-line-mode 1))))

;; Prefer after-change-major-mode-hook so programmatically created
;; buffers (and any later major-mode changes) also get the tab-line
;; when their name matches the enable lists.
(add-hook 'after-change-major-mode-hook
          #'my-tab-line/enable-tab-line-mode-for-specific-buffers)

;; Very occasional fallback for buffers that stay in fundamental-mode
;; without a proper mode call.
(add-hook 'fundamental-mode-hook
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


(log/debug :fn 'tabline-support
           :msg "Finishing load of the tabline-support module."
           :obj t)

(provide 'tabline-support)
;;; tabline-support.el ends here


