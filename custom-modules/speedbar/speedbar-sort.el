;;; speedbar-sort.el --- Interactive Speedbar commands -*- lexical-binding: t; -*-

;; Copyright (C) 2026 Simon Watson
;; SPDX-License-Identifier: MIT

;; Author: Simon Watson

;;; Commentary:
;; Sorting speedbar elements in the file/directory view.

;;; Code:

(with-eval-after-load 'speedbar

  ;; === State variables ===
  (defvar speedbar-file-sort-type 'name
    "Current sort type for Speedbar file/directory view.
Possible values: 'name, 'mtime, 'extension.")

  (defvar speedbar-file-sort-direction 'ascending
    "Current sort direction.
Possible values: 'ascending or 'descending.")

  ;; === Core sorting command ===
  (defun speedbar-set-file-sort (new-type)
    "Set the Speedbar file sort type.
If NEW-TYPE is the same as the current type, toggle the direction.
Otherwise, switch type and reset direction to 'ascending."
    (if (eq new-type speedbar-file-sort-type)
        ;; Same type → toggle direction
        (setq speedbar-file-sort-direction
              (if (eq speedbar-file-sort-direction 'ascending)
                  'descending 'ascending))
      ;; Different type → switch and reset to ascending
      (setq speedbar-file-sort-type new-type
            speedbar-file-sort-direction 'ascending))
    (speedbar-refresh))

  ;; === Named commands for key bindings ===
  (defun speedbar-sort-by-name ()
    (interactive)
    (speedbar-set-file-sort 'name))

  (defun speedbar-sort-by-date ()
    (interactive)
    (speedbar-set-file-sort 'mtime))

  (defun speedbar-sort-by-type ()
    (interactive)
    (speedbar-set-file-sort 'extension))

  ;; === Updated sorting logic (respects direction) ===
  (defun my-speedbar-sort-file-list (lst &optional is-dir)
    "Sort file/directory list LST according to current sort settings."
    (let* ((type speedbar-file-sort-type)
           (dir speedbar-file-sort-direction)
           (sorted
            (pcase type
              ('name
               (sort (copy-sequence lst)
                     (if (eq dir 'ascending) #'string< #'string>)))

              ('mtime
               (sort (copy-sequence lst)
                     (lambda (a b)
                       (let* ((file-a (expand-file-name a default-directory))
                              (file-b (expand-file-name b default-directory))
                              (ta (file-attribute-modification-time
                                   (file-attributes file-a)))
                              (tb (file-attribute-modification-time
                                   (file-attributes file-b))))
                         (if (eq dir 'ascending)
                             (time-less-p ta tb)      ; oldest first
                           (not (time-less-p ta tb))))))) ; newest first

              ('extension
               (sort (copy-sequence lst)
                     (lambda (a b)
                       (let ((ea (or (file-name-extension a t) ""))
                             (eb (or (file-name-extension b t) "")))
                         (if (eq dir 'ascending)
                             (or (string< ea eb)
                                 (and (string= ea eb) (string< a b)))
                           (or (string> ea eb)
                               (and (string= ea eb) (string> a b))))))))
              (_ lst))))
      sorted))

  ;; === Advice that applies the sorting ===
  (advice-add 'speedbar-file-lists :filter-return
              (lambda (result)
                (let* ((dirs  (car result))
                       (files (cadr result))
                       (sorted-dirs  (my-speedbar-sort-file-list dirs t))
                       (sorted-files (my-speedbar-sort-file-list files)))
                  (cons sorted-dirs (list sorted-files)))))

  ;; === Add key bindings to file view keymap ===
  (define-key speedbar-file-key-map (kbd "s n") #'speedbar-sort-by-name)
  (define-key speedbar-file-key-map (kbd "s d") #'speedbar-sort-by-date)
  (define-key speedbar-file-key-map (kbd "s t") #'speedbar-sort-by-type)

  ;; Optional: also add a menu entry (nice to have)
  (add-to-list 'speedbar-easymenu-definition-special
               '("Sort Files"
                 ["By Name"     speedbar-sort-by-name     t]
                 ["By Date"     speedbar-sort-by-date     t]
                 ["By Type"     speedbar-sort-by-type     t])
               t)

  (message "Speedbar file sorting keys loaded (s n / s d / s t)"))


(provide 'speedbar-sort)
;;; speedbar-sort.el ends here
