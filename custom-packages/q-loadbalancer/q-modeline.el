;;; q-modeline.el --- Manage the modeline for KDB/Q processes in Emacs. -*- lexical-binding: t; -*-

;; Author: Simon Watson
;; Version: 1.2
;; Keywords: KDB, Q, process management
;; URL: https://github.com/simonsjw/q-loadbalancer
;; Package-Requires: (Emacs "24.3")

;;; Commentary:

;; This package provides modeline functionality for `q-loadbalancer-mode'.
;; It allows users to start and manage several Q processes, grouped by type,
;; with each group potentially containing multiple processes.

(defvar q-loadbalancer-buffer-list)

(declare-function doom-modeline-p "doom-modeline")
(declare-function doom-modeline-segment-p "doom-modeline")
(declare-function doom-modeline-def-segment "doom-modeline")
(declare-function doom-modeline-def-modeline "doom-modeline")
(declare-function doom-modeline-set-modeline "doom-modeline")
(declare-function q-loadbalancer-buffer-list-segment "q-modeline")
(declare-function q-loadbalancer-buffer-dropdown "q-modeline")

;;; Code:

;; Define the segment: Q Process buffer list.
;; Ensure doom-modeline is available before loading this setup.
(with-eval-after-load 'doom-modeline
  ;; Function to show the dropdown menu and switch to the selected buffer.
  (defun q-loadbalancer-buffer-dropdown ()
    "Show a dropdown list of buffers starting with '*Q PROC:'
Also switch to the selected buffer."
    (interactive)  ;; Make this function a command
    (let ((buffers
           (seq-filter (lambda (buf)
                         (string-prefix-p "*Q PROC:" (buffer-name buf)))
                       (buffer-list))))
      (if buffers
          (let*
              ((buffer-names
                (mapcar (lambda (buf) (cons (buffer-name buf) buf)) buffers))
               (selected-buffer
                (x-popup-menu
                 t
                 (list "Q Processes:" (cons "Q PROC Buffers" buffer-names)))))
            (when selected-buffer
              (switch-to-buffer selected-buffer)))
        (message "No *Q PROC:* buffers available"))))

  ;; Define the Q Process buffer dropdown segment for doom-modeline.
  (doom-modeline-def-segment q-loadbalancer-buffer-dropdown
    "Show a clickable element that opens a drop-down list of *Q PROC:* buffers."
    (let ((display-text
           (propertize
            (buffer-name (current-buffer))
            'mouse-face 'mode-line-highlight
            'help-echo "Click to select a *Q PROC:* buffer"
            'display '(raise 0.0)
            'min-width 50  ;; Set a wider minimum width for testing
            'local-map
            (let ((map (make-sparse-keymap)))
              (define-key map [mode-line mouse-1]
                          #'q-loadbalancer-buffer-dropdown)
              map))))
      ;; Debugging: Display constructed text in the *Messages* buffer to verify
      (message "q-loadbalancer-buffer-dropdown display text: %s" display-text)
      display-text))
  
  ;; Define the doom modeline segment for q-loadbalancer.
  (doom-modeline-def-modeline 'q-loadbalancer
    '(eldoc my-window-tag workspace-name window-number
            modals matches q-loadbalancer-buffer-dropdown
            follow remote-host buffer-position matching-bracket
            word-count parrot selection-info)
    '(compilation objed-state misc-info persp-name battery grip irc mu4e gnus
                  github debug repl lsp minor-modes input-method indent-info
                  buffer-encoding major-mode process vcs check time))

  ;; Define the function to set the q-loadbalancer modeline if not already defined.
  (unless (fboundp 'set-q-loadbalancer-mode-modeline)
    (defun set-q-loadbalancer-mode-modeline ()
      "Set the doom modeline to `q-loadbalancer' only in relevant buffers."
      (when (string-prefix-p "*Q PROC:" (buffer-name))
        (doom-modeline-set-modeline 'q-loadbalancer 'default))))

  ;; Add the hook to q-loadbalancer-mode only once.
  (add-hook 'q-loadbalancer-mode-hook 'set-q-loadbalancer-mode-modeline))


(provide 'q-modeline)

;;; q-modeline.el ends here

                                        ; LocalWords:  cefhijnptuv
                                        ; LocalWords:  loadbalancer
                                        ; LocalWords:  simonsjw
                                        ; LocalWords:  LoadBalancer
                                        ; LocalWords:  keymaps
                                        ; LocalWords:  cominit
