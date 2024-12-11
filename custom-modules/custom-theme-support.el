;;; custom-theme-support.el --- theme support for the crafted setup   -*- lexical-binding: t; -*-

;; Copyright (C) 2022
;; SPDX-License-Identifier: MIT

;; Author: System Crafters Community
;; Keywords: python

;;; Commentary:

;; This package handles the emacs themes settings. It is based on using modus-themes

(defvar modus-themes-mode-line)
(defvar modus-themes-region)
(defvar modus-themes-paren-match)
(defvar modus-themes-syntax)
(defvar modus-themes-fringes)
(defvar modus-themes-tabs-accented)
(defvar modus-themes-scale-headings)

(defvar log-font-lock-keywords)

(defvar doom-modeline-support-imenu)
(defvar doom-modeline-height)
(defvar doom-modeline-bar-width)
(defvar doom-modeline-hud)
(defvar doom-modeline-window-width-limit)
(defvar doom-modeline-project-detection)
(defvar doom-modeline-buffer-file-name-style)
(defvar doom-modeline-icon)
(defvar doom-modeline-major-mode-icon)
(defvar doom-modeline-major-mode-color-icon)
(defvar doom-modeline-buffer-state-icon)
(defvar doom-modeline-buffer-modification-icon)
(defvar doom-modeline-lsp-icon)
(defvar doom-modeline-time-icon)
(defvar doom-modeline-time-live-icon)
(defvar doom-modeline-time-analogue-clock)
(defvar doom-modeline-time-clock-size)
(defvar doom-modeline-unicode-fallback)
(defvar doom-modeline-buffer-name)
(defvar doom-modeline-highlight-modified-buffer-name)
(defvar doom-modeline-column-zero-based)
(defvar doom-modeline-percent-position)
(defvar doom-modeline-position-line-format)
(defvar doom-modeline-position-column-format)
(defvar doom-modeline-position-column-line-format)
(defvar doom-modeline-minor-modes)
(defvar doom-modeline-enable-word-count)
(defvar doom-modeline-continuous-word-count-modes)
(defvar doom-modeline-buffer-encoding)
(defvar doom-modeline-indent-info)
(defvar doom-modeline-total-line-number)
(defvar doom-modeline-vcs-icon)
(defvar doom-modeline-check-icon)
(defvar doom-modeline-check-simple-format)
(defvar doom-modeline-number-limit)
(defvar doom-modeline-vcs-max-length)
(defvar doom-modeline-workspace-name)
(defvar doom-modeline-persp-name)
(defvar doom-modeline-display-default-persp-name)
(defvar doom-modeline-persp-icon)
(defvar doom-modeline-lsp)
(defvar doom-modeline-github)
(defvar doom-modeline-github-interval)
(defvar doom-modeline-modal)
(defvar doom-modeline-modal-icon)
(defvar doom-modeline-modal-modern-icon)
(defvar doom-modeline-always-show-macro-register)
(defvar doom-modeline-gnus)
(defvar doom-modeline-gnus-timer)
(defvar doom-modeline-gnus-excluded-groups)
(defvar doom-modeline-irc)
(defvar doom-modeline-irc-stylize)
(defvar doom-modeline-battery)
(defvar doom-modeline-time)
(defvar doom-modeline-display-misc-in-all-mode-lines)
(defvar doom-modeline-buffer-file-name-function)
(defvar doom-modeline-buffer-file-truename-function)
(defvar doom-modeline-env-version)
(defvar doom-modeline-env-python-executable)
(defvar doom-modeline-env-ruby-executable)
(defvar doom-modeline-env-perl-executable)
(defvar doom-modeline-env-go-executable)
(defvar doom-modeline-env-elixir-executable)
(defvar doom-modeline-env-rust-executable)
(defvar doom-modeline-env-load-string)
(defvar doom-modeline-always-visible-segments)
(defvar doom-modeline-before-update-env-hook)
(defvar doom-modeline-after-update-env-hook)


;; code:


;; https://github.com/emacsmirror/rainbow-mode/blob/master/rainbow-mode.el
(use-package rainbow-mode)

