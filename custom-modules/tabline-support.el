;;; tabline-support.el --- tab-line configuration  -*- lexical-binding: t -*-

;; Copyright (C) 2025
;; SPDX-License-Identifier: MIT

;; Author: Simon Watson
;; Keywords: tabline ui

;;; Commentary:

;; Use tabline to manage buffers and windows workspaces
;; Define useful functions to manage workspaces.
;; (tabline is built in).

;;; Code:

(declare-function my-buffer-tools/switch-to-buffer-in-current-window
                  "custom-system-tools")

(require 'tab-line)  ; (tab-line is built in)
(require 'easymenu)

(defvar info-theme-dark-blue nil "Colour used from the current theme.")
(defvar info-theme-flat-yellow nil "Colour used from the current theme.")
(defvar info-theme-blue-steel nil "Colour used from the current theme.")
(defvar info-theme-dark-green nil "Colour used from the current theme.")
(defvar info-theme-white-grey nil "Colour used from the current theme.")

;; Sort tabs by most recently opened. (NOT IMPLEMENTED YET)
(defvar my-tab-line/tab-line-sort-by-most-recent nil)

;; Set up exceptions to the rules prohibiting tab-line-mode.
(defvar my-tab-line/enabled-buffers
  '("*Async-native-compile-log*" "*Messages*" "*Window Names*")
  "List of buffer names where `tab-line-mode` should always be enabled.")

(defvar my-tab-line/enabled-prefixes
  '("*EGLOT")
  "List of buffer name prefixes where `tab-line-mode` should be enabled.")



(defcustom my-tab-line/tab-min-width 10
  "Minimum width of a tab in characters."
  :type 'integer
  :group 'tab-line)

(defcustom my-tab-line/tab-max-width 30
  "Maximum width of a tab in characters."
  :type 'integer
  :group 'tab-line)

(defcustom my-tab-line/tab-line-height 150
  "Height of tab-bar in the buffer."
  :type 'integer
  :group 'tab-line)

(defcustom my-tab-line/foreground-color info-theme-blue-steel
  "Foreground colour of the tabline bar."
  :type 'string
  :group 'tab-line)

(defcustom my-tab-line/background-color  info-theme-dark-blue
  "Background colour of the tabline bar."
  :type 'string
  :group 'tab-line)

(defcustom my-tab-line/modified-tab-foreground-color info-theme-flat-yellow
  "Foreground colour of a tab for a modified (but not saved) buffer."
  :type 'string
  :group 'tab-line)

(defcustom my-tab-line/focus-tab-foreground-color info-theme-white-grey
  "Foreground colour of a tab for a modified (but not saved) buffer."
  :type 'string
  :group 'tab-line)

(defcustom my-tab-line/mouse-over-color info-theme-dark-green
  "Foreground colour of a tab for a modified (but not saved) buffer."
  :type 'string
  :group 'tab-line)

(defcustom my-tab-line/tab-box-outline-h 2
  "Width of the horizontal lines for the box around a tab in tabling."
  :type 'integer
  :group 'tab-line)

(defcustom my-tab-line/tab-box-outline-v 2
  "Width of the vertical lines for the box around a tab in tabling."
  :type 'integer
  :group 'tab-line)


;;; FACES for tabline

(set-face-attribute 'tab-line nil                                                 ; BACKGROUND STRIP BEHIND TABS
                    :family "source code pro"
                    :background my-tab-line/background-color
                    :foreground my-tab-line/foreground-color
                    :height my-tab-line/tab-line-height
                    :weight 'bold
                    :box `(:line-width (,my-tab-line/tab-box-outline-h
                                        . ,my-tab-line/tab-box-outline-v)
                                       :color ,my-tab-line/foreground-color))

;; tab-line-close-highlight

(set-face-attribute 'tab-line-highlight nil                                       ; TAB WITH MOUSE-OVER
                    :family "source code pro"
                    ;; :foreground my-tab-line/forground-color
                    :background my-tab-line/mouse-over-color
                    :weight 'bold
                    :height 110
                    :box `(:line-width (,my-tab-line/tab-box-outline-h
                                        . ,my-tab-line/tab-box-outline-v)
                                       :color ,my-tab-line/foreground-color))

(set-face-attribute 'tab-line-tab nil                                             ; ACTIVE TAB IN ANOTHER WINDOW
                    :family "source code pro"
                    :foreground my-tab-line/background-color
                    :background my-tab-line/foreground-color
                    :height 110
                    :weight 'bold
                    :box `(:line-width (,my-tab-line/tab-box-outline-h
                                        . ,my-tab-line/tab-box-outline-v)
                                       :color ,my-tab-line/foreground-color)
                    :extend t)

(set-face-attribute 'tab-line-tab-current nil                                     ; ACTIVE TAB CONTAINING BUFFER WITH FOCUS
                    :family "source code pro"
                    :foreground my-tab-line/focus-tab-foreground-color
                    :background my-tab-line/foreground-color
                    :height 110
                    :weight 'bold
                    :box `(:line-width (,my-tab-line/tab-box-outline-h
                                        . ,my-tab-line/tab-box-outline-v)
                                       :color ,my-tab-line/foreground-color)
                    :extend t)

;; (set-face-attribute 'tab-line-tab-group nil                                    ; TAB GROUPING (BY MODE)
;;                     :family "source code pro"
;;                     :foreground info-theme-flat-grey
;;                     :background info-theme-dark-blue
;;                     :height 110
;;                     :inherit nil
;;                     :box `(:line-width (2 . 2)
;;                                        :color ,info-theme-dark-grey))

(set-face-attribute 'tab-line-tab-inactive nil                                    ; INACTIVE TAB
                    :family "source code pro"
                    :foreground my-tab-line/foreground-color
                    :background my-tab-line/background-color
                    :height 110
                    :inherit nil
                    :box `(:line-width (,my-tab-line/tab-box-outline-h
                                        . ,my-tab-line/tab-box-outline-v)
                                       :color ,my-tab-line/foreground-color)
                    :weight 'bold)

(set-face-attribute 'tab-line-tab-inactive-alternate nil                          ; ALTERNATIVE INACTIVE TAB
                    :family "source code pro"
                    :foreground my-tab-line/foreground-color
                    :background my-tab-line/background-color
                    :height 110
                    :inherit nil
                    :box `(:line-width (,my-tab-line/tab-box-outline-h
                                        . ,my-tab-line/tab-box-outline-v)
                                       :color ,my-tab-line/foreground-color)
                    :weight 'bold)

(set-face-attribute 'tab-line-tab-modified nil                                    ; MODIFIED TAB
                    :family "source code pro"
                    :foreground my-tab-line/modified-tab-foreground-color
                    ;; :background info-theme-blue-steel
                    ;; :box `(:line-width (,my-tab-line/tab-box-outline-h
                    ;;                     . ,my-tab-line/tab-box-outline-v)
                    ;;                    :color ,info-theme-blue-steel)
                    :height 110)

;; (set-face-attribute 'tab-line-tab-special nil                                  ; SPECIAL TAB
;;                     :family "source code pro"
;;                     :foreground info-theme-flat-grey
;;                     :background info-theme-dark-blue
;;                     :height 110
;;                     :inherit nil)



;; ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
;; tabline functionality
;; ---------------------
;; the below code improves functionality for tab-line-mode.
;; It is based on this blog:
;; https://andreyor.st/posts/2020-05-10-making-emacs-tabs-look-like-in-atom/
;; with this:

;; [[https://github.com/minad/bookmark-view][bookmark-view]]
;; to allow us to more effectively control layout.
;; In addition, customise the tabline and the modeline.
;; See:
[[https://jdhao.github.io/2021/09/30/emacs_custom_tabline/][Customise Tabline]]
;; for details of the tabline functions used in crafted-workspaces-support.el.

(defun my-tab-line/tab-line-close-tab-given-buffer (buffer
                                                    &optional given-window)
  "Close the selected tab for BUFFER.

If BUFFER is presented in window other than GIVEN-WINDOW, close the tab by
using the `bury-buffer' function.  If BUFFER is unique to all existing windows,
kill the buffer with `kill-buffer' function.  Lastly, if no tabs
are left in the window, it is deleted with `delete-window' function.

This function is used in setting up the IDE."
  (interactive)
  (if (not given-window)
      (setq given-window (selected-window)))
  (with-selected-window given-window
    ;; get a list of the buffers associated with the current window.
    (let
        ((tab-list (tab-line-tabs-window-buffers))
         (buffer-list
          (flatten-list
           (seq-reduce
            (lambda (list window)
              (select-window window t)
              (cons (tab-line-tabs-window-buffers) list))
            (window-list) nil))))

      (select-window given-window)
      (if (> (seq-count (lambda (b) (eq b buffer)) buffer-list) 1)
          (progn
            (if (eq buffer (current-buffer))
                (bury-buffer)
              (set-window-prev-buffers
               given-window
               (assq-delete-all buffer (window-prev-buffers)))
              (set-window-next-buffers
               given-window
               (delq buffer (window-next-buffers))))
            (unless (cdr tab-list)
              (ignore-errors (delete-window given-window))))
        (and (kill-buffer buffer)
             (unless (cdr tab-list)
               (ignore-errors (delete-window given-window))))))))


(defun my-tab-line/tab-line-close-tab (&optional e)
  "Close the selected tab. (E  - using mouse)

If tab is presented in another window, close the tab by using the `bury-buffer'
function.  If tab is unique to all existing windows, kill the buffer with
`kill-buffer' function.  Lastly, if no tabs left in the window, it is deleted
with `delete-window' function."
  (interactive "e")
  (let* ((posnp (event-start e))
         (window (posn-window posnp))
         (buffer (get-pos-property 1 'tab (car (posn-string posnp)))))
    (with-selected-window window
      (let ((tab-list (tab-line-tabs-window-buffers))
            (buffer-list
             (flatten-list
              (seq-reduce
               (lambda (list window)
                 (select-window window t)
                 (cons (tab-line-tabs-window-buffers) list))
               (window-list) nil))))
        (select-window window)
        (if (> (seq-count (lambda (b) (eq b buffer)) buffer-list) 1)
            (progn
              (if (eq buffer (current-buffer))
                  (bury-buffer)
                (set-window-prev-buffers
                 window
                 (assq-delete-all buffer (window-prev-buffers)))
                (set-window-next-buffers
                 window
                 (delq buffer (window-next-buffers))))
              (unless (cdr tab-list)
                (ignore-errors (delete-window window))))
          (and (kill-buffer buffer)
               (unless (cdr tab-list)
                 (ignore-errors (delete-window window)))))))))


(defalias 'tab-line-close-tab 'my-tab-line/tab-line-close-tab
  "Use my-tab-line/tab-line-close-tab to close tabs carefully.")


(defun my-tab-line/tab-line-name-buffer (buffer &rest _buffers)
  "Create name for tab with padding and truncation.

If BUFFER  name is shorter than `tab-line-tab-max-width' it gets
centred with spaces, otherwise it is truncated, to preserve equal width for
all tabs.  This function also tries to fit as many tabs in window as possible,
so if there is no room for tabs with maximum width, it calculates new width
for each tab and truncates text if needed.
Minimal width can be set with `tab-line-tab-min-width' variable."
  (with-current-buffer buffer
    (let* (
           (window-width
            (window-width (get-buffer-window)))
           (tab-amount
            (length (tab-line-tabs-window-buffers)))
           (window-max-tab-width
            (if (>= (* (+ my-tab-line/tab-max-width 3) tab-amount)
                    window-width)
                (/ window-width tab-amount)
              my-tab-line/tab-max-width))
           (tab-width
            (- (cond ((> window-max-tab-width my-tab-line/tab-max-width)
                      my-tab-line/tab-max-width)
                     ((< window-max-tab-width my-tab-line/tab-min-width)
                      my-tab-line/tab-min-width)
                     (t window-max-tab-width))
               3))                                                                ; compensation for ' x ' button
           (buffer-name (string-trim (buffer-name)))
           (name-width (length buffer-name))
           )

      (if (>= name-width tab-width)
          (concat  " "
                   (truncate-string-to-width buffer-name (- tab-width 2))
                   "…")
        (let* (
               (padding
                (make-string (+ (/ (- tab-width name-width) 2) 1) ?\s))
               (buffer-name (concat padding buffer-name))
               )

          (concat buffer-name
                  (make-string (- tab-width (length buffer-name)) ?\s)))))))


;; make sure the mode is loaded before we set variables from the mode.
(global-tab-line-mode t)

;;; ** tabline setup
;; In addition, customise the tabline and the modeline.
;; See:
;; [[https://jdhao.github.io/2021/09/30/emacs_custom_tabline/][Customise Tabline]]
;; for details of the tabline functions used in crafted-workspaces-support.el.
;; Here set the fonts and the colours for each window tab.
;; We also set up exclutions from tabbing based on modes found in the buffer
;; tab candidates.

(setq tab-line-close-button-show t                                                ; show/do not show close button
      tab-line-new-button-show nil                                                ; show/do not show add-new button
      tab-line-separator ""
      tab-line-tab-name-function #'my-tab-line/tab-line-name-buffer
      tab-line-right-button

      (propertize (if (char-displayable-p ?▶) " ▶ " " > ")
                  'keymap tab-line-right-map
                  'mouse-face 'tab-line-highlight
                  'help-echo "Click to scroll right")

      tab-line-left-button
      (propertize (if (char-displayable-p ?◀) " ◀ " " < ")
                  'keymap tab-line-left-map
                  'mouse-face 'tab-line-highlight
                  'help-echo "Click to scroll left")

      tab-line-close-button
      (propertize (if (char-displayable-p ?×) "  ×  " "  x  ")
                  'keymap tab-line-tab-close-map
                  'mouse-face 'tab-line-close-highlight
                  'help-echo "Click to close tab"))



;; exclude some buffers from tab-line according to their mode.
(dolist (mode '(speedbar-mode
                corfu-mode
                corfu-popupinfo-mode
                dape-info-threads-mode
                dape-info-stack-mode
                dape-info-sources-mode
                dape-info-scope-mode
                dape-repl-mode
                dape-info-breakpoints-mode))
  (add-to-list 'tab-line-exclude-modes mode))


(defun my-tab-line/enable-tab-line-mode-for-specific-buffers ()
  "Enable `tab-line-mode' for particular buffers.

These are buffers specified  in `my-tab-line/enabled-buffers' or with names
starting with any of the prefixes in `my-tab-line/enabled-prefixes'."
  (let ((buffer-name (buffer-name)))
    (when (or (member buffer-name my-tab-line/enabled-buffers)
              (cl-some (lambda (prefix) (string-prefix-p prefix buffer-name))
                       my-tab-line/enabled-prefixes))
      (tab-line-mode 1))))

(add-hook 'fundamental-mode-hook
          #'my-tab-line/enable-tab-line-mode-for-specific-buffers)


(defun my-tab-line/tab-line-tabs-window-buffers--removed-nameless-buffers ()
  "Return a list of tabs that should be displayed in the tab line.
By default returns a list of window buffers excluding buffers without a name,
i.e. buffers previously shown in the same window where the tab line is
displayed.  It replaces the built in functionality by using `setq' to override
variable `tab-line-tabs-function'."
  (let
      ((buflist

        (let* ((window (selected-window))
               (buffer (window-buffer window))
               (next-buffers (seq-remove (lambda (b) (eq b buffer))
                                         (window-next-buffers window)))
               (next-buffers (seq-filter #'buffer-live-p next-buffers))
               (prev-buffers
                (seq-remove (lambda (b) (eq b buffer))
                            (mapcar #'car (window-prev-buffers window))))
               (prev-buffers (seq-filter #'buffer-live-p prev-buffers))
               ;; Remove next-buffers from prev-buffers
               (prev-buffers (seq-difference prev-buffers next-buffers)))
          (append (reverse prev-buffers)
                  (list buffer)
                  next-buffers))))

    (delq nil
          (mapcar
           (lambda (buf)
             (let ((name (buffer-name buf)))            ; Exclude buffers with
               (unless                                  ; names that start
                   (or (string-prefix-p                 ; with a space.
                        " " name)
                       (string-match-p                  ; Exclude corfu buffer.
                        "\\` \\*corfu\\*\\'" name)
                       (string-match-p                  ; Exclude Speedbar.
                        "\\` \\*speedbar\\*\\'" name)
                       (string-match-p                  ; Exclude marginalia.
                        "\\` \\*Marginalia\\*\\'" name))
                 buf)))
           buflist))))


(setq tab-line-tabs-function
      'my-tab-line/tab-line-tabs-window-buffers--removed-nameless-buffers)

(defun my-tab-line/close-specific-buffer (buffer-name)
  "Close BUFFER-NAME from the current window.

It ensures:
* a buffer open in other windows will be buried rather than killed so those
  other windows are not affected.
* a buffer open in only the current window will be killed rather than buried.
* if a buffer is closed in a window with only one buffer, then that window
  will also be removed by default."
  (interactive "sBuffer name: ")
  (let ((buffer (get-buffer buffer-name)))
    (when buffer
      (my-buffer-tools/switch-to-buffer-in-current-window buffer-name)
      (my-tab-line/tab-line-close-tab-given-buffer buffer))))


(provide 'tabline-support)
;;; tabline-support.el ends here

                                        ; LocalWords:  ibuffer Ediff
                                        ; LocalWords:  Dired ediff
