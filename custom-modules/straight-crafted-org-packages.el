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
  :straight
  (:type git
         :repo "https://git.savannah.gnu.org/git/emacs/org-mode.git"
         :local-repo "org"
         :depth full
         :pre-build (straight-recipes-org-elpa--build)
         :build (:not autoloads)
         :files (:defaults "lisp/*.el" ("etc/styles/" "etc/styles/*")))
  :ensure org-plus-contrib)

(use-package org-contrib
  :straight
  (:type git
         :includes (ob-csharp
                    ob-eukleides
                    ob-fomus ob-julia
                    ob-mathomatic
                    ob-oz
                    ob-stata
                    ob-tcl
                    ob-vbnet
                    
                    ol-bookmark
                    ol-elisp-symbol
                    ol-git-link ol-man
                    ol-mew ol-vm ol-wl
                    
                    org-annotate-file
                    org-bibtex-extras
                    org-checklist
                    org-choose
                    org-collector
                    org-contribdir
                    org-depend
                    org-effectiveness
                    org-eldoc
                    org-eval
                    org-eval-light
                    org-expiry
                    org-interactive-query
                    org-invoice
                    org-learn
                    org-license
                    org-mac-iCal
                    org-mairix
                    org-panel
                    org-registry
                    org-screen
                    org-screenshot
                    org-secretary
                    org-static-mathjax
                    org-sudoku
                    orgtbl-sqlinsert
                    org-toc
                    org-track
                    org-wikinodes
                    
                    ox-bibtex ox-confluence ox-deck ox-extra
                    ox-freemind ox-groff ox-koma-letter ox-s5
                    ox-taskjuggler)
         :repo "https://git.sr.ht/~bzg/org-contrib"
         :files (:defaults "lisp/*.el")))


(use-package org-contacts
  :straight
  (:type git
         :host github
         :repo "emacsmirror/org-contacts"))


(use-package google-contacts
  :straight (:type git
                   :flavor melpa
                   :host github
                   :repo "jd/google-contacts.el"))

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
(use-package org-appear
  :straight (:type git
                   :flavor melpa
                   :host github
                   :repo "awth13/org-appear"))

;; install a package to prettyfy the tables. 
(use-package org-pretty-table
  :straight (:type git :host github
                   :repo "Fuco1/org-pretty-table"))

;; https://gitlab.com/marcowahl/org-pretty-tags
(use-package org-pretty-tags
  :straight (:type git
                   :flavor melpa
                   :host gitlab
                   :repo "marcowahl/org-pretty-tags"))

;; note `org-roam-directory' set in custom-path-support.
(use-package org-roam
  :straight (:type git
                   :flavor melpa
                   :files (:defaults "extensions/*" "org-roam-pkg.el")
                   :host github
                   :repo "org-roam/org-roam")
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