;;; Modus-themes
;; https://github.com/protesilaos/modus-themes
(use-package modus-themes)

;;; Solaire mode
;; make background of virtual buffers slighly different to real (file based) ones.
;; https://github.com/hlissner/emacs-solaire-mode
(use-package solaire-mode)


;; https://github.com/rainstormstudio/nerd-icons.el
(use-package nerd-icons
  :custom
  ;; The Nerd Font you want to use in GUI
  ;; "Symbols Nerd Font Mono" is the default and is recommended
  ;; but you can use any other Nerd Font if you want
  (nerd-icons-font-family "Symbols Nerd Font Mono"))

(use-package nerd-icons-completion
  :after marginalia
  :config
  (nerd-icons-completion-mode)
  (add-hook 'marginalia-mode-hook #'nerd-icons-completion-marginalia-setup))

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
(use-package nerd-icons-ibuffer
  :hook (ibuffer-mode . nerd-icons-ibuffer-mode))

;; Ensure org-src is loaded for fontification
(require 'org-src)
(require 'org)
(require 'modus-themes)
(require 'solaire-mode)
(require 'custom-system-tools)
;;(require 'doom-modeline-core)
;;(require 'doom-modeline-env)
(require 'tab-line)
(solaire-global-mode +1)

;; Set up the custom info-theme colours.
;; -------------------------------------
;; info-theme is based on GNOME dark settings with Tango secondary colours.

;; object        |         text           |        background      |
;; -----------------------------------------------------------------
;; default       |  (white grey) #CCD0C8  |  (dark blue)  #1B152D  |  #D2D6CE #1B152D
;; Bold colour   |  (code green) #169C05  |                        |
;; Cursor colour |  (sharp lime) #A6BE00  |  (faded lime) #859900  |
;; Highlight     |  (grass)      #4F9C02  |  (drk bl/grn) #06313C  |
;;
;; Tango secondaries:
;; colour       |   light  |   flat   |
;; ------------------------------------
;; grey         |  #2E3436 |  #555753 |
;; red          |  #EF2929 |  #CC0000 |
;; green        |  #8AE234 |  #4E9A06 |
;; yellow       |  #FCE94F |  #C4A000 |
;; blue         |  #729FCF |  #3465A4 |
;; purple       |  #AD7FA8 |  #75507B |
;; cyan         |  #34E2E2 |  #06989A |
;; white        |  #EEEEEC |  #A8ACA4 |

;; Primary settings based on Gnome dark
(defvar info-theme-white-grey              "#D2D6CE")
(defvar info-theme-dark-grey               "#292D48")

(defvar info-theme-blue-steel              "#61647A")
(defvar info-theme-dark-blue               "#1B152D")

(defvar info-theme-bold-code-green         "#169C05")
(defvar info-theme-dark-blue-green         "#06313C")
(defvar info-theme-faded-lime              "#5A6800")
(defvar info-theme-sharp-lime              "#A6BE00")
(defvar info-theme-grass                   "#4F9C02")

(defvar info-theme-dark-red                "#9D1F1F")
(defvar info-theme-dark-orange             "#E54512")

(defvar info-theme-magenta                 "#EA5BBA")
(defvar info-theme-violet                  "#8E7BBB")

;; Tango secondary colours
(defvar info-theme-light-grey              "#989898")
(defvar info-theme-flat-grey               "#555753")

(defvar info-theme-light-red               "#EF2929")
(defvar info-theme-flat-red                "#CC0000")

(defvar info-theme-light-orange            "#CB4B16")
(defvar info-theme-magenta                 "#EA5BBA")

(defvar info-theme-light-green             "#8AE234")
(defvar info-theme-flat-green              "#4E9A06")

(defvar info-theme-light-yellow            "#FCE94F")
(defvar info-theme-flat-yellow             "#D7A13B")

(defvar info-theme-light-blue              "#729FCF")
(defvar info-theme-flat-blue               "#3465A4")

(defvar info-theme-light-purple            "#AD7FA8")
(defvar info-theme-flat-purple             "#75507B")

(defvar info-theme-light-cyan              "#34E2E2")
(defvar info-theme-flat-cyan               "#06989A")

(defvar info-theme-light-white             "#EEEEEC")
(defvar info-theme-flat-white              "#A8ACA4")


(defgroup my-custom-programming-faces nil
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
                             :family "fira code"))))

             '(fixed-pitch
               ((t (:inherit nil
                             :weight regular :height 100
                             :family "source code pro"))))

             '(variable-pitch
               ((t (:inherit nil
                             :weight regular :height 100
                             :family "times new roman"))))

             '(fixed-pitch-serif
               ((t (:inherit nil
                             :weight regular :height 100
                             :family "courier new"))))
             
             ;; Now generate the modus themes faces. 
             `(modus-themes-heading-0
               ((t (:foreground ,info-theme-white-grey  :weight regular :height 300
                                :family "Impact"))) t)

             `(modus-themes-heading-1
               ((t (:foreground ,info-theme-white-grey :weight regular  :height 200
                                :family "Impact"))) t)

             `(modus-themes-heading-2
               ((t (:foreground ,info-theme-white-grey :weight Bold :height 180
                                :family "arial"))) t)

             `(modus-themes-heading-3
               ((t (:foreground ,info-theme-white-grey :weight Bold :height 160
                                :family "arial"))) t)

             `(modus-themes-heading-4
               ((t (:foreground ,info-theme-white-grey :weight regular :height 140
                                :family "arial"))) t)

             `(modus-themes-heading-5
               ((t (:foreground ,info-theme-white-grey :weight regular :height 80
                                :family "arial"))) t)

             )

            (defface my-font-faces/prog-mode-face
              '((t :inherit fixed-pitch :weight normal :slant normal :height 100))
              "Prog-mode default face. "
              :group 'my-custom-programming-faces)

            ))

