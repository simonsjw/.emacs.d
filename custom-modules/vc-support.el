;;; vc-support.el --- git/github support -*- lexical-binding: t; -*-

;; Copyright (C) 2025
;; SPDX-License-Identifier: MIT

;; Author: Simon Watson
;; Keywords: git, VC

;;; Commentary:

;; This package handles the setup of the version control.

;;; library imports:
;;     (none)

;;; Package phase

;; git-modes
;; support for git configuration files.
(use-package git-modes)

;; show line by line status for git in the fringe.
;; https://github.com/emacsorphanage/git-gutter-fringe?tab=readme-ov-file

;; this package requires git-gutter and fringe-helper
;; (installed at ui-config.el)
(use-package git-gutter
  :hook (prog-mode . git-gutter-mode)
  :config
  (setq git-gutter:update-interval 0.1))

(use-package git-gutter-fringe
  :config
  (define-fringe-bitmap
    'git-gutter-fr:added [224] nil nil '(center repeated))
  (define-fringe-bitmap
    'git-gutter-fr:modified [224] nil nil '(center repeated))
  (define-fringe-bitmap
    'git-gutter-fr:deleted [128 192 224 240] nil nil 'bottom))


;;; code:
;;; config phase

;; Customize display-buffer-alist for *vc-log*
;; Control how *vc-log* is displayed using display-buffer-alist.
;; (with-eval-after-load 'system-window-management
;;   (add-to-list 'display-buffer-alist
;;                '("^\\*vc-log\\*"
;;                  (display-buffer-reuse-window
;;                   display-buffer-same-window)))

;;   (add-to-list 'display-buffer-alist
;;                '("^\\*log-edit-files\\*"
;;                  (display-buffer-reuse-window
;;                   display-buffer-same-window))))


;;;; Git Submodule  Support

;;;;; 1) Basic Setup: Ensuring vc-mode Handles Submodules
;; Specify which version control backends Emacs should use.
;; By default, Emacs supports multiple VC backends like Git, SVN, Mercurial,
;; etc.
;; Setting this to '(Git) ensures Emacs only uses Git for version control.
(setq vc-handled-backends '(Git))

;; Modify the regular expression that tells Emacs which directories to ignore
;; in vc-mode.
;; `vc-ignore-dir-regexp` is a built-in variable that holds a regex pattern.
;; The `format` function is used to append a new directory (`cell-mode`) to the
;; existing ignore list.
(setq vc-ignore-dir-regexp
      (format "%s\\|%s"
              vc-ignore-dir-regexp                                                ; Preserve the existing ignore patterns.
              (expand-file-name                                                   ; Get absolute path from the Git root.
               "custom-packages/cell-mode" (vc-root-dir))))                       ; Add cell-mode as an ignored directory.

;;;;; 2) Adding a Submodule

;; To add cell-mode as a Git submodule:
;; ```
;; Choose the protocol for import (SSH needs setting up on the remote first).
;; SSH:
;;     git submodule add
;;        git@gitlab.com:dto/cell-mode.git custom-packages/cell-mode
;; or HTTPS:
;;     git submodule add
;;        https://gitlab.com/dto/cell-mode.git custom-packages/cell-mode
;;
;; ****************
;; Always run these commands from the Parent Git repo and not the submodule.
;; ****************
;;
;; git submodule init
;; git submodule update
;; git commit -m "Added cell-mode as a submodule"
;; ```
;; Now, vc-mode should list cell-mode under custom-packages/ as
;; a sub-repository.


;;;;; 3) Tracking/Checking Submodule Status in vc-mode

;; To check the status of the cell-mode submodule:
;; Open vc-dir:
;;     M-x vc-dir
;; Navigate to custom-packages/cell-mode
;; Press g to refresh
;; If the submodule is not listed, try:
;;     (vc-rescan)

;;;;; 4) Updating Submodules in vc-mode

;; When upstream changes are available in the remote submodule, update using
;; vc-mode:

;; * Open vc-dir:
;;     M-x vc-dir
;; * Navigate to cell-mode
;; * Press U (vc-update) to pull the latest changes.

;; Alternatively, use:
;;     (vc-git-command nil 0 nil "submodule" "update" "--remote" "--merge")

;;;;; 5) Committing Changes in a Submodule

;; If you make changes inside cell-mode:

;; * Open vc-dir
;; * Navigate to custom-packages/cell-mode
;; * Press C-x v v to commit the changes
;; * Then return to the parent repository (.emacs.d/) and
;; commit the new submodule reference:
;;     git commit -m "Updated cell-mode submodule"

