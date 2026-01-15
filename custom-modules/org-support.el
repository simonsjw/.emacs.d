;;; org-support.el --- Modern Org-mode + Org-roam setup  -*- lexical-binding: t; -*-

;; Author: Simon Watson
;; Keywords: org, org-roam, outlines, notes, calendar
;; Package-Requires: ((emacs "29.1") (org "9.6") (org-modern "0.3") (org-appear "0.3"))
;; Version: 0.4
;; URL: (none – personal configuration)

;;; Commentary:

;; Ultra-modern Org-mode configuration with emphasis on clean typography,
;; beautiful indentation, Org-roam knowledge management, and a dedicated
;; agenda dashboard frame.
;; Note that the 'Olivetti' type look is achieved with the use of
;; visual-fill-column in writing-config.el.  Set visual-fill-column-width to
;; change the width of the buffer layout within the window.
;;
;; Main features:
;; • org-modern + org-modern-indent + org-appear for contemporary looks
;; • Pretty priorities, fancy checkboxes, modern tables
;; • Org-roam with sensible defaults and keybindings
;; • Dedicated Org Agenda frame + simple four-pane dashboard
;; • Desktop notifications via org-alert + libnotify
;;
;; Dependencies (assumed installed):
;; • org-modern, org-modern-indent (local), org-appear
;; • org-fancy-priorities, org-roam, org-alert
;; • my-window-tools (custom library for frame/window tagging)

;;; Code:


;;; ──────────────────────────────────────────────────────────────────────
;;; 1. Core Org variables & appearance
;;; ──────────────────────────────────────────────────────────────────────