;; ** Customise the Modeline
;; Here we make sure that the modeline has the right 'fixed pitch' font.

;; Set the mode-line to have a simple font when active and when inactive.
;; (set-face-attribute 'mode-line nil
;;              :inherit 'fixed-pitch-serif :weight 'Bold :height 100)
;;(set-face-attribute 'mode-line-inactive nil
;;              :inherit 'fixed-pitch-serif :weight 'Bold :height 100)

;; Set the mode-line to have a simple font when active and when inactive.
;;(set-face-attribute 'mode-line nil
;;             :inherit 'fixed-pitch :weight 'Bold :height 80)
;;(set-face-attribute 'mode-line-inactive nil
;;             :inherit 'fixed-pitch :weight 'Bold :height 80)

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
;;  modus-themes-mode-line '(accented)            ; set modeline style

(setq
 modus-themes-common-palette-overrides
 ;; 5.10. Option for variable-pitch font in UI elements
 ;; modus-themes-variable-pitch-ui t
 ;; 5.11. Option for palette overrides                                         ; original values
 ;; bg: background
 ;; fg: foreground
 `((bg-main ,info-theme-dark-blue)                                             ; primary background "#0d0e1c"
   (bg-dim ,info-theme-dark-grey)                                              ; dimmed background  "#1d2235"
   (fg-main ,info-theme-white-grey)                                            ; primary font color "#ffffff"
   (fg-dim ,info-theme-flat-grey)                                              ; dimmed font colour  "#989898"
   (fg-alt ,info-theme-bold-code-green)                                        ; alt. font colour    "#c6daff"
   (bg-active ,info-theme-flat-grey)                                           ; "#042027"
   (bg-inactive ,info-theme-dark-grey)                                         ; "#2b3045"
   (border ,info-theme-white-grey)                                             ; "#61647a")

   ;; Do not alter colour definitions.
   ;; --------------------------------
   ;; (red "#ff5f59")
   ;; (red-warmer "#ff6b55")
   ;; (red-cooler "#ff7f9f")
   ;; (red-faint "#ff9f80")
   ;; (red-intense "#ff5f5f")
   ;; (green "#44bc44")
   ;; (green-warmer "#70b900")
   ;; (green-cooler "#00c06f")
   ;; (green-faint "#88ca9f")
   ;; (green-intense "#44df44")
   ;; (yellow "#d0bc00")
   ;; (yellow-warmer "#fec43f")
   ;; (yellow-cooler "#dfaf7a")
   ;; (yellow-faint "#d2b580")
   ;; (yellow-intense "#efef00")
   ;; (blue "#2fafff")
   ;; (blue-warmer "#79a8ff")
   ;; (blue-cooler "#00bcff")
   ;; (blue-faint "#82b0ec")
   ;; (blue-intense "#338fff")
   ;; (magenta "#feacd0")
   ;; (magenta-warmer "#f78fe7")
   ;; (magenta-cooler "#b6a0ff")
   ;; (magenta-faint "#caa6df")
   ;; (magenta-intense "#ff66ff")
   ;; (cyan "#00d3d0")
   ;; (cyan-warmer "#4ae2f0")
   ;; (cyan-cooler "#6ae4b9")
   ;; (cyan-faint "#9ac8e0")
   ;; (cyan-intense "#00eff0")
   ;; (rust "#db7b5f")
   ;; (gold "#c0965b")
   ;; (olive "#9cbd6f")
   ;; (slate "#76afbf")
   ;; (indigo "#9099d9")
   ;; (maroon "#cf7fa7")
   ;; (pink "#d09dc0")
   ;; (bg-red-intense "#9d1f1f")
   ;; (bg-green-intense "#2f822f")
   ;; (bg-yellow-intense "#7a6100")
   ;; (bg-blue-intense "#1640b0")
   ;; (bg-magenta-intense "#7030af")
   ;; (bg-cyan-intense "#2266ae")
   ;; (bg-red-subtle "#620f2a")
   ;; (bg-green-subtle "#00422a")
   ;; (bg-yellow-subtle "#4a4000")
   ;; (bg-blue-subtle "#242679")
   ;; (bg-magenta-subtle "#552f5f")
   ;; (bg-cyan-subtle "#004065")
   ;; (bg-red-nuanced "#350f14")
   ;; (bg-green-nuanced "#002718")
   ;; (bg-yellow-nuanced "#2c1f00")
   ;; (bg-blue-nuanced "#131c4d")
   ;; (bg-magenta-nuanced "#2f133f")
   ;; (bg-cyan-nuanced "#04253f")
   ;; (bg-graph-red-0 "#b52c2c")
   ;; (bg-graph-red-1 "#702020")
   ;; (bg-graph-green-0 "#0fed00")
   ;; (bg-graph-green-1 "#007800")
   ;; (bg-graph-yellow-0 "#f1e00a")
   ;; (bg-graph-yellow-1 "#b08940")
   ;; (bg-graph-blue-0 "#2fafef")
   ;; (bg-graph-blue-1 "#1f2f8f")
   ;; (bg-graph-magenta-0 "#bf94fe")
   ;; (bg-graph-magenta-1 "#5f509f")
   ;; (bg-graph-cyan-0 "#47dfea")
   ;; (bg-graph-cyan-1 "#00808f")

   (bg-completion bg-green-nuanced)                                            ; "#483d8a" selected completion line
   (bg-hover bg-green-nuanced)                                                 ; "#859900" example hover over hyper links
   (bg-hover-secondary bg-yellow-nuanced)                                      ; "#654a39"
   (bg-hl-line "#303a6f")                                                      ; "#303a6f"

   ;;  highlight current line
   (global-hl-line-mode 1)
   (bg-region "#484d67")                                                       ; "#555a66"
   (fg-region ,info-theme-white-grey)                                          ; "#ffffff"
   (bg-char-0 "#0050af")
   (bg-char-1 "#7f1f7f")
   (bg-char-2 "#625a00")

   (bg-mode-line-active ,info-theme-blue-steel)
   (fg-mode-line-active ,info-theme-white-grey)                                ;"#ffffff")
   (border-mode-line-active ,info-theme-white-grey)                            ; "#979797"
   (bg-mode-line-inactive ,info-theme-dark-grey)
   (fg-mode-line-inactive ,info-theme-light-grey)
   (border-mode-line-inactive ,info-theme-light-grey)
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

   ;; (bg-ochre "#442c2f")
   ;; (bg-lavender "#38325c")
   ;; (bg-sage "#0f3d30")

   (bg-paren-match ,info-theme-light-blue)
   (bg-paren-expression "#453040")
   (underline-paren-match unspecified)

   (fringe bg-dim)
   (cursor ,info-theme-sharp-lime)                                             ; magenta-warmer
   (keybind ,info-theme-flat-cyan)                                             ; blue-cooler
   (name ,info-theme-bold-code-green)                                          ; magenta
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
   (builtin ,info-theme-flat-yellow)                                           ; magenta-warmer
   (comment ,info-theme-flat-green)                                            ; red-faint
   (constant ,info-theme-violet)                                               ; blue-cooler
   (docstring ,info-theme-bold-code-green)                                     ; cyan-faint
   (docmarkup ,info-theme-faded-lime)                                          ; magenta-faint
   (fnname ,info-theme-dark-orange)                                            ; magenta
   (keyword ,info-theme-light-yellow)                                          ; magenta-cooler
   (preprocessor ,info-theme-flat-cyan)                                        ; red-cooler
   (string ,info-theme-light-blue)                                             ; blue-warmer
   (type ,info-theme-magenta)                                                  ; cyan-cooler
   (variable ,info-theme-magenta)                                              ; cyan
   (rx-construct ,info-theme-flat-white)                                       ; green-cooler
   (rx-backslash ,info-theme-flat-grey)                                        ; magenta

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

   (fg-heading-0 fg-main)                                                      ; cyan-cooler
   (fg-heading-1 fg-main)
   (fg-heading-2 fg-main)                                                      ; yellow-faint
   (fg-heading-3 fg-main)                                                      ; blue-faint
   (fg-heading-4 fg-main)                                                      ; magenta
   (fg-heading-5 ,info-theme-bold-code-green)                                  ; green-faint
   (fg-heading-6 ,info-theme-grass)                                            ; red-faint
   (fg-heading-7 ,info-theme-dark-blue-green)                                  ; cyan-faint
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
 modus-themes-custom-auto-reload t                                             ; Set Option for reloading the theme on custom change
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

 modus-themes-mode-line '(accented)            ; set modeline style
 modus-themes-region '(bg-only)
 modus-themes-paren-match '(bold intense)
 modus-themes-syntax '(faint)

 modus-themes-syntax '(alt-syntax)
 modus-themes-fringes '(subtle)
 modus-themes-tabs-accented t
 modus-themes-scale-headings t
 modus-themes-syntax '(green-strings yellow-comments))


;; (setq modus-themes-headings
;;       '(
;;         (agenda-date      . (                        1.3))
;;         (agenda-structure . (variable-pitch  light   1.8))
;;         (t                . (variable-pitch  regular 1.0))))

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



;;; DOOM emacs modeline
;; If non-nil, cause imenu to see `doom-modeline' declarations.
;; This is done by adjusting `lisp-imenu-generic-expression' to
;; include support for finding `doom-modeline-def-*' forms.
;; Must be set before loading doom-modeline.
(setq doom-modeline-support-imenu t)

;; How tall the mode-line should be. It's only respected in GUI.
;; If the actual char height is larger, it respects the actual height.
(setq doom-modeline-height 8)

;; How wide the mode-line bar should be. It's only respected in GUI.
(setq doom-modeline-bar-width 8)

;; Whether to use hud instead of default bar. It's only respected in GUI.
(setq doom-modeline-hud nil)

;; The limit of the window width.
;; If `window-width' is smaller than the limit, some information won't be
;; displayed. It can be an integer or a float number. `nil' means no limit."
(setq doom-modeline-window-width-limit 85)

;; How to detect the project root.
;; nil means to use `default-directory'.
;; The project management packages have some issues on detecting project root.
;; e.g. `projectile' doesn't handle symlink folders well, while `project' is unable
;; to hanle sub-projects.
;; You can specify one if you encounter the issue.
(setq doom-modeline-project-detection 'auto)

;; Determines the style used by `doom-modeline-buffer-file-name'.
;;
;; Given ~/Projects/FOSS/emacs/lisp/comint.el
;;   auto => emacs/l/comint.el (in a project) or comint.el
;;   truncate-upto-project => ~/P/F/emacs/lisp/comint.el
;;   truncate-from-project => ~/Projects/FOSS/emacs/l/comint.el
;;   truncate-with-project => emacs/l/comint.el
;;   truncate-except-project => ~/P/F/emacs/l/comint.el
;;   truncate-upto-root => ~/P/F/e/lisp/comint.el
;;   truncate-all => ~/P/F/e/l/comint.el
;;   truncate-nil => ~/Projects/FOSS/emacs/lisp/comint.el
;;   relative-from-project => emacs/lisp/comint.el
;;   relative-to-project => lisp/comint.el
;;   file-name => comint.el
;;   file-name-with-project => FOSS|comint.el
;;   buffer-name => comint.el<2> (uniquify buffer name)
;;
;; If you are experiencing the laggy issue, especially while editing remote files
;; with tramp, please try `file-name' style.
;; Please refer to https://github.com/bbatsov/projectile/issues/657.
(setq doom-modeline-buffer-file-name-style 'file-name-with-project)

;; Whether display icons in the mode-line.
;; While using the server mode in GUI, should set the value explicitly.
(setq doom-modeline-icon t)

;; Whether display the icon for `major-mode'.
;; It respects option `doom-modeline-icon'.
(setq doom-modeline-major-mode-icon t)

;; Whether display the colorful icon for `major-mode'.
;; It respects `nerd-icons-color-icons'.
(setq doom-modeline-major-mode-color-icon t)

;; Whether display the icon for the buffer state.
;; It respects option `doom-modeline-icon'.
(setq doom-modeline-buffer-state-icon t)

;; Whether display the modification icon for the buffer.
;; It respects option `doom-modeline-icon' and
;; option `doom-modeline-buffer-state-icon'.
(setq doom-modeline-buffer-modification-icon t)

;; Whether display the lsp icon. It respects option `doom-modeline-icon'.
(setq doom-modeline-lsp-icon t)

;; Whether display the time icon. It respects option `doom-modeline-icon'.
(setq doom-modeline-time-icon t)

;; Whether display the live icons of time.
;; It respects option `doom-modeline-icon' and option
;; `doom-modeline-time-icon'.
(setq doom-modeline-time-live-icon t)

;; Whether to use an analogue clock svg as the live time icon.
;; It respects options `doom-modeline-icon', `doom-modeline-time-icon',
;; and `doom-modeline-time-live-icon'.
(setq doom-modeline-time-analogue-clock t)

;; The scaling factor used when drawing the analogue clock.
(setq doom-modeline-time-clock-size 0.7)

;; Whether to use unicode as a fallback (instead of ASCII) when not using
;; icons.
(setq doom-modeline-unicode-fallback nil)

;; Whether display the buffer name.
(setq doom-modeline-buffer-name t)

;; Whether highlight the modified buffer name.
(setq doom-modeline-highlight-modified-buffer-name t)

;; When non-nil, mode line displays column numbers zero-based.
;; See `column-number-indicator-zero-based'.
(setq doom-modeline-column-zero-based t)

;; Specification of \"percentage offset\" of window through buffer.
;; See `mode-line-percent-position'.
(setq doom-modeline-percent-position '(-3 "%p"))

;; Format used to display line numbers in the mode line.
;; See `mode-line-position-line-format'.
(setq doom-modeline-position-line-format '("L%l"))

;; Format used to display column numbers in the mode line.
;; See `mode-line-position-column-format'.
(setq doom-modeline-position-column-format '("C%c"))

;; Format used to display combined line/column numbers in the mode line.
;; See `mode-line-position-column-line-format'.
(setq doom-modeline-position-column-line-format '("L%l:C%c"))

;; Whether display the minor modes in the mode-line.
(setq doom-modeline-minor-modes nil)

;; If non-nil, a word count will be added to the selection-info modeline segment.
(setq doom-modeline-enable-word-count nil)

;; Major modes in which to display word count continuously.
;; Also applies to any derived modes. Respects
;; `doom-modeline-enable-word-count'.
;; If it brings the sluggish issue, disable `doom-modeline-enable-word-count'
;; or remove the modes from `doom-modeline-continuous-word-count-modes'.
(setq doom-modeline-continuous-word-count-modes
      '(markdown-mode gfm-mode org-mode))

;; Whether display the buffer encoding.
(setq doom-modeline-buffer-encoding t)

;; Whether display the indentation information.
(setq doom-modeline-indent-info nil)

;; Whether display the total line number。
(setq doom-modeline-total-line-number nil)

;; Whether display the icon of vcs segment. It respects option
;; `doom-modeline-icon'."
(setq doom-modeline-vcs-icon t)

;; Whether display the icon of check segment. It respects option
;; `doom-modeline-icon'.
(setq doom-modeline-check-icon t)

;; If non-nil, only display one number for check information if applicable.
(setq doom-modeline-check-simple-format nil)

;; The maximum number displayed for notifications.
(setq doom-modeline-number-limit 99)

;; The maximum displayed length of the branch name of version control.
(setq doom-modeline-vcs-max-length 12)

;; Whether display the workspace name. Non-nil to display in the mode-line.
(setq doom-modeline-workspace-name t)

;; Whether display the perspective name. Non-nil to display in the mode-line.
(setq doom-modeline-persp-name t)

;; If non nil the default perspective name is displayed in the mode-line.
(setq doom-modeline-display-default-persp-name nil)

;; If non nil the perspective name is displayed alongside a folder icon.
(setq doom-modeline-persp-icon t)

;; Whether display the `lsp' state. Non-nil to display in the mode-line.
(setq doom-modeline-lsp t)

;; Whether display the GitHub notifications. It requires `ghub' package.
(setq doom-modeline-github nil)

;; The interval of checking GitHub.
(setq doom-modeline-github-interval (* 30 60))

;; Whether display the modal state.
;; Including `evil', `overwrite', `god', `ryo' and `xah-fly-keys', etc.
(setq doom-modeline-modal nil)

;; Whether display the modal state icon.
;; Including `evil', `overwrite', `god', `ryo' and `xah-fly-keys', etc.
(setq doom-modeline-modal-icon nil)

;; Whether display the modern icons for modals.
(setq doom-modeline-modal-modern-icon nil)

;; When non-nil, always show the register name when recording an evil macro.
(setq doom-modeline-always-show-macro-register nil)

;; Whether display the mu4e notifications. It requires `mu4e-alert' package.
;; (setq doom-modeline-mu4e nil)
;; also enable the start of mu4e-alert
;; (mu4e-alert-enable-mode-line-display)

;; Whether display the gnus notifications.
(setq doom-modeline-gnus t)

;; Whether gnus should automatically be updated and how often (set to 0 or
;; smaller than 0 to disable)
(setq doom-modeline-gnus-timer 2)

;; Wheter groups should be excludede when gnus automatically being updated.
(setq doom-modeline-gnus-excluded-groups '("dummy.group"))

;; Whether display the IRC notifications. It requires `circe' or `erc' package.
(setq doom-modeline-irc t)

;; Function to stylize the irc buffer names.
(setq doom-modeline-irc-stylize 'identity)

;; Whether display the battery status. It respects `display-battery-mode'.
(setq doom-modeline-battery nil)

;; Whether display the time. It respects `display-time-mode'.
(setq doom-modeline-time t)

;; Whether display the misc segment on all mode lines.
;; If nil, display only if the mode line is active.
(setq doom-modeline-display-misc-in-all-mode-lines nil)

;; The function to handle `buffer-file-name'.
(setq doom-modeline-buffer-file-name-function #'identity)

;; The function to handle `buffer-file-truename'.
(setq doom-modeline-buffer-file-truename-function #'identity)

;; Whether display the environment version.
(setq doom-modeline-env-version t)
;; Or for individual languages
;; (setq doom-modeline-env-enable-python t)
;; (setq doom-modeline-env-enable-ruby t)
;; (setq doom-modeline-env-enable-perl t)
;; (setq doom-modeline-env-enable-go t)
;; (setq doom-modeline-env-enable-elixir t)
;; (setq doom-modeline-env-enable-rust t)

;; Change the executables to use for the language version string
(setq doom-modeline-env-python-executable "python") ; or `python-shell-interpreter'
(setq doom-modeline-env-ruby-executable "ruby")
(setq doom-modeline-env-perl-executable "perl")
(setq doom-modeline-env-go-executable "go")
(setq doom-modeline-env-elixir-executable "iex")
(setq doom-modeline-env-rust-executable "rustc")

;; What to display as the version while a new one is being loaded
(setq doom-modeline-env-load-string "...")

;; By default, almost all segments are displayed only in the active window.
;; To display such segments in all windows, specify e.g.
(setq doom-modeline-always-visible-segments '(mu4e irc))

;; Hooks that run before/after the modeline version string is updated
(setq doom-modeline-before-update-env-hook nil)
(setq doom-modeline-after-update-env-hook nil)

;; Customise the fringes so they are the same colour as the buffer.
(my-theme-support/tone-down-fringes)

;; (custom-set-faces
;;  '(sr-speedbar-mode-line-face
;;    ((t (:height 1.5)))))

;;; ** tabline setup
;; In addition, customise the tabline and the modeline.
;; See:
;; [[https://jdhao.github.io/2021/09/30/emacs_custom_tabline/][Customise Tabline]]
;; for details of the tabline functions used in crafted-workspaces-support.el.
;; Here set the fonts and the colours for each window tab.
;; We also set up exclutions from tabbing based on modes found in the buffer
;; tab candidates.

(with-eval-after-load 'tab-line
  (setq tab-line-new-button-show t)                     ; show/do not show add-new button
  (setq tab-line-close-button-show t)                   ; show/do not show close button
  (setq tab-line-separator "")                          ; set it to empty

  (let ((bg
         (if (facep 'solaire-default-face)
             (face-attribute 'solaire-default-face :background nil 'default)
           (face-attribute 'default :background nil 'default)))

        (fg
         (face-attribute 'default :foreground nil 'default))

        (base
         (face-attribute 'mode-line :background nil 'default))

        (box-width
         (if (functionp 'line-pixel-height)
             (/ (line-pixel-height) 5)
           1)))                                         ; Fallback to 1 if line-pixel-height is undefined

    (when
        (and bg fg base)
      (set-face-attribute 'tab-line nil                 ; BACKGROUND BEHIND TABS
                          :family "fixed-pitch"
                          :background base
                          :foreground fg
                          :height 100
                          :inherit nil
                          :box `(:line-width -1 :color ,base))

      (set-face-attribute 'tab-line-tab nil             ; ACTIVE TAB IN ANOTHER WINDOW
                          :family "fixed-pitch"
                          :foreground fg
                          :background bg
                          :weight 'normal
                          :inherit nil
                          :box `(:line-width ,box-width :color ,bg))

      (set-face-attribute 'tab-line-tab-inactive nil    ; INACTIVE TAB
                          :family "fixed-pitch"
                          :foreground fg
                          :background base
                          :weight 'normal
                          :inherit nil
                          :box `(:line-width ,box-width :color ,base))

      (set-face-attribute 'tab-line-tab-current nil     ; ACTIVE TAB CONTAINING BUFFER WITH FOCUS
                          :family "fixed-pitch"
                          :foreground fg
                          :background bg
                          :weight 'normal
                          :inherit nil
                          :box `(:line-width ,box-width :color ,bg))

      (set-face-attribute 'tab-line-highlight nil       ; TAB WITH MOUSE-OVER
                          :family "fixed-pitch"
                          :foreground fg
                          :background bg
                          :weight 'normal
                          :inherit nil
                          :box `(:line-width ,box-width :color ,bg)))))




(provide 'custom-theme-support)
;;; custom-theme-support.el ends here
