;;; matlab-workspace-tree.el --- MATLAB workspace integration for memory-object-tree -*- lexical-binding: t; -*-

;; Copyright (C) 2025 Simon Watson
;;
;; Author: Simon Watson (simon.watson.sjw@gmailcom)
;; Maintainer: same
;; Version: 0.1
;; Package-Requires: ((emacs "25.1") (eieio "1.4") (memory-object-tree "0.1")
;;                   (matlab "some-version"))
;; Keywords: matlab, speedbar, workspace, memory-objects
;; URL: https://example.com/matlab-workspace-tree

;; This file is part of the memory-object-tree project for displaying
;; in-memory objects in Emacs Speedbar, with specific support for MATLAB.

;;; Commentary:

;; This file provides MATLAB-specific functionality for the memory-object-tree
;; package.  It integrates with the MATLAB shell in Emacs to fetch and parse
;; the current workspace variables, building a hierarchical tree for display
;; in Speedbar.  The tree supports structs and objects with nested
;; fields/properties.
;;
;; To use:
;; 1. Ensure MATLAB shell is running (M-x matlab-shell).
;; 2. Load this file.
;; 3. Use Speedbar with the appropriate expansion list.
;;
;; The MATLAB script `printWorkspaceTree.m' must be in the same directory
;; or added to the MATLAB path.

;;; Code:

(require 'eieio)                                                                  ; For object-oriented programming support
(require 'memory-object-tree)                                                     ; Generic memory object tree functionality
(require 'matlab)                                                                 ; MATLAB mode and shell integration

(defvar matlab-workspace-tree-script-dir
  (file-name-directory (or load-file-name buffer-file-name))
  "Directory containing MATLAB scripts for workspace tree.
This is used to add the path for `printWorkspaceTree.m' to MATLAB's path.")

(defun matlab-fetch-workspace ()
  "Fetch MATLAB workspace objects via `matlab-shell' with output redirection.
This function checks if the MATLAB shell is running, sets up an output buffer,
sends the command to add the script directory to the path and call
`printWorkspaceTree', and waits for the output to complete before returning it
as a string.

Raises an error if the MATLAB shell is not running."
  (unless (get-buffer "*MATLAB*")
    (error "MATLAB shell not running.  Start it with M-x matlab-shell"))
  (let ((output-buffer (get-buffer-create "*MATLAB Workspace Output*"))           ; Temporary buffer for output
        (proc (get-buffer-process "*MATLAB*")))                                   ; Process of the MATLAB shell
    (with-current-buffer output-buffer
      (erase-buffer))                                                             ; Clear any previous content in the output buffer
    (comint-redirect-send-command-to-process
     (format "addpath('%s'); printWorkspaceTree;\n"                               ;
             matlab-workspace-tree-script-dir)                                    ; Command to send
     output-buffer proc nil t)                                                    ; Redirect output to buffer, no echo, wait for prompt
    ;; Wait for redirection to complete by polling the process output
    (while (not comint-redirect-completed)
      (accept-process-output proc 0.1))                                           ; Accept output with 0.1s timeout
    (with-current-buffer output-buffer
      (buffer-string))))                                                          ; Return the collected output as a string

(defun matlab-parse-workspace (output)
  "Parse MATLAB workspace output into a tree structure: (name type children).

OUTPUT is the string from `matlab-fetch-workspace', typically lines like
'* var: type'.

This function splits the output into lines, matches each line for depth
 (based on '*'), name, and type, and builds a nested list structure.  Structs
and classes push onto a stack for handling nested children.  The resulting tree
is reversed for correct order.

Returns a list of top-level nodes, each as (name type children...)."

  ;; Debugging message to indicate entry into the function
  (message "accessed matlab-parse-workspace")
  (let ((lines (split-string output "\n" t))                                      ; Split output into non-empty lines
        (tree '())                                                                ; Accumulator for top-level nodes
        (stack '()))                                                              ; Stack for handling nested structures
    (dolist (line lines)                                                          ; Process each line
      (when (string-match
             "\\([*]+\\) \\([\\w.]+\\)[ \\t]*:[ \\t]*\\(.+\\)$" line)             ; Match prefix, name, type
        (let* ((depth (1- (length (match-string 1 line))))                        ; Depth = num '*' - 1 (top-level depth 0)
               (name (match-string 2 line))                                       ; Extract variable/field name
               (type (match-string 3 line))                                       ; Extract type/class
               (node (list name type nil)))                                       ; Create node: (name type children)
          ;; Pop stack until we reach the correct parent level
          (while (and stack (>= (length stack) depth))
            (pop stack))
          (if stack
              ;; Add node as child to the top of the stack
              (nconc (nth 2 (car stack)) (list node))
            ;; Otherwise, add to top-level tree
            (push node tree))
          ;; If type indicates nesting potential, push to stack
          (when (string-match-p "\\(struct\\|class\\)" type)
            (push node stack)))))
    (nreverse tree)))                                                             ; Reverse tree to maintain original order

(defclass matlab-memory-tree (memory-object-tree)
  ((language :initform "matlab"))
  "Tree visualizer for MATLAB workspace objects.
Inherits from `memory-object-tree' and sets the language slot to 'matlab'.")

(defvar matlab-memory-tree nil
  "Instance of `matlab-memory-tree', initialized on first use.
This is a singleton instance for the MATLAB workspace tree.")

(defun matlab-memory-tree-init ()
  "Initialize `matlab-memory-tree' if not already done.
Creates an instance with fetch and parse functions, and adds it to the
`Speedbar' expansion list."
  (unless matlab-memory-tree                                                      ; Check if already initialized
    (setq matlab-memory-tree
          (make-instance 'matlab-memory-tree
                         :fetch-command #'matlab-fetch-workspace                  ; Function to get raw output
                         :parse-function #'matlab-parse-workspace))               ; Function to parse into tree
    (memory-object-tree-add-expansion matlab-memory-tree)))                       ; Register with Speedbar

(add-hook 'matlab-mode-hook #'matlab-memory-tree-init)
;; Automatically initialize when entering MATLAB mode

(defun matlab-speedbar-refresh-workspace ()
  "Refresh the MATLAB workspace in Speedbar.
Ensures the MATLAB shell is running, initializes the tree if needed,
and refreshes Speedbar (using sr-speedbar if available)."
  (interactive)                                                                   ; Can be called interactively
  (when (get-buffer "*MATLAB*")                                                   ; Check if MATLAB shell is active
    (matlab-memory-tree-init)                                                     ; Ensure tree is initialized
    (if (fboundp 'sr-speedbar-refresh)
        (sr-speedbar-refresh)                                                     ; Refresh if sr-speedbar is loaded
      (speedbar-refresh))))                                                       ; Standard Speedbar refresh

(define-key matlab-mode-map (kbd "C-c w") #'matlab-speedbar-refresh-workspace)
;; Bind C-c w in MATLAB mode to refresh the workspace tree

(provide 'matlab-workspace-tree)
;;; matlab-workspace-tree.el ends here

;; LocalWords:  Structs  matlab Speedbar
