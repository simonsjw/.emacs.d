;;; keymap-tools.el --- Inspect large keymaps for which-key titles. -*- lexical-binding: t; -*-

;; Copyright (C) 2026 Simon Watson
;; SPDX-License-Identifier: MIT

;; Author: Simon Watson

;;; Commentary:

;; Unloaded helper on the system-tools load-path.  `init.el' does not
;; `require' this feature.  Use `M-x my-keymap-tools/show-large-keymaps'
;; to list keymaps with many bindings so which-key titles can be added
;; in `keymaps/' modules.  See `menu-keys-support' for prefix maps and
;; `completion-support' for `which-key' itself.
;;
;; From Lisp: `(my-keymap-tools/show-large-keymaps 6 4)' or
;; `(pp (my-keymap-tools/collect-large-keymaps 5 3))'.
;;
;; Map:
;;   Feature:    keymap-tools
;;   Load-after: path-support logging-config
;;   Load-phase: tools
;;   Keymaps:    none
;;   Docs:       docs/keymap-tools.org
;;   OS:         none

;;; Code:

(require 'path-support)
(require 'logging-config)
(log/debug :fn 'keymap-tools
           :msg "Starting load of the keymap-tools module."
           :obj t)

(defun my-keymap-tools/keymap-binding-count (keymap)
  "Return the number of bindings in KEYMAP (including inherited ones)."
  (let ((count 0))
    (map-keymap (lambda (_event _binding) (setq count (1+ count))) keymap)
    count))

(defun my-keymap-tools/keymap-sample-bindings (keymap &optional n)
  "Return sample bindings from KEYMAP as strings, at most N of them.
KEYMAP is the keymap to sample.  N defaults to 5.
Each string looks like \"KEY → command-or-prefix\"."
  (let ((n (or n 5))
        samples)
    (catch 'done
      (map-keymap
       (lambda (event binding)
         (let* ((key-str (key-description (vector event)))
                (desc (cond
                       ((keymapp binding) "+prefix")
                       ((symbolp binding) (symbol-name binding))
                       ((functionp binding) "#<function>")
                       (t (format "%S" binding)))))
           (push (format "%s → %s" key-str desc) samples)
           (when (>= (length samples) n)
             (throw 'done t))))
       keymap))
    (nreverse samples)))

(defun my-keymap-tools/collect-large-keymaps (&optional min-bindings sample-size)
  "Return a list of (SYMBOL COUNT SAMPLES) for keymaps with > MIN-BINDINGS.
SAMPLES is a list of up to SAMPLE-SIZE example bindings (default 5).
Sorted by size descending, then by name."
  (let ((min (or min-bindings 3))
        (samples-n (or sample-size 5))
        result
        seen)
    (mapatoms
     (lambda (sym)
       (dolist (candidate (list (and (boundp sym) (symbol-value sym))
                                (and (fboundp sym) (symbol-function sym))))
         (when (and (keymapp candidate)
                    (not (memq candidate seen)))
           (push candidate seen)
           (let ((n (my-keymap-tools/keymap-binding-count candidate)))
             (when (> n min)
               (push (list sym
                           n
                           (my-keymap-tools/keymap-sample-bindings candidate samples-n))
                     result)))))))
    (sort result
          (lambda (a b)
            (or (> (cadr a) (cadr b))
                (and (= (cadr a) (cadr b))
                     (string< (symbol-name (car a))
                              (symbol-name (car b)))))))))

(defun my-keymap-tools/show-large-keymaps (&optional min-bindings sample-size)
  "Pretty-print large keymaps into a dedicated buffer.
MIN-BINDINGS is the size threshold (default 3).  SAMPLE-SIZE is how many
example bindings to show per keymap (default 5)."
  (interactive)
  (let* ((min (or min-bindings 3))
         (samples (or sample-size 5))
         (data (my-keymap-tools/collect-large-keymaps min samples))
         (buf (get-buffer-create "*Large Keymaps*")))
    (with-current-buffer buf
      (erase-buffer)
      (insert (format
               "Keymaps with more than %d bindings (showing up to %d samples each)\n"
               min samples)
              (make-string 72 ?═) "\n\n")
      (dolist (entry data)
        (let ((sym (nth 0 entry))
              (count (nth 1 entry))
              (samples (nth 2 entry)))
          (insert (format "%s  (%d bindings)\n" sym count))
          (dolist (s samples)
            (insert (format "    %s\n" s)))
          (insert "\n")))
      (goto-char (point-min))
      (view-mode 1))
    (pop-to-buffer buf)))


(log/debug :fn 'keymap-tools
           :msg "Ending load of the keymap-tools module."
           :obj t)

(provide 'keymap-tools)
;;; keymap-tools.el ends here

