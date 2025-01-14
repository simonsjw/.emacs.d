;;; custom-vc-support.el --- git/github support for the crafted setup   -*- lexical-binding: t; -*-

;; Copyright (C) 2022
;; SPDX-License-Identifier: MIT

;; Author: System Crafters Community
;; Keywords: git, VC

;;; Commentary:

;; This package handles the setup of the version control.

;;; library imports:

;;; Package phase



;; git-modes
;; support for git configuration files.
(use-package git-modes)

;;; code:
;;; config phase

;;User Option: magit-wip-mode

;;    When this mode is enabled, then uncommitted changes are committed to dedicated work-in-progress
;;    refs whenever appropriate (i.e., when dataloss would be a possibility otherwise).

;;    Setting this variable directly does not take effect; either use the Custom interface to do so or
;;    call the respective mode function.

;;    For historic reasons this mode is implemented on top of four other magit-wip-* modes, which can
;;    also be used individually, if you want finer control over when the wip refs are updated; but that
;;    is discouraged. See Legacy Wip Modes.

;; https://magit.vc/manual/magit/Wip-Modes.html


;; User Option: magit-define-global-key-bindings
;;    This option controls which set of Magit key bindings, if any, may be added to the global keymap,
;;    even before Magit is first used in the current Emacs session.

;;         If the value is nil, no bindings are added.
;;         If default, maybe add:
;;         C-x g	magit-status
;;         C-x M-g	magit-dispatch
;;         C-c M-g	magit-file-dispatch
;;         If recommended, maybe add:
;;         C-x g	magit-status
;;         C-c g	magit-dispatch
;;         C-c f	magit-file-dispatch

;;    These bindings are strongly recommended, but we cannot use them by default, because the
;;    C-c <LETTER> namespace is strictly reserved for bindings added by the user
;;    (see (elisp)Key Binding Conventions).


