;;; custom-fileFormat-support.el --- Support for navigating files   -*- lexical-binding: t; -*-

;;; Commentary:

;;;Declare functions and imports
(declare-function treesit-fold-mode treesit-fold)
(declare-function treesit-fold-indicators-mode treesit-fold-indicators)

;;; Code:

;; JSON
(use-package json-snatcher
  :straight ( :type git
              :flavor melpa
              :host github
              :repo "Sterlingg/json-snatcher"))

(use-package json-mode
  :straight ( :type git
              :flavor melpa
              :host github
              :repo "json-emacs/json-mode"))
(use-package csv-mode
  :straight ( :type git
              :host github
              :repo "emacs-straight/csv-mode"
              :files ("*" (:exclude ".git"))))


;; CSV

(add-to-list 'auto-mode-alist '("\\.csv\\'\\|\\.CSV\\'" . csv-mode))
(customize-set-variable 'csv-align-mode t)

;; JSON
(add-to-list 'auto-mode-alist '("\\.json\\'\\|\\.JSON\\'" . json-ts-mode))

(defun my-json-ts-mode-setup ()
  "Custom configurations for json-ts-mode."

  ;; Remove the fill column indicator.
  (display-fill-column-indicator-mode -1)
  
  ;; Set the fringe mode specifically for json-ts-mode
  (set-fringe-mode '(12 . 0))

  ;; Enable ts-fold-mode
  (treesit-fold-mode 1)

  ;; Enable treesit-fold-indicators-mode
  (treesit-fold-indicators-mode 1))

;; Add the custom setup to json-ts-mode-hook
(add-hook 'json-ts-mode-hook 'my-json-ts-mode-setup)

(provide 'custom-fileFormat-support)
;;; custom-fileFormat-support.el ends here
