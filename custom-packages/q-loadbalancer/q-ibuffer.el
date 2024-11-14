;;; q-ibuffer.el --- Manage the ibuffer for KDB/Q processes in Emacs. -*- lexical-binding: t; -*-

;; Author: Simon Watson
;; Version: 1.2
;; Keywords: KDB, Q, process management
;; URL: https://github.com/simonsjw/q-loadbalancer
;; Package-Requires: (Emacs "24.3")

;;; Commentary:

;; This package provides modeline functionality for `q-loadbalancer-mode'.
;; It allows users to start and manage several Q processes, grouped by type,
;; with each group potentially containing multiple processes.

;; In this script, we update ibuffer for this mode.

(defvar ibuffer-saved-filter-groups)
(declare-function ibuffer-switch-to-saved-filter-groups "ibuffer")
(declare-function ibuffer-do-sort-by-alphabetic "ibuffer")

;;; Code:

;; Define the segment: Q Process buffer list.
;; Ensure ibuffer is available before loading this setup.


(when (featurep 'ibuffer)
  ;; Add "Q Processes" group without overwriting existing groups
  (let ((existing-groups (assoc "default" ibuffer-saved-filter-groups)))
    (if existing-groups
        ;; If "default" group exists, add "Q Processes" to it
        (setcdr existing-groups
                (append (cdr existing-groups)
                        '(("Q Processes" (mode . q-loadbalancer)))))
      ;; Otherwise, create a new "default" group with "Q Processes"
      (add-to-list 'ibuffer-saved-filter-groups
                   '("default" ("Q Processes" (mode . q-loadBalancer))))))

  (add-hook 'ibuffer-mode-hook
            (lambda ()
              (ibuffer-switch-to-saved-filter-groups "default")
              ;; Sort by buffer name within groups
              (ibuffer-do-sort-by-alphabetic))))



(provide 'q-ibuffer)

;;; q-ibuffer.el ends here

