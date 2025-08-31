;;; org-support.el --- org setup  -*- lexical-binding: t -*-

;; Copyright (C) 2025
;; SPDX-License-Identifier: MIT
;; -*- mode: org;
;; Author: Simon Watson

;;; Commentary:

;; Org Mode setup and configuration.

;;; Code:
;; make sure the org package is dowloaded and installed before
;; org type functionality is called by anything. The built in or
;; can cause conflicts with this if org is called before this.
(use-package org)                                                                 ; was   :ensure org-plus-contrib
(use-package org-contrib)
(use-package org-contacts)
(use-package google-contacts)

;; This web-link; https://github.com/emacsmirror/org-link-beautify
;; shows as this: [[https://github.com/emacsmirror/org-link-beautify][org-link-beautify]].
(use-package org-link-beautify
  :ensure t
  :init (org-link-beautify-mode t))
  
;; send alerts to the desktop (via `libnotify' here which should be already
;; built in Ubuntu).
;; Note it depends on alert package (installed previously)
;; Here we:
;;    * set org-alert to check your agenda file every 10 minutes (600 seconds),
;;    * start notifying you of a scheduled event 3 hours (180 minutes before
;;      the event),
;;    * stop notifying you of the event 10 minutes after the scheduled time has
;;      passed.
(defvar alert-default-style)
(defvar org-alert-interval)
(defvar org-alert-notify-cutoff)
(defvar org-alert-notify-after-event-cutoff)
(use-package org-alert
  :init
  (setq alert-default-style 'libnotify
        org-alert-interval 300
        org-alert-notify-cutoff 180
        org-alert-notify-after-event-cutoff 10))

;; Second brain/zettlekasten by Protesilaos Stavrou (also known as
;; Prot), similar features as Org-Roam, but keeps everything in a
;; single directory, does not use a database preferring filenameing
;; conventions and grep instead.
;; https://github.com/protesilaos/denote
;; (use-package denote
;;   :straight (:type git
;;                    :host github
;;                    :repo "emacs-straight/denote"
;;                    :files ("*" (:exclude ".git"))))

;; Toggle the visibility of some Org elements.
;; https://github.com/awth13/org-appear
(use-package org-appear)

;; install a package to prettify the tables.
(progn
  (add-to-list 'load-path "~/.emacs.d/custom-packages/org-pretty-table")
  (require 'org-pretty-table)
  (add-hook 'org-mode-hook (lambda () (org-pretty-table-mode))))

;; https://gitlab.com/marcowahl/org-pretty-tags
(use-package org-pretty-tags)

;; note `org-roam-directory' set in custom-path-support.
(use-package org-roam
  :init
  (setq org-roam-v2-ack t)
  :custom
  (org-roam-completion-everywhere t)
  (org-roam-dailies-capture-templates
   '(("d" "default" entry "* %<%I:%M %p>: %?"
      :if-new (file+head "%<%Y-%m-%d>.org" "#+title: %<%Y-%m-%d>\n"))))
  :bind (("C-c n l" . org-roam-buffer-toggle)
         ("C-c n f" . org-roam-node-find)
         ("C-c n i" . org-roam-node-insert)
         :map org-mode-map
         ("C-M-i" . completion-at-point)
         :map org-roam-dailies-map
         ("Y" . org-roam-dailies-capture-yesterday)
         ("T" . org-roam-dailies-capture-tomorrow))
  :bind-keymap
  ("C-c n d" . org-roam-dailies-map)
  :config
  (require 'org-roam-dailies)                                                     ; Ensure the keymap is available
  (org-roam-db-autosync-mode))                                                    ; ensure org-roam looks after itself.

(require 'org)
(require 'org-agenda)
(require 'org-capture)
(require 'org-pretty-table)
;;(require 'org-clock)
(require 'ox-latex)
(require 'calendar)
(require 'holidays)
(require 'org-roam)
(require 'org-alert)


;;;; Set the defaults for viewing org-mode
(customize-set-variable
 'org-agenda-window-setup 'current-window                                         ; previously 'only-window "org-agenda takes the whole window."
 "org-agenda takes the current window.")

;; Return or left-click with mouse follows link
(customize-set-variable
 'org-return-follows-link t
 "Click RETURN to follow links in org-mode.")

(customize-set-variable
 'org-mouse-1-follows-link t
 "Click primary mouse button to follow links in org-mode.")

;; Display links as the description provided
(customize-set-variable
 'org-link-descriptive t
 "Display links as descriptions rather than raw URLs.")

;; Visually indent org-mode files to a given header level
;; (add-hook 'org-mode-hook #'org-indent-mode)

;; make org mode tables pretty.
(add-hook
 'org-mode-hook (lambda () (org-pretty-table-mode)))

;; Hide markup markers
(customize-set-variable 'org-hide-emphasis-markers t)
(when (locate-library "org-appear")
  (add-hook 'org-mode-hook 'org-appear-mode))

;; ensure formatting options used by org-toggle-pretty-entities must only be
;; interpreted if they are in curly brackets ({})
(customize-set-variable 'org-use-sub-superscripts '{})

;; Ensure that TAB works in a code-block the way it works in the major-mode for
;; that buffer.
(customize-set-variable 'org-src-tab-acts-natively t)


;;;; Set the defaults for viewing latex in org-mode
;; note that the cache for rendered latex is stored in
;; ~/.emacs.d/var/MY_NAME/.cache_latex/
;; This is set by custom-no-littering where MY_NAME is the
;; environmental variable where the name of the machine using this
;; setup is stored.



;; This setup allows Org Mode to preview LaTeX fragments inline, using image
;; files rendered by external programs like dvipng and imagemagick, for better
;; visual compatibility.

;; Note that org-format-latex-header is not modified as a custom 
(with-eval-after-load 'org
  
  (customize-set-variable
   'org-preview-latex-process-alist
   '((dvipng :programs ("latex" "dvipng")
             :description "dvi > png"
             :message "You need to install the programs: latex and dvipng."
             :image-input-type "dvi"
             :image-output-type "png"
             :image-size-adjust (1.0 . 1.0)
             :latex-compiler ("latex -interaction nonstopmode -output-directory %o %f")
             :image-converter ("dvipng -D %D -T tight -o %O %f"))

     (imagemagick :programs ("lualatex" "convert")
                  :description "pdf > png"
                  :message "You need to install the programs: lualatex and imagemagick."
                  :image-input-type "pdf"
                  :image-output-type "png"
                  :image-size-adjust (1.0 . 1.0)
                  :latex-compiler ("lualatex -interaction nonstopmode -output-directory %o %f")
                  :image-converter ("convert -density 600 -trim -antialias %f -quality 100 %O"))))

  ;; Define a multi-pass latex generation process to handle complex LaTeX
  ;; documents, including those with TikZ diagrams.
  ;; Running 3 times helps resolve things like cross-references.
  ;; Biber is used to help with inserting book references.
  (customize-set-variable
   'org-latex-pdf-process
   '("lualatex -interaction nonstopmode -output-directory %o %f"
     "biber %b"                                                                   ; If using biber for bibliography
     "lualatex -interaction nonstopmode -output-directory %o %f"
     "lualatex -interaction nonstopmode -output-directory %o %f")
   "Define how Org exports PDFs from LaTeX.")
  ;; Setting the pdf rendering engine without biber would be:
  ;; (setq org-latex-pdf-process
  ;;       '("pdflatex -interaction nonstopmode -output-directory %o %f"
  ;;         "pdflatex -interaction nonstopmode -output-directory %o %f"
  ;;         "pdflatex -interaction nonstopmode -output-directory %o %f"))

  ;; Default to imagemagick for rendering LaTeX previews for improved quality.
  (customize-set-variable
   'org-preview-latex-default-process 'imagemagick
   "Use Imagemagick to render LaTeX previews in Org Mode for high-quality output.")

  ;; Use LuaLaTeX as the default LaTeX compiler for better support with complex
  ;; documents
  (customize-set-variable
   'org-latex-compiler "lualatex"
   "Use LuaLaTeX as the default LaTeX compiler for better font support and compatibility.")

  (customize-set-variable
   'org-startup-with-latex-preview t "Render latex by default.")

  (customize-set-variable
   'org-latex-packages-alist
   '(("" "xcolor" t)                                                              ; Ensure `xcolor' is included
     ("" "array" t)                                                               ; Include `array' for tables
     ("" "amsmath" t)                                                             ; Include `amsmath' explicitly
     ("" "amsfonts" t)                                                            ; Include `amsfonts'
     ("" "amssymb" t)                                                             ; Include `amssymb'
     ("" "graphicx" t)                                                            ; Ensure image support
     ("" "fontspec" t)                                                            ; Ensure `fontspec' for LuaLaTeX
     ("dvipsnames" "xcolor" t)                                                    ; Enable extra colors in `xcolor'
     )
   "Add custom packages (without modifying defaults).")

  (setq my-latex/primary-header-values
        (string-join
         '("\\documentclass[12pt]{article}"
           "\\usepackage[usenames]{color}"
           "\\usepackage{xcolor}"
           "\\usepackage{fontspec}"
           "\\setmainfont{Source Code Pro}"
           "\\usepackage{amsmath}"
           "\\usepackage{amsfonts}"
           "\\usepackage{amssymb}"
           "\\usepackage{graphicx}"
           "\\usepackage{array}"
           "\\pagestyle{empty}      % No page numbers"
           "\\color[HTML]{FFFFFF}   % White text color") "\n"))

  ;; Set up org-format-latex-header for 'in buffer' rendering. 
  (customize-set-variable
   'org-format-latex-header my-latex/primary-header-values)

  ;; Add a custom org-latex-class and set it as default FOR EXPORT ONLY.
  (add-to-list 'org-latex-classes
               `("custom-org-export"
                 ,my-latex/primary-header-values
                 ("\\section{%s}" . "\\section*{%s}")
                 ("\\subsection{%s}" . "\\subsection*{%s}")
                 ("\\subsubsection{%s}" . "\\subsubsection*{%s}")))

  (customize-set-variable
   'org-latex-default-class "custom-org-export"
   "Set the default class to be used for formatting latex in Org.")

  ;;  Set the scale of the latex object so it is smaller.
  (customize-set-variable 'org-format-latex-options
                          (plist-put org-format-latex-options :scale 0.33)
                          "Reduce the scale as needed.")
  )

;; Enable LaTeX previews on file open and when editing LaTeX fragments.
(add-hook 'org-mode-hook 'org-latex-preview)


;;;; Fix the org-table layout when using org-link-beautify-mode
(defun my/org-table-fix-link-width ()
  "Adjust Org table column widths when `org-link-beautify-mode' is active."
  (when (and (bound-and-true-p org-link-beautify-mode)
             (org-at-table-p))
    (save-excursion
      (goto-char (org-table-begin))
      (while (re-search-forward org-bracket-link-regexp (org-table-end) t)
        (let* ((full-link (match-string 0))
               (displayed-text (if (match-string 3) (match-string 3) (match-string 1)))
               ;; Fine-tune extra padding based on estimated icon width
               (icon-width 0.9)                                                   ; Approximate width of the beautified icon
               (extra-spacing (max 0 (ceiling (- 1 icon-width))))                 ; Ensure at least 1 space if necessary
               (adjusted-text
                (concat displayed-text (make-string extra-spacing ?\s))))
          (replace-match adjusted-text t t))))))

(defun my/org-table-align-hook (&rest _)
  "Hook function to adjust table alignment."
  (when (bound-and-true-p org-link-beautify-mode)
    (my/org-table-fix-link-width)))

(advice-add 'org-table-align :before #'my/org-table-align-hook)

;; Disable auto-pairing of "<" in org-mode with electric-pair-mode
(defun org-enhance-electric-pair-inhibit-predicate ()
  "Disable auto-pairing of \"<\" in `org-mode' using `electric-pair-mode'."
  (when (and electric-pair-mode (eql major-mode #'org-mode))
    (setq-local electric-pair-inhibit-predicate
                `(lambda (c)
                   (if (char-equal c ?<)
                       t
                     (,electric-pair-inhibit-predicate c))))))

;; Add hook to both electric-pair-mode-hook and org-mode-hook
;; This ensures org-mode buffers don't behave weirdly,
;; no matter when electric-pair-mode is activated.
(add-hook 'electric-pair-mode-hook
          #'org-enhance-electric-pair-inhibit-predicate)

(add-hook 'org-mode-hook
          #'org-enhance-electric-pair-inhibit-predicate)


;;;; Org Agenda/Calendar

;; (customize-set-variable
;;  'diary-time-format 12
;;  "set the time format to 12 hours (with am/pm) for emacs diary.")

(customize-set-variable 'diary-number-of-entries 7
                        "Number of entries to show for the diary")

(customize-set-variable
 'org-agenda-restore-windows-after-quit t
 "Restore the window configuration on exit of org-agenda.")

;; Set up holidays. 
(defvar holiday-australia-holidays
  (mapcar 'purecopy
          '((holiday-fixed 1 1 "New Year's Day")

            (holiday-fixed 1 26 "Australia Day")                                  ; Always Jan 26
            
            ;; (holiday-sexp                                                         ; If Jan 26 is a weekend, observe the following Monday
            ;;  (let* ((year (or displayed-year (calendar-current-year)))            ; Use displayed-year if available, else fallback to current year
            ;;         (dow (calendar-day-of-week (list 1 26 year))))
            ;;    (cond
            ;;     ((= dow 6) (list 1 28 year))                                      ; Saturday -> holiday on Monday (the 28th)
            ;;     ((= dow 0) (list 1 27 year))                                      ; Sunday -> holiday on Monday (the 27th)
            ;;     (t nil)))
            ;;  "Australia Day (Observed)")

            (holiday-fixed 4 25 "Anzac Day")
            (holiday-float 5 0 2 "Mother's Day")
            (holiday-float 6 1 2 "Queen's Birthday")                              ; Varies by state, commonly second Monday in June
            (holiday-float 9 0 1 "Father's Day")
            (holiday-float 10 1 1 "Labour Day")                                   ; Varies by state, commonly first Monday in October in New South Wales
            (holiday-fixed 12 25 "Christmas Day")
            (holiday-fixed 12 26 "Boxing Day"))))

(defvar holiday-uk-holidays
  (mapcar 'purecopy
          '((holiday-fixed 1 1 "New Year's Day")
            (holiday-float 3 0 1 "Mother's Day")                                  ; Fourth Sunday in Lent, often in March
            (holiday-float 4 0 -2 "Good Friday")                                  ; Good Friday, two days before Easter Sunday
            (holiday-float 4 0 1 "Easter Sunday")                                 ; Easter Sunday, first Sunday after the first full moon on or after March 21
            (holiday-float 4 0 2 "Easter Monday")                                 ; Easter Monday, the day after Easter Sunday
                                                                                  ; First Monday in May
            (holiday-float 5 1 1 "Early May Bank Holiday") 
                                                                                  ; Last Monday in May
            (holiday-float 5 1 -1 "Spring Bank Holiday") 
            (holiday-float 6 0 3 "Father's Day")                                  ; Third Sunday in June
                                                                                  ; Last Monday in August
            (holiday-fixed 8 31 "Summer Bank Holiday") 
            (holiday-fixed 12 25 "Christmas Day")
            (holiday-fixed 12 26 "Boxing Day"))))

(defun combine-holiday-lists (&rest lists)
  "Combine multiple holiday LISTS, removing duplicates."
  (let ((combined (apply 'append lists)))
    ;; Remove duplicates
    (delete-dups combined)))

(defvar holiday-combined-holidays
  (combine-holiday-lists holiday-australia-holidays
                         holiday-uk-holidays
                         holiday-christian-holidays
                         holiday-hebrew-holidays
                         holiday-solar-holidays)
  "Combined list of holidays in Australia, the UK, and other holidays.")

(customize-set-variable
 'calendar-holidays holiday-combined-holidays
 "Set the holidays show in Emacs.")

;; Set calendar location and time zone names

(customize-set-variable
 'calendar-setup 'one-frame "Calendar and diary together")

(customize-set-variable
 'calendar-date-style 'iso "Sets date format for calendar (YYYY.MM.DD).")
(customize-set-variable
 'calendar-latitude -33.8688 "The latitude for working out sunrise/sunset.")
(customize-set-variable
 'calendar-longitude 151.2093 "The longitude for working out sunrise/sunset.")
(customize-set-variable
 'calendar-location-name
 "Sydney NSW, AUSTRALIA" "The name for the location to use in calendar.")

(customize-set-variable
 'calendar-standard-time-zone-name "AEST")
(customize-set-variable
 'calendar-daylight-time-zone-name "AEDT")

;; Define daylight saving time start and end
(defvar  calendar-daylight-savings-starts
  '(calendar-nth-named-day 1 0 10 year))                                          ; First Sunday in October
(defvar  calendar-daylight-savings-ends
  '(calendar-nth-named-day 1 0 4 year))                                           ; First Sunday in April


(defun my-set-calendar-time-zone ()
  "Determine the current time zone offset."
  (let ((current-time (current-time))
        (dst-start (calendar-absolute-from-gregorian
                    (eval calendar-daylight-savings-starts)))
        (dst-end (calendar-absolute-from-gregorian
                  (eval calendar-daylight-savings-ends))))
    (setq calendar-time-zone (if (and (>= (calendar-absolute-from-gregorian
                                           (calendar-current-date))
                                          dst-start)
                                      (< (calendar-absolute-from-gregorian
                                          (calendar-current-date))
                                         dst-end))
                                 660                                              ; Daylight time (AEDT)
                               600))))                                            ; Standard time (AEST)

;; Call the function to set the time zone
;;(my-set-calendar-time-zone)

;; Set up time and date formats and the look of Calendar.
(customize-set-variable
 'calendar-mark-holidays-flag t "Show holidays in the calendar.")
(customize-set-variable
 'calendar-mark-diary-entries-flag t "Show diary entries in the calendar.")
(customize-set-variable
 'calendar-view-holidays-initially-flag t "Show holidays in the calendar.")
(customize-set-variable
 'calendar-setup nil "Show calendar in current frame.")
(customize-set-variable
 'calendar-setup 'one-frame
 "Show calendar with diary entries in a single frame.")

;; make the current day visible. 
(add-hook 'calendar-today-visible-hook 'calendar-mark-today)

(customize-set-variable
 'org-agenda-include-diary "integrate emacs diary in org-agenda.")
;; integrate org-agenda with Emacs appointment functionality.
(org-agenda-to-appt) 

;; ensure appointments are being checked.
;; (after current timezone and position have been set)


;; Make appt aware of appointments from the agenda
(defun my-org/agenda-to-appt ()
  "Activate appointments found in `org-agenda-files'."
  (interactive)
  (require 'org)
  (let* ((today (org-date-to-gregorian
		 (time-to-days (current-time))))
	 (files org-agenda-files) entries file)
    (while (setq file (pop files))
      (setq entries (append entries (org-agenda-get-day-entries
				     file today :timestamp))))
    (setq entries (delq nil entries))
    (mapc (lambda(x)
	    (let* ((event (org-trim (get-text-property 1 'txt x)))
		   (time-of-day (get-text-property 1 'time-of-day x)) tod)
	      (when time-of-day
		(setq tod (number-to-string time-of-day)
		      tod (when (string-match
				 "\\([0-9]\\{1,2\\}\\)\\([0-9]\\{2\\}\\)" tod)
			    (concat (match-string 1 tod) ":"
				    (match-string 2 tod))))
		(if tod (appt-add tod event))))) entries)))


;; Define the todo sequence
(customize-set-variable
 'org-todo-keywords
 '((sequence "PLANNING" "TODO" "IN-PROGRESS" "WAITING" "|" "DONE" "CANCELLED"))
 "Define the sequence of states the TODO will go through.
Pipe indicates that DONE and CANCELLED are both final states to be chosen.")

;; save clock history across emacs sessions in todos. 
;;(setq org-clock-persist 'history)
;;(org-clock-persistence-insinuate)



;; Org Capture:
;; Capture templates
(setq org-capture-templates
      '(
        ("t" "Todo with link to contact"
         entry (file+headline
                (expand-file-name "agenda/todo.org" org-directory) "Tasks")
         "* TODO %^{Title}
 SCHEDULED: %^t
 :PROPERTIES:
 :CONTACT: %^{Contact|}p
 :END:
 %a")
        ("t" "Todo" entry (file
                           (expand-file-name "inbox.org" org-directory))
         "* TODO %?\n  %i\n  %a")
        ("c" "Contact" entry (file "~/org/contacts.org")
         "* %(org-contacts-template-name)
:PROPERTIES:
:EMAIL: %(org-contacts-template-email)
:PHONE: %^{Phone}
:ADDRESS: %^{Address}
:URL: %^{URL}
:END:")
        ("j" "Journal" entry (file+datetree
                              (expand-file-name
                               "journal/journal.org" org-directory))
         "* %?\nEntered on %U\n  %i\n  %a")))


;; --------
;;; Org abbreviations
;; Abbreviations
(customize-set-variable
 'org-link-abbrev-alist
 '(;; Abbreviations for files
   ("dev"            . "file:dev.org::*")
   ("edu"            . "file:edu.org::*")
   ("fin"            . "file:fin.org::*")
   ("hea"            . "file:hea.org::*")
   ("hob"            . "file:hob.org::*")
   ("mul"            . "file:mul.org::*")
   ("org"            . "file:org.org::*")
   ("peo"            . "file:peo.org::*")
   ("pos"            . "file:pos.org::*")
   ("ref"            . "file:ref.org::*")
   ("soc"            . "file:soc.org::*")
   ("wrk"            . "file:wrk.org::*")
   ;; Abbreviations for websites
   ("facebook"       . "https://www.facebook.com/")
   ("fedex"          . "https://www.fedex.com/fedextrack/?tracknumbers=")
   ("gmail"          . "https://mail.google.com/mail/u/0/#all/")
   ("google"         . "https://www.google.com/#q=")
   ("google-maps"    . "https://maps.google.com/maps?q=")
   ("google-plus"    . "https://plus.google.com/")
   ("google-scholar" . "http://scholar.google.com/scholar?hl=en&q=")
   ("github"         . "https://www.github.com/")
   ("hacker-news"    . "https://news.ycombinator.com/item?id=")
   ("instagram"      . "https://www.instagram.com/")
   ("linkedin"       . "http://www.linkedin.com/")
   ("ontrac"         . "http://www.ontrac.com/trackingres.asp?tracking_number=")
   ("pinterest"      . "http://www.pinterest.com/")
   ("reddit"         . "http://reddit.com/user/")
   ("twitter"        . "https://www.twitter.com/")
   ("ups"            . "http://www.ups.com/WebTracking/processRequest?tracknum=")
   ("usps"           . "https://tools.usps.com/go/TrackConfirmAction.action?tRef=fullpage&tLc=1&text28777=&tLabels=")
   ("yelp-business"  . "http://www.yelp.com/biz/")
   ("yelp-user"      . "http://www.yelp.com/user_details?userid=")
   ("youtube"        . "http://www.youtube.com/user/")
   ;; Abbreviations for other protocols
   ("tel"            . "tel:"))
 "Set abbreviations for links in org-mode.")

;; Create abbreviations when writing the file. 
;; (add-hook 'org-mode-hook
;;          (lambda ()
;;            (add-to-list 'write-file-functions 'my-org/org-link-abbreviations-create)))

;; (can also remove abbreviations using my-org/org-link-abbreviations-remove)


;; ----end Org abbreviations----

(defun my-org/open-org-agenda-files ()
  "Sequentially open each file in 'org-agenda-files'."
  (dolist (file org-agenda-files)
    (when (file-exists-p file)                                                    ; Ensure the file exists
      (find-file file)                                                            ; Open the file in the current window
      (message "Opened: %s" file)                                                 ; Optional: Display a message
      (tab-line-mode 1)
      ;;   (sit-for 1)                                                                 ; Pause briefly to visualize the process
      )))           

(declare-function my-buffer-tools/open-temp-buffer "system-tools")
(declare-function my-buffer-tools/show-buffer-from-first-line "system-tools")
(declare-function my-buffer-tools/resize-window-vertically "system-tools")

(defun my-org/open-agenda ()
  "Open Org agenda in a new frame named `*agenda*'."
  (interactive) (appt-activate t)
  (let* (
         (base-buffer (my-buffer-tools/open-temp-buffer "TEMP-agenda"))
         (agenda-frame (make-frame `((name . "*agenda*"))))
         (left-window (frame-selected-window agenda-frame))
         )
    (with-selected-frame agenda-frame
      (let* (
             (right-top-window
              (progn
                (select-window left-window)
                (split-window-horizontally)))
             (right-bottom-left
              (progn
                (select-window right-top-window)
                (split-window-vertically)))
             (right-bottom-right
              (progn
                (select-window right-bottom-left)
                (split-window-horizontally))))

        (select-window right-top-window)
        (let (
              (calendar-setup nil)
              (display-buffer-alist
               '(
                 ("." (display-buffer-same-window)))))
          (calendar)
          (let ((calendar-buffer (get-buffer "*Calendar*")))
            (my-buffer-tools/show-buffer-from-first-line calendar-buffer)
            (set-window-buffer right-top-window calendar-buffer)
            (with-current-buffer (current-buffer)
              (tab-line-mode -1)
              (setq-local header-line-format " Calendar"))
            (my-buffer-tools/resize-window-vertically calendar-buffer 0.3)))
        
        (with-current-buffer calendar-buffer (tab-line-mode -1))
        (select-window left-window)
        (let ((display-buffer-alist
               '(
                 ("." (display-buffer-same-window)))))
          (org-agenda-list)
          (with-current-buffer (current-buffer)
            (tab-line-mode -1)
            (setq-local header-line-format " Agenda")))

        (select-window right-bottom-left)
        (let ((display-buffer-alist
               '(
                 ("." (display-buffer-same-window)))))
          (holiday-list (string-to-number (format-time-string "%Y")))
          (select-window right-bottom-left)
          (with-current-buffer (current-buffer)
            (tab-line-mode -1)
            (setq-local header-line-format " Holidays")))
        
        (select-window right-bottom-right)
        (let ((display-buffer-alist
               '(
                 ("." (display-buffer-same-window)))))
          (my-org/open-org-agenda-files))))
    (kill-buffer base-buffer)))


(provide 'org-support)
;;; org-support.el ends here


;; LocalWords:  filenameing Biber luatex LaTeX imagemagick dvipng png dvi pdf
;; LocalWords:  dvipsnames xcolor LuaLaTeX amssymb amsfonts amsmath fontspec
;; LocalWords:  color graphicx usepackage documentclass setmainfont
