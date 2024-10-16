;;; custom-fileFormat-support.el --- Support for navigating files   -*- lexical-binding: t; -*-

;;; Commentary:



;;; Code:


;; JSON
(straight-use-package '(json-snatcher  :type git :host github
                                    :repo "Sterlingg/json-snatcher"))

(straight-use-package '(json-emacs  :type git :host github
                                    :repo "json-emacs/json-mode"))

(require 'json-mode)
(add-to-list 'auto-mode-alist '("\\.json\\'\\|\\.JSON\\'" . json-ts-mode))


;; CSV
(straight-use-package 'csv-mode)
(require 'csv-mode)
(add-to-list 'auto-mode-alist '("\\.csv\\'\\|\\.CSV\\'" . csv-mode))
(customize-set-variable 'csv-align-mode t)

(my/log-to-file
 (format
  "[%s ; INFO; init.el] providing custom-fileFormat-support.;True;"
  (current-time-string)) init-log)

(provide 'custom-fileFormat-support)
;;; custom-file-formats.el ends here
