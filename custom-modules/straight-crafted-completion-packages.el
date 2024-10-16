;;; straight-crafted-completion-packages.el --- Completion packages  -*- lexical-binding: t; -*-

;; Copyright (C) 2022
;; SPDX-License-Identifier: MIT

;; Author: System Crafters Community

;;; Commentary:

;; Add completion packages to the list of packages to install.

;;; Code:
(require 'custom-logging-config)
(require 'straight)

(use-package cape
  :straight  (:type git
                    :flavor melpa
                    :host github
                    :repo "minad/cape"))

(use-package consult
  :straight  (:type git
                    :flavor melpa
                    :host github
                    :repo "minad/consult"))
                    
(use-package embark-consult
  :straight  (:type git
                    :flavor melpa
                    :files ("embark-consult.el" "embark-consult-pkg.el")
                    :host github :repo "oantolin/embark")
  :hook (embark-collect-mode . consult-preview-at-point-mode))

(use-package marginalia
  :straight  (:type git
                    :flavor melpa
                    :host github
                    :repo "minad/marginalia"))
(use-package corfu
  :straight (:type git
                   :flavor melpa
                   :files (:defaults "extensions/corfu-*.el" "corfu-pkg.el")
                   :host github
                   :repo "minad/corfu"))

(use-package corfu-terminal
  :straight  (:repo "https://codeberg.org/akib/emacs-corfu-terminal"))

(use-package embark
  :straight  (:type git
                    :flavor melpa
                    :files ("embark.el" "embark-org.el"
                            "embark.texi" "embark-pkg.el")
                    :host github
                    :repo "oantolin/embark"))

(use-package orderless
  :straight  (:type git
                    :flavor melpa
                    :host github
                    :repo "oantolin/orderless"))

(use-package vertico
  :straight (:type git
                   :flavor melpa
                   :files (:defaults "extensions/vertico-*.el"
                                     "vertico-pkg.el")))

;; Generic interface to access flyspell. 
;; https://github.com/d12frosted/flyspell-correct
(use-package flyspell-correct
  :straight (:type git
                   :flavor melpa
                   :files ("flyspell-correct.el"
                           "flyspell-correct-ido.el"
                           "flyspell-correct-pkg.el")
                   :host github
                   :repo "d12frosted/flyspell-correct"))

;; Integrate flyspell with consult. 
;; https://gitlab.com/OlMon/consult-flyspell
;; (use-package consult-flyspell
;;   :straight (:type git
;;                    :host gitlab
;;                    :repo "OlMon/consult-flyspell"
;;                    :branch "master"))


(provide 'straight-crafted-completion-packages)
;;; straight-crafted-completion-packages.el ends here
