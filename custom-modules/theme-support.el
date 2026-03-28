;;; theme-support.el --- theme support for the crafted setup   -*- lexical-binding: t; -*-

;; Copyright (C) 2022
;; SPDX-License-Identifier: MIT

;; Author: Simon Watson
;; Keywords: colour color theme font face

;;; Commentary:

;; This module handles the Emacs themes settings.
;; good doom-themes: pale-night, material and grovbox.

;;; Code:

(require 'path-support)
(require 'logging-config)
(log/debug :fn 'theme-support
           :msg "Starting load of the theme-support module."
           :obj t)

;; rainbow-mode variables.
;; (defvar rainbow-x-colors)                                                         ; Disable color names like "red"
;; (defvar rainbow-x-colors-font-lock-keywords)                                      ; Set to nil to stop any color names being highlighted (including customs)
;; (defvar rainbow-latex-rgb-colors)                                                 ; Enable LaTeX rgb colors
;; (defvar rainbow-rgb-colors-font-lock-keywords)                                    ; Enable rgb(...) colors
;; (defvar rainbow-info-theme-colors)                                                ; Enable the system theme colour keywords.
;; (defvar rainbow-hexadecimal-colors-font-lock-keywords)
;; primary system colours
(defvar info-theme-white-grey)
(defvar info-theme-dark-grey)
(defvar info-theme-blue-steel)
(defvar info-theme-dark-blue)
(defvar info-theme-bold-code-green)
(defvar info-theme-dark-blue-green)
(defvar info-theme-faded-lime)
(defvar info-theme-sharp-lime)
(defvar info-theme-dark-green)
(defvar info-theme-dark-red)
(defvar info-theme-dark-orange)
(defvar info-theme-magenta)
(defvar info-theme-violet)
;; secondary system colours
(defvar info-theme-light-grey)
(defvar info-theme-flat-grey)
(defvar info-theme-light-red)
(defvar info-theme-flat-red)
(defvar info-theme-light-orange)
(defvar info-theme-light-green)
(defvar info-theme-flat-green)
(defvar info-theme-light-yellow)
(defvar info-theme-flat-yellow)
(defvar info-theme-light-blue)
(defvar info-theme-flat-blue)
(defvar info-theme-light-purple)
(defvar info-theme-flat-purple)
(defvar info-theme-light-cyan)
(defvar info-theme-flat-cyan)
(defvar info-theme-light-white)
(defvar info-theme-flat-white)

;;(defvar my-paths/custom-rainbow-mode)
(defvar log-font-lock-keywords)

(defvar corfu-margin-formatters)

(declare-function my-theme-support/tone-down-fringes "system-tools")
(declare-function color-dark-p "faces")
;; (declare-function rainbow-mode "rainbow-mode")

;; Icons
;; https://github.com/rainstormstudio/nerd-icons.el
(use-package nerd-icons
  :custom
  ;; The Nerd Font you want to use in GUI
  ;; "Symbols Nerd Font Mono" is the default and is recommended
  ;; but you can use any other Nerd Font if you want
  (nerd-icons-font-family "Symbols Nerd Font Mono"))

(use-package nerd-icons-completion
  :if (display-graphic-p)
  :after marginalia
  ;; FIXME 2024-09-01: For some reason this stopped working because it
  ;; macroexpands to `marginalia-mode' instead of
  ;; `marginalia-mode-hook'.  What is more puzzling is that this does
  ;; not happen in the next :hook...
  ;; :hook (marginalia-mode . nerd-icons-completion-marginalia-setup))
  :config
  (nerd-icons-completion-mode)
  (add-hook 'marginalia-mode-hook #'nerd-icons-completion-marginalia-setup))


;; https://github.com/rainstormstudio/nerd-icons-dired
(use-package nerd-icons-dired
  :if (display-graphic-p)
  :hook
  (dired-mode . nerd-icons-dired-mode))

(use-package rainbow-mode
  :defer t)


;; https://github.com/LuigiPiucco/nerd-icons-corfu
(use-package nerd-icons-corfu
  :if (display-graphic-p)
  :after corfu
  :config
  (add-to-list 'corfu-margin-formatters #'nerd-icons-corfu-formatter))

(declare-function nerd-icons-corfu-formatter "nerd-icons-corfu")

;;; Modus-themes
;; https://github.com/protesilaos/modus-themes
;; (use-package modus-themes)

(declare-function nerd-icons-completion-mode "nerd-icons-completion")
(declare-function nerd-icons-completion-marginalia-setup "nerd-icons-completion")

;; https://github.com/rainstormstudio/nerd-icons-dired
(use-package nerd-icons-dired
  :hook
  (dired-mode . nerd-icons-dired-mode))

;; https://github.com/LuigiPiucco/nerd-icons-corfu
(use-package nerd-icons-corfu
  :after corfu
  :config
  (add-to-list 'corfu-margin-formatters #'nerd-icons-corfu-formatter))

;; Optionally:
;; (setq nerd-icons-corfu-mapping
;;       '((array :style "cod" :icon "symbol_array" :face font-lock-type-face)
;;         (boolean :style "cod" :icon "symbol_boolean" :face font-lock-builtin-face)
;;         ;; ...
;;         (t :style "cod" :icon "code" :face font-lock-warning-face)))
;; Remember to add an entry for `t', the library uses that as default.
;; The Custom interface is also supported for tuning the variable above.

;; https://github.com/seagle0128/nerd-icons-ibuffer
;; (use-package nerd-icons-ibuffer
;;   :hook (ibuffer-mode . nerd-icons-ibuffer-mode))

;; Ensure org-src is loaded for fontification
(require 'org-src)
(require 'org)
;; (require 'modus-themes)
(require 'tab-line)
;; (require 'rainbow-mode)

;; Set up the custom info-theme colours.
;; -------------------------------------
;; info-theme is based on GNOME dark settings with Tango secondary colours.

;; object        |          text           |        background      |
;; -----------------------------------------------------------------
;; default       |  (flat green)  #4E9A06  |  (dark blue)  #1B152D  |
;; Bold colour   |  (light green) #8AE234  |                        |
;; Cursor colour |  (sharp lime)  #CFD400  |  (faded lime) #859B00  |
;; Highlight     |  (light green) #8AE234  |  (dark green) #092f1f  |
;;
;; Tango secondaries:
;; colour       |   light  |   flat   |
;; ------------------------------------
;; grey         |  #989898 |  #555753 |
;; red          |  #FF3535 |  #CC0000 |
;; green        |  #8AE234 |  #4E9A06 |
;; yellow       |  #FCE94F |  #C4A000 |
;; blue         |  #729FCF |  #3465A4 |   "#00BFFF"
;; purple       |  #AD7FA8 |  #75507B |
;; cyan         |  #34E2E2 |  #06989A |
;; white        |  #EEEEEC |  #A8ACA4 |

;; Primary settings based on Gnome dark
;; Group colors into primary and secondary categories

(defvar my-colors/info-theme-colors
  '(
    (:primary
     (info-theme-white-grey . "#D2D6CE")
     (info-theme-dark-grey . "#292D48")
     (info-theme-blue-steel . "#4A4F6A")
     (info-theme-dark-blue . "#1B152D")
     (info-theme-bold-code-green . "#169C05") ;; "#4B9A00"
     (info-theme-dark-blue-green . "#06313C")
     (info-theme-faded-lime . "#859B00")
     (info-theme-sharp-lime . "#CFD400")
     (info-theme-dark-green . "#092f1f")
     (info-theme-dark-red . "#A13423") ;; #A13423  #9D1F1F
     (info-theme-dark-orange . "#E54512")
     (info-theme-magenta . "#EA5BBA")
     (info-theme-violet . "#8E7BBB"))
    
    (:secondary
     (info-theme-light-grey . "#989898")
     (info-theme-flat-grey . "#555753")
     
     (info-theme-light-red . "#FF3535")
     (info-theme-flat-red . "#CC0000")
     
     (info-theme-light-orange . "#CB4B16")
     ;; repeat of  magenta here - need to use alternative.
     
     (info-theme-light-green . "#8AE234")
     (info-theme-flat-green . "#4E9A06")
     
     (info-theme-light-yellow . "#FCE94F")
     (info-theme-flat-yellow . "#D7A13B")
     
     (info-theme-light-blue . "#729FCF")
     (info-theme-flat-blue . "#3465A4")
     
     (info-theme-light-purple . "#AD7FA8")
     (info-theme-flat-purple . "#75507B")
     
     (info-theme-light-cyan . "#34E2E2")
     (info-theme-flat-cyan . "#06989A")
     
     (info-theme-light-white . "#EEEEEC")
     (info-theme-flat-white . "#A8ACA4")))
  "Primary and secondary colours for the info-theme colour scheme.")


(defun my-colors/overwrite-color-variables-by-group (color-scheme)
  "Define color variables for colors in COLOR-SCHEME.

Overwrite existing `defvar`s if needed.  COLOR-SCHEME should be a list of
groups, each containing cons cells with color name and value."
  (dolist (group color-scheme)
    (let ((group-name (car group))
          (colors (cdr group)))
      (message "Processing group: %s" group-name)
      (dolist (color-pair colors)
        (let ((var-name  (car color-pair))                                        ; Convert string to symbol
              (color-code (cdr color-pair)))                                      ; Extract hex color
          ;; Check if the variable is already defined
          (if (boundp var-name)
              ;; Overwrite existing variable
              (progn
                (set var-name color-code)
                (put var-name 'variable-documentation
                     (format "Color variable for %s (group: %s)."
                             var-name  group-name))
                (message "Updated variable: %s = %s" var-name color-code))
            ;; Dynamically define a new variable with `defvar`
            (eval `(defvar ,var-name ,color-code
                     ,(format "Color variable for %s (group: %s)."
                              var-name group-name)))
            (message "Defined new variable: %s = %s" var-name color-code)))))))


