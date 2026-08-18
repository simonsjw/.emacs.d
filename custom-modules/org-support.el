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

(require 'path-support)
(require 'logging-config)
(log/debug :fn 'org-support
           :msg "Starting load of the org-support module."
           :obj t)

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


;;;  ──────────────────────────────────────────────────────────────────────
;;   2. Visual enhancement packages
;;   ──────────────────────────────────────────────────────────────────────

(use-package org-modern
  :custom
  (org-modern-star             '("◉" "○" "✸" "✿" "✤" "◆" "▶" "•"))
  (org-modern-block-fringe     nil)
  (org-modern-table-vertical   1)      ; keep your current values
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
      (font-lock-flush)
      (custom-set-faces
       '(org-table ((t (:height 0.88
                                :inherit fixed-pitch
                                :background "#2E2E2E"
                                :inverse-video nil)))))))
  :hook (org-modern-mode . my-org-modern/update-table-header-face))

(use-package valign
  :ensure t
  :hook (org-mode . valign-mode)
  :custom
  (valign-fancy-bar t))

(use-package org-modern-indent
  :load-path my-paths/org-modern-indent-folder
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


;; useful text calendar views.
(use-package calfw-org
  :ensure t)

;; good gant chart.
;;(use-package elgantt
;;  :ensure t)


;;; ──────────────────────────────────────────────────────────────────────
;;; 3. Org-roam (knowledge graph / Zettelkasten)
;;; ──────────────────────────────────────────────────────────────────────

(use-package org-roam
  :custom
  (org-roam-directory
   (expand-file-name org-roam-directory (getenv "HOME")))
  (org-roam-completion-everywhere t)
  (org-roam-node-display-template
   (concat "${title:*} " (propertize "${tags:30}" 'face 'org-tag)))
  :bind (("C-c n f" . org-roam-node-find)
         ("C-c n i" . org-roam-node-insert)
         ("C-c n c" . org-roam-capture)
         ("C-c n l" . org-roam-buffer-toggle)
         ("C-c n d" . org-roam-dailies-map))
  :config
  (org-roam-db-autosync-mode 1)
  
  (org-id-update-id-locations)                                                      ; Rebuild ID locations automatically on startup
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
         (file+headline org-default-inbox-file "Tasks")
         "* TODO %?\n  %i\n  %a")
        ("j" "Journal"      entry
         (file+datetree org-default-journal-file)
         "* %<\\H:%M> %?\n  %i")))


;;; ──────────────────────────────────────────────────────────────────────
;;; 6. Dedicated Agenda frame & Dashboard
;;; ──────────────────────────────────────────────────────────────────────

;; good gant chart.
(use-package org-super-agenda
  :ensure t
  :after org
  :custom
  (org-super-agenda-groups
   '(;; Each group has an implicit boolean OR operator between its selectors.
     (:name "EPIC Surveillance LLM Project"
            :category "LLM Project")          ; matches the :CATEGORY: you already set
     
     (:name "Today"  ; Optionally specify section name
            :time-grid t  ; Items that appear on the time grid
            :todo "TODAY")  ; Items that have this TODO keyword
     (:name "Important"
            ;; Single arguments given alone
            :tag "bills"
            :priority "A")
     ;; Set order of multiple groups at once
     (:order-multi (2 (:name "Shopping in town"
                             ;; Boolean AND group matches items that match all subgroups
                             :and (:tag "shopping" :tag "@town"))
                      (:name "Food-related"
                             ;; Multiple args given in list with implicit OR
                             :tag ("food" "dinner"))
                      (:name "Personal"
                             :habit t
                             :tag "personal")
                      (:name "Space-related (non-moon-or-planet-related)"
                             ;; Regexps match case-insensitively on the entire entry
                             :and (:regexp ("space" "NASA")
                                           ;; Boolean NOT also has implicit OR between selectors
                                           :not (:regexp "moon" :tag "planet")))))
     ;; Groups supply their own section names when none are given
     (:todo "WAITING" :order 8)  ; Set order of this section
     (:todo ("SOMEDAY" "TO-READ" "CHECK" "TO-WATCH" "WATCHING")
            ;; Show this group at the end of the agenda (since it has the
            ;; highest number). If you specified this group last, items
            ;; with these todo keywords that e.g. have priority A would be
            ;; displayed in that group instead, because items are grouped
            ;; out in the order the groups are listed.
            :order 9)
     (:priority<= "B"
                  ;; Show this section after "Today" and "Important", because
                  ;; their order is unspecified, defaulting to 0. Sections
                  ;; are displayed lowest-number-first.
                  :order 1)
     ;; After the last group, the agenda will display items that didn't
     ;; match any of these groups, with the default order position of 99
     ))
  :hook
  (org-agenda-mode . org-super-agenda-mode)
  :config
  (org-super-agenda-mode 1))

(use-package calfw-org
  :ensure t)

(use-package calfw-cal
  :ensure t)


(defun my-org/update-parent-dates ()
  "Update the current heading's SCHEDULED  and DEADLIN.
This is based on the earliest scheduled and latest deadline in subtree.
These are formatted to be on separate lines, SCHEDULED first."
  (interactive)
  (save-excursion
    (org-back-to-heading)
    (let ((min-s nil)
          (max-d nil)
          (parent-level (org-current-level)))
      (org-map-entries
       (lambda ()
         (unless (= (org-current-level) parent-level)
           (let ((s (org-get-scheduled-time (point)))
                 (d (org-get-deadline-time (point))))
             (when s (setq min-s (if (or (not min-s) (time-less-p s min-s)) s min-s)))
             (when d (setq max-d (if (or (not max-d) (time-less-p max-d d)) d max-d))))))
       nil 'tree)
      ;; Remove any existing SCHEDULED/DEADLINE lines
      (let ((end (org-entry-end-position)))
        (goto-char (org-entry-beginning-position))
        (while (re-search-forward "^[ \t]*\\(SCHEDULED:\\|DEADLINE:\\)" end t)
          (beginning-of-line)
          (kill-line 1)
          (setq end (org-entry-end-position))))
      ;; Insert clean lines in the desired order
      (forward-line 1)
      (when min-s
        (insert "  SCHEDULED: " (format-time-string "<%Y-%m-%d %a>" min-s) "\n"))
      (when max-d
        (insert "  DEADLINE:  " (format-time-string "<%Y-%m-%d %a>" max-d) "\n"))
      (message "Parent dates updated (SCHEDULED then DEADLINE on separate lines)."))))

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
  (my-org/agenda-in-new-frame nil "a")                                            ; main agenda

  (let ((frame (my-window-tools/find-frame-by-project-root "org-agenda")))
    (when (frame-live-p frame)
      (with-selected-frame frame
        (delete-other-windows)
        (split-window-right)
        (other-window 1)
        (calendar)
        (split-window-below)
        (other-window 1)
        (org-agenda nil "t")))))                                                  ; global TODO list



;;; ──────────────────────────────────────────────────────────────────────
;;; 7. Hooks
;;; ──────────────────────────────────────────────────────────────────────

(add-hook 'org-mode-hook
          (lambda ()
            (setq org-table-header-line-p t)))                                    ; keeps header visible when scrolling


(log/debug :fn 'org-support
           :msg "Finishing load of the org-support module."
           :obj t)

(provide 'org-support)
;;; org-support.el ends here
