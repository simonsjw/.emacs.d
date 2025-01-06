;;; custom-completion-support.el --- Completion packages  -*- lexical-binding: t; -*-

;; Copyright (C) 2022
;; SPDX-License-Identifier: MIT

;; Author: System Crafters Community

;;; Commentary:

;; Add completion packages to the list of packages to install.

;;; Code:
(declare-function which-key-mode "which-key")
(defvar corfu-terminal-mode)

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
(use-package which-key
  :config (which-key-mode))



;; Integrate flyspell with consult.
;; https://gitlab.com/OlMon/consult-flyspell
;; (use-package consult-flyspell)


;;; Vertico
;; Cycle back to top/bottom result when the edge is reached
(customize-set-variable 'vertico-cycle t)

;; Start Vertico
(vertico-mode 1)

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

;; Which-key
;; https://github.com/justbur/emacs-which-key

;;(which-key-setup-side-window-right)

;; Show keys in a side window. This popup type has further options:
(setq which-key-popup-type 'side-window)

;; location of which-key window. valid values: top, bottom, left, right,
;; or a list of any of the two. If it's a list, which-key will always try
;; the first location first. It will go to the second location if there is
;; not enough room to display any keys in the first location
(setq which-key-side-window-location 'right)

;; max width of which-key window, when displayed at left or right.
;; valid values: number of columns (integer), or percentage out of current
;; frame's width (float larger than 0 and smaller than 1)
(setq which-key-side-window-max-width 0.4)

;; Set the time delay (in seconds) for the which-key popup to appear. A value of
;; zero might cause issues so a non-zero value is recommended.
(setq which-key-idle-delay 1.0)

;; Set the maximum length (in characters) for key descriptions (commands or
;; prefixes). Descriptions that are longer are truncated and have ".." added.
;; This can also be a float (fraction of available width) or a function.
(setq which-key-max-description-length 27)

;; Use additional padding between columns of keys. This variable specifies the
;; number of spaces to add to the left of each column.
(setq which-key-add-column-padding 0)

;; The maximum number of columns to display in the which-key buffer. nil means
;; don't impose a maximum.
(setq which-key-max-display-columns nil)

;; Set the separator used between keys and descriptions. Change this setting to
;; an ASCII character if your font does not show the default arrow. The second
;; setting here allows for extra padding for Unicode characters. which-key uses
;; characters as a means of width measurement, so wide Unicode characters can
;; throw off the calculation.
(setq which-key-separator " → " )
(setq which-key-unicode-correction 3)

;; Set the prefix string that will be inserted in front of prefix commands
;; (i.e., commands that represent a sub-map).
(setq which-key-prefix-prefix "+" )

;; Set the special keys. These are automatically truncated to one character and
;; have which-key-special-key-face applied. Disabled by default. An example
;; setting is
;; (setq which-key-special-keys '("SPC" "TAB" "RET" "ESC" "DEL"))
(setq which-key-special-keys nil)

;; Show the key prefix on the left, top, or bottom (nil means hide the prefix).
;; The prefix consists of the keys you have typed so far. which-key also shows
;; the page information along with the prefix.
(setq which-key-show-prefix 'left)

;; Set to t to show the count of keys shown vs. total keys in the mode line.
(setq which-key-show-remaining-keys t)                                            ; default is nil.

(provide 'custom-completion-support)
;;; custom-completion-support.el ends here.
