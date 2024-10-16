;;; custom-hydra-support.el --- Hydra configuration  -*- lexical-binding: t; -*-

;; Copyright (C) 2022
;; SPDX-License-Identifier: MIT

;; Author: System Crafters Community
;; Keywords: ui

;;; Commentary:

;; Hydras for minor modes. 

;;; Code:
(use-package hydra
  :straight (:type git
                   :flavor melpa
                   :files (:defaults (:exclude "lv.el") "hydra-pkg.el")
                   :host github
                   :repo "abo-abo/hydra"))

(use-package pretty-hydra
  :straight (:type git
                   :flavor melpa
                   :files ("pretty-hydra.el" "pretty-hydra-pkg.el")
                   :host github
                   :repo "jerrypnz/major-mode-hydra.el"))

(use-package symbol-navigation-hydra
  :straight (:type git
                   :flavor melpa
                   :host github
                   :repo "bgwines/symbol-navigation-hydra"))

(use-package use-package-hydra
  :straight (:type git
                   :flavor melpa
                   :host gitlab
                   :repo "to1ne/use-package-hydra"))

(use-package major-mode-hydra
  :straight (:type git
                   :flavor melpa
                   :files ("major-mode-hydra.el" "major-mode-hydra-pkg.el")
                   :host github
                   :repo "jerrypnz/major-mode-hydra.el"))




;;; Hydras: flyspell
;;  ------------------------------
(defhydra hydra-flyspell (:color amaranth
                                 :body-pre
                                 (progn
                                   (when mark-active
                                     (deactivate-mark))
                                   (when (or (not (mark t))
                                             (/= (mark t) (point)))
                                     (push-mark (point) t)))
                                 :hint nil)
  "
 ^Flyspell^         ^Errors^            ^Word^
---------------------------------------------------------
 _b_ check buffer   _c_ correct         _s_ save (buffer)
 _d_ change dict    _n_ goto next       _l_ lowercase (buffer)
 _u_ undo           _p_ goto previous   _a_ accept (session)
 _q_ quit
"
  ("b" flyspell-buffer)
  ("d" ispell-change-dictionary)
  ("u" undo-tree-undo)
  ("q" nil :color blue)
  ("C-/" undo-tree-undo)

  ("c" my/flyspell-correct-at-point-maybe-next)
  ("n" my/flyspell-goto-next-error)
  ("p" my/flyspell-goto-previous-error)
  ("." my/flyspell-correct-at-point-maybe-next)
  ("SPC" my/flyspell-goto-next-error)
  ("DEL" my/flyspell-goto-previous-error)

  ("s" my/flyspell-accept-word-buffer)
  ("l" my/flyspell-accept-lowercased-buffer)
  ("a" my/flyspell-accept-word)

  ("M->" end-of-buffer)
  ("M-<" beginning-of-buffer)
  ("C-v" scroll-up-command)
  ("M-v" scroll-down-command))

(defun my/flyspell-error-p (&optional position)
  "Return non-nil if at a flyspell misspelling, and nil otherwise."
  ;; The check technique comes from 'flyspell-goto-next-error'.
  (let* ((pos (or position (point)))
         (ovs (overlays-at pos))
         r)
    (while (and (not r) (consp ovs))
      (if (flyspell-overlay-p (car ovs))
          (setq r t)
        (setq ovs (cdr ovs))))
    r))

