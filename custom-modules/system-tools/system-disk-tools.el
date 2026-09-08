;;; system-disk-tools.el --- Dired, image, and filesystem helpers. -*- lexical-binding: t; -*-

;; Copyright (C) 2026 Simon Watson
;; SPDX-License-Identifier: MIT

;; Author: Simon Watson

;;; Commentary:

;; Piece of `system-tools': Dired directory picker, image icons, and
;; on-disk path helpers.  Directory creation lives in `path-support'
;; as `my-on-disk-tools/ensure-directory-exists'.  Required by the
;; loader, not from `init.el' directly.
;;
;; Map:
;;   Feature:    system-disk-tools
;;   Load-after: path-support logging-config
;;   Load-phase: bootstrap
;;   Keymaps:    none
;;   Docs:       docs/system-disk-tools.org
;;   OS:         none

;;; Code:

(require 'path-support)
(require 'logging-config)
(log/debug :fn 'system-disk-tools
           :msg "Starting load of the system-disk-tools module."
           :obj t)

(require 'project)

;;;; Dired tools

(defun my-interactive-tools/select-directory-using-dired ()
  "Open a Dired buffer for directory selection and return the selected path."
  (interactive)
  (let ((selected-dir (dired-get-file-for-visit)))
    (if (file-directory-p selected-dir) ;; Check if it's a directory
        selected-dir
      (user-error "Not a directory"))))

;; end of Dired tools.
;; -------------------


;;;; Image processing

(defun my-image-tools/create-image-icon (file &optional width height)
  "Create an image icon from FILE with optional WIDTH and HEIGHT."
  (let* ((type (image-supported-file-p file))                                     ; Automatically detect image type
         (image (create-image file type nil
                              :width width
                              :height height)))
    (if image
        (propertize " " 'display image)
      (message "Image creation failed for file: %s" file)
      "")))
;; end of Image processing
;; -----------------------


;;;; TOOLS FOR THE FILE SYSTEM
;;   -------------------------

(defun my-on-disk-tools/summary-path (path)
  "Return a summarized version of PATH, with project name if applicable."
  (let* ((home-dir (expand-file-name "~/"))
         (proj (project-current))                                                 ; Check if the path is in a project.el project
         (path-name (if proj
                        (concat (project-name proj) ": ")
                      (if (string-prefix-p home-dir path)
                          "home: "
                        "")))

         (path-root (if proj
                        (project-root proj)
                      (if (string-prefix-p home-dir path)
                          home-dir
                        nil)))
         
         (rel-path (if path-root
                       (file-relative-name path path-root)
                     path))
         (components (split-string rel-path "/" t))                               ; Split, omit empty strings
         
         (max-width (- (window-width) (length path-name) 5))                      ; Room for ": " and " ... "
         (comp-count (length components))
         (keep-each-side (max 1 (/ (- max-width (length " ... ")) 2))))
    (if (> comp-count (* 2 keep-each-side))
        ;; Truncate with " ... " if too many components
        (let* ((start-comps (seq-take components keep-each-side))
               (end-comps (seq-take-last components keep-each-side))
               (start (string-join start-comps "/"))
               (end (string-join end-comps "/")))
          (format "%s%s ... %s" path-name start end))
      ;; Otherwise show full path
      (format "%s%s" path-name rel-path))))

(defun my-in-buffer-tools/insert-section-header (&optional level)
  "Insert a language-agnostic ruled section header at point.

LEVEL is 1 (default) for a major section or 2 for a sub-section.
The rule character is '=' for level 1 and '-' for level 2.

The final column of the rule is determined in this order:
  1. `display-fill-column-indicator-column' (when it is a positive integer)
  2. `comment-column'
  3. 88

Uses the Emacs comment framework (`comment-start' / `comment-end') so the
correct comment leader is chosen automatically for the current major mode
 (Python #, Emacs Lisp ;, C-like //, etc.).

The header is inserted on its own line(s) and point is left after it."
  (interactive (list (if current-prefix-arg 2 1)))  ; Use C-u to set the section level.
  (comment-normalize-vars)   ; ensure comment-start etc. are set
  (unless comment-start
    (user-error "No comment syntax defined for this mode"))

  (let* ((level (or level 1))
         (title (read-string (format "Section title (level %d): " level)))
         (rule-char (if (= level 1) ?= ?-))
         (prefix (string-trim-right comment-start))
         (suffix (if (and comment-end (not (string-empty-p comment-end)))
                     (concat " " (string-trim comment-end))
                   ""))
         ;; Determine target column
         (target-col
          (cond
           ((and (boundp 'display-fill-column-indicator-column)
                 (integerp display-fill-column-indicator-column)
                 (> display-fill-column-indicator-column 0))
            display-fill-column-indicator-column)
           ((and (boundp 'comment-column)
                 (integerp comment-column)
                 (> comment-column 0))
            comment-column)
           (t 88)))
         ;; Build the rule line so that the last rule character lands on target-col
         (prefix-len (length prefix))
         (suffix-len (length suffix))
         (available (- target-col prefix-len suffix-len))
         (rule (make-string (max 4 available) rule-char))
         (header-line (concat prefix " " title))
         (rule-line   (concat prefix rule suffix)))

    (beginning-of-line)
    (unless (looking-at-p "^[[:space:]]*$")
      (open-line 1)
      (forward-line 1))
    (insert header-line "\n" rule-line "\n")
    (forward-line 1)))

;; ---end of TOOLS FOR THE FILE SYSTEM---

(log/debug :fn 'system-disk-tools
           :msg "Finishing load of the system-disk-tools module."
           :obj t)

(provide 'system-disk-tools)
;;; system-disk-tools.el ends here
