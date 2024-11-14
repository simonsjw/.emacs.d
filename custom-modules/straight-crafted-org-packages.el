;;; straight-crafted-org-packages.el  -*- lexical-binding: t; -*-

;; Copyright (C) 2022
;; SPDX-License-Identifier: MIT

;; Author: System Crafters Community

;; Commentary

;; Packages to augment Org mode configuration

;;; Code:
;; make sure the org package is dowloaded and installed before
;; org type functionality is called by anything. The built in or
;; can cause conflicts with this if org is called before this.
(use-package org
  :ensure org-plus-contrib)
(use-package org-contrib)
(use-package org-contacts)
(use-package google-contacts)

;; Second brain/zettlekasten by Protesilaos Stavrou (also known as
;; Prot), similar features as Org-Roam, but keeps everything in a
;; single directory, does not use a database preferring filenameing
;; conventions and grep instead.
;; https://github.com/protesilaos/denote
;; (use-package denote
;;   :straight (:type git
;;                    :host github
;;                    :repo "emacs-straight/denote"
;;                    :files ("*" (:exclude ".git"))))

;; Toggle the visibility of some Org elements.
;; https://github.com/awth13/org-appear
(use-package org-appear)
;; install a package to prettyfy the tables. 
(progn
  (add-to-list 'load-path "~/.emacs.d/custom-packages/org-pretty-table")
  (require 'org-pretty-table)
  (add-hook 'org-mode-hook (lambda () (org-pretty-table-mode))))
;; https://gitlab.com/marcowahl/org-pretty-tags
(use-package org-pretty-tags)
;; note `org-roam-directory' set in custom-path-support.
(use-package org-roam
  :init
  (setq org-roam-v2-ack t)
  :custom
  (org-roam-completion-everywhere t)
  (org-roam-dailies-capture-templates
   '(("d" "default" entry "* %<%I:%M %p>: %?"
      :if-new (file+head "%<%Y-%m-%d>.org" "#+title: %<%Y-%m-%d>\n"))))
  :bind (("C-c n l" . org-roam-buffer-toggle)
         ("C-c n f" . org-roam-node-find)
         ("C-c n i" . org-roam-node-insert)
         :map org-mode-map
         ("C-M-i" . completion-at-point)
         :map org-roam-dailies-map
         ("Y" . org-roam-dailies-capture-yesterday)
         ("T" . org-roam-dailies-capture-tomorrow))
  :bind-keymap
  ("C-c n d" . org-roam-dailies-map)
  :config
  (require 'org-roam-dailies) ;; Ensure the keymap is available
  (org-roam-db-autosync-mode))

(provide 'straight-crafted-org-packages)
;;; straight-crafted-org-packages.el ends here
