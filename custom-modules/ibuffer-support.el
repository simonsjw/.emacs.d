;;; ibuffer-support.el --- setup for treesit -*- lexical-binding: t; -*-

;; Copyright (C) 2025
;; SPDX-License-Identifier: MIT

;; Author: Simon Watson

;;; Commentary:

;; Support for ibuffer in Emacs.

;;; Imports:

(use-package ibuffer-vc)

;;(use-package buffer-menu+)

(require 'ibuffer)
(require 'ibuffer-vc)
(require 'nerd-icons)

;; Set explicit column names for headers (ensure all are defined)
(put 'mark 'ibuffer-column-name "")
(put 'icon 'ibuffer-column-name "")
(put 'modified 'ibuffer-column-name "M")
(put 'vc-status-mini 'ibuffer-column-name "V")
(put 'read-only 'ibuffer-column-name "R")
(put 'locked 'ibuffer-column-name "L")
(put 'name 'ibuffer-column-name "Name")
(put 'size-h 'ibuffer-column-name "Size")
(put 'mode+ 'ibuffer-column-name "Mode")
(put 'vc-status 'ibuffer-column-name "VC status")
(put 'filename-and-process+vc 'ibuffer-column-name "Filename/Process")

;;; Code:

;;;; Ibuffer column definitions

(defgroup nerd-icons-ibuffer nil
  "Display nerd icons in ibuffer."
  :group 'nerd-icons
  :group 'ibuffer
  :link '(url-link :tag "Homepage"
                   "https://github.com/seagle0128/nerd-icons-ibuffer"))

(defface nerd-icons-ibuffer-icon-face
  '((t (:inherit default)))
  "Face used for the icons while `nerd-icons-ibuffer-color-icon' is nil."
  :group 'nerd-icons-ibuffer)

(defface nerd-icons-ibuffer-dir-face
  '((t (:inherit font-lock-doc-face)))
  "Face used for the directory icon."
  :group 'nerd-icons-ibuffer)

(defface nerd-icons-ibuffer-size-face
  '((t (:inherit font-lock-constant-face)))
  "Face used for the size."
  :group 'nerd-icons-ibuffer)

(defface nerd-icons-ibuffer-mode-face
  '((t (:inherit font-lock-keyword-face)))
  "Face used for the major mode."
  :group 'nerd-icons-ibuffer)

(defface nerd-icons-ibuffer-file-face
  '((t (:inherit completions-annotations)))
  "Face used for the filename/process."
  :group 'nerd-icons-ibuffer)

(defcustom nerd-icons-ibuffer-icon t
  "Whether display the icons."
  :group 'nerd-icons-ibuffer
  :type 'boolean)

(defcustom nerd-icons-ibuffer-color-icon t
  "Whether display the colorful icons.

It respects `nerd-icons-color-icons'."
  :group 'nerd-icons-ibuffer
  :type 'boolean)

(defcustom nerd-icons-ibuffer-icon-size 1.0
  "The default icon size in ibuffer."
  :group 'nerd-icons-ibuffer
  :type 'float)

(defcustom nerd-icons-ibuffer-human-readable-size t
  "Use human readable file size in ibuffer."
  :group 'nerd-icons-ibuffer
  :type 'boolean)

;; For alignment, the size of the name field should be the width of an icon

;; Create an icon for the entry from nerd-icons.
(define-ibuffer-column icon
  (:name "" :inline t)
  (if nerd-icons-ibuffer-icon
      (let ((icon (cond ((and (buffer-file-name) (nerd-icons-auto-mode-match?))
                         (nerd-icons-icon-for-file
                          (file-name-nondirectory (buffer-file-name))
                          :height nerd-icons-ibuffer-icon-size))
                        ((eq major-mode 'dired-mode)
                         (nerd-icons-icon-for-dir
                          (buffer-name)
                          :height nerd-icons-ibuffer-icon-size
                          :face 'nerd-icons-ibuffer-dir-face))
                        (t
                         (nerd-icons-icon-for-mode
                          major-mode
                          :height nerd-icons-ibuffer-icon-size)))))
        (concat
         (if (or (null icon) (symbolp icon))
             (nerd-icons-faicon "nf-fa-file_o"
                                :face (if nerd-icons-ibuffer-color-icon
                                          'nerd-icons-dsilver
                                        'nerd-icons-ibuffer-icon-face)
                                :height nerd-icons-ibuffer-icon-size)
           (if nerd-icons-ibuffer-color-icon
               icon
             (propertize icon
                         'face
                         `(:inherit nerd-icons-ibuffer-icon-face
                                    :family ,(plist-get
                                              (get-text-property 0 'face icon)
                                              :family)))))
         " "))
    ""))

(define-ibuffer-column mode+
  (:name "Mode"
   :inline t
   :header-mouse-map ibuffer-mode-header-map
   :props ('font-lock-face 'nerd-icons-ibuffer-mode-face
           'mouse-face 'highlight
           'keymap ibuffer-mode-name-map
           'help-echo "mouse-2: filter by this mode"))
  (format-mode-line mode-name nil nil (current-buffer)))

(define-ibuffer-column filename-and-process+vc
  (:name "Filename/Process"
   :props ('font-lock-face 'nerd-icons-ibuffer-file-face)
   :header-mouse-map ibuffer-filename/process-header-map
   :summarizer
   (lambda (strings)
     (setq strings (delete "" strings))
     (let ((procs 0)
           (files 0))
       (dolist (string strings)
         (when (get-text-property 1 'ibuffer-process string)
           (setq procs (1+ procs)))
         (setq files (1+ files)))
       (concat (cond ((zerop files) "No files")
                     ((= 1 files) "1 file")
                     (t (format "%d files" files)))
               ", "
               (cond ((zerop procs) "no processes")
                     ((= 1 procs) "1 process")
                     (t (format "%d processes" procs)))))))
  (let ((proc (get-buffer-process buffer))
        (filename (ibuffer-make-column-filename buffer mark)))
    (if proc
        (concat (propertize (format "(%s %s)" proc (process-status proc))
                            'font-lock-face 'italic
                            'ibuffer-process proc)
                (if (> (length filename) 0)
                    (format " %s" filename)
                  ""))
      ;; below logic used from ibuffer-vc
      (if buffer-file-name
          (let ((root (cdr (ibuffer-vc-root buffer))))
            (if root
                (file-relative-name buffer-file-name root)
              (abbreviate-file-name buffer-file-name)))
        filename))))

;; Make VC status header clickable
(defvar ibuffer-vc-status-header-map
  (let ((map (make-sparse-keymap)))
    (define-key map [header-line mouse-1]
      (lambda () (interactive) (ibuffer-do-sort-by-vc-status)))
    (define-key map [header-line mouse-2]
      (lambda () (interactive) (ibuffer-do-sort-by-vc-status)))
    map)
  "Keymap for mouse clicks on the 'VC status' header in ibuffer.")

(define-ibuffer-column vc-status
  (:name "VC status"
   :header-mouse-map ibuffer-vc-status-header-map)
  (ibuffer-vc--status-string))

;; Replace the `Size' column showing the size of the buffer with a human
;; readable alternative.
;; (see [[https://www.emacswiki.org/emacs/IbufferMode][IbufferMode]])
(define-ibuffer-column size-h
  (:name " Size"
   :inline t
   :header-mouse-map ibuffer-size-header-map
   :summarizer
   (lambda (column-strings)
     (let ((total 0))
       (dolist (string column-strings)
         (setq total
               (+
                (float
                 (my-strings/human-readable-file-sizes-to-bytes string))
                total)))
       (my-strings/bytes-to-human-readable-file-sizes total))))
  (my-strings/bytes-to-human-readable-file-sizes (buffer-size)))

;;; Customization:

;; Prefer the more full-featured built-in ibuffer for managing buffers.
(keymap-global-set "<remap> <list-buffers>" #'ibuffer-list-buffers)
;; Turn on forward and backward movement cycling
(customize-set-variable 'ibuffer-movement-cycle t)
;; The number of hours before a buffer is considered "old" by ibuffer.
(customize-set-variable 'ibuffer-old-time 24)
;; Disable native header-line for filters (we'll use it for columns)
(customize-set-variable 'ibuffer-use-header-line nil)

(custom-set-faces
 '(ibuffer-header-face ((t (:foreground "cyan" :weight bold :underline t)))))

;; Modify the default ibuffer-formats. Note the two lists allow us to switch
;; between two views using the command ibuffer-switch-format.
(setq ibuffer-formats
      '(
        ;; Default view
        ;; elide is the number of characters to limit the column at.
        ((mark 1)
         (icon 2)
         (modified 1)
         (vc-status-mini 1)
         (read-only 1)
         (locked 1)
         " "
         (name 30 30 :left :elide)
         " "
         (size-h 10 -1 :right)
         "   "
         (mode+ 16 16 :left :elide)
         "  "
         (vc-status 10 10 :left)
         " "
         (filename-and-process+vc 50 50 :left :elide))                            ; filename-and-process (incorporates logic from vc-relative-file.
        ;; Summary view
        (mark
         " "
         (name 16 -1)
         " "
         filename-and-process)))

;;; Hooks:

;; Override to prevent in-buffer column header insertion
(defun my-ibuffer/insert-header-override (_format)
  "Override ibuffer's header insertion to do nothing."
  nil)

(advice-add 'ibuffer-update-title-and-summary :override #'my-ibuffer/insert-header-override)

;; Build clickable header-line string aligned to formats
(defun my-ibuffer/build-header-line ()
  "Create a clickable header-line string based on ibuffer-formats."
  (let* ((format (or (ibuffer-current-format t)
                     (error "No current format: %S" ibuffer-formats)))            ; Debug if nil
         (window-width (window-width))                                            ; Respect current window width
         (header "")
         (total-width 0))
    (dolist (col format)
      (if (stringp col)
          (progn
            (setq header (concat header col))
            (cl-incf total-width (length col)))
        (let* ((sym (if (symbolp col) col (car col)))
               (rest (if (symbolp col) nil (cdr col)))
               (min (or (pop rest) 0))
               (max (or (pop rest) -1))
               (align (or (pop rest) :left))
               (elide (or (pop rest) nil))
               (name (or (get sym 'ibuffer-column-name) (symbol-name sym)))       ; Fallback to symbol
               (hmap (get sym 'header-mouse-map))
               (len (length name))
               (padded (ibuffer-format-column name (max 0 (- min len)) align)))
          (when hmap
            (setq padded (propertize padded 'mouse-face 'highlight 'keymap hmap 'help-echo (format "Click to sort by %s" sym))))
          (setq header (concat header padded))
          (cl-incf total-width min)))
      ;;(message "Col: %S, Header so far: %S, Total width: %d" col header total-width); Debug each step
      )  
    ;; Truncate or pad to window width
    (let ((current-width (string-width header)))
      (if (> current-width window-width)
          (substring header 0 window-width)
        (concat header (make-string (- window-width current-width) ?\s))))))

(defun my-ibuffer/ibuffer-config-hook (&rest _)
  "Set up the ibuffer header after update."
  (when (eq major-mode 'ibuffer-mode)
    (ibuffer-auto-mode 1)                                                         ; make ibuffer refresh automatically. 
    (setq header-line-format (my-ibuffer/build-header-line))))

;; Advice to run config after ibuffer-update
(advice-add 'ibuffer-update :after #'my-ibuffer/ibuffer-config-hook)


(defun my-ibuffer/mouse-bring-to-front (event)
  "Bring the buffer chosen with the mouse to the front.

If the BUFFER is already displayed in any window (including on other
frames), select that window and raise the frame to the top.  

Otherwise, visit the buffer in the current window using
`SWITCH-TO-BUFFER'.

EVENT is the mouse event passed by the keymap.
This function sets point temporarily to locate the buffer then
restores normal flow."
  (interactive "e")
  (let* ((buf (save-excursion
                (mouse-set-point event)
                (ibuffer-current-buffer t)))
         (win (and buf (get-buffer-window buf t))))
    (if (window-live-p win)
        (progn
          (select-window win)
          (raise-frame (window-frame win)))
      (when buf
        (switch-to-buffer buf)))))

(with-eval-after-load 'ibuffer

  (define-key ibuffer-name-map [mouse-1] #'my-ibuffer/mouse-bring-to-front)       ; set up ibuffer so clicking the names brings that element to the front in whatever window it is in. 
  )

(provide 'ibuffer-support)
;;; ibuffer-support.el ends here
