;;; crafted-ui-packages.el -*- lexical-binding: t; -*-

;; Copyright (C) 2022
;; SPDX-License-Identifier: MIT

;; Author: System Crafters Community

;;; Commentary:

;; Packages to configure with `crafted-ui-config.el'

;;; packages
(use-package bookmark+
  :straight(:type git
                  :host github
                  :repo "emacsmirror/bookmark-plus"))


(use-package dired+
  :straight (:type git
                   :host github
                   :repo "emacsmirror/dired-plus"))                


;; here we use a direct load of info+.el since use-package
;; throws up an error. 
(load (expand-file-name
       "custom-packages/info+.el" user-emacs-directory))

(use-package imenu-list
  :straight (:type git
                   :host github
                   :repo "bmag/imenu-list"))

(use-package elisp-demos
  :straight (:type git
                   :flavor melpa
                   :files (:defaults "*.org" "elisp-demos-pkg.el")
                   :host github :repo "xuchunyang/elisp-demos"))

;; Get Bufler the recursive buffer grouping package
(use-package bufler
  :straight (:type git
                   :host github
                   :repo "alphapapa/bufler.el"
                   :files (:defaults (:exclude "helm-bufler.el"))))

;; (straight-use-package 'tabspaces)
;; This groups whole frames under a tab as opposed to tab-line which
;; adds a tab to windows with multiple buffers. 

;; Burly - save and restore desktop layouts. 
(use-package burly 
  :straight (:type git
                   :host github
                   :repo "alphapapa/burly.el"))

(provide 'straight-crafted-ui-packages)
;;; straight-crafted-ui-packages.el ends here