;; or in Emacs:
;;     (vc-git-command nil 0 nil "commit" "-m" "Updated cell-mode submodule")

;;;;; 6) Cloning a Repository with Submodules

;; When cloning a repository that contains submodules, ensure you initialise
;; them:
;;     git clone --recurse-submodules https://github.com/your-repo/dotfiles.git

;; Or if already cloned:
;;     git submodule init
;;     git submodule update

;; To do this from Emacs:
;;     (vc-git-command nil 0 nil "submodule" "update" "--init" "--recursive")

;;;;; 8) Removing a Submodule in vc-mode

;; If you need to remove cell-mode:
;;     git submodule deinit -f -- custom-packages/cell-mode
;;     rm -rf .git/modules/custom-packages/cell-mode
;;     git rm -f custom-packages/cell-mode
;;     git commit -m "Removed cell-mode submodule"

;; To do this in Emacs:
;; Open vc-dir
;; Navigate to cell-mode, press m to mark it
;; Press C-x v v to commit
;; Run:
;;     (vc-git-command
;;        nil 0 nil "submodule" "deinit" "-f" "--" "custom-packages/cell-mode")
;;     (vc-git-command
;;        nil 0 nil "rm" "-f" "custom-packages/cell-mode")
;;     (vc-git-command
;;        nil 0 nil "commit" "-m" "Removed cell-mode submodule")

;;;;; 8) Common Issues & Fixes

;; |----------------------------------------------+---------------------------------------------------------|
;; |  Issue                                       |  Fix                                                    |
;; |----------------------------------------------+---------------------------------------------------------|
;; | vc-dir does not show the submodule           | Run (vc-rescan) or restart Emacs                        |
;; |----------------------------------------------+---------------------------------------------------------|
;; | Submodule changes are not recognised         | M-x vc-refresh-state                                    |
;; |----------------------------------------------+---------------------------------------------------------|
;; | Submodule updates don\’t appear              | Run git submodule update --remote --merge in a terminal |
;; |----------------------------------------------+---------------------------------------------------------|
;; | Parent repo does not track submodule changes | Run git commit -m "Updated submodule reference"         |
;; |----------------------------------------------+---------------------------------------------------------|

;;; Set up git tags list.

;; Define `my-magit/tagCommits-alist` with `defcustom` to make it customizable
;; via Emacs's Customize interface.
(defcustom my-vc/tagCommits-alist
  '(
    ("[feature]" . "introduction of new functionality")
    ("[debug]" . "fix of previous errors")
    ("[refactor]" . "refactor of existing functionality")
    ("[doc]" . "supporting documentation for the code")
    ("[tidy]" . "clean up of the project files, spelling-checking")
    ("[gitRefactor]"
     . "change to the repo (creating of new branches and such)"))
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
         ;; Prompt the user to select a tag. `completing-read` returns the
         ;; chosen string.
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
       (:background ,info-theme-light-orange
                    :foreground ,info-theme-white-grey))
    (  t
       (:weight bold :underline t)  )
    )
  "VC status tag face for files that have just been added to version-control."
  :group 'my-faces/vc-modeline)

