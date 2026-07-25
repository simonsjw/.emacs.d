;;; speedbar-icons.el --- Enhanced Pretty Speedbar Icons -*- lexical-binding: t; -*-

;; Copyright (C) 2026 Simon Watson
;; SPDX-License-Identifier: MIT

;; Author: Simon Watson

;;; Commentary:
;; Improved icon system for Speedbar using pretty-speedbar.
;; Features:
;; - Base folder/file/tag icons
;; - File-type specific icons (different icon per extension)
;; - Re-entrant setup for daemon + client frames
;; - Easy to extend

;;; Code:

(require 'pretty-speedbar)
(require 'logging-config)
(require 'theme-support)
;;; ------------------------------------------------------------------
;;; 1. Base Icon Definitions (Nerd Font glyphs)
;;; ------------------------------------------------------------------

(defvar my-speedbar/base-icons
  '((folder          . "\uf07b")      ; Closed folder
    (folder-open     . "\uf07c")      ; Open folder
    (file            . "\uf15b")      ; Default file
    (file-open       . "\uf15c")
    (tag             . "\uf02b")
    (tag-group       . "\uf02c")
    (info            . "\uf05a")
    (mail            . "\uf0e0")
    (book            . "\uf02d")
    (box-closed      . "\uebb4")
    (box-open        . "\uebb5"))
  "Base Nerd Font icons used by Speedbar.")

;;; ------------------------------------------------------------------
;;; 2. File-Type Specific Icons (The Cool Part)
;;; ------------------------------------------------------------------

(defvar my-speedbar/file-type-icons
  '(;; Programming Languages
    ("el"     . "\ue632")      ; Emacs Lisp (λ)
    ("lisp"   . "\ue632")
    ("cl"     . "\ue632")
    ("py"     . "\ue235")      ; Python
    ("js"     . "\ue781")      ; JavaScript
    ("ts"     . "\ue628")      ; TypeScript
    ("rs"     . "\ue7a8")      ; Rust
    ("go"     . "\ue627")      ; Go
    ("java"   . "\ue256")      ; Java
    ("c"      . "\ue61e")      ; C
    ("cpp"    . "\ue61d")      ; C++
    ("h"      . "\ue61e")
    ("sh"     . "\ue795")      ; Shell
    ("bash"   . "\ue795")
    ("lua"    . "\ue620")      ; Lua

    ;; Markup / Config
    ("org"    . "\ue633")      ; Org-mode
    ("md"     . "\ue609")      ; Markdown
    ("markdown" . "\ue609")
    ("json"   . "\ue60b")      ; JSON
    ("yaml"   . "\ue60b")
    ("toml"   . "\ue60b")
    ("xml"    . "\ue619")
    ("html"   . "\ue60e")      ; HTML
    ("css"    . "\ue618")      ; CSS

    ;; Documents
    ("pdf"    . "\uf1c1")
    ("doc"    . "\uf1c2")
    ("docx"   . "\uf1c2")
    ("txt"    . "\uf15c")

    ;; Images
    ("png"    . "\uf1c5")
    ("jpg"    . "\uf1c5")
    ("jpeg"   . "\uf1c5")
    ("svg"    . "\uf1c5")
    ("gif"    . "\uf1c5")

    ;; Data / Other
    ("csv"    . "\uf1c3")
    ("sql"    . "\uf1c0")
    ("lock"   . "\uf023"))
  "Mapping from file extension to Nerd Font icon glyph.")

(defun my-speedbar/icon-for-file (filename)
  "Return the appropriate icon for FILENAME based on its extension.
Falls back to default file icon if no specific icon exists."
  (let* ((ext (downcase (or (file-name-extension filename) "")))
         (icon (cdr (assoc ext my-speedbar/file-type-icons))))
    (or icon (cdr (assoc 'file my-speedbar/base-icons)))))

;;; ------------------------------------------------------------------
;;; 3. Make File-Type Icons Actually Work (Advice)
;;; ------------------------------------------------------------------

(defun my-speedbar--insert-files-with-icons (orig-fun files level)
  "Advise speedbar-insert-files-at-point to use file-type specific icons."
  (let ((dirs (car files))
        (lst  (cadr files)))
    ;; Insert directories (unchanged)
    (dolist (dir dirs)
      (speedbar-make-tag-line 'angle ?+ 'speedbar-dired dir
                              dir 'speedbar-dir-follow nil
                              'speedbar-directory-face level))

    ;; Insert files with correct icon
    (dolist (file lst)
      (let* ((known (string-match speedbar-file-regexp file))
             (expchar (if known ?+ ??))
             (fn (if known 'speedbar-tag-file nil))
             (icon (my-speedbar/icon-for-file file)))

        ;; Temporarily override the default page icon
        (let ((pretty-speedbar-page icon)
              (pretty-speedbar-blank-page icon))
          (when (or speedbar-show-unknown-files (/= expchar ??))
            (speedbar-make-tag-line 'bracket expchar fn file
                                    file 'speedbar-find-file nil
                                    'speedbar-file-face level)))))))

(advice-add 'speedbar-insert-files-at-point :around #'my-speedbar--insert-files-with-icons)

;;; ------------------------------------------------------------------
;;; 3. Main Setup Function (Improved)
;;; ------------------------------------------------------------------

(defun my-speedbar/setup-pretty-icons ()
  "Set up pretty-speedbar with base + file-type specific icons.
Safe to call multiple times (daemon + client frames)."
  (require 'pretty-speedbar)

  (setq pretty-speedbar-icon-size 20
        pretty-speedbar-font "Symbols Nerd Font Mono")

  ;; Base icons
  (setq pretty-speedbar-folder          (list (cdr (assoc 'folder my-speedbar/base-icons)) t)
        pretty-speedbar-folder-open     (list (cdr (assoc 'folder-open my-speedbar/base-icons)) t)
        pretty-speedbar-blank-page      (cdr (assoc 'file my-speedbar/base-icons))
        pretty-speedbar-page            (cdr (assoc 'file-open my-speedbar/base-icons))
        pretty-speedbar-box-closed      (cdr (assoc 'box-closed my-speedbar/base-icons))
        pretty-speedbar-box-open        (cdr (assoc 'box-open my-speedbar/base-icons))
        pretty-speedbar-book            (cdr (assoc 'book my-speedbar/base-icons))
        pretty-speedbar-mail            (cdr (assoc 'mail my-speedbar/base-icons))
        pretty-speedbar-info            (cdr (assoc 'info my-speedbar/base-icons))
        pretty-speedbar-tags            (cdr (assoc 'tag-group my-speedbar/base-icons))
        pretty-speedbar-tag             (cdr (assoc 'tag my-speedbar/base-icons)))

  ;; Colours (customise these to match your theme)
  (setq pretty-speedbar-icon-fill        info-theme-light-white
        pretty-speedbar-icon-stroke      info-theme-dark-red
        pretty-speedbar-icon-folder-fill info-theme-dark-red
        pretty-speedbar-icon-folder-stroke info-theme-dark-red
        pretty-speedbar-about-fill       info-theme-dark-red
        pretty-speedbar-about-stroke     info-theme-light-white
        pretty-speedbar-signs-fill       info-theme-light-white)

  ;; Generate icons
  (when (fboundp 'pretty-speedbar-generate)
    (pretty-speedbar-generate))

  (log/info :fn 'my-speedbar/setup-pretty-icons
            :msg "Pretty icons (with file-type support) applied."
            :obj nil))

;;; ------------------------------------------------------------------
;;; 4. Toggle Between Pretty and Native Icons
;;; ------------------------------------------------------------------


(defun my-speedbar/toggle-pretty-icons ()
  "Toggle between pretty-speedbar and native ezimage icons (with file-type support)."
  (interactive)
  (setq my-speedbar/use-pretty-icons (not my-speedbar/use-pretty-icons))

  (if my-speedbar/use-pretty-icons
      (progn
        (my-speedbar/setup-pretty-icons)
        (message "Switched to Pretty Speedbar icons"))
    (progn
      ;; Native ezimage mode with file-type icons
      (setq ezimage-use-images t
            speedbar-use-images t)

      ;; Base native icons
      (setq ezimage-directory-plus    "\uf07b"
            ezimage-directory-minus   "\uf07c"
            ezimage-directory         "\uf07b"
            ezimage-page-plus         "\uf15b"
            ezimage-page-minus        "\uf15c"
            ezimage-page              "\uf15b"
            ezimage-tag               "\uf02b"
            ezimage-tag-plus          "\uf02c"
            ezimage-info-tag          "\uf05a"
            ezimage-mail              "\uf0e0"
            ezimage-box-plus          "\uebb4"
            ezimage-box-minus         "\uebb5")

      (message "Switched to native ezimage icons (file-type support enabled)")))

  (speedbar-refresh))

;;; ------------------------------------------------------------------
;;; 5. Hooks & Auto-Setup
;;; ------------------------------------------------------------------

;; Generate icons on first run if missing
(unless (file-exists-p (expand-file-name "pretty-folder.svg"
                                         pretty-speedbar-icons-dir))
  (pretty-speedbar-reload))

;; Auto-setup on Speedbar modes
(add-hook 'speedbar-mode-hook #'my-speedbar/setup-pretty-icons)
(add-hook 'speedbar-mode-hook
          (lambda ()
            (when (fboundp 'speedbar-refresh)
              (speedbar-refresh))))

(with-eval-after-load 'sr-speedbar
  (add-hook 'sr-speedbar-after-toggle-hook
            (lambda ()
              (when (fboundp 'my-speedbar/setup-pretty-icons)
                (my-speedbar/setup-pretty-icons))
              (when (fboundp 'sr-speedbar-refresh)
                (sr-speedbar-refresh)))))

(provide 'speedbar-icons)
;;; speedbar-icons.el ends here
