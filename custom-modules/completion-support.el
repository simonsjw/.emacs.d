;;; completion-support.el --- Modern completion framework -*- lexical-binding: t; -*-

;; Copyright (C) 2025 Simon Watson
;; SPDX-License-Identifier: MIT

;;; Commentary:

;; This file configures a modern, cohesive completion experience using:
;; - Vertico: Vertical minibuffer completion UI
;; - Orderless: Flexible out-of-order (fuzzy) matching
;; - Marginalia: Rich candidate annotations in the minibuffer
;; - Consult: Enhanced completion commands with preview
;; - Embark: Contextual actions on candidates
;; - Corfu: In-buffer completion UI (child-frame popup)
;; - Cape: Additional completion-at-point backends
;; - Built-in which-key (Emacs 30+): Keybinding discovery popup

;; All configuration is consolidated within `use-package' declarations
;; for clarity and maintainability.  Extensive inline comments explain
;; each setting.

;;; Code:

(use-package vertico
  :ensure t
  :custom
  ;; Enable cycling: pressing the edge of the candidate list wraps around
  ;; to the opposite end for easier navigation.
  (vertico-cycle t)
  :init
  (vertico-mode 1)
  :config
  ;; Optional: Improve performance for very large completion tables
  ;; by using faster dispatchers (requires orderless-fast from MELPA,
  ;; uncomment if installed).
  ;; (vertico-multiform-mode 1)
  )


(use-package orderless
  :ensure t
  :custom
  ;; Global styles: Orderless primary, with fallbacks.
  (completion-styles '(orderless basic))
  ;; Clear packaged defaults to avoid conflicts.
  (completion-category-defaults nil)
  ;; Specific overrides:
  ;; - Files: partial-completion for better path expansion.
  ;; - Eglot (LSP via Pyrefly): Orderless for local fuzzy filtering.
  (completion-category-overrides
   '((file (styles partial-completion))
     (eglot (styles orderless))))
  ;; Space separates Orderless components (default behaviour).
  (orderless-component-separator " "))

(use-package marginalia
  :ensure t
  :custom
  ;; Use the heaviest (most detailed) annotators available.
  (marginalia-annotators '(marginalia-annotators-heavy marginalia-annotators-light nil))
  :init
  (marginalia-mode 1))

(use-package consult
  :ensure t
  :bind
  (;; Global search replacement: Consult's live-updating line search.
   ("C-s" . consult-line)
   ;; Minibuffer history navigation.
   ([remap consult-history] . consult-history))
  :custom
  ;; Use Consult's enhanced completion-in-region function for consistency
  ;; between minibuffer and in-buffer completions.
  (completion-in-region-function #'consult-completion-in-region))

(use-package embark
  :ensure t
  :bind
  (;; Remap built-in describe-bindings to Embark's binding overview.
   ([remap describe-bindings] . embark-bindings)
   ;; Primary Embark action key.
   ("C-." . embark-act))
  :custom
  ;; Use describe-prefix-bindings instead of the old which-key C-h behaviour
  ;; (cleaner and more interactive).
  (prefix-help-command #'describe-prefix-bindings))

(use-package embark-consult
  :ensure t
  :after (embark consult)
  :hook
  (embark-collect-mode . consult-preview-at-point-mode))

(use-package corfu
  :ensure t
  :custom
  (corfu-cycle t)                                                                 ; Enable candidate cycling in the popup.
  (corfu-auto t)                                                                  ; Enable automatic popup after typing (recommended for modern workflows).
  (corfu-auto-delay 0.1)                                                          ; Small delay for responsiveness without excessive triggering.
  (corfu-auto-prefix 2)                                                           ; Require at least 2 characters before auto-triggering.
  (corfu-quit-no-match t)                                                         ; Quit popup if no candidates match input.
  (corfu-quit-at-boundary 'separator)                                             ; Quit at word boundaries when auto-completing (prevents unwanted popups).
  (corfu-preview-current t)                                                       ; Preview the selected candidate (inserts temporarily).
  :bind
  (:map corfu-map
        ("M-p" . corfu-popupinfo-scroll-down)                                     ; Scroll doc popup down
        ("M-n" . corfu-popupinfo-scroll-up)                                       ; Scroll doc popup up
        ("M-d" . corfu-popupinfo-toggle))                                         ; Toggle documentation popup
  :init
  (global-corfu-mode 1)
  ;; Enable documentation popup globally.
  (corfu-popupinfo-mode 1)
  ;; Make eldoc aware of Corfu insertions.
  (eldoc-add-command #'corfu-insert))

(use-package cape
  :ensure t
  :init
  ;; Add useful default completion-at-point functions globally.
  ;; File paths at point.
  (add-to-list 'completion-at-point-functions #'cape-file)
  ;; Words from current buffer (dabbrev).
  (add-to-list 'completion-at-point-functions #'cape-dabbrev)
  ;; Optional additions (uncomment as needed):
  (add-to-list 'completion-at-point-functions #'cape-keyword)                     ; What it completes: Programming-language-specific keywords, reserved words, and sometimes constants defined by the major mode.
  ;; (add-to-list 'completion-at-point-functions #'cape-symbol)                     ; Symbols from Emacs’s dynamic environment – primarily names bound with defvar, defconst, defface, etc., and also things like function names known to elisp-completion-at-point.
  ;; (add-to-list 'completion-at-point-functions #'cape-line)                       ; What it completes: Entire lines from the current buffer that begin with the text before point.
  :config
  ;; Silence pcomplete (shell completion) messages – cleaner output.
  (advice-add 'pcomplete-completions-at-point :around #'cape-wrap-silent)
  ;; Ensure pcomplete behaves purely as a capf (no buffer modifications).
  (advice-add 'pcomplete-completions-at-point :around #'cape-wrap-purify)
  ;; Specialised eshell configuration: disable aggressive auto-completion
  ;; to avoid interference with shell commands.
  (defun my-corfu-eshell-setup ()
    "Configure Corfu conservatively for eshell."
    (setq-local corfu-auto nil
                corfu-quit-at-boundary t
                corfu-quit-no-match t))
  (add-hook 'eshell-mode-hook #'my-corfu-eshell-setup))

(use-package which-key
  :ensure nil                                                                     ; Built-in to Emacs 30+
  :custom
  (which-key-popup-type 'side-window)                                             ; Display popup as a side window (right preferred, bottom fallback).
  (which-key-side-window-location '(right bottom))                                ; Preferred location: right side, fallback to bottom.
  (which-key-side-window-max-width 0.4)                                           ; Maximum width as fraction of frame (40% here).
  (which-key-idle-delay 1.0)                                                      ; Delay before popup appears (seconds).
  (which-key-max-description-length 27)                                           ; Maximum length of command descriptions before truncation.
  (which-key-separator " → ")                                                     ; Separator between keys and descriptions.
  (which-key-show-prefix 'left)                                                   ; Show prefix (typed keys so far) on the left.
  (which-key-show-remaining-keys t)                                               ; Show remaining key count in mode-line.
  :init
  (which-key-mode 1))

(provide 'completion-support)
;;; completion-support.el ends here
