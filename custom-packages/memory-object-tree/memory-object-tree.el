(require 'eieio)
(require 'speedbar)

(defclass memory-object-tree ()
  ((language :initarg :language :type string :documentation "The programming language.")
   (fetch-command :initarg :fetch-command :type function :documentation "Function to fetch memory objects.")
   (parse-function :initarg :parse-function :type function :documentation "Function to parse fetched data into a tree."))
  "Generic class for visualizing memory objects as a tree in Speedbar.")

(defun memory-object-tree-node-to-item (node)
  "Convert a raw node (name type children...) to a Speedbar item format."
  (let ((name (car node))
        (children (cddr node)))
    (if children
        (list name node t)
      (cons name node))))

(defun memory-object-tree-expand (text token indent)
  "Expand a subtree node in Speedbar. TOKEN is the node (name type children...)."
  (let ((children (cddr token)))
    (speedbar-with-writable
      (let ((items (mapcar #'memory-object-tree-node-to-item children)))
        (speedbar-insert-generic-list (1+ indent) items #'memory-object-tree-expand #'memory-object-tree-item-info)))))

(defun memory-object-tree-item-info (text token indent)
  "Display information about a tree node."
  (message "Item: %s, Type: %s" (car token) (cadr token)))

(defun memory-object-tree-line-function (text token indent)
  "Handle clicks on a tree node."
  (memory-object-tree-item-info text token indent))

(defun memory-object-tree-group-expand (text token indent)
  "Toggle expansion of the top-level workspace group. TOKEN is the tree-obj instance."
  (save-excursion
    (beginning-of-line)
    (forward-char 1)  ; Move to the button char position.
    (if (char-equal (char-after) ?+)
        (progn
          (speedbar-change-expand-button-char ?-)
          (forward-char -1)
          (speedbar-next 1)
          (speedbar-with-writable
            (let* ((output (funcall (oref token fetch-command)))
                   (tree (funcall (oref token parse-function) output))
                   (items (mapcar #'memory-object-tree-node-to-item tree)))
              (speedbar-insert-generic-list indent items #'memory-object-tree-expand #'memory-object-tree-item-info #'memory-object-tree-line-function))))
      (speedbar-change-expand-button-char ?+)
      (speedbar-delete-subblock indent))))

(defun memory-object-tree-insert-group-button (tree-obj indent)
  "Insert the top-level workspace group button."
  (speedbar-make-tag-line 'bracket ?+ #'memory-object-tree-group-expand tree-obj
                          (format "%s Workspace" (capitalize (oref tree-obj language)))
                          'speedbar-tag-face
                          indent))

(defun memory-object-tree-add-expansion (tree-obj)
  "Add the memory object tree group to Speedbar's initial expansion list."
  (add-to-list 'speedbar-initial-expansion-list-alist
               (list (format "%s-workspace" (oref tree-obj language))
                     (lambda (indent) (memory-object-tree-insert-group-button tree-obj indent))
                     nil  ; No separate list function needed.
                     #'memory-object-tree-item-info
                     #'memory-object-tree-line-function)))

(provide 'memory-object-tree)