(defvar my/hydra-flyspell-direction 'forward)
(defun my/flyspell-correct-at-point-maybe-next ()
  (interactive)
  (cond ((my/flyspell-error-p)
         (save-excursion
           (flyspell-correct-at-point)))
        ((equal my/hydra-flyspell-direction 'forward)
         (my/flyspell-goto-next-error)
         ;; recheck, for 'my/flyspell-goto-next-error' can legitimately stop
         ;; at the end of buffer
         (when (my/flyspell-error-p)
           (save-excursion
             (flyspell-correct-at-point))))
        ((equal my/hydra-flyspell-direction 'backward)
         (my/flyspell-goto-previous-error)
         ;; recheck, for 'my/flyspell-goto-previous-error' can legitimately
         ;; stop at the beginning of buffer
         (when (my/flyspell-error-p)
           (save-excursion
             (flyspell-correct-at-point))))))

;; Just an adapted version of 'flyspell-goto-next-error'.
(defun my/flyspell-goto-previous-error ()
  "Go to the previous previously detected error.
In general FLYSPELL-GOTO-PREVIOUS-ERROR must be used after
FLYSPELL-BUFFER."
  (interactive)
  (setq my/hydra-flyspell-direction 'backward)
  (let ((pos (point))
        (min (point-min)))
    (if (and (eq (current-buffer) flyspell-old-buffer-error)
             (eq pos flyspell-old-pos-error))
        (progn
          (if (= flyspell-old-pos-error min)
              ;; goto end of buffer
              (progn
                (message "Restarting from end of buffer")
                (goto-char (point-max)))
            (backward-word 1))
          (setq pos (point))))
    ;; seek the previous error
    (while (and (> pos min)
                (not (my/flyspell-error-p pos)))
      (setq pos (1- pos)))
    (goto-char pos)
    (when (eq (char-syntax (preceding-char)) ?w)
      (backward-word 1))
    ;; save the current location for next invocation
    (setq flyspell-old-pos-error (point))
    (setq flyspell-old-buffer-error (current-buffer))
    (if (= pos min)
        (message "No more miss-spelled word!")))
  ;; After moving, check again if we are at a misspelling (accepting a word
  ;; might have changed this, since the last check).  If not, go to the next
  ;; error again, unless we are at point-min (otherwise we might enter into
  ;; infinite loop, if there are no remaining errors).
  (flyspell-word)
  (unless (or (= (point) (point-min))
              (my/flyspell-error-p))
    (my/flyspell-goto-previous-error))
  (when (my/flyspell-error-p)
    (swiper--ensure-visible)))

(defun my/flyspell-goto-next-error ()
  "Go to the next previously detected error.
In general FLYSPELL-GOTO-NEXT-ERROR must be used after
FLYSPELL-BUFFER."
  ;; Just a recursive wrapper on the original flyspell function, which takes
  ;; into account possible changes of accepted words since the last check.
  (interactive)
  (setq my/hydra-flyspell-direction 'forward)
  (flyspell-goto-next-error)
  ;; After moving, check again if we are at a misspelling.  If not, go to
  ;; the next error again.
  (flyspell-word)
  (unless (or (= (point) (point-max))
              (my/flyspell-error-p))
    (my/flyspell-goto-next-error))
  (when (my/flyspell-error-p)
    (swiper--ensure-visible)))

(defun my/flyspell-accept-word (&optional local-dict lowercase)
  "Accept word at point for this session.
If LOCAL-DICT is non-nil, also add it to the buffer-local
dictionary. And if LOWERCASE is non-nil, do so with the word
lower-cased."
  (interactive)
  (let ((word (flyspell-get-word)))
    (if (not (and (consp word)
                  ;; Check if we are actually at a flyspell error.
                  (my/flyspell-error-p (car (cdr word)))))
        (message "Point is not at a misspelling.")
      (let ((start (car (cdr word)))
            (word (car word)))
        (when (and local-dict lowercase)
          (setq word (downcase word)))
        ;; This is just taken (slightly adjusted) from
        ;; 'flyspell-do-correct', which is essentially what
        ;; 'ispell-command-loop' also does.
        (ispell-send-string (concat "@" word "\n"))
        (add-to-list 'ispell-buffer-session-localwords word)
        (or ispell-buffer-local-name ; session localwords might conflict
            (setq ispell-buffer-local-name (buffer-name)))
        (flyspell-unhighlight-at start)
        (if (null ispell-pdict-modified-p)
            (setq ispell-pdict-modified-p
                  (list ispell-pdict-modified-p)))
        (if local-dict
            (ispell-add-per-file-word-list word))))))

(defun my/flyspell-accept-word-buffer ()
  "See `my/flyspell-accept-word'."
  (interactive)
  (my/flyspell-accept-word 'local-dict))
(defun my/flyspell-accept-lowercased-buffer ()
  "See `my/flyspell-accept-word'."
  (interactive)
  (my/flyspell-accept-word 'local-dict 'lowercase))


(global-set-key (kbd "C-c s") 'hydra-flyspell/body)

;; END Hydras: flyspell ------------------------------

(require 'custom-logging-config)


(provide 'custom-hydra-support)
;;; custom-hydra-support.el ends here
