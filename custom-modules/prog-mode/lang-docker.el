;;; lang-docker.el --- systemd service file support for the crafted setup   -*- lexical-binding: t; -*-

;;; Commentary:
;;
;; Packages for docker related high-jinx.
;;
;;
;; Prerequisites: docker and the compose plugin. 
;;


;;; Code:

;;; Packages phase

;; base docker commands.
;; https://github.com/Silex/docker.el
(use-package docker)

;; completions for editing docker compose files.
;; https://github.com/meqif/docker-compose-mode
(use-package docker-compose-mode)

;;; Configuration phase
(defvar docker-run-as-root)
(setq docker-run-as-root t)


(provide 'lang-docker)
;;; lang-docker.el ends here
