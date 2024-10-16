;;; straight-crafted-hydra-packages.el -*- lexical-binding: t; -*-

;; Copyright (C) 2022
;; SPDX-License-Identifier: MIT

;; Author: System Crafters Community

;;; Commentary:

;; Hydra packages

;;; Code:
(require 'custom-logging-config)

(use-package hydra
  :straight (:type git
                   :flavor melpa
                   :files (:defaults (:exclude "lv.el") "hydra-pkg.el")
                   :host github
                   :repo "abo-abo/hydra"))

(use-package pretty-hydra
  :straight (:type git
                   :flavor melpa
                   :files ("pretty-hydra.el" "pretty-hydra-pkg.el")
                   :host github
                   :repo "jerrypnz/major-mode-hydra.el"))

(use-package symbol-navigation-hydra
  :straight (:type git
                   :flavor melpa
                   :host github
                   :repo "bgwines/symbol-navigation-hydra"))

(use-package use-package-hydra
  :straight (:type git
                   :flavor melpa
                   :host gitlab
                   :repo "to1ne/use-package-hydra"))

(use-package major-mode-hydra
  :straight (:type git
                   :flavor melpa
                   :files ("major-mode-hydra.el" "major-mode-hydra-pkg.el")
                   :host github
                   :repo "jerrypnz/major-mode-hydra.el"))



(provide 'straight-crafted-hydra-packages)
;;; straight-crafted-hydra-packages.el ends here
