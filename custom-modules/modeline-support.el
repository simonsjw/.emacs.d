;;; mode-line-support.el --- modeline support for the crafted setup   -*- lexical-binding: t -*-

;; Copyright (C) 2022
;; SPDX-License-Identifier: MIT

;; Author: Simon Watson
;; Keywords: mode-line modeline

;;; Commentary:

;; This package handles modeline customisation.

;;; Declarations and imports


(declare-function
 my-in-buffer-tools/get-matching-bracket-position "custom-system-tools")
(declare-function
 my-window-tools/get-tag-given-window "system-window-management")
;; (declare-function delight "delight")

(defvar nerd-icons-mode-icon-alist "nerd-icons")

;;; Code:


;; ##########################################################################
;;;; CUSTOM SEGMENTS.
;; ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++


;;;;;; loadbalancer Process List

;; (defun q-loadbalancer-buffer-list-segment ()
;;   "Display buffers with names starting with '*Q PROC:' in q-loadbalancer-mode."
;;   (let ((buffers (seq-filter (lambda (buf)
;;                                (string-prefix-p "*Q PROC:" (buffer-name buf)))
;;                              (buffer-list))))
;;     (mapconcat (lambda (buf) (buffer-name buf)) buffers " | ")))


;;;;;; Buffer Icon

(defvar-local my-modeline/buffer-icon
    '(:eval
      (let ((icon (nerd-icons-icon-for-buffer)))
        (if icon
            icon
          "")))
  "Display the icon for the current buffer in the mode-line.")

;;;;;; Modeline Window Tag 
;; (defun my-modeline/drag-window-boundary (start-event)
;;   "Allow dragging of window boundaries when the mode-line element is clicked.

;; START-EVENT is the mouse event starting the window edge drag."
;;   (interactive "e")
;;   (let ((start-pos (event-start start-event))
;;         (window (selected-window)))
;;     (track-mouse
;;       (while (let ((event (read-event)))
;;                (and (mouse-movement-p event)
;;                     (let ((delta-x (- (car (posn-x-y (event-end event)))
;;                                       (car (posn-x-y start-pos))))
;;                           (delta-y (- (cdr (posn-x-y (event-end event)))
;;                                       (cdr (posn-x-y start-pos)))))
;;                       ;; Adjust left boundary if horizontal movement is detected
;;                       (when (/= delta-x 0)
;;                         (adjust-window-trailing-edge window delta-x t))
;;                       ;; Adjust bottom boundary if vertical movement is detected
;;                       (when (/= delta-y 0)
;;                         (adjust-window-trailing-edge window (- delta-y) nil))
;;                       t)))))))

;; (defvar-local my-modeline/window-tag
;;     '(:eval
;;       (let ((tag (my-window-tools/get-tag-given-window)))
;;         (if tag
;;             (propertize (format "[%s]" tag)
;;                         'face (if (mode-line-window-selected-p)
;;                                   'mode-line-highlight                            ; Face for the active mode-line
;;                                 'mode-line-inactive))                             ; Face for the inactive mode-line
;;           "")))
;;   "Return the tag of the current window for the modeline.")

;; (defvar-local my-modeline/window-tag
;;     '(:eval
;;       (let ((tag (my-window-tools/get-tag-given-window)))
;;         (if tag
;;             (propertize (format "[%s]" tag)
;;                         'face (if (mode-line-window-selected-p)
;;                                   'mode-line-highlight
;;                                 'mode-line-inactive)
;;                         'mouse-face 'mode-line-highlight
;;                         'help-echo "Drag to resize window"
;;                         'local-map
;;                         (let ((map (make-sparse-keymap)))
;;                           (define-key map [mode-line down-mouse-1] #'my-modeline/drag-window-boundary)
;;                           map))
;;           "")))
;;   "Return the tag of the current window for the modeline.")

;; my-font-faces/mode-line-clicked

;; First define a face for the active mouse press.
(defface my-face/active
  '((t :background "orange" :foreground "black"))
  "Face used on the modeline element while actively dragging.")

