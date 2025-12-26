;;; org-support.el --- ultra-modern Org + Roam in 2025  -*- lexical-binding: t -*-

(use-package org
  :ensure nil
  :hook ((org-mode . visual-line-mode)
         (org-mode . org-indent-mode))                                            ; clean indentation built-in
  :custom
  ;; Core look & feel
  (org-hide-emphasis-markers t)                                                   ; hide */_= etc.
  (org-startup-indented t)
  (org-startup-with-latex-preview t)
  (org-return-follows-link t)
  (org-link-descriptive t)
  (org-pretty-entities t)
  (org-pretty-entities-include-sub-superscripts t)
  (org-use-sub-superscripts '{})

  (org-ellipsis "…")
  (org-auto-align-tags nil)
  (org-tags-column 0)
  
  ;; LaTeX – the 2025 gold standard (tiny!)
  (org-preview-latex-default-process 'imagemagick)
  (org-latex-compiler "lualatex")

  (org-catch-invisible-edits 'show-and-error) ;; current: 'smart
  (org-special-ctrl-a/e t)
  (org-insert-heading-respect-content t)
  
  ;; Agenda behaviour
  (org-agenda-tags-column 0)
  (org-agenda-window-setup 'current-window)
  (org-agenda-restore-windows-after-quit t)

  ;; TODO keywords
  (org-todo-keywords '((sequence "TODO(t)" "IN-PROGRESS(p!)" "WAITING(w@/!)" "|"
                                 "DONE(d!)" "CANCELLED(c@)")))
  )

;; THE big three visual packages (2024–2025)

(use-package org-modern
  ;; ... (your existing :ensure, :hook, etc.)
  :custom
  (org-modern-star '("◉" "○" "✸" "✿" "✤" "◆" "▶" "•"))                           ; pick whatever you love
  (org-modern-block-fringe nil)                                                     ; Fancy block borders
  (org-modern-table-vertical 1)
  (org-modern-table-horizontal 2)
  (org-modern-list '((?* . "•") (?+ . "◦") (?- . "–")))
  (org-modern-checkbox '((?X . "✔") (?- . "❍") (?\s . "☐")))
  (org-modern-priority t)
  (org-modern-todo t)
  (org-modern-tag t)
  :config
  (defun my-org-modern/table-header-face ()
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
  
  ;; Hook to apply after org-modern-mode
  :hook ((org-mode . org-modern-mode)
         (org-agenda-finalize . org-modern-agenda)
         (org-modern-mode . my-org-modern/table-header-face)))


;; Beautiful indented blocks (replaces old org-indent hacks)
(use-package org-modern-indent
  :load-path "~/.emacs.d/custom-packages/org-modern-indent"
  :hook (org-mode . org-modern-indent-mode)
  :custom (org-modern-indent/block t))                                            ; optional but looks amazing

(use-package org-appear
  :ensure t
  :hook (org-mode . org-appear-mode)
  :custom
  (org-appear-autolinks t)
  (org-appear-autosubmarkers t)
  (org-appear-autoemphasis t)
  (org-appear-autokeywords t))


;; Optional: fancy priorities instead of A/B/C
(use-package org-fancy-priorities
  :hook (org-mode . org-fancy-priorities-mode)
  :custom
  (org-fancy-priorities-list '("⚡" "🔥" "⏳"))
  (org-highest-priority ?A)
  (org-lowest-priority ?C)
  (org-default-priority ?B))

;; Org-roam – clean and modern
(use-package org-roam
  :ensure t
  :custom
  (org-roam-directory "/home/simon/Documents/org/org-roam/nodes")                 ; ← your desired location
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

;; Desktop notifications – the 2025 blessed version
(use-package org-alert
  :ensure t
  :after org
  :custom
  (alert-default-style 'libnotify)                                                ; works perfectly on Ubuntu
  (org-alert-interval 600)                                                        ; check every 10 min
  (org-alert-notification-title "Org")                                            ; optional prettiness
  (org-alert-notify-cutoff 180)                                                   ; start 3 hours before
  :config
  (org-alert-enable))

;; Keep your capture templates exactly as you like them (only tiny tidy-up)
(setq org-capture-templates
      '(("t" "Todo" entry
         (file+headline "~/Documents/org/inbox.org" "Tasks")
         "* TODO %?\n  %i\n  %a")
        ("j" "Journal" entry
         (file+datetree "~/Documents/org/journal/journal.org")
         "* %<\\H:%M> %?\n  %i")))

;; Your holidays and calendar settings – unchanged, they still work perfectly
;; (just leave everything you already have for holidays, latitude, etc.)

;; Dedicated agenda frame integration with window management
(defun my-org/agenda-in-new-frame (&optional arg keys)
  "Run `org-agenda' in a new frame, tagged for custom window management.
Preserves main frame layout.  ARG is passed to `org-agenda'.
KEYS is the agenda view string (e.g., \"a\" for agenda, \"t\" for TODOs)."
  (interactive "P")
  (let* ((agenda-frame (make-frame `((name . "Org-Agenda")
                                     (width . 120)
                                     (height . 40)
                                     (minibuffer . t)
                                     (menu-bar-lines . 0)
                                     (tool-bar-lines . 0)
                                     (vertical-scroll-bars . nil)  ; Fixed: hide scrollbars
                                     ;; Tag this frame for your custom management (non-project, but routable)
                                     (custom-window-management . t)
                                     (project-root . "org-agenda"))))  ; Dummy root to isolate
         (old-frame (selected-frame))
         (old-buffer (current-buffer)))
    (unwind-protect
        (with-selected-frame agenda-frame
          (my-window-tools/set-frame-project-root agenda-frame "org-agenda")  ; Integrate with your frame-map
          (my-window-tools/tag-windows-by-list agenda-frame my-window-tools/tag-list t)  ; Tag windows (e.g., 'data' for agenda)
          ;; Add hook BEFORE org-agenda so it fires on finalize
          (add-hook 'org-agenda-finalize-hook #'org-modern-agenda nil t)
          ;; Call with correct args: arg + keys (restriction defaults to nil)
          (org-agenda arg keys)
          ;; Optional: Log success (uses your log if available, else message)
          (if (fboundp 'log/debug)
              (log/debug :fn 'my-org/agenda-in-new-frame :msg "Agenda frame setup complete" :obj (list :frame agenda-frame :keys keys))
            (message "Org-Agenda frame created: %s (view: %s)" agenda-frame keys)))
      ;; Restore original frame/buffer on exit (e.g., errors)
      (when (frame-live-p old-frame)
        (select-frame-set-input-focus old-frame))
      (when (buffer-live-p old-buffer)
        (set-buffer old-buffer)))))

;; Updated dashboard: Pass only arg + keys
(defun my-agenda/dashboard ()
  "2025 four-pane dashboard in a dedicated frame."
  (interactive)
  (my-org/agenda-in-new-frame nil "a")  ; 'a' for agenda view
  ;; Post-setup: Split in the agenda frame (your window mgmt handles routing)
  (let ((agenda-frame (my-window-tools/find-frame-by-project-root "org-agenda")))
    (when (frame-live-p agenda-frame)
      (with-selected-frame agenda-frame
        (delete-other-windows)
        (split-window-right)
        (other-window 1)
        (calendar)
        (split-window-below)
        (other-window 1)
        (org-agenda nil "t")))))  ; TODO view in bottom-right

;; Global bindings (C-c a for agenda; keeps your C-c l for dashboard)
(global-set-key (kbd "C-c a") #'my-org/agenda-in-new-frame)
(global-set-key (kbd "C-c l") #'my-agenda/dashboard)

(provide 'org-support)
;;; org-support.el ends here

;; LocalWords:  lualatex
;; LocalWords:  routable
;; LocalWords:  ARG
;; LocalWords:  TODOs
