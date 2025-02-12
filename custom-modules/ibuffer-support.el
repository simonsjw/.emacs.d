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

;;; Code:


;;;; Ibuffer column definitions


(defgroup nerd-icons-ibuffer nil
  "Display nerd icons in ibuffer."
  :group 'nerd-icons
  :group 'ibuffer
  :link '(url-link :tag "Homepage" "https://github.com/seagle0128/nerd-icons-ibuffer"))

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

;; create an icon for the entry from nerd-icons.
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

;; ;;;; Cursor wrapping
;; ;; wrap cursor movement at top and bottom of ibuffer.
;; ;; original code from brust at https://www.emacswiki.org/emacs/IbufferMode
;; (defun my-ibuffer/advance-motion (direction)
;;   "A function to move the cursor in a given DIRECTION."
;;   (forward-line direction)
;;   (beginning-of-line)
;;   (if (not (get-text-property (point) 'ibuffer-filter-group-name))
;;       t
;;     (ibuffer-skip-properties '(ibuffer-filter-group-name)
;;                              direction)
;;     nil))

;; (defun my-ibuffer/previous-line (&optional arg)
;;   "Move backwards ARG lines, wrapping around the list if necessary."
;;   (interactive "P")
;;   (or arg (setq arg 1))
;;   (let (err1 err2)
;;     (while (> arg 0)
;;       (cl-decf arg)
;;       (setq err1 (my-ibuffer/advance-motion -1)
;;             err2 (if (not (get-text-property (point) 'ibuffer-title))
;;                      t
;;                    (goto-char (point-max))
;;                    (beginning-of-line)
;;                    (ibuffer-skip-properties '(ibuffer-summary
;;                                               ibuffer-filter-group-name)
;;                                             -1)
;;                    nil)))
;;     (and err1 err2)))

;; (defun my-ibuffer/next-line (&optional arg)
;;   "Move forward ARG lines, wrapping around the list if necessary."
;;   (interactive "P")
;;   (or arg (setq arg 1))
;;   (let (err1 err2)
;;     (while (> arg 0)
;;       (cl-decf arg)
;;       (setq err1 (my-ibuffer/advance-motion 1)
;;             err2 (if (not (get-text-property (point) 'ibuffer-summary))
;;                      t
;;                    (goto-char (point-min))
;;                    (beginning-of-line)
;;                    (ibuffer-skip-properties '(ibuffer-summary
;;                                               ibuffer-filter-group-name
;;                                               ibuffer-title)
;;                                             1)
;;                    nil)))
;;     (and err1 err2)))

;; (defun my-ibuffer/ibuffer-next-header ()
;;   "Move forwards between headers using key binding."
;;   (interactive)
;;   (while (my-ibuffer/next-line)))

;; (defun my-ibuffer/previous-header ()
;;   "Move backwards between headers using key binding."
;;   (interactive)
;;   (while (my-ibuffer/previous-line)))


;; Replace the `Size' column showing the size of the buffer with a human 
;; readable alternative.
;; (see [[https://www.emacswiki.org/emacs/IbufferMode][IbufferMode]])
(define-ibuffer-column size-h
  (:name " Size"
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
             (my-strings/bytes-to-human-readable-file-sizes total)))              ; :summarizer nil
         )
  (my-strings/bytes-to-human-readable-file-sizes (buffer-size)))


;;; Customization:

;; prefer the more full-featured built-in ibuffer for managing
;; buffers.
(keymap-global-set "<remap> <list-buffers>" #'ibuffer-list-buffers)
;; turn on forward and backward movement cycling
(customize-set-variable 'ibuffer-movement-cycle t)
;; the number of hours before a buffer is considered "old" by
;; ibuffer.
(customize-set-variable 'ibuffer-old-time 24)
;; Use header-line
(customize-set-variable 'ibuffer-use-header-line t)

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
         "  "
         (mode+ 16 16 :left :elide)
         "  "
         (vc-status 10 10 :left)
         " "
         (filename-and-process+vc 50 50 :left :elide)                             ; filename-and-process (incorporates logic from vc-relative-file.
         )
        ;; Summary view
        (mark
         " "
         (name 16 -1)
         " "
         filename-and-process)
        ))

;; (setq-local header-line-format
;;       "    MRVL Name                                 Size  Mode              VC_Status  Filename/Process")




;; Here you may adjust by replacing :right with :center or :left
;; According to taste, if you want the icon further from the name
;; " " (icon 2 2)
;; (name 18 18 :left :elide)
;; " " (size-h 9 -1 :right)

;; (name 16 -1)


;;; Keybindings:

;; (define-key ibuffer-mode-map (kbd "<up>") 'my-ibuffer/previous-line)
;; (define-key ibuffer-mode-map (kbd "<down>") 'my-ibuffer/next-line)
;; (define-key ibuffer-mode-map (kbd "<right>") 'my-ibuffer/previous-header)
;; (define-key ibuffer-mode-map (kbd "<left>") 'my-ibuffer/next-header)

;;; Hooks:

(defun my-ibuffer/ibuffer-mode-config-hook ()
  "Set up the ibuffer."
  
  ;; Define a function to set the font in ibuffer.
  ;; (face-remap-add-relative 'default  :height 90)
  
  ;; sort ibuffer by vc status. 
  ;;(ibuffer-do-sort-by-vc-status)

  ;; apply filter groups by vc-root. 
  (ibuffer-vc-set-filter-groups-by-vc-root)
  )
;;  - then add it to a hook.
(add-hook 'ibuffer-mode-hook 'my-ibuffer/ibuffer-mode-config-hook)


(provide 'ibuffer-support)
;;; ibuffer-support.el ends here


                                                                                  ; LocalWords:  ibuffer
                                                                                  ; LocalWords:  brust
                                                                                  ; LocalWords:  IbufferMode
                                                                                  ; LocalWords:  defun
