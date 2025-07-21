(require 'eieio)
(require 'memory-object-tree)
(require 'matlab)

(defvar matlab-workspace-tree-script-dir
  (file-name-directory (or load-file-name buffer-file-name))
  "Directory containing MATLAB scripts for workspace tree.")

(defun matlab-fetch-workspace ()
  "Fetch MATLAB workspace objects via matlab-shell-collect-command-output."
  (unless (get-buffer "*MATLAB*")
    (error "MATLAB shell not running. Start it with M-x matlab-shell"))
  (matlab-shell-collect-command-output
   (format "addpath('%s'); printWorkspaceTree;", matlab-workspace-tree-script-dir)))

(defun matlab-parse-workspace (output)
  "Parse MATLAB workspace output into a tree structure: (name type children...). Returns list of top-level nodes."
  (let ((lines (split-string output "\n" t))
        (tree '())
        (stack '()))
    (dolist (line lines)
      (when (string-match "^\\(\\*+\\) \\([\\w.]+\\): \\(.+\\)$" line)
        (let* ((stars (match-string 1 line))
               (depth (1- (length stars)))  ; * -> depth 0, ** -> 1, etc.
               (name (match-string 2 line))
               (type (match-string 3 line))
               (node (list name type)))
          (while (and stack (>= (length stack) depth))
            (pop stack))
          (if stack
              (setcdr (cdr (car (last (cddr (car stack))))) (list node))  ; Append to parent's children
            (push node tree))
          (when (string-match-p "\\(struct\\|object:\\)" type)
            (push node stack)))))
    (nreverse tree)))

(defclass matlab-memory-tree (memory-object-tree)
  ((language :initform "matlab"))
  "Tree visualizer for MATLAB workspace objects.")

(defvar matlab-memory-tree nil
  "Instance of matlab-memory-tree, initialized on first use.")

(defun matlab-memory-tree-init ()
  "Initialize matlab-memory-tree if not already done."
  (unless matlab-memory-tree
    (setq matlab-memory-tree
          (make-instance 'matlab-memory-tree
                         :fetch-command #'matlab-fetch-workspace
                         :parse-function #'matlab-parse-workspace))
    (memory-object-tree-add-expansion matlab-memory-tree)))

(add-hook 'matlab-mode-hook #'matlab-memory-tree-init)

(defun matlab-speedbar-refresh-workspace ()
  "Refresh the MATLAB workspace in Speedbar."
  (interactive)
  (when (get-buffer "*MATLAB*")
    (matlab-memory-tree-init)  ; Ensure tree is initialized
    (if (fboundp 'sr-speedbar-refresh)
        (sr-speedbar-refresh)  ; Use sr-speedbar refresh if available
      (speedbar-refresh))))

(define-key matlab-mode-map (kbd "C-c w") #'matlab-speedbar-refresh-workspace)

(provide 'matlab-workspace-tree)
