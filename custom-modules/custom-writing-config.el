;;;; custom-writing-config.el --- Configuration for writing text documents  -*- lexical-binding: t; -*-

;; Copyright (C) 2023
;; SPDX-License-Identifier: MIT

;; Author: Simon Watson (based on system-crafters template)

;;; Commentary:

;; Configures Markdown, LaTeX, and general text editing in Emacs.

;;; Code:


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

;;; parentheses
(electric-pair-mode 1) ; auto-insert matching bracket
(show-paren-mode 1)    ; turn on paren match highlighting

;;; configure citar
(setq citar-templates
      '((main . "${author editor:30%sn}     ${date year issued:4}     ${title:48}")
        (suffix . "          ${=key= id:15}    ${=type=:12}    ${tags keywords:*}")
        (preview . "${author editor:%etal} (${year issued date}) ${title}, ${journal journaltitle publisher container-title collection-title}.\n")
        (note . "Notes on ${author editor:%etal}, ${title}")))

;;; LaTeX configuration
(with-eval-after-load 'tex
  (customize-set-variable 'TeX-auto-save t)
  (customize-set-variable 'TeX-parse-self t)
  (setq-default TeX-master nil)

  ;; This line tells AUCTeX to use LuaTeX engine
  ;;(setq TeX-engine 'luatex)
  (customize-set-variable
   'TeX-engine 'luatex "Use LuaLaTeX as the default LaTeX engine.")

  ;; Ensure AUCTeX generates PDFs by default
  (setq TeX-PDF-mode t)
  
  ;; Enable source correlation to map between source code and PDF viewer.
  (TeX-source-correlate-mode)

  ;; Custom indentation for specific LaTeX environments.
  ;; `lstlisting`: Used for code listings.
  ;; `tikzcd`: Used for commutative diagrams (indentation aligns with tables).
  ;; `tikzpicture`: Used for TikZ graphics.
  (add-to-list 'LaTeX-indent-environment-list '("lstlisting" current-indentation))
  (add-to-list 'LaTeX-indent-environment-list '("tikzcd" LaTeX-indent-tabular))
  (add-to-list 'LaTeX-indent-environment-list '("tikzpicture" current-indentation))

  ;; Define `verbatim` environments to prevent LaTeX from auto-formatting text.
  ;; This applies especially to code, ensuring it appears as-is.
  (add-to-list 'LaTeX-verbatim-environments "lstlisting")
  (add-to-list 'LaTeX-verbatim-environments "Verbatim")
  (add-to-list 'LaTeX-verbatim-macros-with-braces "lstinline")
  (add-to-list 'LaTeX-verbatim-macros-with-delims "lstinline")


  ;; Enable electric pairs for sub- and superscripts, braces, and `$` symbols.
  ;; This makes it easier to enter LaTeX math environments and brackets.
  (customize-set-variable 'TeX-electric-sub-and-superscript t)
  (customize-set-variable 'LaTeX-electric-left-right-brace t)
  (customize-set-variable 'TeX-electric-math (cons "$" "$"))

  ;; Automatically enable `auto-fill-mode` for line wrapping in LaTeX files.
  ;; Enables `LaTeX-math-mode` for easier input of math symbols.
  (add-hook 'LaTeX-mode-hook #'auto-fill-mode)
  (add-hook 'LaTeX-mode-hook #'LaTeX-math-mode)

  ;; Turn on RefTeX, a powerful tool for managing references, citations, and
  ;; cross-references in LaTeX.
  ;; Citar and RefTeX
  (add-hook 'LaTeX-mode-hook #'turn-on-reftex)
  (add-hook 'LaTeX-mode-hook #'citar-refresh)
  (customize-set-variable 'reftex-plug-into-AUCTeX t)

  ;; Automatically refresh the PDF buffer after compilation to keep it up-to-date.
  (add-hook 'TeX-after-compilation-finished-functions
            #'TeX-revert-document-buffer)

;;; PDF Support when using pdf-tools
  ;; PDF Tools configuration to replace the default viewer with PDF Tools
  ;; (if available) for synchronized viewing of the compiled document.
  (defun my-tex/latex-use-pdf-tools ()
    "Use PDF Tools instead of docview, requires a build environment
to compile PDF Tools and on having `pdf-tools'."
    (require 'pdf-tools nil :noerror)
    (with-eval-after-load 'tex
      ;; Select PDF Tools as the default viewer for PDFs.
      (customize-set-variable 'TeX-view-program-selection '((output-pdf "PDF Tools")))
      
      ;; Add PDF Tools to the program list, enabling source sync between TeX and PDF.
      (customize-set-variable 'TeX-view-program-list '(("PDF Tools" "TeX-pdf-tools-sync-view")))
      
      ;; Start the server for source correlation to sync the PDF viewer with LaTeX source.
      (customize-set-variable 'TeX-source-correlate-start-server t)))

  (when (locate-library "pdf-tools")
    ;; load pdf-tools when going into doc-view-mode
    (add-hook 'doc-view-mode-hook #'my-tex/latex-use-pdf-tools)

    ;; when pdf-tools is loaded, apply settings.
    (with-eval-after-load 'pdf-tools
      (setq-default pdf-view-display-size 'fit-width)))

  ;; Check if `latex` and `latexmk` executables are available and configure
  ;; AUCTeX to use `latexmk` for building documents.
  ;; message the user if the latex executable is not found

  ;; Check for `latex` and `latexmk`, configure AUCTeX to use `latexmk`
  (defun my-tex/latex-warning-if-no-executable ()
    "Notify if `latex` executable not found."
    (unless (executable-find "latex")
      (message "latex executable not found")))

  (add-hook 'tex-mode-hook #'my-tex/latex-warning-if-no-executable)

  (when (and (executable-find "latex") (executable-find "latexmk"))
    (when (require 'auctex-latexmk nil 'noerror)
      (auctex-latexmk-setup)
      (customize-set-variable 'auctex-latexmk-inherit-TeX-PDF-mode t)
      ;; Set up Biber as the default for bibliography management
      (setq TeX-command-list (delete '("Biber" "biber %s" TeX-run-BibTeX nil t :help "Run Biber") TeX-command-list))
      (add-to-list 'TeX-command-list '("Biber" "biber %s" TeX-run-BibTeX nil t :help "Run Biber"))
      (setq bibtex-dialect 'biblatex)
      (setq TeX-command-default "LatexMk"))))

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

;; provide a means of calling a temp org buffer without underlying file.
;;(global-set-key (kbd "C-c t") 'my-buffer-tools/open-temp-org-buffer)

(provide 'custom-writing-config)
;;; custom-writing-config.el ends here

