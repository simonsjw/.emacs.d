;;; custom-window-tree.el --- Save and restore window layouts  -*- lexical-binding: t; -*-


;; Author: Your Name <your.email@example.com>
;; Version: 1.0
;; Package-Requires: ((emacs "24.3"))
;; Keywords: convenience, windows, layout
;; URL: http://example.com/window-tree

;;; Commentary:

;; This package provides functions to save and restore Emacs window layouts.
;; It allows you to save the current window tree to a file and later restore
;; it from the saved file. This can be particularly useful for setting up
;; IDE-like layouts or maintaining specific window configurations across
;; sessions.

;; Usage:
;; - Save the current window tree:
;;   M-x my-window-tree/save-window-tree
;; - Save the window tree to a file:
;;   M-x my-window-tree/save-window-tree-to-file
;; - Restore the window tree from a file:
;;   M-x restore-saved-window-tree

;;; Code:

(require 'recentf)
(require 'cl-lib)
(require 'no-littering)
(require 'custom-system-tools)


(defvar my-window-tree/directory
  (expand-file-name "window-tree/" no-littering-etc-directory)
  "Directory where window tree files are stored.")

(defvar my-window-tree/file
  (expand-file-name "current-window-tree.el" my-window-tree/directory)
  "Directory where window tree files are stored.")

(defvar my-window-tree/object
  (list (selected-window) nil nil)
  "An empty window tree structure with the current selected window as the root.")

(my-on-disk-tools/ensure-directory-exists my-window-tree/directory)

(defun my-window-tree/save-window-tree ()
  "Save the window tree of the current frame to a variable.
The window tree is stored in the `my-window-tree` variable."
  (interactive)
  (setq my-window-tree/object (window-tree))
  (message "Window tree saved."))

(defun my-window-tree/window-tree-to-string (tree)
  "Convert window TREE to a string.
This string can be saved to a file for later restoration."
  (prin1-to-string tree))

(defun my-window-tree/save-window-tree-to-file (filename)
  "Save the current window tree to FILENAME.
The window tree is serialised to a string and written to the specified file."
  (interactive "FSave window tree to file: ")
  (let ((tree-string
         (my-window-tree/window-tree-to-string my-window-tree/object))
        (file (expand-file-name filename my-window-tree/directory)))
    (with-temp-file file
      (insert tree-string))
    (message "Window tree saved to %s" file)))

(defun my-window-tree/save-window-tree-to-default-file ()
  "Save the current window tree to FILENAME.
The window tree is serialised to a string and written to the default file."
  (let ((tree-string
         (my-window-tree/window-tree-to-string my-window-tree/object)))
    (with-temp-file my-window-tree/file
      (insert tree-string))
    (message "Window tree saved to %s" my-window-tree/file)))

(defun my-window-tree/load-window-tree-from-file (filename)
  "Load a window tree from FILENAME.
The window tree is read from the specified file and returned as a Lisp object."
  (interactive "FLoad window tree from file: ")
  (let ((file (expand-file-name filename my-window-tree/directory)))
    (with-temp-buffer
      (insert-file-contents file)
      (read (buffer-string)))))

(defun my-window-tree/load-window-tree-from-default-file ()
  "Load a window tree from FILENAME.
The window tree is read from the default file and returned as a Lisp object."
  (with-temp-buffer
    (insert-file-contents my-window-tree/file)
    (read (buffer-string))))

(defun my-window-tree/parse-window-tree (tree)
  "Parse the window tree structure, replacing unreadable objects with placeholders."
  (let ((pattern "#<\\([^>]+\\)>"))
    ;; Replace unreadable objects with a placeholder `(unreadable <type>)`
    (with-temp-buffer
      (insert tree)
      (goto-char (point-min))
      (while (re-search-forward pattern nil t)
        (replace-match "(unreadable \\1)"))
      ;; Read the modified structure safely
      (read (buffer-string)))))

(defun my-window-tree/restore-window-tree (input-tree &optional parent)
  "Restore the window layout from TREE into the current frame.
TREE is a window tree structure, and PARENT is the parent window (if any).
This function recursively restores the window layout."
  (let ((tree (my-window-tree/parse-window-tree input-tree)))
    (let ((root (nth 0 tree))
          (is-horizontal (nth 1 tree))
          (children (nth 2 tree)))
      (if (windowp root)
          ;; If root is a window, set the buffer
          (set-window-buffer (or parent (selected-window)) (window-buffer root))
        ;; If root is a combined window, split and recurse
        (let ((first-child (car children))
              (next-window (or parent (selected-window))))
          (dolist
              (child children)
            (let
                ((new-window
                  (if (eq child first-child)
                      next-window
                    (if is-horizontal
                        (my-window-tree/split-window-next-to next-window 'right)
                      (my-window-tree/split-window-next-to next-window 'below)))))
              (my-window-tree/restore-window-tree child new-window))))))))

(defun my-window-tree/split-window-next-to (window direction)
  "Split WINDOW in DIRECTION and return the new window.
DIRECTION should be either `'right or `'below."
  (let ((new-window
         (split-window window nil (if (eq direction 'right) 'right 'below))))
    (select-window new-window)
    new-window))

(defun my-window-tree/restore-saved-window-tree (filename)
  "Restore the window tree from FILENAME.
This function ensures the current frame has only one window before restoring
the layout."
  (interactive "FRestore window tree from file: ")
  (let ((tree (my-window-tree/load-window-tree-from-file filename)))
    (my-window-tree/ensure-single-window)
    (my-window-tree/restore-window-tree tree))
  (message "Window tree restored from %s" filename))

(defun my-window-tree/restore-saved-default-window-tree ()
  "Restore the window tree from FILENAME.
This function ensures the current frame has only one window before restoring
the layout."
  (let ((tree (my-window-tree/load-window-tree-from-file my-window-tree/file)))
    (my-window-tree/ensure-single-window)
    (my-window-tree/restore-window-tree tree))
  (message "Window tree restored from %s" my-window-tree/file))

(defun my-window-tree/ensure-single-window ()
  "Ensure the current frame has only one window."
  (delete-other-windows))

(provide 'custom-window-tree)
;;; custom-window-tree.el ends here
