;;; custom-fileFormat-support.el --- Support for navigating files   -*- lexical-binding: t; -*-

;;; Commentary:



;;; Code:


;; JSON
(use-package json-snatcher)
(add-to-list 'auto-mode-alist '("\\.json\\'\\|\\.JSON\\'" . json-ts-mode))

;; (defun my-file-format/json-setup ()
;;   "Set a hotkey for using the json-snatcher plugin."
;;   (when (string-match  "\\.json$" (buffer-name))
;;     (local-set-key (kbd "C-c C-g") 'jsons-print-path)))
;; (add-hook 'js-mode-hook 'my-file-format/json-setup)
;; (add-hook 'js2-mode-hook 'my-file-format/json-setup)

;; CSV
(use-package csv-mode)
(add-to-list 'auto-mode-alist '("\\.csv\\'\\|\\.CSV\\'" . csv-mode))
(customize-set-variable 'csv-align-mode t)


(provide 'custom-fileFormat-support)
;;; custom-file-formats.el ends here
