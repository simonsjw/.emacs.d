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

;;; Code:


;;;; Ibuffer column definitions
;; Replace the `Size' column showing the size of the buffer with a human readable
;; alternative.
;; (see [[https://www.emacswiki.org/emacs/IbufferMode][IbufferMode]])
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
             (my-strings/bytes-to-human-readable-file-sizes total)))              ; :summarizer nil
         )
  (my-strings/bytes-to-human-readable-file-sizes (buffer-size)))


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

;;; Customization:

;; prefer the more full-featured built-in ibuffer for managing
;; buffers.
(keymap-global-set "<remap> <list-buffers>" #'ibuffer-list-buffers)
;; turn on forward and backward movement cycling
(customize-set-variable 'ibuffer-movement-cycle t)
;; the number of hours before a buffer is considered "old" by
;; ibuffer.
(customize-set-variable 'ibuffer-old-time 24)

;; Modify the default ibuffer-formats. Note the two lists allow us to switch
;; between two views using the command ibuffer-switch-format.
(setq ibuffer-formats
      '(
        
        ;; Default view
        (mark
         modified
         read-only
         vc-status-mini
         locked
         " "
         (name 20 20 :left :elide)
         " "
         (size-h 11 -1 :right)
         " "
         (mode 16 16 :left :elide)
         " "
         (vc-status 16 16 :left)
         " "
         vc-relative-file
         " "
         filename-and-process)
        
        ;; Summary view
        (mark
         " "
         (name 16 -1)
         " "
         filename-and-process)
        )
      )


;;; Keybindings:

;; (define-key ibuffer-mode-map (kbd "<up>") 'my-ibuffer/previous-line)
;; (define-key ibuffer-mode-map (kbd "<down>") 'my-ibuffer/next-line)
;; (define-key ibuffer-mode-map (kbd "<right>") 'my-ibuffer/previous-header)
;; (define-key ibuffer-mode-map (kbd "<left>") 'my-ibuffer/next-header)

;;; Hooks:

;; (defun my-ibuffer/ibuffer-mode-config-hook ()
;;   "Define a function to set the font in ibuffer."
;;   (face-remap-add-relative 'default  :height 90))
;; ;;  - then add it to a hook.
;; (add-hook 'ibuffer-mode-hook 'my-ibuffer/ibuffer-mode-config-hook)


(provide 'ibuffer-support)
;;; ibuffer-support.el ends here


                                                                                  ; LocalWords:  ibuffer
                                                                                  ; LocalWords:  brust
                                                                                  ; LocalWords:  IbufferMode
