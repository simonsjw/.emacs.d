;;; speedbar-config.el --- Core Speedbar configuration and faces -*- lexical-binding: t; -*-

;; Copyright (C) 2026 Simon Watson
;; SPDX-License-Identifier: MIT

;; Author: Simon Watson

;;; Commentary:
;; All basic customizations, variables, and faces for Speedbar.

;;; Code:

(require 'speedbar)
(require 'sr-speedbar)
(require 'path-support)
(require 'theme-support)
;; ----------------------------------------------------------------------
;; pretty-speedbar (icon package) - must load early
;; ----------------------------------------------------------------------
(use-package pretty-speedbar
  :load-path my-paths/pretty-speedbar
  :ensure nil
  :demand t
  :custom
  (ezimage-use-images t)
  (speedbar-use-images t)
  :config
  ;; Generate icons on first run if missing
  (unless (file-exists-p (expand-file-name "pretty-folder.svg"
                                           pretty-speedbar-icons-dir))
    (pretty-speedbar-reload))

  ;; Apply our custom icon setup (defined in speedbar-icons.el)
  (when (fboundp 'my-speedbar/setup-pretty-icons)
    (my-speedbar/setup-pretty-icons)))

(custom-set-variables
 '(speedbar-indentation-width 3)
 '(speedbar-directory-button-trim-method 'trim)
 '(speedbar-update-flag t)
 '(semantic-sb-info-format-tag-function 'semantic-format-tag-short-doc)
 '(speedbar-vc-do-check t)
 '(speedbar-show-unknown-files t)
 '(speedbar-smart-directory-expand-flag t)
 '(speedbar-directory-unshown-regexp "^\\(CVS\\|RCS\\|SCCS\\|\\.\\.*$\\)\\'")
 '(speedbar-add-supported-extension
   '(".cl" ".li?sp" ".lua" ".fnl" ".fennel" ".kt" ".mvn" ".gradle" ".properties"
     ".cljs?" ".sh" ".bash" ".php" ".ts" ".html?" ".css" ".less" ".scss" ".sass"
     ".py" ".p" ".q" ".k" ".rs" ".lock" "makefile" "MAKEFILE" "Makefile"
     ".json" ".yaml" ".toml" ".md" ".markdown" ".org" ".txt" "README"))
 '(sr-speedbar-auto-refresh t)
 '(sr-speedbar-max-width 170)
 '(sr-speedbar-width 40)
 '(sr-speedbar-right-side nil))

;; Faces (minimal — colours primarily handled via theme)
(custom-set-faces
 `(speedbar-button-face ((t (:foreground ,info-theme-white-grey))))
 `(speedbar-directory-face ((t (:foreground ,info-theme-white-grey))))
 `(speedbar-file-face ((t (:foreground ,info-theme-white-grey))))
 '(speedbar-selected-face ((t (:foreground "gray98" :underline nil))))
 `(speedbar-highlight-face ((t (:inherit 'popup-menu-selection-face))))
 `(speedbar-tag-face ((t (:inherit 'font-lock-variable-name-face))))
 `(speedbar-separator-face ((t (:inherit 'org-level-2
                                         :foreground ,info-theme-white-grey
                                         :background ,info-theme-dark-blue)))))

(provide 'speedbar-config)
;;; speedbar-config.el ends here
