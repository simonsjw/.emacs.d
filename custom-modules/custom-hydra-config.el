;;; custom-hydra-config.el --- Hydra configuration  -*- lexical-binding: t; -*-

;; Copyright (C) 2022
;; SPDX-License-Identifier: MIT

;; Author: System Crafters Community
;; Keywords: UI, hydra, menu

;;; Commentary:

;; Hydras for minor modes. 

;;; Code:
;;(require 'major-mode-hydra)

;;(require 'undo-tree)
;;(require 'hydra)
;;(require 'flyspell)
;;(require 'helpful)
;;(require 'custom-logging-config)
;; (require 'custom-system-tools)

;; ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
;;; Hydras: flyspell
;;  ------------------------------
(defhydra hydra-flyspell (:color pink
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
  ("C-/" undo-tree-undo :color red)

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
  ("M-v" scroll-down-command)

  ("o" hydra-of-hydras/body "top level hydra" :color blue)) ; return to hydra-of-hydras


(defun my/flyspell-error-p (&optional position)
  "Return non-nil if POSITION is a flyspell misspelling, and nil otherwise."
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
        (message "No more miss-spelled words!")))
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


;; (global-set-key (kbd "C-c s") 'hydra-flyspell/body)

;; END Hydras: flyspell ------------------------------

;; ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
;;; Hydras: Helpful
;;  ------------------------------


(defvar hydra-helpful--title
  (concat
   (my-image-tools/create-image-icon
    "/home/simon/.emacs.d/etc/images/helping-hand.jpg" 24 24)
   "  Helpful"))

(pretty-hydra-define hydra-helpful
  (:color teal
          :quit-key "q"
          :title hydra-helpful--title)
  ("Helpful"
   (("f" helpful-callable "callable")
    ("v" helpful-variable "variable")
    ("k" helpful-key "key")
    ("c" helpful-command "command")
    ("d" helpful-at-point "thing at point")
    ("o" hydra-of-hydras/body "top level hydra" :color blue))))
;; END Hydras: Helpful ------------------------------

;;; Hydras: treesit-fold


;; ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
;;; Hydras: Dape


;; END Hydras: Dape ------------------------------


;; ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
;;; Hydras: Undo-tree
;;  ------------------------------

(defvar hydra-undo-tree--title
  (concat
   (nerd-icons-faicon "nf-fa-undo" :height 1.2 :v-adjust 0.0)
   " Undo Tree"))

(defun my-toggle/undo-tree-visualizer-timestamps ()
  "Toggle undo-tree-visualizer-timestamps."
  (interactive)
  (setq undo-tree-visualizer-timestamps (not undo-tree-visualizer-timestamps))
  (message "undo-tree-visualizer-timestamps %s"
           (if undo-tree-visualizer-timestamps "enabled" "disabled")))

(defun my-toggle/undo-tree-visualizer-diff ()
  "Toggle undo-tree-visualizer-diff."
  (interactive)
  (setq undo-tree-visualizer-diff (not undo-tree-visualizer-diff))
  (message "undo-tree-visualizer-diff %s"
           (if undo-tree-visualizer-diff "enabled" "disabled")))


(defun my/undo-tree-visualizer-open-p ()
  "Check if the undo-tree visualizer is currently open."
  (get-buffer "*undo-tree*"))


(defvar my-hydras/undo-tree-heads
  '(("Actions"
     (("s" undo-tree-save-history "save history")
      ("l" undo-tree-load-history "load history")
      ("o" hydra-of-hydras/body "top level hydra" :color blue))
     "Navigation"
     (("h" undo-tree-undo "undo")
      ("j" undo-tree-redo "redo"))
     "Visualisation"
     (("v" undo-tree-visualize "visualize tree"
       :toggle (my/undo-tree-visualizer-open-p))
      ("d" my-toggle/undo-tree-visualizer-timestamps "show timestamps"
       :toggle t)
      ("p" my-toggle/undo-tree-visualizer-diff "view diff"
       :toggle t)))))


;; END Hydras: Undo-tree ------------------------------

;; ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
;;; Hydras: treesit-fold
;;  ------------------------------

(defvar hydra-treesit-fold--title
  (concat
   (nerd-icons-mdicon "nf-md-family_tree" :height 1.2 :v-adjust 0.0)
   " Treesit Fold"))

(pretty-hydra-define hydra-tree-fold
  (:color pink
          :quit-key "q"
          :title hydra-treesit-fold--title)
  ("All"
   (("ao" treesit-fold-open-all "open all")
    ("ac" treesit-fold-close-all "close all"))
   "Point"
   (("t" treesit-fold-toggle "toggle")
    ("o" treesit-fold-open "open")
    ("c" treesit-fold-close "close"))
   "Settings"
   (("i" treesit-fold-indicators-mode "indicators" :toggle t)
    ("c" treesit-fold-line-comment-mode "comments" :toggle t))
   )
  )

;; END Hydras: treesit-fold  ------------------------------

;; ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
;;; Hydras: newcomment.el
;;  ------------------------------

(defvar hydra-comment-format--title
  "#/; Comment format")

(pretty-hydra-define hydra-comment-format
  (:color pink
          :quit-key "q"
          :title hydra-comment-format--title)
  ("Format Comment"
   (("a" comment-indent "align comment")
    ("f" fill-comment-paragraph "fill comment paragraph")
    ("bf" my-in-buffer-tools/comment-box-filled "add filled box around comment")
    ("b" comment-box "add box around comment")
    ("sc" ispell-comment-or-string-at-point "check current comment spellings")
    ("sa" checkdoc-ispell-comments "check comment spellings in buffer")
    ("cc" set-comment-set-column "set comment column to cursor"))
   "Make Comment"
   ((";" comment-dwim "toggle/tab comment as needed")
    ("cl" comment-line "comment line")
    ("cr" comment-region "comment region")
    ("ur" uncomment-region "uncomment region")
    ("uk" comment-kill "kill comment")
    ("i" comment-indent-new-line "break line at point and indentation"))
   )
  )

;; END Hydras: treesit-fold  ------------------------------


;; ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
;; Now bring all the globally useful hydras together. 
(pretty-hydra-define hydra-of-hydras
  (:color teal
          :quit-key "q"
          :title "MENUS")
  ("Navigate"
   (("f" hydra-tree-fold/body "tree-fold" :color blue)
    ("u" hydra-undo-tree/body "undo-tree" :color blue))
   "Tools"
   (("c" hydra-comment-format/body "comments" :color blue)
    ("s" hydra-flyspell/body "flyspell" :color blue))
   "Docs"
   (("h" hydra-helpful/body "helpful" :color blue))
   )
  )

(global-set-key (kbd "C-<tab>") 'hydra-of-hydras/body)

(provide 'custom-hydra-config)
;;; custom-hydra-config.el ends here