(defun my-drag-window-resize (event)
  "Resize the current window by dragging in the mode-line.
EVENT must be a down-mouse-1 event in the mode-line."
  (interactive "e")
  (let* ((start (event-start event))
         (start-col-row (posn-col-row start))
         (start-x (car start-col-row))
         (start-y (cdr start-col-row))
         (done nil))
    ;; Make sure this window is selected so we enlarge it.
    (select-window (posn-window start))
    (track-mouse
      (while (not done)
        (let ((ev (read-event)))
          (cond
           ;; Mouse drag event
           ((mouse-movement-p ev)
            (let* ((pos (event-start ev))
                   (col-row (posn-col-row pos))
                   (dx (- (car col-row) start-x))
                   (dy (- (cdr col-row) start-y)))
              ;; Horizontal resizing: move right boundary
              (when (/= dx 0)
                ;; enlarge-window (positive DX => enlarge; negative => shrink)
                (ignore-errors (enlarge-window dx t)))
              ;; Vertical resizing: move bottom boundary
              (when (/= dy 0)
                (ignore-errors (enlarge-window dy))))
            ;; Update reference point
            (setq start-x (car (posn-col-row (event-start ev))))
            (setq start-y (cdr (posn-col-row (event-start ev)))))
           ;; Mouse up event or anything else
           (t
            (setq done t))))))))


;; Now let’s attach this to the mode-line element:
;; (defvar-local my-modeline/window-tag
;;     '(:eval
;;       (let ((tag (my-window-tools/get-tag-given-window)))
;;         (if tag
;;             (propertize (format "[%s]" tag)
;;                         ;; Use an appropriate face for active/inactive windows:
;;                         'face (if (mode-line-window-selected-p)
;;                                   'mode-line-highlight
;;                                 'mode-line-inactive)
;;                         ;; Change face while mouse is over or pressed:
;;                         ;; 'mouse-face 'my-face/active
;;                         ;; Attach a keymap that invokes our drag function:
;;                         'local-map (let ((map (make-sparse-keymap)))
;;                                      (define-key map [mode-line down-mouse-3]
;;                                                  '(lambda ()
;;                                                     "Ask for confirmation before deleting the window."
;;                                                     (when (y-or-n-p "Are you sure you want to delete this window?"))
;;                                                     (delete-window)))
;;                                      map)
;;                         ;; Optional tool-tip:
;;                         'help-echo "Right click to delete window.")
;;           "")))
;;"Return the tag of the current window for the modeline.")



;;;;;; Modeline Matching Bracket

(defvar-local my-modeline/matching-bracket
    '(:eval (let* ((match-info
                    (my-in-buffer-tools/get-matching-bracket-position (point)))   ; Get matching bracket information
                   (display-info
                    (if match-info
                        ;; If match-info is available, format the bracket details
                        (let* ((line (nth 0 match-info))
                               (column (nth 1 match-info))
                               (char (nth 3 match-info)))
                          (format " ['%s':L%d:C%d] " char line column))
                      ;; If no match-info, return the default position data.
                      mode-line-position)))
              ;; Return the formatted string or an empty string
              display-info))
  "Displays the matching bracket information if the cursor is near a bracket.

If the cursor is not on or next to a bracket, display the default position info.")

;; pyvenv


;;;;;; sly mode-line entry

;; fix up the recursive sly--mode-line-format error.
;; (defun my-modeline/sly-mode-line-setup()
;;   "Setup or update the mode-line for buffers with Sly-mode."
;;   '(:eval
;;     (if (sly-connected-p)
;;         ;; Make mode-line-misc-info buffer-local
;;         (setq-local mode-line-misc-info mode-line-misc-info)
;;       ;; Add Eglot to mode-line-misc-info, if not already added
;;       (add-to-list 'mode-line-misc-info " [Sly:Connected]")
;;       (setq-local mode-line-misc-info
;;                   (remove " [Sly:Connected]" mode-line-misc-info)))
;;     (force-mode-line-update)))


;; (add-hook 'sly-mode-hook #'my-modeline/sly-mode-line-setup)



;;;;;;  eglot mode-line entry