(defface my-font-faces/mode:vc-edited
  `((((class color))
     (:background ,info-theme-flat-yellow :foreground ,info-theme-dark-blue))
    (t (:weight bold :underline t)))
  "VC status tag face for files under version control which have been edited."
  :group 'my-faces/vc-modeline)

(defface my-font-faces/mode:vc-in-sync
  `(
    (((class color))
     (:background ,info-theme-flat-green :foreground ,info-theme-dark-green))
    (t
     (:weight bold :underline t)  )
    )
  "VC status tag face for files in sync with the repository."
  :group 'my-faces/vc-modeline)

(defface my-font-faces/mode:vc-none
  `(
    (((class color))
     (:background ,info-theme-blue-steel :foreground ,info-theme-white-grey))
    (t
     (:weight bold :underline t)  )
    )
  "VC status tag face for files that are not under version control."
  :group 'my-faces/vc-modeline)

(defface my-font-faces/mode:vc-unknown
  `((((class color))
     (:background ,info-theme-white-grey :foreground ,info-theme-blue-steel))
    (t
     (:weight bold :underline t)))
  "VC status tag face for files whose vc status cannot be determined."
  :group 'my-faces/vc-modeline)

(defvar my-vc/mode-attrs
  '((""  . (" NoVC "  my-font-faces/mode:vc-none))
    ("-" . (" VC = "  my-font-faces/mode:vc-in-sync))
    (":" . (" VC > "  my-font-faces/mode:vc-edited))
    ("@" . (" VC + "  my-font-faces/mode:vc-added))
    ("?" . (" ?VC? "  my-font-faces/mode:vc-unknown))
    )
  "Lookup table to translate `vc-mode' character into another string/face."
  )

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
been modified since its last check-in.

Variables:
- `vc-mode': Built-in VC status string (e.g., \" Git:master\").
- `class': Extracted status indicator
           (e.g., \"-\", \":\", \"@\", \"\" or \"?\").
- `branch': Optional branch name string (e.g., \" master\").
- `props': Property list for fontification, fetched from `my-vc/mode-attrs'.

Output: A propertized string for mode-line display.

Flow:
1. Determine `class' via cond based on `vc-mode'.
2. If `class' indicates a valid VC state with branch info, extract `branch'.
3. Fetch display properties for `class' from `my-vc/mode-attrs'.
4. Concatenate propertized status symbol and branch."
  (let* ((class
          (cond
           ;; If not under version-control
           ((not vc-mode)
            "")

           ;; If under version-control decode the -:@ character
           ((string-match
             "\\` ?\\(?:CVS\\|Git\\)\\([-:@]\\)\\([^^:~ \x00-\x1F\\\\/]+\\)?"
             vc-mode)
            (match-string-no-properties 1 vc-mode))

           ;; Otherwise, indicate confusion
           (t
            "?")
           ))

         (branch
          (if (member class '("-" ":" "@"))                                       ; Check if class is one of the valid indicators (replaces fictitious 'any').
              (concat " " (match-string-no-properties 2 vc-mode))
            ""))

         ;; Fetch properties list for the class character above
         (props (cdr (assoc class my-vc/mode-attrs))))

    (concat (propertize (car props) 'face (cadr props))
            branch)))
;; end of toggle repo list functionality.


;;; Preserve VC log windows by burying instead of deleting.
;; Customise VC dispatcher to bury log buffers, keeping the window.
(setq vc-delete-logbuf-window nil)

;;; Prevent and clean splits in vc-dir.

(defun my-vc-dir-enforce-single-window ()
  "Make `vc-dir' buffer use a single window, deleting extras.
  
  Checks for multiple windows in the frame; deletes those showing
  VC-related sub-buffers (e.g., diffs/logs).  Balances if needed.
  
  Flow:
  - If single window, return early.
  - Collect extra windows.
  - Delete if buffer matches VC patterns.
  - Log deletions.
  - Balance windows.
  
  Edge: Preserves non-VC windows; runs efficiently (O(n) on windows)."
  (when (and (derived-mode-p 'vc-dir-mode)
             (> (length (window-list)) 1))
    (let ((main-win (selected-window))
          (extras (delq (selected-window) (window-list))))
      (dolist (win extras)
        (let ((buf (window-buffer win)))
          (when (string-match-p "^\\*\\(vc-\\|diff\\|log\\)" (buffer-name buf))
            (delete-window win)
            (log/debug :fn 'my-vc-dir-enforce-single-window
                       :msg "Deleted split sub-window in vc-dir"
                       :obj (list :buffer (buffer-name buf) :window win)))))
      (balance-windows)
      (select-window main-win))))

(defun my-vc-dir-no-split-hook ()
  "Hook to prevent splits in `vc-dir-mode'.
  
  Sets window unsplittable and defers single-window enforcement
  to handle async/post-command splits.
  
  Flow:
  - Set 'no-split parameter.
  - Use `run-with-idle-timer' for deferred clean (0.1s delay).
  
  Edge: Timer avoids races with dispatcher async; cancel if needed."
  (when (equal (window-parameter nil 'window-category) 'vc)
    (set-window-parameter nil 'no-split t)
    (run-with-idle-timer 0.1 nil #'my-vc-dir-enforce-single-window)))

(add-hook 'vc-dir-mode-hook #'my-vc-dir-no-split-hook)

;; Force VC sub-buffers to reuse same window, preventing splits.
(add-to-list 'display-buffer-alist
             '("^\\*\\(vc-diff\\|vc-log\\|log-edit\\|vc-change-log\\)\\*"
               (display-buffer-same-window)))

;; Optional: Ensure window persistence in log-edit-done
;; (add-hook 'log-edit-hook
;;           (lambda ()
;;             (when (equal (window-parameter nil 'window-category) 'vc)
;;               (set-window-parameter nil 'quit-restore nil))))
;;

(provide 'vc-support)
;;; vc-support.el ends here

;; LocalWords: gitRefactor vc submodule unhide customizable
