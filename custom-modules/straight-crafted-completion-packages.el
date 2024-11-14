;;; straight-crafted-completion-packages.el --- Completion packages  -*- lexical-binding: t; -*-

;; Copyright (C) 2022
;; SPDX-License-Identifier: MIT

;; Author: System Crafters Community

;;; Commentary:

;; Add completion packages to the list of packages to install.

;;; Code:
(require 'custom-logging-config)
(require 'straight)

(use-package cape)
(use-package consult)
(use-package embark-consult
  :hook (embark-collect-mode . consult-preview-at-point-mode))
(use-package marginalia)
(use-package corfu)
(use-package corfu-terminal)
(use-package embark)
(use-package orderless)
(use-package vertico)

;; Generic interface to access flyspell. 
;; https://github.com/d12frosted/flyspell-correct
(use-package flyspell-correct)

;; Integrate flyspell with consult. 
;; https://gitlab.com/OlMon/consult-flyspell
;; (use-package consult-flyspell
;;   :straight (:type git
;;                    :host gitlab
;;                    :repo "OlMon/consult-flyspell"
;;                    :branch "master"))


(provide 'straight-crafted-completion-packages)
;;; straight-crafted-completion-packages.el ends here
