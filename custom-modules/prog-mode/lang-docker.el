;;; lang-docker.el --- Dockerfile and docker-compose editing. -*- lexical-binding: t; -*-

;; Copyright (C) 2026 Simon Watson
;; SPDX-License-Identifier: MIT

;; Author: Simon Watson

;;; Commentary:

;; Language module for Docker: `docker.el' commands and
;; `docker-compose-mode'.  Requires Docker and the compose plugin
;; on the host.  Load from `init.el'.
;;
;; Map:
;;   Feature:    lang-docker
;;   Load-after: path-support logging-config
;;   Load-phase: lang
;;   Keymaps:    none
;;   Docs:       docs/lang-docker.org
;;   OS:         docker

;;; Code:

(require 'path-support)
(require 'logging-config)
(log/debug :fn 'lang-docker
           :msg "Starting load of the lang-docker module."
           :obj t)
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


(log/debug :fn 'lang-docker
           :msg "Finishing load of the lang-docker module."
           :obj t)

(provide 'lang-docker)
;;; lang-docker.el ends here
