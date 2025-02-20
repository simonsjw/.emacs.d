;;; ui-config.el --- UI configuration  -*- lexical-binding: t; -*-

;; Local Variables:
;; outline-regexp:  ";;;+"
;; outline-start:  ";;"
;; outline-level: my-outline-mode/outline-level
;; End:

;; Copyright (C) 2022
;; SPDX-License-Identifier: MIT

;; Author: System Crafters Community
;; Keywords: UI User Interface

;;; Commentary:

;; Use tabline to manage workspaces
;; Define useful functions to manage workspaces.
;; (tabline is built in).

;;; Code:

(use-package bookmark+
  :vc (:url "https://github.com/emacsmirror/bookmark-plus.git"))
(use-package info+
  :vc (:url "https://github.com/emacsmirror/info-plus.git"))
(use-package dired+
  :vc (:url "https://github.com/emacsmirror/dired-plus.git"))
(use-package imenu-list)
(use-package elisp-demos)
(use-package page-break-lines)

;; docs in windows over code.
(use-package eldoc-box)

(require 'org)
(require 'outline)
(require 'easymenu)

(require 'bookmark+)                                                              ; commands usually have a bmkp prefix.
(require 'dired+)                                                                 ; commands usually have a diredp prefix.
(require 'info+)
(require 'page-break-lines)

(defvar org-roam-directory)

(defvar rainbow-hexadecimal-colors-font-lock-keywords)

(defvar rainbow-x-colors)
(defvar rainbow-x-colors-font-lock-keywords)
(defvar rainbow-latex-rgb-colors)
(defvar rainbow-rgb-colors-font-lock-keywords)

(defvar ediff-window-setup-function)

(defvar ediff-split-window-function)
(defvar ediff-buffer-A)
(defvar ediff-buffer-B)
(defvar ediff-merge-buffer)

(declare-function global-page-break-lines-mode "page-break-lines-mode")
(declare-function ediff-get-file-name "ediff")


;; replace form-feed with clean lines.

(global-page-break-lines-mode 1)


;;;; Outline-mode/Outline-minor-mode

;; The below function can be used to determine the outline-level for use with
;; outline-mode and outline-minor-mode.

(defun my-outline-mode/outline-level (&optional outline-start)
  "Calculate the outline level from the number of characters in START-STRING.

If OUTLINE-START is not provided, default to the length of `outline-regexp'
minus one.  It also accounts for leading white-space.  A typical formatting
expression for an Elisp script might be:
  ;; Local Variables:
  ;; outline-regexp:  \"^[[:space:]]*;;;+\"  ; note that ^[[:space:]]* allows
                                             ; white-space in front of the
                                             ; outline mark.
  ;; outline-start:  \";;\"
  ;; outline-level: my-outline-mode/outline-level
  ;; End:"
  (let ((match (match-string 0)))
    (if (not match)
        nil                                                                      ; Return nil to indicate the line is not a heading
      (let* ((trimmed-match (string-trim-left match))                            ; Remove leading spaces
             (n (length trimmed-match))                                          ; get the length of the last matched string.
             (regex-length (length outline-regexp))                              ; get the length of the regex string.
             ;; outline-start is provided so subtract that from the total
             ;; length of the string to get the number of outlines in.
             ;; Example: for outline start of ';;'
             ;; ;;;    is level 1.
             ;; ;;;;   is level 2.
             ;; ;;;;;  is level 3.
             (level (if outline-start
                        ;; Here we assume there is one character added to the
                        ;; regex on the end (usually +).
                        ;; If the regex is only 1 character for some reason, we
                        ;; ensure no zeros or negatives are passed.
                        (- n (length outline-start))
                      ;; if no start-string is provided, calculate where to
                      ;; start counting levels from looking at the given regex
                      ;; for an outline.
                      (- n (if (> regex-length 1) (- regex-length 1) 1))
                      )))
        ;; Given there are 8 outline faces, we must also ensure the number is
        ;; never bigger than 8.
        ;; (message "my-outline-mode/outline-level: match='%s', n=%d,
        ;;          regex-length=%d, level=%d"
        ;;          match n regex-length level)
        (min (max 1 level) 8)))))


(custom-set-variables
 '(outline-minor-mode-cycle t)                                                    ; Enable cycling through outline states by default.
 '(outline-minor-mode-highlight 'override)                                        ; Use the outline face, overwriting attributes of the existing face by default. 
 '(outline-minor-mode-prefix [3 64])                                              ; Set the prefix keys for the mode ([3 64] corresponds to 'C-c @').
 '(outline-minor-mode-use-buttons 'in-margins))                                   ; Use buttons in margins by default


(defun my-outline-mode/faces-for-prog-mode ()
  "Customise outline faces to use `default' color in `prog-mode'."
  (dolist (face '((outline-1 . 1.0)  ;; Adjust size multipliers if needed
                  (outline-2 . 1.0)
                  (outline-3 . 1.0)
                  (outline-4 . 1.0)
                  (outline-5 . 1.0)
                  (outline-6 . 1.0)
                  (outline-7 . 1.0)
                  (outline-8 . 1.0)))
    (let ((face-name (car face))
          (scale (cdr face)))
      (set-face-attribute face-name nil
                          :inherit 'default
                          :weight 'bold
                          :height scale))))


(set-face-attribute 'fill-column-indicator nil
                    :foreground "dimgray"
                    :inherit 'default)

;; Apply customizations only in `prog-mode`
(add-hook 'prog-mode-hook
          (lambda ()
            (when outline-minor-mode
              (my-outline-mode/faces-for-prog-mode))))



;; ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
;; Clickable links.
;; -----------------------------------------------
;; Ensure we can use hyperlinks and org type links throughout emacs.
;; Enable clickable URLs in all modes
(global-goto-address-mode 1)
;; (org-open-at-point-global)

;; Enable Org-style link handling everywhere
;; (global-org-link-mode 1)


;; Define custom faces for links
;; (defface  my-font-faces/url-face
;;   '((t (:foreground "DodgerBlue" :underline t)))
;;   "Face for plain URLs."
;;   :group 'my-faces/programming)

;; (defface  my-font-faces/org-link-face
;;   '((t (:foreground "MediumPurple1" :underline t)))
;;   "Face for Org-style links."
;;   :group 'my-faces/programming)

;; ;; Add highlighting rules
;; (defun my-links/highlight-links ()
;;   "Highlight plain URLs and Org-style links in comments."
;;   (font-lock-add-keywords
;;    nil
;;    '(("\\(https?://[^ \t\n]+\\)" ;; Plain URLs
;;       (1 'my-font-faces/url-face t))
;;      ("\\(\\[\\[https?://[^ \t\n]+\\]\\[[^]]+\\]\\]\\)"                           ; Org-style links
;;       (1 'my-font-faces/org-link-face t)))))

;; (add-hook 'prog-mode-hook #'my-links/highlight-links)                             ; For code modes
;; (add-hook 'text-mode-hook #'my-links/highlight-links)                             ; For text modes

;; ;; Show tool-tips for links
;; ;; (defun my-links/tooltip (window object position)
;; ;;   "Show a tooltip with the URL or Org link description.
;; ;; ARGS:
;; ;;     WINDOW is the window the link is in.
;; ;;     OBJECT is the link.
;; ;;     POSITION is the position of the link in the window."
;; ;;   (when (and (stringp object)
;; ;;              (string-match "\\(https?://[^ \t\n]+\\)" object))
;; ;;     (let ((url (match-string 1 object)))
;; ;;       (concat "Open: " url))))

;; ;; (add-to-list 'tooltip-functions #'my-links/tooltip)

;; (defun my-links/add-tooltips ()
;;   "Add tool-tips to URLs in the current buffer."
;;   (save-excursion
;;     (goto-char (point-min))
;;     (while (re-search-forward "\\(https?://[^ \t\n]+\\)" nil t)
;;       (let ((url (match-string 0)))
;;         (put-text-property (match-beginning 0) (match-end 0)
;;                            'help-echo (concat "Open: " url))))))
;; (add-hook 'prog-mode-hook #'my-links/add-tooltips)
;; (add-hook 'text-mode-hook #'my-links/add-tooltips)

;; (defun my-links/add-org-tooltips ()
;;   "Add tooltips to Org-style links in the current buffer."
;;   (save-excursion
;;     (goto-char (point-min))
;;     (while (re-search-forward "\\[\\[\\(https?://[^]]+\\)\\]\\[\\([^]]+\\)\\]\\]" nil t)
;;       (let ((url (match-string 1))
;;             (desc (match-string 2)))
;;         (put-text-property (match-beginning 0) (match-end 0)
;;                            'help-echo (format "URL: %s\nDescription: %s" url desc))))))
;; (add-hook 'prog-mode-hook #'my-links/add-org-tooltips)
;; (add-hook 'text-mode-hook #'my-links/add-org-tooltips)

;; (defun my-links/format-plain-links ()
;;   "Format plain URLs in comments as Org-style links."
;;   (save-excursion
;;     (goto-char (point-min))
;;     (while (re-search-forward "\\(https?://[^ \t\n]+\\)" nil t)
;;       (unless (save-match-data (org-in-regexp org-link-any-re))
;;         (replace-match "[[\\1][Link]]" nil nil)))))

;; ;; Add to save hooks
;; (add-hook 'before-save-hook #'my-links/format-plain-links)

;; (defun my-links/open-link-at-point ()
;;   "Open the link at point in a browser."
;;   (interactive)
;;   (let ((url (thing-at-point 'url t)))
;;     (if url
;;         (browse-url url)
;;       (message "No link at point!"))))

;; (global-set-key (kbd "C-c o") #'my-links/open-link-at-point)


;; (defun my-links/save-link-to-roam (url description)
;;   "Save a link to the Org Roam database.
;; ARGS:
;;     URL is the link.
;;     DESCRIPTION is a description of what the URL links to."
;;   (with-temp-buffer
;;     (insert (format "* %s\n  %s\n" description url))
;;     (write-file (concat org-roam-directory "/links.org"))))

;; ;; Save a link interactively
;; (defun my-links/save-link-at-point ()
;;   "Save the link at point to Org Roam."
;;   (interactive)
;;   (let ((url (thing-at-point 'url))
;;         (description (read-string "Description: ")))
;;     (my-links/save-link-to-roam url description)))


;; (defun my-links/list-links ()
;;   "List all Org-style links in the buffer."
;;   (interactive)
;;   (let ((links '()))
;;     (save-excursion
;;       (goto-char (point-min))
;;       (while
;;           (re-search-forward "\\[\\[https?://[^]]+\\]\\[\\([^]]+\\)\\]\\]"
;;                              nil t)
;;         (push (match-string 1) links)))
;;     (message "Links: %s" (string-join links ", "))))


;; ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
;; Fix 'use mini-buffer whilst in minibuffer' error
;; -----------------------------------------------
;; automatically cancel the minibuffer when you switch to it, to avoid
;; "attempted to use minibuffer" error.
;; see stack-overflow:
;; [[https://stackoverflow.com/questions/812135/emacs-modes-command-attempted-to-use-minibuffer-while-in-minibuffer][attempted-to-use-minibuffer-while-in-minibuffer]]

;; (defun my-ui/cancel-minibuffer-before-using-again (sub-read &rest args)
;;   "If you call the mini-buffer whilst in the mini-buffer, you get an error.

;; This can be managed by allowing recursive mini-buffer calls but this is seldom
;; what the user intends.  This function provides an alternative, cancelling the
;; existing mini-buffer session before starting the new one.
;; SUB-READ is the prompt used to call the mini-buffer.  ARGS is the list of
;; commands used with the buffer call."
;;   (let ((active (active-minibuffer-window)))
;;     (if active
;;         (progn
;;           ;; we have to trampoline, since we're IN the minibuffer right now.
;;           (apply 'run-at-time 0 nil sub-read args)
;;           (abort-recursive-edit))
;;       (apply sub-read args))))

;; (advice-add 'read-from-minibuffer :around #'my-ui/cancel-minibuffer-before-using-again)


;; ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
;; Fix 'use minibuffer whilst in minibuffer' error with Vertico compatibility
;; ----------------------------------------------------------------------------

(defun my-ui/cancel-minibuffer-before-using-again (sub-read &rest args)
  "Safely cancel the minibuffer session if called within an active minibuffer.

SUB-READ is the prompt used to call the minibuffer, and ARGS are additional
parameters for the minibuffer function."
  (if-let ((active (active-minibuffer-window)))
      (progn
        ;; Cancel the current recursive edit safely.
        (abort-recursive-edit)
        ;; Defer the new minibuffer call slightly to allow proper cleanup.
        (run-at-time 0 nil (lambda ()
                             (apply sub-read args))))
    ;; No active minibuffer, proceed normally.
    (apply sub-read args)))

;; Add advice to handle minibuffer recursion gracefully.
(advice-add 'read-from-minibuffer
            :around #'my-ui/cancel-minibuffer-before-using-again)


;; ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
;; Dired functionality
;; -------------------

;; Buffer title
(defun my-dired/set-dired-buffer-title ()
  "Set Dired buffer title to `Dired: <immediate directory>'."
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

;; ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
;; Ediff functionality
;; -------------------

;; (defun my-ediff/rename-buffers ()
;;   "Rename buffers in Ediff sessions to a custom format."
;;   (let ((file-a (ediff-get-file-name 'A))
;;         (file-b (ediff-get-file-name 'B)))
;;     (with-current-buffer ediff-buffer-A
;;       (rename-buffer (format "Ediff A: %s" (file-name-nondirectory file-a)) t))
;;     (with-current-buffer ediff-buffer-B
;;       (rename-buffer (format "Ediff B: %s" (file-name-nondirectory file-b)) t))
;;     (when ediff-merge-buffer
;;       (with-current-buffer ediff-merge-buffer
;;         (rename-buffer (format "*Ediff Config*") t)))))

;; (add-hook 'ediff-startup-hook 'my-ediff/rename-buffers)

;; (setq ediff-window-setup-function 'ediff-setup-windows-plain)                  ; prevent frame creation.
;; (setq ediff-split-window-function 'ignore)                                     ; Prevent any window splitting

;; Define key maps

;; set up functionality to reopen a buffer in a new frame here you click on the
;; modeline with Cntrl pressed and the buffer opens in a new frame.
;; This is adapted from `tear-off-window' but unlike that package does not
;; delete the buffer from the window which the new frame is spawned from.
;; The function my-buffer-tools/copy-buffer-in-new-fram is in
;; system-tools
(global-set-key [mode-line C-mouse-1]
                'my-buffer-tools/copy-buffer-in-new-frame)

;; ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
;; Highlight-changes-mode
;; ----------------------
;; removed: not worth it since highlighted changes is a bit *intense* to work
;; with.

;; ;; Manage your change indicators.
;; (defun my-ui/add-change-indicators-right-click-menu()
;;   "Add 'Remove Change Indicators' to right-click menu in prog-mode."
;;   (easy-menu-define my-prog-mode-menu prog-mode-map
;;     "Custom right-click menu for prog-mode."
;;     '("Change Indicators"
;;       ["Remove Indicators" highlight-changes-remove-highlight t]
;;       ["Rotate Indicators" highlight-changes-rotate-faces t]))

;;   ;; Bind the custom menu to right-click
;;   (define-key prog-mode-map [mouse-3] 'my-prog-mode-menu))

;; ;; Add the function to prog-mode-hook to ensure it's active in prog-mode buffers
;; (add-hook 'prog-mode-hook 'my-ui/add-change-indicators-right-click-menu)
;; ----------------------------------------------------------------------------


(provide 'ui-config)
;;; ui-config.el ends here

                                                                                  ; LocalWords:  ibuffer Ediff Elisp
                                                                                  ; LocalWords:  Dired ediff