(use-package org
  :ensure nil
  :hook ((org-mode . visual-line-mode)
         (org-mode . org-indent-mode)
         )
  :custom
  ;; ── Visibility & typography ──
  (org-hide-emphasis-markers   t)
  (org-startup-indented        t)
  (org-startup-with-latex-preview t)
  (org-pretty-entities         t)
  (org-pretty-entities-include-sub-superscripts t)
  (org-use-sub-superscripts    '{})

  (org-ellipsis                "…")
  (org-return-follows-link     t)
  (org-link-descriptive        t)

  ;; ── Tags & columns ──
  (org-auto-align-tags         nil)
  (org-tags-column             0)
  (org-agenda-tags-column      0)

  ;; ── Editing behaviour ──
  (org-catch-invisible-edits   'show-and-error)
  (org-special-ctrl-a/e        t)
  (org-insert-heading-respect-content t)

  ;; ── Agenda window behaviour ──
  (org-agenda-window-setup     'current-window)
  (org-agenda-restore-windows-after-quit t)

  ;; ── LaTeX preview (2025 preference: fast & beautiful) ──
  (org-preview-latex-default-process 'imagemagick)
  (org-latex-compiler          "lualatex")

  ;; ── TODO workflow ──
  (org-todo-keywords
   '((sequence "TODO(t)" "IN-PROGRESS(p!)" "WAITING(w@/!)"
               "|" "DONE(d!)" "CANCELLED(c@)"))))


;;; ──────────────────────────────────────────────────────────────────────
;;; 2. Visual enhancement packages
;;; ──────────────────────────────────────────────────────────────────────

(use-package org-modern
  :custom
  (org-modern-star             '("◉" "○" "✸" "✿" "✤" "◆" "▶" "•"))
  (org-modern-block-fringe     nil)
  (org-modern-table-vertical   1)
  (org-modern-table-horizontal 2)
  (org-modern-list             '((?* . "•") (?+ . "◦") (?- . "–")))
  (org-modern-checkbox         '((?X . "✔") (?- . "❍") (?\s . "☐")))
  (org-modern-priority         t)
  (org-modern-todo             t)
  (org-modern-tag              t)
  :hook ((org-mode           . org-modern-mode)
         (org-agenda-finalize . org-modern-agenda))
  :config
  (defun my-org-modern/update-table-header-face ()
    "Customise table header appearance post-org-modern.
Purpose: Override inverse-video for subtler headers.
Variables: Uses org-table face inheritance.
Output: Modified text properties for first row.
Flow: Hook checks buffer, finds tables, adjusts faces."
    (when (derived-mode-p 'org-mode)
      (font-lock-flush)  ; Ensure fresh rendering
      ;; Example: Set header background to subtle grey (adjust hex)
      (custom-set-faces
       '(org-table ((t :background "#2E2E2E" :inverse-video nil))))))
  
  :hook (org-modern-mode . my-org-modern/update-table-header-face))

(use-package org-modern-indent
  :load-path "~/.emacs.d/custom-packages/org-modern-indent"
  :hook (org-mode . org-modern-indent-mode)
  :custom (org-modern-indent/block t))

(use-package org-appear
  :hook (org-mode . org-appear-mode)
  :custom
  (org-appear-autolinks     t)
  (org-appear-autosubmarkers t)
  (org-appear-autoemphasis   t)
  (org-appear-autokeywords   t))

(use-package org-fancy-priorities
  :hook (org-mode . org-fancy-priorities-mode)
  :custom
  (org-fancy-priorities-list '("⚡" "🔥" "⏳"))
  (org-highest-priority      ?A)
  (org-lowest-priority       ?C)
  (org-default-priority      ?B))


;;; ──────────────────────────────────────────────────────────────────────
;;; 3. Org-roam (knowledge graph / Zettelkasten)
;;; ──────────────────────────────────────────────────────────────────────

(use-package org-roam
  :custom
  (org-roam-directory
   (expand-file-name "org/org-roam/nodes" (getenv "HOME")))
  (org-roam-completion-everywhere t)
  (org-roam-node-display-template
   (concat "${title:*} " (propertize "${tags:30}" 'face 'org-tag)))
  :bind (("C-c n f" . org-roam-node-find)
         ("C-c n i" . org-roam-node-insert)
         ("C-c n c" . org-roam-capture)
         ("C-c n l" . org-roam-buffer-toggle)
         ("C-c n d" . org-roam-dailies-map))
  :config
  (org-roam-db-autosync-mode)
  (require 'org-roam-dailies))


;;; ──────────────────────────────────────────────────────────────────────
;;; 4. Notifications
;;; ──────────────────────────────────────────────────────────────────────

(use-package org-alert
  :after org
  :custom
  (alert-default-style          'libnotify)
  (org-alert-interval           600)
  (org-alert-notification-title "Org")
  (org-alert-notify-cutoff      180)
  :config
  (org-alert-enable))


;;; ──────────────────────────────────────────────────────────────────────
;;; 5. Capture templates
;;; ──────────────────────────────────────────────────────────────────────

(setq org-capture-templates
      '(("t" "Todo"         entry
         (file+headline "~/Documents/org/inbox.org" "Tasks")
         "* TODO %?\n  %i\n  %a")
        ("j" "Journal"      entry
         (file+datetree "~/Documents/org/journal/journal.org")
         "* %<\\H:%M> %?\n  %i")))


;;; ──────────────────────────────────────────────────────────────────────
;;; 6. Dedicated Agenda frame & Dashboard
;;; ──────────────────────────────────────────────────────────────────────

(defun my-org/agenda-in-new-frame (&optional arg keys)
  "Open `org-agenda' in a new dedicated frame.
ARG and KEYS are passed directly to `org-agenda'."
  (interactive "P")
  (let* ((frame-params `((name                . "Org-Agenda")
                         (width               . 120)
                         (height              . 40)
                         (minibuffer          . t)
                         (menu-bar-lines      . 0)
                         (tool-bar-lines      . 0)
                         (vertical-scroll-bars . nil)
                         (custom-window-management . t)
                         (project-root        . "org-agenda")))
         (agenda-frame (make-frame frame-params))
         (old-frame    (selected-frame))
         (old-buffer   (current-buffer)))

    (unwind-protect
        (with-selected-frame agenda-frame
          ;; Integrate with your custom window management library
          (my-window-tools/set-frame-project-root agenda-frame "org-agenda")
          (my-window-tools/tag-windows-by-list agenda-frame
                                               my-window-tools/tag-list t)

          ;; Ensure modern agenda appearance
          (add-hook 'org-agenda-finalize-hook #'org-modern-agenda nil t)

          (org-agenda arg keys)

          (when (fboundp 'log/debug)
            (log/debug :fn 'my-org/agenda-in-new-frame
                       :msg "Agenda frame created"
                       :obj (list :frame agenda-frame :keys keys))))
      ;; Clean up on error / exit
      (when (frame-live-p old-frame)
        (select-frame-set-input-focus old-frame))
      (when (buffer-live-p old-buffer)
        (set-buffer old-buffer)))))

(defun my-agenda/dashboard ()
  "Create 2025-style four-pane Org dashboard in dedicated frame."
  (interactive)
  (my-org/agenda-in-new-frame nil "a")           ; main agenda

  (let ((frame (my-window-tools/find-frame-by-project-root "org-agenda")))
    (when (frame-live-p frame)
      (with-selected-frame frame
        (delete-other-windows)
        (split-window-right)
        (other-window 1)
        (calendar)
        (split-window-below)
        (other-window 1)
        (org-agenda nil "t")))))                   ; global TODO list


;;; ──────────────────────────────────────────────────────────────────────
;;; 7. Global keybindings
;;; ──────────────────────────────────────────────────────────────────────

(global-set-key (kbd "C-c a") #'my-org/agenda-in-new-frame)
(global-set-key (kbd "C-c l") #'my-agenda/dashboard)

(provide 'org-support)
;;; org-support.el ends here
