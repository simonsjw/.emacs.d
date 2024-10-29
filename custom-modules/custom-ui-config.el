;;; custom-ui-config.el --- Ui configuration  -*- lexical-binding: t; -*-

;; Copyright (C) 2022
;; SPDX-License-Identifier: MIT

;; Author: System Crafters Community
;; Keywords: ui

;;; Commentary:

;; Use tabline to manage workspaces
;; Define useful functions to manage workspaces.
;; (tabline is built in). 

;;; Code:
(require 'delight)
(require 'hydra)
(require 'major-mode-hydra)
(require 'tab-line)  ;; (tab-line is built in)
(require 'ibuffer)
(require 'easymenu)
(require 'custom-system-tools)

;;; Code:


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Dired Buffer title
(defun my-dired/set-dired-buffer-title ()
  "Set Dired buffer title to 'Dired: <immediate directory>'."
  (when (eq major-mode 'dired-mode)
    (let*
        ((dir-name (expand-file-name dired-directory))
         (base-name (file-name-nondirectory
                     (directory-file-name dir-name))))
      (rename-buffer (concat "Dired: "
                             (if (string= base-name "")
                                 "/" base-name))
                     t))))

(add-hook 'dired-after-readin-hook 'my-dired/set-dired-buffer-title)


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; tabline functionality
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; the below code improves functionality for tab-line-mode.
;; It is based on this blog:
;; https://andreyor.st/posts/2020-05-10-making-emacs-tabs-look-like-in-atom/
;; with this: 
;; [[https://github.com/minad/bookmark-view][bookmark-view]]
;; to allow us to more effectively control layout.  
;; In addition, customise the tabline and the modeline.
;; See:
;; [[https://jdhao.github.io/2021/09/30/emacs_custom_tabline/][Customise Tabline]]
;; for details of the tabline functions used in crafted-workspaces-support.el.

(defcustom my-tab-line/tab-min-width 10
  "Minimum width of a tab in characters."
  :type 'integer
  :group 'tab-line)

(defcustom my-tab-line/tab-max-width 30
  "Maximum width of a tab in characters."
  :type 'integer
  :group 'tab-line)

(defun my-tab-line/tab-line-close-tab-given-buffer (buffer &optional given-window)
  "Close the selected tab for BUFFER.

If BUFFER is presented in another window, close the tab by using the
`bury-buffer' function. If BUFFER is unique to all existing windows,
kill the buffer with `kill-buffer' function. Lastly, if no tabs
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
  "Close the selected tab.

     If tab is presented in another window, close the tab by using the
     `bury-buffer' function.  If tab is unique to all existing windows,
     kill the buffer with `kill-buffer' function.  Lastly, if no tabs
     left in the window, it is deleted with `delete-window' function."
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

If buffer name is shorter than `tab-line-tab-max-width' it gets
centred with spaces, otherwise it is truncated, to preserve equal width for
all tabs. This function also tries to fit as many tabs in window as possible,
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
            (if (>= (* (+ my-tab-line/tab-max-width 3) tab-amount) window-width)
                (/ window-width tab-amount)
              my-tab-line/tab-max-width))
           (tab-width
            (- (cond ((> window-max-tab-width my-tab-line/tab-max-width)
                      my-tab-line/tab-max-width)
                     ((< window-max-tab-width my-tab-line/tab-min-width)
                      my-tab-line/tab-min-width)
                     (t window-max-tab-width))
               3)) ; compensation for ' x ' button
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


(setq tab-line-close-button-show t
      tab-line-new-button-show nil
      tab-line-separator "|"
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
                ;; ediff-mode
                ;; process-menu-mode
                ;; term-mode
                ;; vterm-mode
                ;; imenu-list-mode
                ;; dired-mode
                ;; ibuffer-mode
                ))
  (add-to-list 'tab-line-exclude-modes mode))


;; exclude all tabs that do not have a name.
(defvar  my-tab-line/tab-line-sort-by-most-recent nil)


;; Set up exceptions to the rules prohibiting tab-line-mode.
(defvar my-tab-line/enabled-buffers
  '("*Async-native-compile-log*" "*Messages*")
  "List of buffer names where `tab-line-mode` should always be enabled.")


(defvar my-tab-line/enabled-prefixes
  '("*EGLOT")
  "List of buffer name prefixes where `tab-line-mode` should be enabled.")


(defun my-tab-line/enable-tab-line-mode-for-specific-buffers ()
  "Enable `tab-line-mode` for buffers in `my-tab-line-enabled-buffers`
or with names starting with any of the prefixes in
`my-tab-line-enabled-prefixes`."
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
displayed. This list can be overridden by changing the default value of the
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
                        "\\`\\*speedbar\\*\\'" name)    
                       (string-match-p                  ; Exclude marginalia.
                        "\\`\\*Marginalia\\*\\'" name)) 
                 buf)))
           buflist))))


(setq tab-line-tabs-function
      'my-tab-line/tab-line-tabs-window-buffers--removed-nameless-buffers)


(defun my-tab-line/close-specific-buffer (buffer-name)
  "Close BUFFER-NAME from the current window, handling all necessary steps.

This function is used in setting up the IDE."
  (interactive "sBuffer name: ")
  (let ((buffer (get-buffer buffer-name)))
    (when buffer
      (my-buffer-tools/switch-to-buffer-in-current-window buffer-name)
      (my-tab-line/tab-line-close-tab-given-buffer buffer))))


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; ibuffer mode
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

;; Make the buffer size human readable.
;; (see https://www.emacswiki.org/emacs/IbufferMode)
;; Use human readable Size column instead of original one
(define-ibuffer-column size-h
  (:name "Size"
         :inline t
         :summarizer
         (lambda (column-strings)
           (let ((total 0))
             (dolist (string column-strings)
               (setq total
                     (+
                      (float
                       (my-strings/human-readable-file-sizes-to-bytes string))
                      total)))
             (my-strings/bytes-to-human-readable-file-sizes total)))  ; :summarizer nil
         )
  (my-strings/bytes-to-human-readable-file-sizes (buffer-size)))

;; Modify the default ibuffer-formats. Note the two lists allow us to switch
;;  between two views using the command `=ibuffer-switch-format=
(setq ibuffer-formats
      '((mark
         modified
         read-only
         locked
         " "
         (name 20 20 :left :elide)
         " "
         (size-h 11 -1 :right)
         " "
         (mode 16 16 :left :elide)
         " "
         filename-and-process)
        (mark
         " "
         (name 16 -1)
         " "
         filename)))

;; define a function to set the font in ibuffer - then add it to a hook.
(defun my-ibuffer/ibuffer-mode-config-hook ()
  (face-remap-add-relative 'default  :height 90))

(add-hook 'ibuffer-mode-hook 'my-ibuffer/ibuffer-mode-config-hook)

;; handle ensuring minor modes don't crowd the modeline.
(delight '((checkdoc-minor-mode nill "checkdoc")
           (eldoc-mode nil "eldoc")
           (flyspell-mode nil "flyspell")
           (olivetti-mode nil "olivetti")
           (magit-wip-mode nil "magit-wip")
           (undo-tree-mode nil "undo-tree")
           (editorconfig-mode nil "editorconfig")
           (bufler-mode nil "bufler")
           (aggressive-indent-mode nil "aggressive-indent")
           (anaconda-mode nil "anaconda-mode")
           (blacken-mode nil "blacken")
           ))


;; Define key maps
;;CNTRL-SPACE activates any major-mode-hydra defined. 
(global-set-key (kbd "C-SPC") #'major-mode-hydra)

;; Manage your change indicators. 
(defun my-ui/add-change-indicators-right-click-menu()
  "Add 'Remove Change Indicators' to right-click menu in prog-mode."
  (easy-menu-define my-prog-mode-menu prog-mode-map
    "Custom right-click menu for prog-mode."
    '("Change Indicators"
      ["Remove Indicators" highlight-changes-remove-highlight t]
      ["Rotate Indicators" highlight-changes-rotate-faces t]))
  
  ;; Bind the custom menu to right-click
  (define-key prog-mode-map [mouse-3] 'my-prog-mode-menu))

;; Add the function to prog-mode-hook to ensure it's active in prog-mode buffers
(add-hook 'prog-mode-hook 'my-ui/add-change-indicators-right-click-menu)

;; Define menu items

;; (with-eval-after-load 'projectile
;;   (let ((itemPath '("Projectile" "Projects")))
;;     (progn
;;       (easy-menu-add-item
;;        nil itemPath                  ; nil - default to global menu. 
;;        ["New project frame"          ; text to put in menu
;;         my-ui/create-project-frame   ; function to run 
;;         t]                           ; condition when it is shown (t - always)
;;        "Switch to project")          ; the menu item it is in front of. 
;;       (easy-menu-add-item
;;        nil itemPath "--" "New project frame")
;;       )))

(provide 'custom-ui-config)
;;; custom-ui-config.el ends here
