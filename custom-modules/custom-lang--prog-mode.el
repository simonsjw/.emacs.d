;;; custom-lang--prog-mode.el --- parent mode for programming -*- lexical-binding: t; -*-

;;; Commentary:

;; Functionality common across all custom-lang settings.
;;

;;; Code:

(require 'menu-keys-support)

(defvar display-line-numbers-type)                                                ; variable from display-line-numbers - show relative or absolute line numbers.
(declare-function org-link-minor-mode "org-link-minor-mode")
;; Provide an autosave hook.
(defun my-prog-mode/auto-save-hook ()
  "Enable auto-saving in `prog-mode' buffers."
  (when buffer-file-name
    (setq-local compilation-ask-about-save nil)))

;; Configuration for all programming modes.
(defun my-prog-mode/programming-mode-config-hook ()
  "Set useful layout tweeks for programming modes."
  (interactive)

  ;; Set programming modes to pick up the custom prog-mode face.
  ;; (after custom-theme-support has defined the face.)
  (when (facep 'my-font-faces/prog-mode-face)
    (face-remap-add-relative 'default 'my-font-faces/prog-mode-face))

  (setq-local display-line-numbers-type 'absolute)
  (display-line-numbers-mode)                                                     ; activate line numbers.
  (set-face-attribute 'line-number nil :height 0.8)

  ;; show org-links: [[http://reddit.com/][reddit]]
  (org-link-minor-mode 1)

  ;; Auto-save files.
  (my-prog-mode/auto-save-hook)

  ;; (set-face-attribute 'line-number-current-line nil :height `unspecified)
  ;; careful with `line-number-current-line. - setting line size changes for
  ;; the line number current line causes the text to indent slightly. I find
  ;; it quite annoying.

  ;; make the left and right fringe-mode 5 and 10 pixels respectively.
  ;; (left is narrower because it  has a following line number adding thickness)
  (fringe-mode '(5 . 10))

  ;; show the fill column with an indicator line
  (setq-local display-fill-column-indicator-column t)
  (display-fill-column-indicator-mode)
  
  ;; ensure changess are visible in the buffer.
  ;; (highlight-changes-mode)

  ;; (setq yas-use-menu 'abbreviate)                                              ; show only the snippets for the mode of the buffer.
  ;; activate yas mode.
  ;; (yas-minor-mode)                                                             ; or M-x yas-reload-all if you've started YASnippet already.
  ;; (yas-mode 1)

  ;; (setq fci-rule-width 1)
  ;; (setq fci-rule-color "darkgrey")

  (setq-local truncate-lines t)   ; deactivate line-wrapping.

  ;; Keymaps and Menus
  ;; Assign buffer local prefixes to comment keymap.
  (local-set-key (kbd my-custom-prefix-keys/comment) 'my-key-maps/prog-mode-comment-map)

  ;; Create comment menu including thoose new buffer local keymaps.
  (easy-menu-define my-prog-mode-menu                                             ; symbol-name
    (current-local-map)                                                           ; maps
    "Menu for comment-related functions."                                         ; docs
    my-custom-menus/comment-menu)                                                 ; menu

  ;; set up flyspell. (flyspell-prog-mode ignores function and variable names.)
  (flyspell-prog-mode)

  ;; (setq-local mode-line-format
  ;;             '("%e"
  ;;               my-modeline/window-tag
  ;;               " "
  ;;               my-modeline/buffer-icon
  ;;               mode-line-front-space
  ;;               (:propertize
  ;;                (" "
  ;;                 mode-line-mule-info
  ;;                 mode-line-client
  ;;                 mode-line-modified
  ;;                 mode-line-remote
  ;;                 mode-line-auto-compile)
  ;;                display
  ;;                (min-width
  ;;                 (1.0)))
  ;;               " "
  ;;               mode-line-buffer-identification
  ;;               "  "
  ;;               ;;my-modeline/projectile
  ;;               projectile--mode-line
  ;;               " "
  ;;               my-modeline/matching-bracket
  ;;               " "
  ;;               mode-name
  ;;               " "
  ;;               (vc-mode vc-mode)
  ;;               " "
  ;;               ;;  projectile--mode-line
  ;;               " "
  ;;               ;; (:eval
  ;;               ;;  (:propertize ("" mode-name)
  ;;               ;;               'help-echo "Major mode menu"
  ;;               ;;               'mouse-face 'mode-line-highlight
  ;;               ;;               'keymap (let ((map (make-sparse-keymap)))
  ;;               ;;                         (define-key map [mode-line down-mouse-1]
  ;;               ;;                                     (lambda () (interactive)
  ;;               ;;                                       (popup-menu (current-local-map))))
  ;;               ;;                         map)))



  ;;               ;; mode-line-modes
  ;;               ;;    mode-line-misc-info
  ;;               (pyvenv-mode pyvenv-mode-line-indicator)
  ;;               ;;   (sly-mode
  ;;               ;;   (" [" sly--mode-line-format "] "))
  ;;               ;; (dape-active-mode
  ;;               ;;  ("[" dape--mode-line-format "] "))
  ;;               ;; (eglot--managed-mode
  ;;               ;;  (" [" eglot--mode-line-format "] "))
  ;;               my-modeline/eglot
  ;;               " "
  ;;               my-modeline/flymake
  ;;               mode-line-end-spaces
  ;;               ))
  )
  

;;; Hooks

;; add the programming mode config to prog-mode
(add-hook 'prog-mode-hook #'my-prog-mode/programming-mode-config-hook)

(provide 'custom-lang--prog-mode)
;;; custom-lang--prog-mode.el ends here
