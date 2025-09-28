;;; custom-fileFormat-support.el --- Support for navigating files   -*- lexical-binding: t; -*-

;;; Commentary:

;;;Declare functions and imports
(declare-function treesit-fold-mode "treesit-fold")
(declare-function treesit-fold-indicators-mode "treesit-fold-indicators")
(declare-function json-mode "json-mode")

;;; Code:

;; packages
(use-package vlf)
(use-package csv-mode)
(use-package dotenv-mode)

;;;; Very Large Files (vlf)
;;   ----------------------
;; ensure vlf is used automatically.
(custom-set-variables
 '(vlf-application 'dont-ask))

;;;; .env files
;;   ----------
;; support additional file extensions such as `.env.test' with this major mode.
(add-to-list 'auto-mode-alist '("\\.env\\..*\\'" . dotenv-mode))

;;;; CSV formatted files
;;   -------------------
(add-to-list 'auto-mode-alist '("\\.csv\\'\\|\\.CSV\\'" . csv-mode))
(customize-set-variable 'csv-align-mode t)

;;;; JSON formatted files
;;   --------------------

;; apply json-ts-mode to file name suffix .json/ .JSON or .jsonl/ .JSONL
(add-to-list 'auto-mode-alist '("\\.json\\'\\|\\.JSON\\'" . json-ts-mode))
(add-to-list 'auto-mode-alist '("\\.jsonl\\'\\|\\.JSONL\\'" . json-ts-mode))

;; apply this mode to any file up to 2GB in size.
(setq treesit-max-buffer-size 2000000000)

(defun my-fileFormat-support/json-ts-mode-setup ()
  "Custom configurations for json-ts-mode."

  ;; Remove the fill column indicator.
  (display-fill-column-indicator-mode -1)
  
  ;; Set the fringe mode specifically for json-ts-mode
  (set-fringe-mode '(12 . 5))

  ;; Enable treesit-fold-mode
  (require 'treesit-fold)
  (treesit-fold-mode 1)
  ;; Enable treesit-fold-indicators-mode
  (treesit-fold-indicators-mode 1)


  ;; Note the below is the work of Eshel Yaron at
  ;; [[https://eshelyaron.com/posts/2023-05-17-orientation-in-json-documents-with-emacs-and-tree-sitter.html][eshelyaron.com]]
  (defun my-json/json-path-to-position (pos)
    "Return the JSON path from the document's root to the element at POS.

The path is represented as a list of strings and integers,
corresponding to the object keys and array indices that lead from
the root to the element at POS."
    (named-let loop ((node (treesit-node-at pos)) (acc nil))
      (if-let ((parent (treesit-parent-until
                        node
                        (lambda (n)
                          (member (treesit-node-type n)
                                  '("pair" "array"))))))
          (loop parent
                (cons
                 (pcase (treesit-node-type parent)
                   ("pair"
                    (treesit-node-text
                     (treesit-node-child (treesit-node-child parent 0) 1) t))
                   ("array"
                    (named-let check ((i 1))
                      (if (< pos (treesit-node-end (treesit-node-child parent i)))
                          (/ (1- i) 2)
                        (check (+ i 2))))))
                 acc))
        acc)))

  (defun my-json/json-path-at-point (point &optional kill)
    "Display the JSON path at POINT.  When KILL is non-nil, kill it too.

Interactively, POINT is point and KILL is the prefix argument."
    (interactive "d\nP" json-ts-mode)
    (let ((path (mapconcat (lambda (o) (format "%s" o))
                           ( my-json/json-path-to-position point)
                           ".")))
      (if kill
          (progn (kill-new path) (message "Copied: %s" path))
        (message path))
      path))

  )

;; Add the custom setup to json-ts-mode-hook
(add-hook 'json-ts-mode-hook #'my-fileFormat-support/json-ts-mode-setup)


;;;; TOML formatted files
;;   --------------------
(add-to-list 'auto-mode-alist '("\\.toml\\'\\|\\.TOML\\'" . toml-ts-mode))

(defun my-fileFormat-support/toml-ts-mode-setup ()
  "Custom configurations for toml-ts-mode."
  (require 'treesit-fold)
  
  (setq display-fill-column-indicator-column 50)                                 ; Edge 
  (setq fill-column 50)                                                          ; Column beyond which line wrapping occurs if it is activated.
  (setq comment-fill-column 270)                                                 ; Colujmn to use for 'comment-indent'. If nil, use 'fill-column' instead.
  (setq comment-column 52)                                                       ; Column to indent right-margin comments to.
  (display-fill-column-indicator-mode 1)                                         ; show fill column indicator 
  
  ;; Set the fringe mode specifically for json-ts-mode
  (set-fringe-mode '(12 . 5))

  ;; Enable treesit-fold-mode
  (treesit-fold-mode 1)
  ;; Enable treesit-fold-indicators-mode
  (treesit-fold-indicators-mode 1))

;; Add the custom setup to toml-ts-mode-hook
(add-hook 'toml-ts-mode-hook #'my-fileFormat-support/toml-ts-mode-setup)

(provide 'fileFormat-support)
;;; fileFormat-support.el ends here
