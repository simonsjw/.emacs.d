;;; custom-fileFormat-support.el --- Support for navigating files   -*- lexical-binding: t; -*-

;;; Commentary:

;;;Declare functions and imports
(declare-function treesit-fold-mode "treesit-fold")
(declare-function treesit-fold-indicators-mode "treesit-fold-indicators")
(declare-function json-mode "json-mode")

;;; Code:

;; packages
(use-package json-snatcher)
(use-package json-mode)
(use-package csv-mode)



;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;; CSV formatted files ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;


(add-to-list 'auto-mode-alist '("\\.csv\\'\\|\\.CSV\\'" . csv-mode))
(customize-set-variable 'csv-align-mode t)


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;; JSON formatted files ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;


(add-to-list 'auto-mode-alist '("\\.json\\'\\|\\.JSON\\'" . json-ts-mode))

(defun my-fileFormat-support/json-ts-mode-setup ()
  "Custom configurations for json-ts-mode."

  (json-mode)

  ;; Remove the fill column indicator.
  (display-fill-column-indicator-mode -1)
  
  ;; Set the fringe mode specifically for json-ts-mode
  (set-fringe-mode '(12 . 5))

  ;; Enable ts-fold-mode
  (treesit-fold-mode 1)

  ;; Enable treesit-fold-indicators-mode
  (treesit-fold-indicators-mode 1))

;; Add the custom setup to json-ts-mode-hook
(add-hook 'json-ts-mode-hook #'my-fileFormat-support/json-ts-mode-setup)

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;; TOML formatted files ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

(add-to-list 'auto-mode-alist '("\\.toml\\'\\|\\.TOML\\'" . toml-ts-mode))

(defun my-fileFormat-support/toml-ts-mode-setup ()
  "Custom configurations for toml-ts-mode."

  (setq display-fill-column-indicator-column 50)                                 ; Edge 
  (setq fill-column 50)                                                          ; Column beyond which line wrapping occurs if it is activated.
  (setq comment-fill-column 270)                                                 ; Colujmn to use for 'comment-indent'. If nil, use 'fill-column' instead.
  (setq comment-column 52)                                                       ; Column to indent right-margin comments to.
  (display-fill-column-indicator-mode 1)                                         ; show fill column indicator 
  
  ;; Set the fringe mode specifically for json-ts-mode
  (set-fringe-mode '(12 . 5))

  ;; Enable ts-fold-mode
  (treesit-fold-mode 1)

  ;; Enable treesit-fold-indicators-mode
  (treesit-fold-indicators-mode 1))

;; Add the custom setup to toml-ts-mode-hook
(add-hook 'toml-ts-mode-hook #'my-fileFormat-support/toml-ts-mode-setup)

(provide 'custom-fileFormat-support)
;;; custom-fileFormat-support.el ends here