(my-colors/overwrite-color-variables-by-group my-colors/info-theme-colors)        ; Generate the individual variables.

(defun my-colors/extract-theme-colors (color-scheme)
  "Extract a flat list of (name . color) pairs from COLOR-SCHEME.

Converts keys to strings and ensures values are strings."
  (let (flat-colors)
    (dolist (group color-scheme)
      (setq flat-colors
            (append flat-colors
                    (mapcar (lambda (pair)
                              (cons (symbol-name (car pair)) (cdr pair)))
                            (cdr group)))))
    flat-colors))


(defgroup my-faces/programming nil
  "Custom font faces for programming modes."
  :group 'faces)


;; Set up the default fonts
;; ------------------------
;; Height is in 1/10 of a point so :height 120 is a 12 point font size.
(add-hook 'emacs-startup-hook
          (lambda ()
            ;; Set the main faces.
            (custom-set-faces

             `(default
               ((t (:inherit nil
                             :weight regular :height 100
                             :family "Noto Mono"))))   ;; fira code

             '(fixed-pitch
               ((t (:inherit nil
                             :weight regular :height 100
                             :family "Source Code Pro"))))

             '(variable-pitch
               ((t (:inherit nil
                             :weight regular :height 100
                             :family "Times New Roman"))))

             '(fixed-pitch-serif
               ((t (:inherit nil
                             :weight regular :height 100
                             :family "Courier New"))))

             ;; Now generate the modus themes faces.
             `(modus-themes-heading-0
               ((t (:foreground ,info-theme-white-grey  :weight Bold
                                :height 150
                                :family "Impact")))
               t)

             `(modus-themes-heading-1
               ((t (:foreground ,info-theme-white-grey :weight Bold
                                :height 140 :family "arial")))
               t)

             `(modus-themes-heading-2
               ((t (:foreground ,info-theme-white-grey :weight Bold
                                :height 130 :family "arial")))
               t)

             `(modus-themes-heading-3
               ((t (:foreground ,info-theme-white-grey :weight Bold
                                :height 120 :family "arial")))
               t)

             `(modus-themes-heading-4
               ((t (:foreground ,info-theme-white-grey :weight regular
                                :height 120 :family "arial")))
               t)

             `(modus-themes-heading-5
               ((t (:foreground ,info-theme-white-grey :weight regular
                                :height 80 :family "arial")))
               t)

             )

            (defface my-font-faces/prog-mode-face
              '((t :inherit fixed-pitch :weight normal
                   :slant normal
                   :height 100))
              "Prog-mode default face. "
              :group 'my-faces/programming)

            (defface my-font-faces/mode-line-clicked
              `((t :inherit 'mode-line-highlight
                   :background ,info-theme-sharp-lime))
              "The face for elements currently `clicked' on the modeline. "
              :group 'my-faces/programming)))



;; ** Customise the Minibuffer
;; Here we make sure that the modeline has the right 'fixed pitch' font.
;; Set the mode-line to have a simple font when active and when inactive.
;;(set-face-attribute 'minibuffer-prompt nil
;;             :inherit 'fixed-pitch :weight 'Bold :height 100)

;;(buffer-face-set :family "fixed-pitch" :weight 'bold :height 120)

;; below the next section, see also these toggles to apply modeline styling with modus-themes.
;; modus-themes-variable-pitch-ui nil
;; Advanced customization
;; 6.2. Stylistic variants using palette overrides
;; modus-themes-mode-line '(accented)            ; set modeline style

(setq
 modus-themes-common-palette-overrides
 ;; 5.10. Option for variable-pitch font in UI elements
 ;; modus-themes-variable-pitch-ui t
 ;; 5.11. Option for palette overrides                                            ; original values
 ;; bg: background
 ;; fg: foreground
 `((bg-main ,info-theme-dark-blue)                                                ; primary background "#0d0e1c"
   (bg-dim ,info-theme-dark-grey)                                                 ; dimmed background  "#1d2235"
   (fg-main ,info-theme-white-grey)                                               ; primary font color "#ffffff"
   (fg-dim ,info-theme-flat-grey)                                                 ; dimmed font colour  "#989898"
   (fg-alt ,info-theme-bold-code-green)                                           ; alt. font colour    "#c6daff"
   (bg-active ,info-theme-flat-grey)                                              ; "#042027"
   (bg-inactive ,info-theme-dark-grey)                                            ; "#2b3045"
   (border ,info-theme-white-grey)                                                ; "#61647a")

   (bg-completion bg-green-nuanced)                                               ; "#483d8a" selected completion line
   (bg-hover bg-green-nuanced)                                                    ; "#859900" example hover over hyper links
   (bg-hover-secondary bg-yellow-nuanced)                                         ; "#654a39"
   (bg-hl-line "#303a6f")                                                         ; "#303a6f"

   ;;  highlight current line
   (global-hl-line-mode 1)
   (bg-region "#484d67")                                                          ; "#555a66"
   (fg-region ,info-theme-white-grey)                                             ; "#ffffff"
   (bg-char-0 "#0050af")
   (bg-char-1 "#7f1f7f")
   (bg-char-2 "#625a00")

   (bg-mode-line-active ,info-theme-blue-steel)
   (fg-mode-line-active ,info-theme-white-grey)                                   ;"#ffffff")
   (border-mode-line-active ,info-theme-white-grey)                               ; "#979797"
   (bg-mode-line-inactive ,info-theme-dark-grey)
   (fg-mode-line-inactive ,info-theme-light-grey)
   (border-mode-line-inactive ,info-theme-blue-steel)
   (modeline-err "#ffa9bf")
   (modeline-warning "#dfcf43")
   (modeline-info "#9fefff")

   (bg-tab-bar "#2c3045")
   (bg-tab-current "#0d0e1c")
   (bg-tab-other "#4a4f6a")

   (bg-added "#003a2f")
   (bg-added-faint "#002922")
   (bg-added-refine "#035542")
   (bg-added-fringe "#23884f")
   (fg-added "#a0e0a0")
   (fg-added-intense "#80e080")

   (bg-changed "#363300")
   (bg-changed-faint "#2a1f00")
   (bg-changed-refine "#4a4a00")
   (bg-changed-fringe "#8f7a30")
   (fg-changed "#efef80")
   (fg-changed-intense "#c0b05f")

   (bg-removed "#4f1127")
   (bg-removed-faint "#380a19")
   (bg-removed-refine "#781a3a")
   (bg-removed-fringe "#b81a26")
   (fg-removed "#ffbfbf")
   (fg-removed-intense "#ff9095")

   (bg-diff-context "#1a1f30")

   (bg-paren-match ,info-theme-light-blue)
   (bg-paren-expression "#453040")
   (underline-paren-match unspecified)

   (fringe bg-dim)
   (cursor ,info-theme-sharp-lime)                                                ; magenta-warmer
   (keybind ,info-theme-flat-cyan)                                                ; blue-cooler
   (name ,info-theme-bold-code-green)                                             ; magenta
   (identifier ,info-theme-flat-yellow)
   (err red)
   (warning yellow-warmer)
   (info cyan-cooler)
   (underline-err red-intense)
   (underline-warning yellow)
   (underline-note cyan)
   (bg-prominent-err bg-red-intense)
   (fg-prominent-err fg-main)
   (bg-prominent-warning bg-yellow-intense)
   (fg-prominent-warning fg-main)
   (bg-prominent-note bg-cyan-intense)
   (fg-prominent-note fg-main)

   ;; Coding colour formats
   (builtin ,info-theme-flat-yellow)                                              ; magenta-warmer
   (comment ,info-theme-flat-green)                                               ; red-faint
   (constant ,info-theme-violet)                                                  ; blue-cooler
   (docstring ,info-theme-bold-code-green)                                        ; cyan-faint
   (docmarkup ,info-theme-faded-lime)                                             ; magenta-faint
   (fnname ,info-theme-dark-orange)                                               ; magenta
   (keyword ,info-theme-light-yellow)                                             ; magenta-cooler
   (preprocessor ,info-theme-flat-cyan)                                           ; red-cooler
   (string ,info-theme-light-blue)                                                ; blue-warmer
   (type ,info-theme-magenta)                                                     ; cyan-cooler
   (variable ,info-theme-magenta)                                                 ; cyan
   (rx-construct ,info-theme-flat-white)                                          ; green-cooler
   (rx-backslash ,info-theme-flat-grey)                                           ; magenta

   (accent-0 blue-cooler)
   (accent-1 magenta-warmer)
   (accent-2 cyan-cooler)
   (accent-3 yellow)

   (fg-button-active fg-main)
   (fg-button-inactive fg-dim)
   (bg-button-active bg-active)
   (bg-button-inactive bg-dim)

   (fg-completion-match-0 blue-cooler)
   (fg-completion-match-1 magenta-warmer)
   (fg-completion-match-2 cyan-cooler)
   (fg-completion-match-3 yellow)
   (bg-completion-match-0 unspecified)
   (bg-completion-match-1 unspecified)
   (bg-completion-match-2 unspecified)
   (bg-completion-match-3 unspecified)

   (date-common cyan)
   (date-deadline red)
   (date-event fg-alt)
   (date-holiday red-cooler)
   (date-now fg-main)
   (date-range fg-alt)
   (date-scheduled yellow-warmer)
   (date-weekday cyan)
   (date-weekend red-faint)

   (fg-line-number-inactive fg-dim)
   (fg-line-number-active fg-main)
   (bg-line-number-inactive bg-dim)
   (bg-line-number-active bg-active)

   (fg-link blue-warmer)
   (bg-link unspecified)
   (underline-link unspecified)

   (fg-link-symbolic cyan)
   (bg-link-symbolic unspecified)
   (underline-link-symbolic unspecified)

   (fg-link-visited magenta)
   (bg-link-visited unspecified)
   (underline-link-visited unspecified)

   (mail-cite-0 blue-warmer)
   (mail-cite-1 yellow-cooler)
   (mail-cite-2 cyan-cooler)
   (mail-cite-3 red-cooler)
   (mail-part blue)
   (mail-recipient magenta-cooler)
   (mail-subject magenta-warmer)
   (mail-other magenta-faint)

   (bg-mark-delete bg-red-subtle)
   (fg-mark-delete red-cooler)
   (bg-mark-select bg-cyan-subtle)
   (fg-mark-select cyan)
   (bg-mark-other bg-yellow-subtle)
   (fg-mark-other yellow)

   (fg-prompt cyan-cooler)
   (bg-prompt unspecified)

   (bg-space-err bg-red-intense)

   (prose-block fg-dim)
   (prose-code cyan-cooler)
   (prose-done green)
   (prose-macro magenta-cooler)
   (prose-metadata fg-dim)
   (prose-metadata-value fg-alt)
   (prose-table fg-alt)
   (prose-tag magenta-faint)
   (prose-todo red)
   (prose-verbatim magenta-warmer)

   (rainbow-0 fg-main)
   (rainbow-1 magenta-intense)
   (rainbow-2 cyan-intense)
   (rainbow-3 red-warmer)
   (rainbow-4 yellow-intense)
   (rainbow-5 magenta-cooler)
   (rainbow-6 green-intense)
   (rainbow-7 blue-warmer)
   (rainbow-8 magenta-warmer)

   (bg-space unspecified)
   (fg-space border)

   (fg-heading-0 fg-main)                                                         ; cyan-cooler
   (fg-heading-1 fg-main)
   (fg-heading-2 fg-main)                                                         ; yellow-faint
   (fg-heading-3 fg-main)                                                         ; blue-faint
   (fg-heading-4 fg-main)                                                         ; magenta
   (fg-heading-5 ,info-theme-bold-code-green)                                     ; green-faint
   (fg-heading-6 ,info-theme-flat-green)                                          ; red-faint
   (fg-heading-7 ,info-theme-dark-blue-green)                                     ; cyan-faint
   (fg-heading-8 fg-dim)
   (bg-heading-0 unspecified)
   (bg-heading-1 unspecified)
   (bg-heading-2 unspecified)
   (bg-heading-3 unspecified)
   (bg-heading-4 unspecified)
   (bg-heading-5 unspecified)
   (bg-heading-6 unspecified)
   (bg-heading-7 unspecified)
   (bg-heading-8 unspecified)

   (overline-heading-0 unspecified)
   (overline-heading-1 unspecified)
   (overline-heading-2 unspecified)
   (overline-heading-3 unspecified)
   (overline-heading-4 unspecified)
   (overline-heading-5 unspecified)
   (overline-heading-6 unspecified)
   (overline-heading-7 unspecified)
   (overline-heading-8 unspecified)))

(setq
 ;; 5.2. Option for disabling other themes while loading Modus
 modus-themes-disable-other-themes t
 ;; 5.3. Option for more bold constructs
 modus-themes-bold-constructs t
 ;; 5.4. Option for more italic constructs
 modus-themes-italic-constructs t
 ;; 5.5. Option for font mixinv
 modus-themes-mixed-fonts t
 modus-themes-variable-pitch-ui nil
 modus-themes-custom-auto-reload t                                                ; Set Option for reloading the theme on custom change
 ;; 5.6. Option for command prompt styles
 modus-themes-prompts '(bold intense)
 ;; 5.7. Option for completion framework aesthetics
 modus-themes-completions
 '((matches . (bold))
   (selection . (semibold)))
 ;; 5.8. Option for org-mode block styles
 org-fontify-whole-block-delimiter-line t
 ;; modus-themes-org-blocks 'tinted-background
 org-src-fontify-natively t
 org-fontify-quote-and-verse-blocks t
 ;; 5.9. Option for the headings' overall style
                                                                                  ; the style for all other levels.

 ;; Advanced customization
 ;; 6.1 Palette override presets
 ;; 6.2. Stylistic variants using palette overrides

 ;;  modus-themes-mode-line '(accented)            ; set modeline style
 modus-themes-region '(bg-only)
 modus-themes-paren-match '(bold intense)
 modus-themes-syntax '(faint)

 modus-themes-syntax '(alt-syntax)
 modus-themes-fringes '(subtle)
 modus-themes-tabs-accented t
 modus-themes-scale-headings t
 modus-themes-syntax '(green-strings yellow-comments))

(setq modus-themes-headings
      '(
        (agenda-date      . (                        1.3))
        (agenda-structure . (variable-pitch  light   1.8))
        (t                . (variable-pitch  regular 1.0))))

;; 8. Advanced customization
;; 8.13. DIY Use colored Org source blocks per language
;; The author of modus themes does not recommend this
;; method because it hardcodes values and thus requires
;; `org-mode-restart' every time you change a theme.
;; here is an example of how he suggests doing it:
;;           ("css" modus-themes-nuanced-red)
;;           ("scss" modus-themes-nuanced-red)
;;           ("yaml" modus-themes-nuanced-cyan)
;; (defun my-modus-themes-org-block-faces (&rest _)
;;   (modus-themes-with-colors
;;     (setq org-src-block-faces
;;           `(("emacs-lisp" (:inherit fixed-pitch :background "#f7f5f3"))
;;             ("elisp" (:inherit fixed-pitch :background ,bg-magenta-nuanced))
;;             ("clojure" (:inherit fixed-pitch :background ,bg-magenta-nuanced))
;;             ("clojurescript" (:inherit fixed-pitch :background ,bg-magenta-nuanced))
;;             ("c" (:inherit fixed-pitch :background ,bg-blue-nuanced))
;;             ("c++" (:inherit fixed-pitch :background ,bg-blue-nuanced))
;;             ("sh" (:inherit fixed-pitch :background ,bg-yellow-nuanced))
;;             ("shell" (:inherit fixed-pitch :background ,bg-yellow-nuanced))
;;             ("python" (:inherit fixed-pitch  :background ,bg-yellow-nuanced))
;;             ("ipython" (:inherit fixed-pitch :background ,bg-yellow-nuanced))
;;             ("r" (:inherit fixed-pitch :background ,bg-yellow-nuanced))
;;             ("html" (:inherit fixed-pitch :background ,bg-green-nuanced))
;;             ("xml" (:inherit fixed-pitch :background ,bg-green-nuanced))
;;             ("css" (:inherit fixed-pitch :background ,bg-red-nuanced))
;;             ("scss" (:inherit fixed-pitch :background ,bg-red-nuanced))
;;             ("yaml" (:inherit fixed-pitch :background ,bg-cyan-nuanced))
;;             ("conf" (:inherit fixed-pitch :background ,bg-cyan-nuanced))
;;             ("docker" (:inherit fixed-pitch :background ,bg-cyan-nuanced))))))

;; (add-hook 'modus-themes-after-load-theme-hook #'my-modus-themes-org-block-faces)


;; first turn off the deeper-blue theme
(disable-theme 'deeper-blue)

;; load the theme with variables set.
(load-theme 'modus-vivendi-tinted t)

;; set the org source block faces after loading modus-themes to
;; overwrite any changes it made (workaround!)
(setq org-src-block-faces
      `(("emacs-lisp" (:background "#1B1B1B" :extend t))
        ("elisp" (:background "#1B1B1B" :extend t))
        ("clojure" (:background "#555753" :extend t))
        ("clojurescript" (:background "#555753" :extend t))
        ("c" (:background "#2B2601" :extend t))
        ("c++" (:background "#2B2601" :extend t))
        ("sh" (:background "#092B01" :extend t))
        ("shell" (:background "#092B01" :extend t))
        ("bash" (:background "#092B01" :extend t))
        ("python" (:background "#081d47" :extend t))
        ("ipython" (:background "#081d47" :extend t))
        ("r" (:background "#555753" :extend t))
        ("html" (:background "#212121" :extend t))
        ("css" (:background "#212121" :extend t))
        ("scss" (:background "#212121" :extend t))
        ("yaml" (:background "#06313C" :extend t))
        ("json" (:background "#06313C" :extend t))
        ("xml" (:background "#06313C" :extend t))
        ("conf" (:background "#555753" :extend t))
        ("docker"  (:background "#0db7ed" :extend t))))

;; Customise the fringes so they are the same colour as the buffer.
(my-theme-support/tone-down-fringes)

;; prefer symbols most for icons.
(custom-set-variables  '(icon-preference '(symbol image text emoji)))

;; (custom-set-faces
;;  '(sr-speedbar-mode-line-face
;;    ((t (:height 1.5)))))

(defun my-visual/apply-all-customisations ()
  "Final production version — deep dark-blue dividers + pretty icons.
Purpose:
  Strong frame-local divider override (survives sr-speedbar) + safe icon setup.
  No direct refresh here (moved to idle-timer in speedbar hooks).
Efficiency: early return, frame-local remap, <35 lines."
  (when (display-graphic-p)
    ;; === Thick deep dark-blue dividers — frame-local override (survives everything) ===
    (setq window-divider-default-right-width 8
          window-divider-default-bottom-width 8)
    (window-divider-mode 1)

    (let ((dark-blue (or info-theme-dark-blue "#1B152D")))
      (set-face-attribute 'window-divider nil
                          :foreground dark-blue :background dark-blue)
      (set-face-attribute 'window-divider-first-pixel nil
                          :foreground dark-blue)
      (set-face-attribute 'window-divider-last-pixel nil
                          :foreground dark-blue))

    ;; === Icon path + setup (no refresh) ===
    (let ((icon-dir (expand-file-name "pretty-speedbar-icons/"
                                      (or user-emacs-directory
                                          (expand-file-name "~/.emacs.d/" (getenv "HOME"))))))
      (when (and (stringp icon-dir) (file-directory-p icon-dir))
        (add-to-list 'image-load-path icon-dir t)
       ;; (setq speedbar-use-images t)
        (when (fboundp 'my-speedbar/setup-pretty-icons)
          (my-speedbar/setup-pretty-icons))

        (log/info :fn 'my-visual/apply-all-customisations
                  :msg "Pretty speedbar icons path + setup applied"
                  :obj nil)
        )))

  (my-theme-support/tone-down-fringes)

  (log/info :fn 'my-visual/apply-all-customisations
            :msg "Core visuals applied (frame-local dividers)."
            :obj (selected-frame)))

(with-eval-after-load 'sr-speedbar
  (my-visual/apply-all-customisations))


(log/debug :fn 'theme-support
           :msg "Ending the load of the theme-support module."
           :obj t)

(provide 'theme-support)
;;; theme-support.el ends here

