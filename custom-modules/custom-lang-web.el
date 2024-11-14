;;; custom-lang-web.el --- systemd service file support for the crafted setup   -*- lexical-binding: t; -*-

;;; Commentary:
;;
;; Packages for web related highjinx. 
;;
;;
;; Prerequisites:
;;


;;; Code:


;;; Packages phase

(use-package apache-mode)                                                      ; apache-mode: Emacs major mode for editing Apache HTTP Server configuration files.
(use-package robots-txt-mode)                                                  ; Emacs major mode for editing robots.txt. This mode supports well-known extension by Google and RFC Draft.
(use-package web-mode)                                                         ; format multiple modes in the same buffer; (HTML, javascript, php etc)

;;; Configuration phase
;; (non - can add company-mode hooks if you use company though.)

;; set up web mode
(require 'web-mode)
(add-to-list 'auto-mode-alist '("\\.phtml\\'" . web-mode))
(add-to-list 'auto-mode-alist '("\\.tpl\\.php\\'" . web-mode))
(add-to-list 'auto-mode-alist '("\\.[agj]sp\\'" . web-mode))
(add-to-list 'auto-mode-alist '("\\.as[cp]x\\'" . web-mode))
(add-to-list 'auto-mode-alist '("\\.erb\\'" . web-mode))
(add-to-list 'auto-mode-alist '("\\.mustache\\'" . web-mode))
(add-to-list 'auto-mode-alist '("\\.djhtml\\'" . web-mode))

(provide 'custom-lang-web)
;;; custom-lang-web.el ends here
