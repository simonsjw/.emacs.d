;;; custom-mode-line-support.el --- modeline support for the crafted setup   -*- lexical-binding: t; -*-

;; Copyright (C) 2022
;; SPDX-License-Identifier: MIT

;; Author: System Crafters Community
;; Keywords: python

;;; Commentary:

;; This package handles the doom-emacs modeline

;;; Declarations and imports
(defvar my-window-tag)
(defvar matching-bracket)

(declare-function
 my-in-buffer-tools/get-matching-bracket-position "custom-system-tools")
(declare-function
 my-window-tools/get-tag-given-window "custom-system-window-management")

(declare-function
 doom-modeline--active "doom-modeline-core")
(declare-function
 doom-modeline-def-segment "doom-modeline-core")
(declare-function
 doom-modeline-def-modeline "doom-modeline-core")
(declare-function
 doom-modeline-set-modeline "doom-modeline-core")


;;; Packages

;; https://github.com/seagle0128/doom-modeline
(use-package doom-modeline
  :straight (:type git
                   :flavor melpa
                   :host github
                   :repo "seagle0128/doom-modeline")
  :ensure t
  :hook (after-init . doom-modeline-mode))

;;; code:

;; note - I have deleted the `bar' segment from each of the below. 
(defun my-segment/window-tag ()
  "Return the tag of the current window for the modeline."
  (let ((tag (my-window-tools/get-tag-given-window)))
    (if tag
        (propertize (format "[%s]" tag)
                    'face (if (doom-modeline--active)
                              'mode-line-highlight; Face for the active mode-line mode-line
                            'mode-line-inactive)) ; Face for the inactive mode-line
      "")))

(with-eval-after-load 'doom-modeline
  (doom-modeline-def-segment my-window-tag
    "Display the tag of the current window in the modeline."
    (my-segment/window-tag))

  ;;
  ;; Matching Bracket Segment
  ;;

  (doom-modeline-def-segment matching-bracket
    "Displays the matching bracket information if the cursor is on or next to a bracket.

If the cursor is not on or next to a bracket, displays an empty string."
    (let* ((match-info
            (my-in-buffer-tools/get-matching-bracket-position (point)))  ; Get matching bracket information
           (display-info
            (if match-info
                ;; If match-info is available, format the bracket details
                (let* ((line (nth 0 match-info))
                       (column (nth 1 match-info))
                       (char (nth 3 match-info)))
                  (format "'%s':L%d:C%d" char line column))
              ;; If no match-info, return an empty string
              "")))
      ;; Return the formatted string or an empty string
      display-info))


  
  (doom-modeline-def-modeline 'main
    '(eldoc my-window-tag workspace-name window-number modals matches
            follow buffer-info remote-host buffer-position matching-bracket
            word-count parrot selection-info)
    '(compilation objed-state misc-info persp-name battery grip irc mu4e gnus
                  github debug repl lsp minor-modes input-method indent-info
                  buffer-encoding major-mode process vcs check time))

  (doom-modeline-def-modeline 'minimal
    '(window-number modals matches buffer-info-simple)
    '(media-info major-mode time))

  (doom-modeline-def-modeline 'special
    '(eldoc window-number my-window-tag modals matches buffer-info
            remote-host buffer-position matching-bracket word-count parrot
            selection-info)
    '(compilation objed-state misc-info battery irc-buffers debug minor-modes
                  input-method indent-info buffer-encoding major-mode process
                  time))

  (doom-modeline-def-modeline 'project
    '(window-number my-window-tag modals buffer-default-directory
                    remote-host buffer-position matching-bracket)
    '(compilation misc-info battery irc mu4e gnus github debug minor-modes
                  input-method major-mode process time))

  (doom-modeline-def-modeline 'dashboard
    '(window-number my-window-tag modals buffer-default-directory-simple
                    remote-host)
    '(compilation misc-info battery irc mu4e gnus github debug minor-modes
                  input-method major-mode process time))

  (doom-modeline-def-modeline 'vcs
    '(window-number my-window-tag modals matches buffer-info remote-host
                    buffer-position matching-bracket parrot selection-info)
    '(compilation misc-info battery irc mu4e gnus github debug minor-modes
                  buffer-encoding major-mode process time))

  (doom-modeline-def-modeline 'package
    '(window-number my-window-tag modals package)
    '(compilation misc-info major-mode process time))

  (doom-modeline-def-modeline 'info
    '(window-number my-window-tag modals buffer-info info-nodes
                    buffer-position matching-bracket parrot selection-info)
    '(compilation misc-info buffer-encoding major-mode time))

  (doom-modeline-def-modeline 'media
    '(window-number my-window-tag modals buffer-size buffer-info)
    '(compilation misc-info media-info major-mode process vcs time))

  (doom-modeline-def-modeline 'message
    '(eldoc window-number my-window-tag modals matches buffer-info-simple
            buffer-position matching-bracket word-count parrot selection-info)
    '(compilation objed-state misc-info battery debug minor-modes input-method
                  indent-info buffer-encoding major-mode time))

  (doom-modeline-def-modeline 'pdf
    '(window-number my-window-tag modals matches buffer-info pdf-pages)
    '(compilation misc-info major-mode process vcs time))

  (doom-modeline-def-modeline 'org-src
    '(eldoc window-number my-window-tag modals matches buffer-info
            buffer-position matching-bracket word-count parrot selection-info)
    '(compilation objed-state misc-info debug lsp minor-modes input-method
                  indent-info buffer-encoding major-mode process check time))

  (doom-modeline-def-modeline 'helm
    '(helm-buffer-id helm-number helm-follow helm-prefix-argument)
    '(helm-help time))

  (doom-modeline-def-modeline 'timemachine
    '(eldoc window-number my-window-tag modals matches git-timemachine
            buffer-position matching-bracket word-count parrot selection-info)
    '(misc-info minor-modes indent-info buffer-encoding major-mode time))

  (doom-modeline-def-modeline 'calculator
    '(window-number my-window-tag modals matches calc buffer-position
                    matching-bracket)
    '(misc-info minor-modes major-mode process))


  ;; Set the custom modeline as the default
  (doom-modeline-set-modeline 'my-modeline 'main))



;; Delete window using modeline:
;; Add a warning to the 'right click delete window'
;; from the modeline. 
(global-set-key [mode-line mouse-3]
                'my-window-tools/delete-window-confirmation)



(provide 'custom-modeline-support)
;;; custom-modeline-support.el ends here
