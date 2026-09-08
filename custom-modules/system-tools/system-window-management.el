;;; system-window-management.el --- Multi-frame IDE window tagging. -*- lexical-binding: t; -*-

;; Copyright (C) 2026 Simon Watson
;; SPDX-License-Identifier: MIT

;; Author: Simon Watson

;;; Commentary:

;; MAP feature and `provide' of IDE window tagging.  Load from
;; `init.el' with:
;;
;;   (require 'system-window-management)
;;
;; Category maps live here.  Piece files:
;;
;;   system-window-helpers  — tagging helpers and `log/debug-window-management'
;;   system-window-panes    — pane toggle, bury, reallocation
;;   system-window-display  — `display-buffer' advice and Ediff
;;
;; Principle 1: collections are mapped by tags on frames and windows.
;; Principle 2: buffers run free; this file only chooses display.
;; Principle 3: untagged frames and unmatched buffers behave as stock
;; Emacs would.
;; Principle 4: IDE panes other than `edit' may be closed.  Buffers
;; that would have been shown in a missing pane follow
;; `my-window-tools/category-fallback'.  The edit pane cannot be
;; closed.
;;
;; Map:
;;   Feature:    system-window-management
;;   Load-after: path-support logging-config
;;   Load-phase: tools
;;   Keymaps:    none
;;   Docs:       docs/system-window-management.org
;;   OS:         none

;;; Code:

(require 'cl-lib)
(require 'path-support)
(require 'logging-config)
(log/debug :fn 'system-window-management
           :msg "Starting load of the system-window-management module."
           :obj t)

(require 'ui-config)

(defvar switch-to-buffer-obey-display-actions t
  "Use custom window management if t.")

(defvar my-buffer-tools/category-map
  '(
    (:whitelist-names . ("*Speedbar*"
                         " SPEEDBAR"
                         "*SPEEDBAR*"
                         "*SR-SPEEDBAR*"
                         "*Ilist*"
                         "*Dictionary*"
                         "*Completions*"                                          ; Completion dropdowns
                         "*Echo Area 0*"                                          ; Minibuffer echo areas
                         "*Echo Area 1*"                                          ; Minibuffer echo areas
                         "*Minibuf-0*"                                            ; Minibuffer internals
                         "*Minibuf-1*"
                         "*LV*"                                                   ; Temporary overlay buffers (e.g., from Hydra or similar)
                         "*company-documentation*"                                ; Company mode popups
                         "*corfu-popup*"                                          ; Corfu completion overlays
                         "*posframe-buffer*"                                      ; Posframe child frame buffers
                         "*Ediff Control Panel*"
                         ))
    (:whitelist-regexps . ("^\\*temp.*"                                           ; Temporary buffers starting with *temp
                           "^\\*ivy-.*"                                           ; Ivy/Counsel dropdowns
                           "^\\*helm.*"                                           ; Helm completion lists
                           "^\\*vertico.*"                                        ; Vertico minibuffer extensions
                           "^\\*transient.*"                                      ; Transient (Magit-like) popups
                           "^\\*Embark.*"                                         ; Embark action menus
                           "^\\*Ediff.*"                                          ; Ediff windows
                           "^\\*?\\(ediff\\|Ediff\\|dired-diff\\|vc-diff\\|smerge\\)"
                           ".*\\(ediff\\|diff\\|smerge\\).*"
                           ))
    (:names . (("WINDOW_EDIT" . edit)
               ("WINDOW_DATA" . data)
               ("WINDOW_CONFIG" . data)
               ("WINDOW_TERMINAL" .terminal)
               ("WINDOW_VC" . vc)
               ("WINDOW_LOGS" . logs)
               ("spreadsheet-support.el" . edit)
               ("flymake-config.el" . edit)
               ("*dape-memory*" . data)                                           ; Add missing (memory viewer)
               ("Checkdoc Status" . data)
               ("SQL Results" . data)
               ("Backtrace" . data)
               ("*grep*" . data)
               ("xref" . data)
               ("xAI Chat" . data)
               ("Org Agenda" . data)
               ("docker-images" . data)
               ("docker-contexts" . data)
               ("docker-networks" . data)
               ("docker-containers" . data)
               ("docker-volumes" . data)
               ("spreadsheet.ses" . data)
               ("spreadsheet.ses<simon>" . data)
               ("Emacs" . edit)
               ("vc-support.el" . edit)
               ("config.el" . edit)
               ("early-config.el" . edit)
               (".bashrc" . edit)
               (".bash_history" . edit)
               (".bashrc_profile" . edit)
               (".LESS_TERMCAP" . edit)
               (".profile" . edit)
               (".zshrc" . edit)
               ("*dape-connection events*" . logs)
               ("*Messages*" . logs)
               ("*Warnings*" . logs)
               ("ruff-format errors" . logs)
               ("Async-native-compile-log" . logs)
               ("elisp-flymake-byte-compile" . logs)
               ("log-edit-files" . vc)
               ("*log-edit-files*" . vc)
               ("Org Babel Results" . logs)
               ("vc" . logs)
               ("*Load-History*" . logs)
               ("RE-Builder" . config)
               ("conf.org" . config)
               ("todos.org" . config)
               ("gracie.org" . config)
               ("evie.org" . config)
               ("*eldoc*" . config)
               ("*pydoc*" . config)
               ("EGLOT workspace configuration" . config)
               ("Help" . config)
               ("info" . config)
               ("Ediff Config" . config)
               ("Ilist" . config)
               ("*Projects View*" . config)
               ("*dape-repl*" . config)
               (".gitignore" . vc)
               ("*vc*" . vc)
               ("*vc-dir*" . vc)
               ("*vc-log*" . vc)
               ("*vc-log-edit*" . vc)
               ("*vc-diff*" . vc)
               ("*log-edit-files*" . vc)
               ("*vc-change-log*" . vc)
               ("*VC-log*" . vc)
               ("*VC-change-log*" . vc)
               ("*Flymake log*" . vc)
               ("*dape-shell*" . terminal)
               ("*scratch*" . terminal)
               ("*MATLAB*" . terminal)
               ))                                                                 ; Note: If conflicting with above, choose one
    (:regexps . (("^documentation$" . config)                                     ; Exact match for "documentation"
                 ("^README.*" . config)                                           ; Starting with "README" + any chars
                 (".*\\.conf$" . config)                                          ; Any chars + literal ".conf" at end
                 (".*\\.dconf$" . config)                                         ; Any chars + literal ".dconf" at end
                 ("^\\*Customize.*" . config)                                     ; Starting with literal "*Customize" + any chars
                 ("^\\*Ibuffer.*" . config)                                       ; Starting with literal "*Ibuffer" + any chars
                 (".*_types.py" . config)                                         ; Any chars + "_types.py"
                 (".*\\.pdf$" . config)                                           ; Any chars + literal ".pdf" at end
                 ("^vc-.*" . vc)                                                  ; Starting with "vc-" + any chars
                 ("^\\*vc-.*" . vc)                                               ; Starting with "*vc-" + any chars
                 ("^\\*log-edit.*" . vc)                                          ; Containing log-edit (for vc mode)
                 ("^\\*VC-.*" . vc)                                               ; Containing *VC- (for vc mode)
                 (".*Annotate .*" . vc)                                           ; Any chars + "Annotate " + any chars
                 (".*ede-proj.*" . vc)                                            ; Any chars + "ede-proj" + any chars
                 ("^\\*dape-info.*" . data)                                       ; Starting with *dape-info" + any chars
                 ("^\\*undo-tree.*" . data)                                       ; Starting with *undo-tree" + any chars
                 ("^\\*Flymake diagnostics.*" . data)                             ; Starting with literal "*Flymake diagnostics" + any chars
                 ("^flymake-.*" . data)                                           ; Starting with "flymake-" + any chars
                 (".*cell sheet.*" . data)                                        ; Any chars + "cell sheet" + any chars
                 (".*spreadsheet.*" . data)                                       ; Any chars + "spreadsheet" + any chars
                 ("*\\.bib" . data)                                               ; Any chars + literal ".bib" at end
                 ("^Ediff A\\:.*" . data)                                         ; Starting with "Ediff A:" + any chars (escaped :)
                 ("^Ediff B\\:.*" . data)                                         ; Starting with "Ediff B:" + any chars (escaped :)
                 ("^\\*EGLOT.*" . logs)                                           ; Starting with literal "*EGLOT" + any chars
                 (".*+sterr$" . logs)                                             ; Any chars + "+sterr" at end
                 (".*\\.log" . logs)                                              ; Any chars + literal ".log"
                 (".*-log.*" . logs)                                              ; Any chars + "-log" + any chars
                 (".*tramp.*" . logs)                                             ; Any chars + "tramp" + any chars
                 ("^\\*vc-git :.*" . logs)                                        ; Starting with literal "*vc-git :" + any chars
                 ("^\\*.*output\\*$" . logs)                                      ; starting with a star then any chars + "tramp" + ending with output* (latex compilation file)
                 ("^Vterm:" . terminal)                                           ; Starting with literal "Vterm:"
                 ("^\\*ielm" . terminal)                                          ; Starting with literal "*ielm"
                 ("^\\*Q PROC.*" . terminal)                                      ; Starting with literal "*Q PROC" + any chars
                 ("^\\*vterm.*" . terminal)                                       ; Starting with literal "*vterm" + any chars
                 ("^\\*eshell.*" . terminal)))                                    ; Starting with literal "*eshell" + any chars
    (:modes . ((vterm-mode . terminal)
               (eshell-mode . terminal)
               (shell-mode . terminal)
               (term-mode . terminal)
               (dired-mode . terminal)
               (ielm-mode . terminal)
               (inferior-python-mode . terminal)
               (flymake-diagnostics-buffer-mode . data)
               (calendar-mode . data)
               (diary-mode . data)
               (clojure-mode . edit)
               (lisp-mode . edit)
               (python-ts-mode . edit)
               (q-script-mode . edit)
               (rust-mode . edit)
               (scheme-mode . edit)
               (systemd-mode . config)
               (toml-ts-mode . config)
               (XML-mode . config)
               (nXML-mode . config)
               (json-mode . config)
               ;; (org-mode . config)  ; Commented as in original
               (csv-mode . config)
               (ibuffer-mode . config)
               (bufler-list-mode . config)
               (bookmark-menu . config)
               (imenu-list-mode . config)
               (help-mode . config)
               (helpful-mode . config)
               (log-view-mode . logs)
               (compilation-mode . logs)
               (debugger-mode . logs)
               (vc-dir . vc))))
  "Mapping of buffer properties to window categories.  Any name beginning with a space is white listed automatically.")


(defvar my-window-tools/category-map
  '((:IDE . (edit data config logs vc terminal))))

(defconst my-window-tools/category-fallback
  '((edit)
    (data logs vc config terminal edit)
    (config logs vc data terminal edit)
    (logs vc config data terminal edit)
    (vc logs config data terminal edit)
    (terminal logs vc config data edit))
  "Alist of CATEGORY -> ordered lookup chain.

The first element of each list is the home category.
`my-window-tools/get-window-for-window-category' tries each entry in
order until an open, live window of that category exists on the frame.
`edit' has no alternative: it cannot be redirected or closed.")

(defconst my-window-tools/default-occupants
  '((edit . "*Emacs*")
    (data . "xAI Chat")
    (config . "*Ibuffer*")
    (logs . "*Warnings*")
    (vc . "*vc-dir*")
    (terminal . "*scratch*"))
  "Default buffer names shown when a category pane is (re)created.")

(defconst my-window-tools/ide-category-weight
  '((edit . 0.639)
    (data . 0.500)
    (config . 0.500)
    (logs . 0.320)
    (vc . 0.344)
    (terminal . 0.336))
  "Relative weights used when splitting a neighbour to reopen a pane.")

(defconst my-window-tools/ide-category-layout
  '((data     . (:group right  :axis vertical   :order 0 :edit-side right :edit-frac 0.361))
    (config   . (:group right  :axis vertical   :order 1 :edit-side right :edit-frac 0.361))
    (logs     . (:group bottom :axis horizontal :order 0 :edit-side below :edit-frac 0.237))
    (vc       . (:group bottom :axis horizontal :order 1 :edit-side below :edit-frac 0.237))
    (terminal . (:group bottom :axis horizontal :order 2 :edit-side below :edit-frac 0.237)))
  "Canonical combination metadata used to place a reopened category window.")

(defvar my-window-tools--inhibit-retag nil
  "Non-nil suppresses `my-window-tools/retag-on-config-change'.")

(defvar my-window-tools--in-toggle nil
  "Non-nil while a pane toggle or category close is rewriting the layout.")

(defvar my-window-tools/in-ediff-session nil
  "Non-nil when inside an Ediff session (frame-local).")

(defvar my-window-tools/keep-buffers
  '("*emacs*" "*Emacs*" "*scratch*" "*Ibuffer*" "*SPEEDBAR*"
    "*Warnings*" "*vc-dir*" "*vc-dir<.emacs.d>*" "xAI Chat")
  "Do not delete these buffers when carrying out aggregate buffer deletes.
Each element must be a string that exactly matches a `buffer-name'.")

(require 'system-window-helpers)
(require 'system-window-panes)
(require 'system-window-display)

(log/debug :fn 'system-window-management
           :msg "Finishing load of the system-window-management module."
           :obj t)
(provide 'system-window-management)

;;; system-window-management.el ends here
