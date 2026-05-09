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

(require 'path-support)
(require 'logging-config)
(log/debug :fn 'ui-config
           :msg "Starting load of the ui-config module."
           :obj t)
;; Add frame borders and window dividers
(modify-all-frames-parameters
 '(
   (right-divider-width . 10)                                                    ;; the horizontal width between windows in the frame
   (bottom-divider-width . 10)                                                   ;; the vertical width between windows in the frame
   (internal-border-width . 40)                                                  ;; width between the frame and the windows within.
   )
 )

(dolist (face '(window-divider ;; remove the window dividers
                window-divider-first-pixel
                window-divider-last-pixel))
  (face-spec-reset-face face)
  (set-face-foreground face (face-attribute 'default :background)))
(set-face-background 'fringe (face-attribute 'default :background))


;;;; linkd:
;;
;;  Make hypertext with active links in any buffer
;;
;;
;;(@* "Overview") ----------------------------------------------------
;;
;;  Linkd-mode is a major mode that automatically recognizes and
;;  processes certain S-expressions, called "links", embedded in plain
;;  text files.  Links may be followed by invoking certain interactive
;;  functions when point is on the link text.  Links may also be
;;  interpreted as marking up the surrounding text.  Different types
;;  of links have different behaviors when followed, and they may have
;;  different interpretations as markup.
;;
;;  With Linkd mode, you can do the following:
;;  * Embed hyperlinks to files, webpages, or documentation into
;;    any type of text file in any major mode.
;;  * Delimit and name regions of text ("blocks") in these text files.
;;    See (@> "Stars")
;;  * Extract and send blocks to other programs for processing.
;;    See (@> "Processing blocks")
;;  * Identify and mark locations and concepts in source code.
;;    See (@> "Tags")
;;  * Embed active data objects ("datablocks") into text files.
;;    See (@> "Datablocks")
;;  * Convert Lisp source-code listings to LaTeX for publication.
;;    See (@> "Exporting to LaTeX")
;;  * Define new link behaviors.
;;
;;  For detailed information about using linkd-mode, see the online
;;  manual: http://dto.github.com/notebook/linkd.html.



(let ((crnt-package-dir (expand-file-name "emacs-wiki/linkd/" user-emacs-directory))
      (emacswiki-base "https://www.emacswiki.org/emacs/download/")
      (package-files '("linkd.el")))
  (require 'url)
  (add-to-list 'load-path crnt-package-dir)
  (make-directory crnt-package-dir t)
  (mapcar (lambda (arg)
            (let ((local-file (concat crnt-package-dir arg)))
              (unless (file-exists-p local-file)
                (url-copy-file (concat emacswiki-base arg) local-file t)
                (native-compile-async
                 (list (expand-file-name local-file crnt-package-dir)) nil t))))
          package-files))



;;;; Bookmark+:
;;
;;    Documentation for the Bookmark+ package, which provides
;;    extensions to standard library `bookmark.el'.
;;
;;    The Bookmark+ libraries are these:
;;
;;    `bookmark+.el'     - main (driver) library
;;    `bookmark+-mac.el' - Lisp macros
;;    `bookmark+-lit.el' - (optional) code for highlighting bookmarks
;;    `bookmark+-bmu.el' - code for the `*Bookmark List*' (bmenu)
;;    `bookmark+-1.el'   - other required code (non-bmenu)
;;    `bookmark+-key.el' - key and menu bindings
;;
;;    `bookmark+-doc.el' - documentation (comment-only - this file)
;;    `bookmark+-chg.el' - change log (comment-only file)
;;
;;    The documentation includes how to byte-compile and install
;;    Bookmark+.  It is also available in these ways:
;;
;;    1. From the bookmark list (`C-x x e' or `C-x r l'):
;;       Use `?' to show the current bookmark-list status and general
;;       help, then click link `Doc in Commentary' or link `Doc on the
;;       Web'.
;;
;;    2. From the Emacs-Wiki Web site:
;;       https://www.emacswiki.org/emacs/BookmarkPlus.
;;    
;;    3. From the Bookmark+ group customization buffer:
;;       `M-x customize-group bookmark-plus', then click link
;;       `Commentary'.
;;
;;    (The commentary links in #1 and #3 work only if put you this
;;    library, `bookmark+-doc.el', in your `load-path'.)
;;
;;    More Bookmark+ description below.
;;
;;    To report Bookmark+ bugs: `M-x customize-group bookmark-plus'
;;    and then follow (e.g. click) the link `Send Bug Report', which
;;    helps you prepare an email to the author Drew Adams.

(let* (
       (bookmarkplus-dir (expand-file-name "emacs-wiki/bookmark+/" user-emacs-directory))
       (macros-file-already-exists-p
        (file-exists-p (concat bookmarkplus-dir "bookmark+-mac.el")))
       (emacswiki-base "https://www.emacswiki.org/emacs/download/")
       (bookmark-files '("bookmark+.el" "bookmark+-mac.el" "bookmark+-bmu.el"
                         "bookmark+-key.el" "bookmark+-lit.el" "bookmark+-1.el"
                         "bookmark+-chg.el" "bookmark+-doc.el"))
       (other-files
        (remove (expand-file-name "bookmark+-mac.el" bookmarkplus-dir)
                (directory-files bookmarkplus-dir t "\\.el$"))))
  
  (require 'url)
  (add-to-list 'load-path bookmarkplus-dir)
  (make-directory bookmarkplus-dir t)
  (mapcar (lambda (arg)
            (let ((local-file (concat bookmarkplus-dir arg)))
              (unless (file-exists-p local-file)
                (url-copy-file
                 (concat emacswiki-base arg) local-file t))))
          bookmark-files)
  
  ;; Handle native compilation.
  (unless macros-file-already-exists-p
    ;; if bookmark+-mac.el has just been downloaded, it is compiled first to
    ;; provide needed functionality before the other files can be compiled.)
    (emacs-lisp-native-compile
     (list (expand-file-name "bookmark+-mac.el" bookmarkplus-dir)) nil t)
    ;; Compile all other .el files, excluding bookmark+-mac.el
    (emacs-lisp-native-compile other-files nil t)))

;; This variable prevents a feature in bookmark+ that allows multiple bookmarks
;; with the same name. In theory, it propertizes the names so then contain all
;; bookmark details. In practice, this causes problems when saving to file.
(defvar bmkp-propertize-bookmark-names-flag
  nil "Non-nil means bookmark titles are propertized.")
(setq bmkp-propertize-bookmark-names-flag nil)

;; These mappings are made in custom-path-support.el.
;;
;; The location of the default bookmark desktop directory bmkp is set under
;;     no-littering-var-directory
;; the variable files for bookmark+ (and bookmark) are in bmkp.
;; bmkp-desktop-default-directory is set to bmkp/desktops
;;     - this is where desktop bookmarks are stored.
;; bmkp-bmenu-state-file is set to bmkp/emacs-bmk-bmenu-state.el
;;     - this is where the current state of the list-bookmark buffer is stored.
;; bookmark-default-file is set to bmkp/bookmark-default.bmk
;;     - this is the default location for bookmark files.

(require 'bookmark+)                                                              ; commands usually have a bmkp prefix.

(use-package info+
  :vc (:url "https://github.com/emacsmirror/info-plus.git"))
(use-package dired+
  :vc (:url "https://github.com/emacsmirror/dired-plus.git"))
(use-package imenu-list)
(use-package elisp-demos)
(use-package page-break-lines)

;; functionality to set up bitmaps in buffer fringes.
(use-package fringe-helper)

(require 'org)
(require 'outline)
(require 'easymenu)


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


(log/debug :fn 'ui-config
           :msg "Finishing load of the ui-config module."
           :obj t)

(provide 'ui-config)
;;; ui-config.el ends here

