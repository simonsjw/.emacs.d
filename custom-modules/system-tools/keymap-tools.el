;;; keymap-tools.el --- Tools to maintain Keymap group names -*- lexical-binding: t; -*-

;; Copyright (C) 2025 Simon Watson
;; SPDX-License-Identifier: MIT

;;; Commentary:

;; This file allows for the maintenance of keymap groups, aiding the use of
;; which-key.  See menu-keys-support.el for setting keys or
;; completion-support.el to see the `which-key' setup.

;; Usage:
;; Interactive – opens a nice buffer
;; M-x my-keymap-tools/show-large-keymaps

;; ;; Or from Lisp with custom thresholds
;; (my-keymap-tools/show-large-keymaps 6 4)   ; >6 bindings, show 4 samples each

;; ;; Just get the raw data
;; (pp (my-keymap-tools/collect-large-keymaps 5 3))


;; The buffer will look roughly like this:
;; Keymaps with more than 3 bindings (showing up to 5 samples each)
;; ════════════════════════════════════════════════════════════════

;; vc-prefix-map  (28 bindings)
;; a → vc-update-change-log
;; b → +prefix
;; d → vc-dir
;; g → vc-annotate
;; h → +prefix          ; ← your diff-hl one will appear here

;; dired-mode-map  (142 bindings)
;; RET → dired-find-file
;; a → dired-find-alternate-file
;; ...

;; You can now quickly scan by name prefix (vc-, git-, diff-, magi-, project-,
;; ctl-x, etc.) and only add which-key names for the maps that matter to you.


;;; Code:
(defun my-keymap-tools/keymap-binding-count (keymap)
  "Return the number of bindings in KEYMAP (including inherited ones)."
  (let ((count 0))
    (map-keymap (lambda (_event _binding) (setq count (1+ count))) keymap)
    count))

(defun my-keymap-tools/keymap-sample-bindings (keymap &optional n)
  "Return a list of up to N sample bindings from KEYMAP as strings.
Each string looks like \"KEY → command-or-prefix\".
N defaults to 5."
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

(defun my-keymap-tools/keymap-binding-count (keymap)
  "Return the number of bindings in KEYMAP (including inherited ones)."
  (let ((count 0))
    (map-keymap (lambda (_event _binding) (setq count (1+ count))) keymap)
    count))

(defun my-keymap-tools/keymap-sample-bindings (keymap &optional n)
  "Return a list of up to N sample bindings from KEYMAP as strings.
Each string looks like \"KEY → command-or-prefix\".
N defaults to 5."
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
  "Pretty-print all large keymaps (with sample keys) into a dedicated buffer."
  (interactive)
  (let* ((min (or min-bindings 3))
         (samples (or sample-size 5))
         (data (my/collect-large-keymaps min samples))
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

