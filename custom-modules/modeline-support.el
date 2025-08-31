;;; mode-line-support.el --- modeline support for the crafted setup   -*- lexical-binding: t -*-

;; Copyright (C) 2022
;; SPDX-License-Identifier: MIT

;; Author: Simon Watson
;; Keywords: mode-line modeline

;;; Commentary:

;; This package handles modeline customisation.

;;; Declarations and imports

(require 'delight)

(declare-function
 my-in-buffer-tools/get-matching-bracket-position "system-tools")
(declare-function
 my-window-tools/get-tag-given-window "system-window-management")
;; (declare-function delight "delight")

(defvar nerd-icons-mode-icon-alist "nerd-icons")

;;; Code:
;; Show compile status in the mode line
(setq auto-compile-use-mode-line t)

;;;; CUSTOM SEGMENTS.

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


;;;;;; Modeline Matching Bracket

;; First, save the default mode-line-position (which displays line and column).
(defvar my-modeline/default-mode-line-position
  (default-value 'mode-line-position)
  "The default value of `mode-line-position' before customisation.")

;; Define a mode-line element that shows matching bracket info if available.
(defvar-local my-modeline/position-or-matching-bracket
    '(:eval
      (let* ((match-info
              (my-in-buffer-tools/get-matching-bracket-position (point)))
             (match-string (if match-info
                               (let ((line   (nth 0 match-info))
                                     (column (nth 1 match-info))
                                     (char   (nth 3 match-info)))
                                 (format " ['%s':L%d:C%d] " char line column))
                             "")))
        (if (not (string-empty-p match-string))
            match-string
          ;; Fall back to the default mode-line position formatting.
          (format-mode-line my-modeline/default-mode-line-position))))
  "This mode-line element displays position or matching bracket info,

The matching bracket info is shown if the cursor is near a bracket.")


;; ##########################################################################
;; END OF CUSTOM SEGMENTS.


;; Propertize modeline variables with `risky-local-variable'. Variables will
;; not work without it.
(dolist (construct '(my-modeline/position-or-matching-bracket
                     my-modeline/buffer-icon))
  (put construct 'risky-local-variable t))


;;;;;; Delight
;; change some built in minor modes.
(use-package emacs
  :delight
  (page-break-lines-mode)
  (eldoc-mode)
  (auto-fill-function " AF")
  (visual-line-mode))

(delight '((compile-angel-on-save-local-mode nil compile-angel)
           (yas-minor-mode nil yasnippet)
        ;;   (which-key-mode nil which-key)
           (flyspell-mode nil flyspell)
           (compile-angel-on-load-mode nil compile-angel)))


;;;;;; Set up modeline layout

(setq-default mode-line-format
              '(
                "%e"
                mode-line-front-space
                (:propertize my-modeline/buffer-icon)
                " "
                (:propertize
                 (""
                  mode-line-mule-info
                  mode-line-client
                  mode-line-modified
                  mode-line-remote
                  mode-line-window-dedicated)
                 display (min-width (2.0)))
                mode-line-frame-identification
                mode-line-buffer-identification
                "  "
                my-modeline/position-or-matching-bracket
                (project-mode-line project-mode-line-format)
                (vc-mode vc-mode)
                "  "
                mode-line-modes
                mode-line-misc-info
                mode-line-end-spaces))

;;; Define Org key maps
;;;; Links
;; (global-set-key (kbd "C-c l s") #'org-store-link)
;; (global-set-key (kbd "C-c l i") #'org-insert-link-global)
;; (global-set-key (kbd "C-c l o") #'org-open-at-point-global)

;;;; Agenda
;;(global-set-key (kbd "C-c a") #'org-agenda-list)
(global-set-key (kbd "C-c a") #'my-org/open-agenda)

;;;; Org Capture
;; (global-set-key (kbd "C-c c") #'org-capture)

(provide 'modeline-support)
;;; modeline-support.el ends here

                                                                                  ; LocalWords:  FIXME
