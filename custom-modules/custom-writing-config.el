;;;; custom-writing-config.el --- Configuration for writing text documents  -*- lexical-binding: t; -*-

;; Copyright (C) 2023
;; SPDX-License-Identifier: MIT

;; Author: Simon Watson (based on system-crafters template)

;;; Commentary:

;; Configures Markdown, LaTeX, and general text editing in Emacs.

;;; Code:

(defvar citar-templates)
(defvar TeX-auto-save)
(defvar TeX-parse-self)
(defvar TeX-master)
(defvar TeX-engine)
(defvar TeX-PDF-mode)
(defvar reftex-plug-into-AUCTeX)
(defvar LaTeX-indent-environment-list)
(defvar LaTeX-verbatim-environments)
(defvar LaTeX-verbatim-macros-with-braces)
(defvar LaTeX-verbatim-macros-with-delims)
(defvar LaTeX-electric-left-right-brace)
(defvar TeX-command-default)
(defvar TeX-electric-sub-and-superscript)
(defvar TeX-electric-math)
(defvar TeX-view-program-selection)
(defvar TeX-view-program-list)
(defvar TeX-source-correlate-start-server)
(defvar TeX-output-dir)
(defvar TeX-command-extra-options)
(defvar auctex-latexmk-inherit-TeX-PDF-mode)
(defvar bibtex-dialect)

(declare-function flyspell-mode-on "flyspell")
(declare-function auto-fill-mode "simple")
(declare-function LaTeX-math-mode "tex")
(declare-function TeX-source-correlate-mode "tex")
(declare-function yas-minor-mode-on "yasnippet")
(declare-function conditionally-turn-on-pandoc "pandoc-mode")
(declare-function TeX-revert-document-buffer "tex")
(declare-function pdf-tools-install "pdf-tools")
(declare-function auctex-latexmk-setup "auctex")

(use-package markdown-mode)                                                       ; Markdown support
(use-package flymake-markdownlint)                                                ; lint markdown in flymake if markdownlint-cli is installed. 
(use-package pandoc-mode)
(use-package olivetti)

;; PDF support
(use-package pdf-tools
  :config
  (pdf-tools-install))

;; LaTeX support - uses Auctex
;; only install and load auctex when the latex executable is found,
;; otherwise it crashes when loading
(when (executable-find "latex")
  (use-package auctex)
  ;; Install the auctex-latexmk package when the latex and latexmk
  ;; executable are found.
  ;;
  ;; This package contains a bug which might make it crash during loading
  ;; (with a bug related to tex-buf) on newer systems.
  ;;
  ;; If you encounter the bug, you should uninstall this package, then
  ;; you can install a fix (not on melpa) with the following recipe,
  ;; and the configuration in this file will still work
  ;;
  ;; (N.B. the recipe is for straight.el, but can be modified for use with Emacs
  ;;       29 package-vc, quelpa.el, or other \"from source\" package
  ;;       managers.)
  ;;
  ;; '(auctex-latexmk :fetcher git :host github :repo \"wang1zhen/auctex-latexmk\")
  (when (executable-find "latexmk")
    (use-package auctex-latexmk)))

(use-package citar
  :custom
  (citar-bibliography (list (getenv "BIB_HOME")))                                 ; Wrap in `list` to ensure it's a list
  :hook
  (LaTeX-mode . citar-capf-setup)
  (org-mode . citar-capf-setup))

(use-package citar-embark
  :after citar embark
  :no-require
  :config (citar-embark-mode))