;; fix up the recursive eglot--mode-line-format error.
;; (defun my-modeline/eglot-mode-line-setup ()
;;   "Setup or update the mode-line for buffers managed by Eglot."
;;   ;; Make mode-line-misc-info buffer-local
;;   (setq-local mode-line-misc-info mode-line-misc-info)
;;   ;; Add the static string to mode-line-misc-info if not already present
;;   (unless (member '(" [Eglot:Active]") mode-line-misc-info)
;;     (add-to-list 'mode-line-misc-info '(" [Eglot:Active]")))
;;   (force-mode-line-update))

;; (defun my-modeline/eglot-mode-line-cleanup ()
;;   "Remove Eglot-related information from the mode-line."
;;   ;; Remove the static string from mode-line-misc-info
;;   (setq-local mode-line-misc-info
;;               (remove '(" [Eglot:Active]") mode-line-misc-info))
;;   (force-mode-line-update))


;; ;; Hook these functions into Eglot lifecycle events
;; (add-hook 'eglot-managed-mode-hook #'my-modeline/eglot-mode-line-setup)
;; (add-hook 'eglot-unmanaged-mode-hook #'my-modeline/eglot-mode-line-cleanup)


;; Projectile
(customize-set-variable 'projectile-mode-line-prefix " Project:")

;; (defvar-local my-modeline/projectile
;;     `(:eval
;;       (when (and (bound-and-true-p projectile-mode)
;;                  (mode-line-window-selected-p))
;;         (propertize projectile--mode-line
;;                     'help-echo "Projectile menu"
;;                     'mouse-face 'mode-line-highlight
;;                     'keymap (let ((map (make-sparse-keymap)))
;;                               (define-key map [mode-line down-mouse-1]
;;                                           (lambda ()
;;                                             (interactive)
;;                                             (easy-menu-show
;;                                              (lookup-key projectile-mode-map [menu-bar projectile]))))
;;                               map))))
;;   "Mode line construct displaying `Projectile`.
;; Specific to the current window's mode line.")

;; (easy-menu-define my-prog-mode-menu                                             ; symbol-name
;;   (current-local-map)                                                           ; maps
;;   "Menu for comment-related functions."                                         ; docs
;;   my-custom-menus/comment-menu)
                                                                                  ; menu


;;;;;; Flymake entry

(declare-function flymake--severity "flymake" (type))
(declare-function flymake-diagnostic-type "flymake" (diag))

;; Based on `flymake--mode-line-counter'.
(defun my-modeline/flymake-counter (type)
  "Compute number of diagnostics in buffer with TYPE's severity.
TYPE is usually keyword `:error', `:warning' or `:note'."
  (let ((count 0))
    (dolist (d (flymake-diagnostics))
      (when (= (flymake--severity type)
               (flymake--severity (flymake-diagnostic-type d)))
        (cl-incf count)))
    (when (cl-plusp count)
      (number-to-string count))))

(defvar my-modeline/flymake-map
  (let ((map (make-sparse-keymap)))
    (define-key map [mode-line down-mouse-1] 'flymake-show-buffer-diagnostics)
    (define-key map [mode-line down-mouse-3] 'my-flymake/show-project-diagnostics)
    map)
  "Keymap to display on Flymake indicator.")

(defmacro my-modeline/flymake-type (type indicator &optional face)
  "Return function that handles Flymake TYPE with stylistic INDICATOR and FACE."
  `(defun ,(intern (format "my-modeline/flymake-%s" type)) ()
     (when-let*
         ((count (my-modeline/flymake-counter
                  ,(intern (format ":%s" type)))))
       (concat
        (propertize ,indicator 'face 'shadow)
        (propertize
         count
         'face ',(or face type)
         'mouse-face 'mode-line-highlight
         ;; FIXME 2023-07-03: Clicking on the text with
         ;; this buffer and a single warning present, the
         ;; diagnostics take up the entire frame.  Why?
         'local-map my-modeline/flymake-map
         'help-echo
         "mouse-1: buffer diagnostics\nmouse-3: project diagnostics")))))

;; "☣"  "!"
(my-modeline/flymake-type error "" error)
(my-modeline/flymake-type warning "!" warning)
(my-modeline/flymake-type note "·" success)

(defvar-local my-modeline/flymake
    `(:eval
      (when (and (bound-and-true-p flymake-mode)
                 (mode-line-window-selected-p))
        (list
         ;; See the calls to the macro `my-modeline/flymake-type'
         '(:eval (my-modeline/flymake-error))
         '(:eval (my-modeline/flymake-warning))
         '(:eval (my-modeline/flymake-note)))))
  "Mode line construct displaying `flymake-mode-line-format'.
Specific to the current window's mode line.")

;;;;;; Eglot

;; (with-eval-after-load 'eglot
;;   (setq mode-line-misc-info
;;         (delete '(eglot--managed-mode (" [" eglot--mode-line-format "] ")) mode-line-misc-info)))

;; (defvar-local my-modeline/eglot
;;     `(:eval
;;       (when (and (featurep 'eglot) (mode-line-window-selected-p))
;;         '(eglot--managed-mode eglot--mode-line-format)))
;;   "Mode line construct displaying Eglot information.
;; Specific to the current window's mode line.")

;; ##########################################################################
;; END OF CUSTOM SEGMENTS.


;; Propertize modeline variables with `risky-local-variable'. Variables will
;; not work without it.
;; (dolist (construct '(my-modeline/matching-bracket
;;                      my-modeline/window-tag
;;                      my-modeline/buffer-icon
;;                      my-modeline/flymake
;;                      my-modeline/eglot
;;                      my-modeline/projectile
;;                      my-modeline/vc-info
;;                      pyvenv-mode-line-indictator
;;                      my-speedbar/show-relative-path))
;;   (put construct 'risky-local-variable t))


;;;;;; Set up modeline layout


;; (setq-default mode-line-misc-info
;;               '(
;;                 (sly-mode
;;                  (" [" sly--mode-line-format "] "))
;;                 (dape-active-mode
;;                  ("[" dape--mode-line-format "] "))
;;                 (eglot--managed-mode
;;                  (" [" eglot--mode-line-format "] "))
;;                 (which-function-mode
;;                  (which-func-mode
;;                   ("" which-func-format " ")))
;;                 ("" so-long-mode-line-info)
;;                 (global-mode-string
;;                  ("" global-mode-string))))

;; (setq-default mode-line-format
;;               '("%e"
;;                 my-modeline/window-tag
;;                 " "
;;                 my-modeline/buffer-icon
;;                 mode-line-front-space
;;                 (:propertize
;;                  (" "
;;                   mode-line-mule-info
;;                   mode-line-client
;;                   mode-line-modified
;;                   mode-line-remote
;;                   mode-line-auto-compile)
;;                  display
;;                  (min-width
;;                   (1.0)))
;;                 " "
;;                 mode-line-buffer-identification
;;                 "  "
;;                 ;;   (:eval projectile-update-mode-line)
;;                 " "
;;                 my-modeline/matching-bracket
;;                 " "
;;                 mode-name
;;                 " "
;;                 ;; (:eval my-modeline/vc-info)
;;                 " "
;;                 (:eval (pyvenv-mode pyvenv-mode-line-indicator))
;;                 ;;    (:eval my-modeline/eglot)
;;                 " "
;;                 my-modeline/flymake
;;                 mode-line-end-spaces
;;                 ))


;; The default original:
;; --------------------
;; ("%e" mode-line-front-space
;;  (:propertize
;;   (""
;;    mode-line-mule-info
;;    mode-line-client
;;    mode-line-modified
;;    mode-line-remote
;;    mode-line-auto-compile)
;;   display
;;   (min-width
;;    (5.0)))
;;  mode-line-frame-identification
;;  mode-line-buffer-identification
;;  "   "
;;  mode-line-position
;;  (vc-mode vc-mode)
;;  "  "
;;  mode-line-modes
;;  mode-line-misc-info
;;  mode-line-end-spaces)

(provide 'modeline-support)
;;; modeline-support.el ends here

                                                                                  ; LocalWords:  FIXME