;; The below function is part of work to manage collection of local repos.
;; (defun my-display-csv-as-org-table (csv-file)
;;   "Display CSV data from CSV-FILE in an Org table format."
;;   (interactive "fCSV File: ")
;;   (let ((buffer (generate-new-buffer (concat (file-name-base csv-file) "-table"))))
;;     (with-current-buffer buffer
;;       (insert-file-contents csv-file)
;;       (org-mode)
;;       (org-table-convert-region (point-min) (point-max) '(4)) ; Adjust the separator if needed
;;       (switch-to-buffer buffer))))

;; To hide a column in the current org table, place the cursor on the desired column and run:
;; (defun my-org-table-hide-column ()
;;   "Hide the current column in an Org table."
;;   (interactive)
;;   (org-table-hide-column))

;; To move a column left or right, place the cursor on the desired column and run:
;; (defun my-org-table-move-column (direction)
;;   "Move the current column in an Org table left or right.
;; DIRECTION should be 'left or 'right."
;;   (interactive "sDirection (left/right): ")
;;   (cond ((string= direction "left") (org-table-move-column-left))
;;         ((string= direction "right") (org-table-move-column-right))
;;         (t (message "Invalid direction. Use 'left or 'right."))))

;; Bind these functions to keys or call them interactively with M-x

;; (defvar-local my-org-hidden-columns-overlays nil
;;   "List of overlays hiding columns in the current org table.")

;; (defun my-org-hide-column ()
;;   "Hide the current column in an Org table."
;;   (interactive)
;;   (unless (org-at-table-p)
;;     (error "Not at an org table"))
;;   (let* ((col (org-table-current-column))
;;          (beg (point-min))
;;          (end (point-max))
;;          (re (concat "^[|]\\(?:[^|\n]*[|]\\){" (number-to-string (1- col)) "}\\([^|\n]+\\)")))
;;     (save-excursion
;;       (goto-char (point-min))
;;       (while (re-search-forward re end t)
;;         (let* ((match-beg (match-beginning 1))
;;                (match-end (match-end 1))
;;                (ov (make-overlay match-beg match-end)))
;;           (overlay-put ov 'invisible t)
;;           (push ov my-org-hidden-columns-overlays))))))

;; (defun my-org-unhide-columns ()
;;   "Unhide all hidden columns in the current Org table."
;;   (interactive)
;;   (mapc 'delete-overlay my-org-hidden-columns-overlays)
;;   (setq my-org-hidden-columns-overlays nil))


;; non-interactive use.
;;(my-display-csv-as-org-table
;; "/home/simon/sync/primary/dotfiles/git/repoList.csv")

;; interactive use.
;; (defun open-my-repo-list ()
;;   "Open my repository list CSV as an Org table."
;;   (interactive)
;;   (my-display-csv-as-org-table my/REPO_LIST))

;;
;; This functionality hides and shows the full path to your repo list.
;; (defvar my-org-table-repo-col-visible nil
;;   "State of the 'Repository' column visibility, t for full paths, nil for shortened paths.")

;; (defun my-toggle-repo-path-display ()
;;   "Toggle the display format of the 'Repository' column between full and shortened paths."
;;   (interactive)
;;   (unless (org-at-table-p)
;;     (error "Not at an org table"))
;;   (let* ((table-begin (org-table-begin))
;;          (table-end (org-table-end))
;;          ;; regex to capture the content of the first column
;;          (re "^|\\([^|]+\\)|")
;;          (header-line (line-number-at-pos table-begin)))
;;     (save-excursion
;;       (goto-char table-begin)
;;       (forward-line 1) ;; Skip the header line
;;       (let ((inhibit-read-only t)) ;; In case the buffer is read-only
;;         ;; Search and update each occurrence in the first column
;;         (while (search-forward-regexp re table-end t)
;;           (let* ((match-str (match-string 1))
;;                  (path-parts (split-string match-str "/"))
;;                  (new-text (if (and (not my-org-table-repo-col-visible) (> (length path-parts) 2))
;;                                ;; Show only the last two parts of the path
;;                                (concat "|.../" (string-join (last path-parts 2) "/") "|")
;;                              ;; Show the full path
;;                              (concat "|" match-str "|"))))
;;             (replace-match new-text t t nil 1)))))
;;     (setq my-org-table-repo-col-visible (not my-org-table-repo-col-visible))
;;     ;; Color the header line
;;     (save-excursion
;;       (goto-char table-begin)
;;       (let ((overlay (make-overlay (line-beginning-position) (line-end-position))))
;;         (overlay-put overlay 'face '(:foreground "white"))
;;         ;; Store the overlay so it can be removed later
;;         (setq my-org-table-header-overlay overlay)))))

;; (defun my-remove-header-color ()
;;   "Remove the color of the header line."
;;   (interactive)
;;   (when (overlayp my-org-table-header-overlay)
;;     (delete-overlay my-org-table-header-overlay)
;;     (setq my-org-table-header-overlay nil)))



;; Customize display-buffer-alist for *vc-log*
;; Control how *vc-log* is displayed using display-buffer-alist.
(with-eval-after-load 'system-window-management
  (add-to-list 'display-buffer-alist
               '("^\\*vc-log\\*"
                 (display-buffer-reuse-window
                  display-buffer-same-window)))

  (add-to-list 'display-buffer-alist
               '("^\\*log-edit-files\\*"
                 (display-buffer-reuse-window
                  display-buffer-same-window))))

;;; Set up git tags list.
;;  ---------------------
;; Define `my-magit/tagCommits-alist` with `defcustom` to make it customizable
;; via Emacs's Customize interface.
(defcustom my-vc/tagCommits-alist
  '(
    ("[feature]" . "introduction of new functionality")
    ("[debug]" . "fix of previous errors")
    ("[refactor]" . "refactor of existing functionality")
    ("[doc]" . "supporting documentation for the code")
    ("[tidy]" . "clean up of the project files, spelling-checking")
    ("[gitRefactor]" . "change to the repo (creating of new branches and such)"))
  "Alist of tags for git commit messages.

 Each element is a cons cell (TAG . DESCRIPTION)."
  :type '(alist :key-type string :value-type string)
  :group 'my/customizations)

(defun my-vc/tagCommits ()
  "Display a list of tags for git commit messages and insert the selected tag.
Utilises `tagCommits-alist` for retrieving the list of available tags.
Users can select a tag from a prompted list in the mini-buffer, and the
selected tag is then inserted at the current cursor position in the active
buffer."
  (interactive)
  ;; Generate a list of strings that combine each tag with its description.
  (let* ((tag-list (mapcar (lambda (item)
                             (concat (car item) " - " (cdr item)))
                           my-vc/tagCommits-alist))
         ;; Prompt the user to select a tag. `completing-read` returns the chosen string.
         (selection (completing-read "Select tag: " tag-list nil t))
         ;; Extract the tag part from the selection.
         (tag (car (split-string selection " - "))))
    ;; Insert the selected tag at the current cursor position.
    (insert tag)))


;; Modeline support

;; Define faces.

(defgroup my-faces/vc-modeline nil
  "Custom font faces for the vc modeline."
  :group 'faces)

(defface my-font-faces/mode:vc-added
  `(
    (  ((class color))
       (:background ,info-theme-light-orange :foreground ,info-theme-white-grey))
    (  t
       (:weight bold :underline t)  )
    )
  "VC status tag face for files that have just been added to version-control."
  :group 'my-faces/vc-modeline)

(defface my-font-faces/mode:vc-edited
  `(
    (  ((class color))
       (:background ,info-theme-flat-yellow :foreground ,info-theme-dark-blue))
    (  t
       (:weight bold :underline t)  )
    )
  "VC status tag face for files under version control which have been edited."
  :group 'my-faces/vc-modeline)

(defface my-font-faces/mode:vc-in-sync
  `(
    (  ((class color))
       (:background ,info-theme-flat-green :foreground ,info-theme-dark-green))
    (  t
       (:weight bold :underline t)  )
    )
  "VC status tag face for files in sync with the repository."
  :group 'my-faces/vc-modeline)

(defface my-font-faces/mode:vc-none
  `(
    (  ((class color))
       (:background ,info-theme-blue-steel :foreground ,info-theme-white-grey))
    (  t
       (:weight bold :underline t)  )
    )
  "VC status tag face for files that are not under version control."
  :group 'my-faces/vc-modeline)

(defface my-font-faces/mode:vc-unknown
  `(
    (  ((class color))
       (:background ,info-theme-white-grey :foreground ,info-theme-blue-steel))
    (  t
       (:weight bold :underline t)  )
    )
  "VC status tag face for files whose vc status cannot be determined."
  :group 'my-faces/vc-modeline)

(defvar my-vc/mode-attrs
  '((""  . (" NoVC "  my-font-faces/mode:vc-none))
    ("-" . (" VC = "  my-font-faces/mode:vc-in-sync))
    (":" . (" VC > "  my-font-faces/mode:vc-edited))
    ("@" . (" VC + "  my-font-faces/mode:vc-added))
    ("?" . (" ?VC? "  my-font-faces/mode:vc-unknown))
    )
  "Lookup table to translate vc-mode character into another string/face."
  )


;; This function helps me understand the version-control status.
(defun my-modeline/vc-info ()
  "Return version-control status information about the current buffer.

The information will be in a fontified string.

The mode-line variable `vc-mode' is nil if the file is not under
version control, and displays a hyphen or a colon depending on whether
the file has been modified since check-in.  I can never keep those
straight.

This function returns \"NoVC\" if the file is not under version 
control.  It displays a string with an = sign if the file is in sync
with its version control, and a string with a > sign if the file has
been modified since its last check-in."
  (let* ((class
          (cond
           ;; If not under version-control
           ((not vc-mode)
            "")

           ;; If under version-control decode the -:@ character
           ((string-match "\\` ?\\(?:CVS\\|Git\\)\\([-:@]\\)\\([^^:~ \x00-\x1F\\\\/]+\\)?" vc-mode)
            (match-string-no-properties 1 vc-mode))

           ;; Otherwise, indicate confusion
           (t
            "?")
           ))

         (branch
          (if (any class '("-" ":" "@"))
              (concat " " (match-string-no-properties 2 vc-mode))
            ""))

         ;; Fetch properties list for the class character above
         (props (cdr (assoc class my-vc/mode-attrs)))
         )

    (concat (propertize (car props) 'face (cadr props))
            branch)))


;; end of toggle repo list functionality.

;; Optionally, bind this function to a key for convenience.
;; (global-set-key (kbd "<your-preferred-key-combination>") 'my-toggle-repo-path-display)





(provide 'custom-vc-support)
;;; custom-vc-support.el ends here

; LocalWords:  gitRefactor