;;; Whitespace
(defun crafted-writing-configure-whitespace
    (use-tabs &optional use-globally &rest enabled-modes)
  "Helper function to configure `whitespace' mode.

Enable using TAB characters if USE-TABS is non-nil.  If
USE-GLOBALLY is non-nil, turn on `global-whitespace-mode'.  If
ENABLED-MODES is non-nil, it will be a list of modes to activate
whitespace mode using hooks.  The hooks will be the name of the
mode in the list with `-hook' appended.  If USE-GLOBALLY is
non-nil, ENABLED-MODES is ignored.

Configuring whitespace mode is not buffer local.  So calling this
function twice with different settings will not do what you
think.  For example, if you wanted to use spaces instead of tabs
globally except for in Makefiles, doing the following won't work:

;; turns on global-whitespace-mode to use spaces instead of tabs
(crafted-writing-configure-whitespace nil t)

;; overwrites the above to turn to use tabs instead of spaces,
;; does not turn off global-whitespace-mode, adds a hook to
;; makefile-mode-hook
(crafted-writing-configure-whitespace t nil 'makefile-mode)

Instead, use a configuration like this:
;; turns on global-whitespace-mode to use spaces instead of tabs
(crafted-writing-configure-whitespace nil t)

;; turn on the buffer-local mode for using tabs instead of spaces.
(add-hook 'makefile-mode-hook #'indent-tabs-mode)

For more information on `indent-tabs-mode', See the info
node `(emacs)Just Spaces'

Example usage:

;; Configuring whitespace mode does not turn on whitespace mode
;; since we don't know which modes to turn it on for.
;; You will need to do that in your configuration by adding
;; whitespace mode to the appropriate mode hooks.
(crafted-writing-configure-whitespace nil)

;; Configure whitespace mode, but turn it on globally.
(crafted-writing-configure-whitespace nil t)

;; Configure whitespace mode and turn it on only for prog-mode
;; and derived modes.
(crafted-writing-configure-whitespace nil nil 'prog-mode)"
  (if use-tabs
      (customize-set-variable 'whitespace-style
                              '(face empty trailing indentation::tab
                                     space-after-tab::tab
                                     space-before-tab::tab))
    ;; use spaces instead of tabs
    (customize-set-variable 'whitespace-style
                            '(face empty trailing tab-mark
                                   indentation::space)))
  (if use-globally
      (global-whitespace-mode 1)
    (when enabled-modes
      (dolist (mode enabled-modes)
        (add-hook (intern (format "%s-hook" mode))
                  #'whitespace-mode))))
  ;; cleanup whitespace
  (customize-set-variable
   'whitespace-action '(cleanup auto-cleanup)))


;;; configure citar
(setq citar-templates
      '((main . "${author editor:30%sn}     ${date year issued:4}     ${title:48}")
        (suffix . "          ${=key= id:15}    ${=type=:12}    ${tags keywords:*}")
        (preview . "${author editor:%etal} (${year issued date}) ${title}, ${journal journaltitle publisher container-title collection-title}.\n")
        (note . "Notes on ${author editor:%etal}, ${title}")))


;;; Markdown support
(when (fboundp 'markdown-mode)
  (unless (or (bound-and-true-p markdown-command)
              (executable-find "markdown")
              (executable-find "pandoc"))
    (message "No Markdown processor found; preview may not be possible."))
  (with-eval-after-load 'markdown-mode
    (customize-set-variable 'markdown-enable-math t)
    (customize-set-variable 'markdown-enable-html t)
    (add-hook 'markdown-mode-hook #'conditionally-turn-on-pandoc)))

;; Check for `latex`
(defun my-lang-tex/latex-warning-if-no-executable ()
  "Notify if `latex` executable not found."
  (unless (executable-find "latex")
    (message "latex executable not found")))

(defun my-lang-tex/latex-setup ()
  "Configure LaTeX environment for writing and editing."
  (my-lang-tex/latex-warning-if-no-executable)

  ;; turn on flyspell.
  (flyspell-mode-on)

  ;; Point latex at the current directory. 

  ;; Delay Corfu drop-downs.
  (customize-set-variable 'corfu-auto-delay 0.25)

  ;; AUCTeX Settings
  (setq TeX-auto-save t
        TeX-parse-self t
        TeX-master (if (or (buffer-file-name)
                           (string-match "main\\.tex" (buffer-file-name)))
                       "main"
                     nil)
        TeX-engine 'luatex                                                     ; Use LuaLaTeX as the default LaTeX engine.
        TeX-PDF-mode t                                                         ; Ensure AUCTeX generates PDFs by default
        reftex-plug-into-AUCTeX t
        ;; Set output directory for latexmk or other compilers
        TeX-output-dir (file-name-directory (buffer-file-name))
        TeX-command-extra-options
        (concat "-cd -output-directory="
                (file-name-directory (buffer-file-name))))

  ;; Automatically refresh the PDF buffer after compilation to keep it up-to-date.
  (add-hook
   'TeX-after-compilation-finished-functions #'TeX-revert-document-buffer)

  ;; Enable useful modes
  (TeX-source-correlate-mode 1)                                                ; Enable source correlation to map between source code and PDF viewer.
  (auto-fill-mode 1)                                                           ; Automatically enable `auto-fill-mode` for line wrapping in LaTeX files.
  (LaTeX-math-mode 1)                                                          ; Enables `LaTeX-math-mode` for easier input of math symbols.
  (yas-minor-mode-on)

  ;; Turn on RefTeX, a powerful tool for managing references, citations, and
  ;; cross-references in LaTeX.
  ;; Citar and RefTeX
  (when (fboundp 'citar-refresh) (citar-refresh))
  (turn-on-reftex)

  ;; Custom indentation for specific LaTeX environments.
  ;; `lstlisting`: Used for code listings.
  ;; `tikzcd`: Used for commutative diagrams (indentation aligns with tables).
  ;; `tikzpicture`: Used for TikZ graphics.
  ;; (add-to-list 'LaTeX-indent-environment-list '("lstlisting" current-indentation))
  ;; (add-to-list 'LaTeX-indent-environment-list '("tikzcd" LaTeX-indent-tabular))
  ;; (add-to-list 'LaTeX-indent-environment-list '("tikzpicture" current-indentation))
  (dolist (env '("lstlisting" "tikzcd" "tikzpicture"))
    (add-to-list
     'LaTeX-indent-environment-list (cons env 'current-indentation)))

  ;; Verbatim environments
  ;; Define `verbatim` environments to prevent LaTeX from auto-formatting text.
  ;; This applies especially to code, ensuring it appears as-is.
  ;; (add-to-list 'LaTeX-verbatim-environments "lstlisting")
  ;; (add-to-list 'LaTeX-verbatim-environments "Verbatim")
  ;; (add-to-list 'LaTeX-verbatim-macros-with-braces "lstinline")
  ;; (add-to-list 'LaTeX-verbatim-macros-with-delims "lstinline")
  (dolist (env '("lstlisting" "Verbatim"))
    (add-to-list 'LaTeX-verbatim-environments env))
  (dolist (macro '("lstinline"))
    (add-to-list 'LaTeX-verbatim-macros-with-braces macro)
    (add-to-list 'LaTeX-verbatim-macros-with-delims macro))

  ;; parentheses
  (electric-pair-mode 1) ; auto-insert matching bracket
  (show-paren-mode 1)    ; turn on paren match highlighting

  ;; Enable electric pairs for sub- and superscripts, braces, and `$` symbols.
  ;; This makes it easier to enter LaTeX math environments and brackets.
  (setq TeX-electric-sub-and-superscript t
        LaTeX-electric-left-right-brace t
        TeX-electric-math (cons "$" "$"))

  ;; PDF Tools integration if available
  (when (and (require 'pdf-tools nil 'noerror)
             (executable-find "pdf-tools"))
    (setq TeX-view-program-selection '((output-pdf "PDF Tools"))
          TeX-view-program-list '(("PDF Tools" "TeX-pdf-tools-sync-view"))
          TeX-source-correlate-start-server t)
    (pdf-tools-install))

  ;; Check if `latexmk` is executables are available and configure
  ;; AUCTeX to use `latexmk` for building documents.
  ;; message the user if the latex executable is not found
  (when (and (executable-find "latexmk") (require 'auctex-latexmk nil 'noerror))
    (auctex-latexmk-setup)
    ;; ("Biber" "biber %s" TeX-run-BibTeX nil t :help "Run Biber")

    (setq TeX-command-default "LatexMk"
          auctex-latexmk-inherit-TeX-PDF-mode t
          bibtex-dialect 'biblatex))
  ;; when pdf-tools is loaded, apply settings.
  (with-eval-after-load 'pdf-tools
    (setq-default pdf-view-display-size 'fit-width))
  )

;; Hook the function to LaTeX mode
(add-hook 'LaTeX-mode-hook 'my-lang-tex/latex-setup)


;; provide a means of calling a temp org buffer without underlying file.
;;(global-set-key (kbd "C-c t") 'my-buffer-tools/open-temp-org-buffer)

(provide 'custom-writing-config)
;;; custom-writing-config.el ends here


                                                                                  ; LocalWords:  pandoc citar whitespace tex lstinline TikZ lstlisting LatexMk etal executables tikzpicture makefile Biber delims auctex yasnippet
