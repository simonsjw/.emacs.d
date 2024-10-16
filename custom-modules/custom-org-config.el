;;; custom-org-config.el  -*- lexical-binding: t; -*-

;; Copyright (C) 2022
;; SPDX-License-Identifier: MIT

;; Author: System Crafters Community

;; Commentary

;; Provides basic configuration for Org Mode.

;;; Code:
(require 'custom-logging-config)
(require 'org)
(require 'org-agenda)
(require 'org-capture)
(require 'org-pretty-table)
;;(require 'org-clock)
(require 'ox-latex)
(require 'calendar)
(require 'holidays)
(require 'org-roam)

;; ensure org-roam looks after itself.
(org-roam-db-autosync-mode)

;; ensure Luatex is used to process LaTex rather than dvipng.
(customize-set-variable
 'org-latex-compiler "luatex" "Use LuaLaTeX as the default LaTeX compiler.")

;;; set the defaults for viewing latex in org-mode
;;  ----------------------------------------------
;; note that the cache for rendered latex is stored in
;; ~/.emacs.d/var/MY_NAME/.cache_latex/
;; This is set by custom-no-littering where MY_NAME is the
;; environmental variable where the name of the machine using this
;; setup is stored.

;; set the pdf rendering engine. 
(setq org-latex-pdf-process
      '"lualatex -interaction nonstopmode -output-directory %o %f")

;; Render wiht luaLatex and use image magik to produce pngs in org files.
(with-eval-after-load 'org
  (add-to-list
   'org-preview-latex-process-alist
   '(luatex
     :programs ("lualatex" "convert")
     :description "pdf > png"
     :message "you need to install the programs: lualatex and imagemagick."
     :image-input-type "pdf"
     :image-output-type "png"
     :image-size-adjust (0.25 . 0.25)
     :latex-compiler ("lualatex -output-format=pdf -interaction nonstopmode -output-directory %o %f")
     :image-converter ("convert -density 300 %f -quality 90 %O")))
  (customize-set-variable
   'org-preview-latex-default-process 'luatex
   "Use LuaLaTeX for LaTeX previews.")
  )


(customize-set-variable
 'org-agenda-window-setup 'only-window
 "org-agenda takes the whole window.")

;; (customize-set-variable
;;  'diary-time-format 12
;;  "set the time format to 12 hours (with am/pm) for emacs diary.") 

(customize-set-variable
 'org-agenda-restore-windows-after-quit t
 "Restore the window configuration on exit of org-agenda.")

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
 "Display links as the description provided.")

;; Visually indent org-mode files to a given header level
(add-hook 'org-mode-hook #'org-indent-mode)

;; make org mode tables pretty.
(add-hook
 'org-mode-hook (lambda () (org-pretty-table-mode)))

;; Hide markup markers
(customize-set-variable 'org-hide-emphasis-markers t)
(when (locate-library "org-appear")
  (add-hook 'org-mode-hook 'org-appear-mode))

;; Disable auto-pairing of "<" in org-mode with electric-pair-mode
(defun crafted-org-enhance-electric-pair-inhibit-predicate ()
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
          #'crafted-org-enhance-electric-pair-inhibit-predicate)

(add-hook 'org-mode-hook
          #'crafted-org-enhance-electric-pair-inhibit-predicate)

;; Render latex by default. 
(setq org-startup-with-latex-preview t)
;; Set the default format. 
(setq org-format-latex-header
"\\documentclass[12pt]{article}    % This sets the default font size to 10pt
\\usepackage[usenames]{color}
\\usepackage{xcolor}
\\usepackage{amsmath}
\\usepackage{amsfonts}
\\usepackage{amssymb}
\\usepackage{graphicx}
\\usepackage{fontspec}            % fontspec allows us to set the font 
\\setmainfont{source code pro}    % Set the font to Source Code Pro
\\usepackage{array}               % for specifying cell format
\\pagestyle{empty}                % Removes page numbers
\\color[HTML]{FFFFFF}             % Sets default text color to white")       

;;begin{document}

;; Set the scale of the latex object so it is bigger.
;;(default makes you squint)
(setq org-format-latex-options
      (plist-put org-format-latex-options :scale 0.25))


;; Set up holidays. 
(defvar holiday-australia-holidays
  (mapcar 'purecopy
          '((holiday-fixed 1 1 "New Year's Day")
            (holiday-float 1 1 2 "Australia Day")     ; Typically observed on the 26th, but can be floated for observance
            (holiday-fixed 4 25 "Anzac Day")
            (holiday-float 5 0 2 "Mother's Day")
            (holiday-float 6 1 2 "Queen's Birthday")  ; Varies by state, commonly second Monday in June
            (holiday-float 9 0 1 "Father's Day")
            (holiday-float 10 1 1 "Labour Day")       ; Varies by state, commonly first Monday in October in New South Wales
            (holiday-fixed 12 25 "Christmas Day")
            (holiday-fixed 12 26 "Boxing Day"))))

(defvar holiday-uk-holidays
  (mapcar 'purecopy
          '((holiday-fixed 1 1 "New Year's Day")
            (holiday-float 3 0 1 "Mother's Day")      ; Fourth Sunday in Lent, often in March
            (holiday-float 4 0 -2 "Good Friday")      ; Good Friday, two days before Easter Sunday
            (holiday-float 4 0 1 "Easter Sunday")     ; Easter Sunday, first Sunday after the first full moon on or after March 21
            (holiday-float 4 0 2 "Easter Monday")     ; Easter Monday, the day after Easter Sunday
                                                      ; First Monday in May
            (holiday-float 5 1 1 "Early May Bank Holiday") 
                                                      ; Last Monday in May
            (holiday-float 5 1 -1 "Spring Bank Holiday") 
            (holiday-float 6 0 3 "Father's Day")      ; Third Sunday in June
                                                      ; Last Monday in August
            (holiday-fixed 8 31 "Summer Bank Holiday") 
            (holiday-fixed 12 25 "Christmas Day")
            (holiday-fixed 12 26 "Boxing Day"))))

(defun combine-holiday-lists (&rest lists)
  "Combine multiple holiday lists, removing duplicates."
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
  '(calendar-nth-named-day 1 0 10 year))              ; First Sunday in October
(defvar  calendar-daylight-savings-ends
  '(calendar-nth-named-day 1 0 4 year))               ; First Sunday in April

    
;; Function to determine the current time zone offset
(defun my-set-calendar-time-zone ()
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
                                 660                  ; Daylight time (AEDT)
                               600))))                ; Standard time (AEST)

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
 'calendar-setup 'one-frame "Show calendar with diary entries.")

;; make the current day visible. 
(add-hook 'calendar-today-visible-hook 'calendar-mark-today)

(customize-set-variable
 'org-agenda-include-diary "integrate emacs diary in org-agenda.")
;; integrate org-agenda with emacs appointment functionality.
;; (org-agenda-to-appt) TODO: INVESTIGATE WHY THIS BREAKS THE UI. 


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
        ("t" "Todo with link to contact" entry (file+headline "~/org/todo.org" "Tasks")
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

(defun my-org/open-agenda-in-new-frame ()
  "Open Org agenda in a new frame named `agenda'."
  (interactive)
  (let ((frame (make-frame '((name . "agenda")))))
    (with-selected-frame frame
      (org-agenda-list)
      ;; Ensure the buffer is displayed in the new frame
      (switch-to-buffer (get-buffer "*Org Agenda*"))
      (delete-other-windows))))


;;; Define keymaps
(global-set-key (kbd "C-c l") #'org-store-link)
(global-set-key (kbd "C-c a") 'my-org/open-agenda-in-new-frame)
(global-set-key (kbd "C-c c") #'org-capture)

(provide 'custom-org-config)
;;; custom-org-config.el ends here

