;;;; writing-config.el --- Configuration for writing text documents  -*- lexical-binding: t; -*-

;; Copyright (C) 2023
;; SPDX-License-Identifier: MIT

;; Author: Simon Watson (based on system-crafters template)

;;; Commentary:

;; Configures Markdown, LaTeX, and general text editing in Emacs.
;; Prioritises efficiency by lazy-loading where possible, clarity via docstrings,
;; and readability by decomposing long functions.

;;; Code:
(require 'path-support)
(require 'logging-config)
(log/debug :fn 'writing-config
           :msg "Starting load of the writing-config module."
           :obj t)


(use-package markdown-mode)                                                       ; Markdown support
(use-package flymake-markdownlint)                                                ; Lint markdown in flymake if markdownlint-cli is installed.
(use-package pandoc-mode)
(use-package olivetti)


(use-package markdown-toc
  :ensure t
  :config
  (add-hook 'markdown-mode-hook #'markdown-toc-mode))

;; PDF support
;; -----------
;; First ensure you have the right tools installed:
;; # Install pdf-tools dependencies for Ubuntu/Debian.
;; sudo apt update
;; sudo apt install -y libpoppler-dev libpoppler-glib-dev libcairo2-dev libpng-dev zlib1g-dev libglib2.0-dev make
;; # Optional: For following image links in PDFs.
;; sudo apt install -y libmagickwand-dev
;; # Optional: Ubuntu-packaged epdfinfo binary to skip manual compile (if available in 24.04 repos).
;; sudo apt install -y elpa-pdf-tools-server
(package-initialize)
(use-package pdf-tools
  :ensure t
  :defer t                                                                        ; Defer full load until needed.
  :hook
  (pdf-view-mode . pdf-history-minor-mode)                                        ; Enable history in PDF buffers.
  (pdf-view-mode . pdf-misc-size-indication-minor-mode)                           ; Enable size indicators in PDF buffers.
  :config
  (pdf-occur-global-minor-mode 1))                                                ; Global search mode (safe here, as it's not buffer-dependent).


(use-package pdf-loader
  :ensure pdf-tools                                                               ; Pulls from pdf-tools package.
  :demand t                                                                       ; Load immediately to define autoloads.
  :config
  (pdf-loader-install :no-query))                                                 ; Sets up on-demand; no build prompt.

;; Defer global modes explicitly—add this new block.
;;(with-eval-after-load 'pdf-tools
;;  (pdf-occur-global-minor-mode 1)       ; Enable only after full load.
;;  (pdf-history-minor-mode 1) ; Optional: Defer history if it errors too.
;;  (pdf-misc-size-indication-minor-mode 1)) ; Optional: For size indicators.                                           ; Sets up autoloads; no build prompt.



;; LaTeX support - uses Auctex
;; Only install and load auctex when the latex executable is found,
;; otherwise it crashes when loading.
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

(when (executable-find "latex")
  (use-package auctex
    :ensure t
    :defer t                                                                      ; Defer until LaTeX-mode.
    :hook (LaTeX-mode . my-lang-tex/latex-setup)                                  ; Existing hook.
    :config
    ;; Wait for tex.el to load before setting viewer vars.
    (eval-after-load 'tex
      '(when (require 'pdf-tools nil 'noerror)
         (add-to-list 'TeX-view-program-selection
                      '(output-pdf "PDF Tools"))
         (add-to-list 'TeX-view-program-list
                      '("PDF Tools" TeX-pdf-tools-sync-view)))))
  (use-package cdlatex))

(when (executable-find "latexmk")
  (use-package auctex-latexmk
    :ensure t
    :after auctex                                                                 ; Ensure after AUCTeX.
    :config
    (auctex-latexmk-setup)))


(use-package citar
  :custom
  (citar-bibliography (list (getenv "BIB_HOME")))                                 ; Wrap in `list` to ensure it's a list.
  :delight                                                                        ; Hide from modeline.
  :hook
  (LaTeX-mode . citar-capf-setup)
  (org-mode . citar-capf-setup))

(use-package citar-embark
  :after citar embark
  :delight                                                                        ; Hide from modeline.
  :no-require
  :config (citar-embark-mode))

(use-package visual-fill-column
  :ensure t
  :hook ((org-mode org-roam-mode) . visual-fill-column-mode)
  :custom
  (visual-fill-column-width 88)                                                   ; or 88 if you’re strict
  (visual-fill-column-center-text t))                                             ; optional but very popular

;; Soft-wrap lines at the window edge instead of hard line breaks
(add-hook 'org-mode-hook #'visual-line-mode)

;; Optional: make visual-line-mode the default for Org-roam dailies too
(add-hook 'org-roam-mode-hook #'visual-line-mode)


;;; Set fancy icons in citar.
(defvar citar-indicator-notes-icons
  (citar-indicator-create
   :symbol (nerd-icons-mdicon
            "nf-md-notebook"
            :face 'nerd-icons-blue
            :v-adjust -0.3)
   :function #'citar-has-notes
   :padding "  "
   :tag "has:notes"))

(defvar citar-indicator-links-icons
  (citar-indicator-create
   :symbol (nerd-icons-octicon
            "nf-oct-link"
            :face 'nerd-icons-orange
            :v-adjust -0.1)
   :function #'citar-has-links
   :padding "  "
   :tag "has:links"))

(defvar citar-indicator-files-icons
  (citar-indicator-create
   :symbol (nerd-icons-faicon
            "nf-fa-file"
            :face 'nerd-icons-green
            :v-adjust -0.1)
   :function #'citar-has-files
   :padding "  "
   :tag "has:files"))

(setq citar-indicators
      (list citar-indicator-files-icons
            citar-indicator-notes-icons
            citar-indicator-links-icons))



;;; Whitespace
(defun crafted-writing-configure-whitespace
    (use-tabs &optional use-globally &rest enabled-modes)
  "Helper function to configure `whitespace' mode.

Enable using TAB characters if USE-TABS is non-nil.  If
USE-GLOBALLY is non-nil, turn on `global-whitespace-mode'.  If
ENABLED-MODES is non-nil, it will be a list of modes to activate
whitespace mode using hooks.  The hooks will be the name of the
mode in the list with `-hook' appended.  If USE-GLOBALLY is
non-nil, ENABLED-MODES is ignojred.

Configuring whitespace mode is not buffer local.  So calling this
function twice with different settings will not do what you
think.  For example, if you wanted to use spaces instead of tabs
globally except for in Makefiles, doing the following won't work:

turns on `global-whitespace-mode' to use spaces instead of tabs:
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

;;; PDF support fix
;; When you attempt to scroll before the first page or after
;;  the last, you get an error. I would prefer that rather
;;  the attempt is ignored.
(with-eval-after-load "pdf-view"
  (defun pdf-view-scroll-up-or-next-page (&optional arg)
    "Scroll page up ARG lines if possible, else go to the next page.

When `pdf-view-continuous' is non-nil, scrolling upward at the
bottom edge of the page moves to the next page.  Otherwise, go to
next page only on typing SPC (ARG is nil)."
    (interactive "P")
    (if (or pdf-view-continuous (null arg))
        (let ((hscroll (window-hscroll))
              (cur-page (pdf-view-current-page)))
          (when (or (= (window-vscroll) (image-scroll-up arg))
                    ;; Workaround rounding/off-by-one issues.
                    (memq pdf-view-display-size
                          '(fit-height fit-page fit-width)))
            (pdf-view-next-page-command)
            (when (/= cur-page (pdf-view-current-page))
              (image-bob)
              (image-bol 1))
            (set-window-hscroll (selected-window) hscroll)))
      (image-scroll-up arg)))

  (defun pdf-view-scroll-down-or-previous-page (&optional arg)
    "Scroll page down ARG lines if possible, else go to the previous page.

When `pdf-view-continuous' is non-nil, scrolling downward at the
top edge of the page moves to the previous page.  Otherwise, go
to previous page only on typing DEL (ARG is nil)."
    (interactive "P")
    (if (or pdf-view-continuous (null arg))
        (let ((hscroll (window-hscroll))
              (cur-page (pdf-view-current-page)))
          (when (or (= (window-vscroll) (image-scroll-down arg))
                    ;; Workaround rounding/off-by-one issues.
                    (memq pdf-view-display-size
                          '(fit-height fit-page fit-width)))
            (pdf-view-previous-page-command)
            (when (/= cur-page (pdf-view-current-page))
              (image-eob)
              (image-bol 1))
            (set-window-hscroll (selected-window) hscroll)))
      (image-scroll-down arg))))

;;; LaTeX support

(defun my-lang-tex/check-executables ()
  "Check for required LaTeX executables and warn if missing.

Returns t if all are present, nil otherwise.
- Checks 'latex' and optionally 'latexmk'.
- Outputs messages for missing tools."
  (unless (executable-find "latex")
    (message "latex executable not found; LaTeX features disabled.")
    (cl-return nil))
  (when (not (executable-find "latexmk"))
    (message "latexmk not found; falling back to default TeX command."))
  t)

(defun my-lang-tex/setup-outline ()
  "Configure outline-minor-mode for LaTeX buffers.

- Uses LaTeX section commands for headings.
- Enables buttons, highlighting, and blank lines."
  (setq-local outline-minor-mode-use-buttons 'in-margins)                         ; Show buttons in margins.
  (setq-local outline-blank-line t)                                               ; Insert blank line before headers.
  (setq-local outline-minor-mode-highlight t)                                     ; Highlight outlines with font-lock.
  (setq-local outline-regexp (concat "\\\\"                                       ; Match LaTeX sections.
                                     "\\(part\\|chapter\\|"
                                     "\\(\\(sub\\)?\\(sub\\)?section\\|paragraph\\)"
                                     "\\)\\*?\\b"))
  (setq-local outline-level 'outline-level)                                       ; Use built-in level function for sections.
  (outline-minor-mode 1))                                                         ; Activate minor mode.

(defun my-lang-tex/setup-modes ()
  "Enable minor modes and tools for LaTeX editing.

- Activates cdlatex, reftex, etc.
- Sets up electric pairs and math modes."
  ;; Basic modes.
  (set-fringe-mode '(12 . 12))                                                    ; Set fringe for folding indicators.
  (display-line-numbers-mode 1)                                                   ; Show line numbers.
  (eglot-ensure)                                                                  ; Start Eglot for LSP support.
  (turn-on-cdlatex)                                                               ; Faster LaTeX input.
  (auto-fill-mode 1)                                                              ; Auto-wrap lines.
  (LaTeX-math-mode 1)                                                             ; Math symbol input.
  (yas-minor-mode-on)                                                             ; Yasnippet for templates.

  ;; Citar and RefTeX.
  (when (fboundp 'citar-refresh) (citar-refresh))
  (turn-on-reftex)                                                                ; Reference management.

  ;; Parentheses and electric features.
  (electric-pair-mode 1)                                                          ; Auto-insert matching brackets.
  (show-paren-mode 1)                                                             ; Highlight matching parens.
  (setq TeX-electric-sub-and-superscript t                                        ; Electric sub/superscripts.
        LaTeX-electric-left-right-brace t                                         ; Electric braces.
        TeX-electric-math (cons "$" "$"))                                         ; Electric math delimiters.

  ;; Tree-sitter for parsing.
  (treesit-major-mode-setup)
  
  ;; display flymake project level window.
  (my-flymake/show-project-diagnostics)
  )

(defun my-lang-tex/setup-indent-and-verbatim ()
  "Configure indentation and verbatim environments for LaTeX.

- Customises no-indent for specific environments.
- Sets verbatim to prevent formatting in code blocks."
  ;; Indentation.
  (dolist (env '("lstlisting" "tikzcd" "tikzpicture"))
    (add-to-list 'LaTeX-indent-environment-list
                 (list env 'current-indentation)))                                ; No extra indent in these envs.

  ;; Verbatim.
  (dolist (env '("lstlisting" "Verbatim"))
    (add-to-list 'LaTeX-verbatim-environments env))                               ; Prevent formatting in these envs.
  (dolist (macro '("lstinline"))
    (add-to-list 'LaTeX-verbatim-macros-with-braces macro)
    (add-to-list 'LaTeX-verbatim-macros-with-delims macro)))                      ; Inline verbatim macros.

(defun my-lang-tex/setup-compiler-and-viewer ()
  "Set up LaTeX compiler, viewer, and correlation.

- Integrates pdf-tools with SyncTeX.
- Configures LatexMk if available."
  ;; Core AUCTeX settings.
  (setq TeX-auto-save t                                                           ; Auto-save TeX info.
        TeX-parse-self t                                                          ; Parse on load.
        TeX-master (if (or (buffer-file-name)                                     ; Set master file.
                           (string-match "main\\.tex" (buffer-file-name)))
                       "main"
                     nil)
        TeX-engine 'luatex                                                        ; Default to LuaLaTeX.
        TeX-PDF-mode t                                                            ; Generate PDFs.
        reftex-plug-into-AUCTeX t                                                 ; Integrate RefTeX.
        TeX-source-correlate-start-server t                                       ; Start server for SyncTeX.
        TeX-command-extra-options "-synctex=1")                                   ; Enable SyncTeX in compiler.

  ;; Auto-revert PDF after compile.
  (add-hook 'TeX-after-compilation-finished-functions
            #'TeX-revert-document-buffer)

  ;; PDF Tools viewer (integrated from previous suggestion).
  (when (require 'pdf-tools nil 'noerror)
    (add-to-list 'TeX-view-program-selection '(output-pdf "PDF Tools"))           ; Associate PDF with viewer.
    (add-to-list 'TeX-view-program-list                                           ; Define viewer as function (not string).
                 '("PDF Tools" TeX-pdf-tools-sync-view)))

  ;; LatexMk setup.
  (when (and (executable-find "latexmk")
             (require 'auctex-latexmk nil 'noerror))
    (auctex-latexmk-setup)                                                        ; Integrate LatexMk.
    (setq TeX-command-default "LatexMk"                                           ; Default command.
          auctex-latexmk-inherit-TeX-PDF-mode t                                   ; Inherit PDF mode.
          bibtex-dialect 'biblatex))                                              ; Use BibLaTeX.

  ;; Biber as BibTeX command.
  (add-to-list 'TeX-command-list
               '("Biber" "biber %s" TeX-run-BibTeX nil t :help "Run Biber"))
  (setq TeX-command-BibTeX "Biber")

;;; Suppress texlab unused entry warnings for ref.bib
  (defun my-flymake-filter-texlab-unused (diagnostics)
    "Filter out 'Unused entry' diagnostics from texlab for ref.bib.

Args:
  DIAGNOSTICS: List of Flymake diagnostic objects.

Returns:
  Filtered list of diagnostics, excluding 'Unused entry' for ref.bib."
    (if (string-match-p "ref\\.bib$" (or (buffer-file-name) ""))
        (seq-filter
         (lambda (diag)
           (not (string-match-p "Unused entry"
                                (flymake-diagnostic-text diag))))
         diagnostics)
      diagnostics))

  (add-hook 'bibtex-mode-hook
            (lambda ()
              (add-hook 'flymake-diagnostic-functions
                        #'my-flymake-filter-texlab-unused nil t)))

  ;; Show compilation in-buffer.
  (setq TeX-show-compilation t)

  ;; PDF view defaults.
  (with-eval-after-load 'pdf-tools
    (setq-default pdf-view-display-size 'fit-width))                              ; Fit width by default.
  ;; Source correlation.
  (TeX-source-correlate-mode 1)                                                   ; Enable SyncTeX mapping.
  )

(defun my-lang-tex/latex-setup ()
  "Main setup function for LaTeX environment.

Calls decomposed helpers for modularity.
- Checks executables first.
- Sets up outline, modes, indent/verbatim, compiler/viewer."
  (when (my-lang-tex/check-executables)                                           ; Early exit if tools missing.
    ;; Delay Corfu.
    (customize-set-variable 'corfu-auto-delay 0.25)                               ; Reduce popup delay for efficiency.

    (my-lang-tex/setup-outline)                                                   ; Outline config.
    (my-lang-tex/setup-modes)                                                     ; Minor modes and tools.
    (my-lang-tex/setup-indent-and-verbatim)                                       ; Indent and verbatim.
    (my-lang-tex/setup-compiler-and-viewer)))                                     ; Compiler and viewer.

;; Hook the function to LaTeX mode.
(add-hook 'LaTeX-mode-hook 'my-lang-tex/latex-setup)


(log/debug :fn 'writing-config
           :msg "Finishing load of the writing-config module."
           :obj t)

(provide 'writing-config)
;;; writing-config.el ends here

