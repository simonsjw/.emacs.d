;;; custom-completion-support.el --- Completion packages  -*- lexical-binding: t; -*-

;; Copyright (C) 2022
;; SPDX-License-Identifier: MIT

;; Author: System Crafters Community

;;; Commentary:

;; Add completion packages to the list of packages to install.

;;; Code:
(declare-function which-key-mode "which-key")
(declare-function corfu-terminal-mode "corfu-terminal")

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
(use-package which-key :config (which-key-mode))

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

;;; Vertico
;; Cycle back to top/bottom result when the edge is reached
(customize-set-variable 'vertico-cycle t)

;; Start Vertico
(vertico-mode 1)

;; Turn off the built-in fido-vertical-mode and icomplete-vertical-mode if
;; they have been turned on by crafted-defaults-config because they interfere
;; with this module.
;;(fido-mode -1)
;;(fido-vertical-mode -1)
;;(icomplete-mode -1)
;;(icomplete-vertical-mode -1)

;;; Marginalia
(customize-set-variable 'marginalia-annotators
                        '(marginalia-annotators-heavy
                          marginalia-annotators-light
                          nil))
(marginalia-mode 1)

;;; Consult
(keymap-global-set "C-s" 'consult-line)
(keymap-set minibuffer-local-map "C-r" 'consult-history)

(setq completion-in-region-function #'consult-completion-in-region)


;;; Orderless
;; Set up Orderless for better fuzzy matching
(customize-set-variable 'completion-styles '(orderless basic))
(customize-set-variable 'completion-category-overrides
                        '((file (styles . (partial-completion)))))

;;; Embark
(keymap-global-set "<remap> <describe-bindings>" #'embark-bindings)
(keymap-global-set "C-." 'embark-act)

;; Use Embark to show bindings in a key prefix with `C-h`
;; (setq prefix-help-command #'embark-prefix-help-command)
;; alternatively, show them in a separate help buffer.
(setq prefix-help-command #'describe-prefix-bindings)


(with-eval-after-load 'embark-consult
  (add-hook 'embark-collect-mode-hook #'consult-preview-at-point-mode))

;;; Corfu
(unless (display-graphic-p)
  (when (require 'corfu-terminal nil :noerror)
    (corfu-terminal-mode +1)))

;; Setup corfu for popup like completion
(customize-set-variable 'corfu-cycle t "Allows cycling through candidates")  
(customize-set-variable 'corfu-auto t "Enable auto completion")     
(customize-set-variable 'corfu-auto-prefix 3 "Complete with less prefix keys") 

(global-corfu-mode 1)

(corfu-popupinfo-mode 1)
(eldoc-add-command #'corfu-insert)
(keymap-set corfu-map "M-p" #'corfu-popupinfo-scroll-down)
(keymap-set corfu-map "M-n" #'corfu-popupinfo-scroll-up)
(keymap-set corfu-map "M-d" #'corfu-popupinfo-toggle)

;;; Cape
;; Setup Cape for better completion-at-point support and more
;; Add useful defaults completion sources from cape
(add-to-list 'completion-at-point-functions #'cape-file)
(add-to-list 'completion-at-point-functions #'cape-dabbrev)

;; Silence the pcomplete capf, no errors or messages!
;; Important for corfu
(advice-add 'pcomplete-completions-at-point
            :around #'cape-wrap-silent)

;; Ensure that pcomplete does not write to the buffer
;; and behaves as a pure `completion-at-point-function'.
(advice-add 'pcomplete-completions-at-point
            :around #'cape-wrap-purify)

;; No auto-completion or completion-on-quit in eshell
(defun crafted-completion-corfu-eshell ()
  "Special settings for when using corfu with eshell."
  (setq-local corfu-quit-at-boundary t
              corfu-quit-no-match t
              corfu-auto nil)
  (corfu-mode))

(add-hook 'eshell-mode-hook #'crafted-completion-corfu-eshell)

(provide 'custom-completion-support)
;;; straight-crafted-completion-support.el ends here
