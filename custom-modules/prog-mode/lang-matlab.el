;;; lang-matlab.el --- python support for the crafted setup   -*- lexical-binding: t; -*-

;;; Commentary:

;; A starter config for editing Matlab code.
;;
;; Prerequisites:
;;
;; - Matlab installation.


;;; Package phase
(use-package matlab-mode)



;;; Code:
(require 'path-support)
(require 'logging-config)
(log/debug :fn 'lang-matlab
           :msg "Starting load of the lang-matlab module."
           :obj t)


(defun matlab-mode-treesit-setup ()
  "Enable Tree-sitter features in `matlab-mode`."
  (when (and (treesit-available-p)
             (treesit-language-available-p 'matlab))
    (treesit-parser-create 'matlab)
    (setq-local treesit-font-lock-settings
                (treesit-font-lock-rules
                 :language 'matlab
                 :feature 'basic
                 '((function_declaration name: (identifier) @font-lock-function-name-face)
                   (variable_declaration name: (identifier) @font-lock-variable-name-face)
                   (string) @font-lock-string-face
                   (number) @font-lock-number-face
                   (comment) @font-lock-comment-face)))
    (setq-local treesit-font-lock-feature-list
                '((basic)))
    (treesit-font-lock-recompute-features)))

(defun matlab-ts-jump-to-function ()
  "Jump to the next function declaration in a MATLAB file."
  (interactive)
  (let ((node (treesit-search-subtree
               (treesit-buffer-root-node 'matlab)
               (lambda (n)
                 (equal (treesit-node-type n) "function_declaration"))
               nil t)))
    (when node
      (goto-char (treesit-node-start node)))))

;;; Configuration phase

(with-eval-after-load 'eglot
  (add-to-list
   'eglot-server-programs
   '(matlab-mode .
                 ("node"
                  "/home/simon/sync/primary/dotfiles/emacs/.emacs.d/etc/INFODYNAMICS/lang-servers/MATLAB-language-server/out/index.js" "--stdio"))))

;; load the paths for memory-tree.
(setq lang-matlab-dir
      (expand-file-name "lang-matlab/" my-paths/memory-object-tree-folder))
(add-to-list 'load-path lang-matlab-dir)

;;;; settings for matlab-mode.
(defun my-lang/matlab-mode-setup ()
  "Central function to hook into `matlab-mode' for matlab functionality."
  (message
   "[%s ; DEBUG; my-lang/matlab-mode-setup]starting loading the defun ; ;"
   (current-time-string))


  ;; start up Eglot in this mode.
  (eglot-ensure)

  ;; flymake
  (flymake-show-project-diagnostics)

  ;; ensure memory-tree is available for inspection from speedbar.
  (require 'matlab-mode)
  (require 'memory-object-tree)
  (require 'matlab-workspace-tree)
  (matlab-memory-tree-init)
  ;;;;; Set up outline

  ;; Set up customisations for outline-minor-mode.
  (setq-local outline-minor-mode-use-buttons 'in-margins)                         ; Show buttons
  (setq-local outline-blank-line t)                                               ; Blank line before headers
  (setq-local outline-minor-mode-highlight t)                                     ; Font-lock outlines
  (setq-local outline-regexp "^[[:space:]]*%%+")                                  ; Match `%%' and more.
  (setq-local outline-start "%")                                                  ; Start marker
  (setq-local outline-level #'my-outline-mode/outline-level)                      ; Custom level function
  (outline-minor-mode 1)                                                          ; Use outline-minor-mode

  ;;;;; Folding

  ;; Set the fringe mode for python-ts-mode folding.
  (set-fringe-mode '(12 . 12))
  
  ;; Enable treesit-fold-mode
  (treesit-fold-mode 1)
  ;; Enable treesit-fold-indicators-mode
  (treesit-fold-indicators-mode 1)

  ;; You will probably want to tweak this variable, it determines how
  ;; quickly the completion prompt provides LSP suggestions when
  ;; typing. Be careful if you set it to 0 in a large project!
  (customize-set-variable 'corfu-auto-delay 0.25)

  ;; Enable Ya-snippets.
  (yas-minor-mode)

  ;;;;; Keybindings
  (define-key matlab-mode-map (kbd "C-c f") #'matlab-ts-jump-to-function)

  ;;;;; IDE layout
  
  ;; Provide a function to set the fill column indicator.
  ;; This has a default of 80 but can be set on a per mode basis.
  ;; Set the preferred fill column indicator for the mode and activate it.
  
  (setq display-fill-column-indicator-column 120)                                 ; right limit on script.
  (setq fill-column 120)                                                          ; Column beyond which line wrapping occurs if it is activated.
  (setq comment-fill-column 250)                                                  ; Column to use for wrapping comment lines.
  (setq comment-column 122)                                                       ; Column to indent right-margin comments to.

  (display-fill-column-indicator-mode 1)                                          ; show the buffer line width.

  ;; (matlab-shell)                                                                ; ensure matlab is running.

     ;;;;; IDE functionality map
  
  ;; compiling the code (Not applicable)
  ;; (keymap-set python-ts-mode-map "C-c C-c C-u" #)

  ;; debugging the code tbc
  ;; (keymap-set python-ts-mode-map "C-c C-c C-k" #)

  ;; document thing at point:
  ;; (keymap-set python-ts-mode-map "C-c C-c C-r" #'eldoc)
  ;;  (keymap-set python-ts-mode-map "M-?" #'anaconda-mode-show-doc)
  ;; testing (tbd)
  ;; (keymap-set python-ts-mode-map "C-c C-c C-t"
  ;; #'projectile-test-project)

  ;; running the code
  ;;  (keymap-set python-ts-mode-map "C-c r b" #'eval-buffer)

  ;; run an inferior python process
  ;;  (keymap-set python-ts-mode-map "C-c r p" #'run-python)

  ;; formatting
  ;; (keymap-set python-ts-mode-map "C-c C-f b" #'blacken-buffer)
  ;;  (keymap-set python-ts-mode-map "C-c C-f r" #'blacken-buffer)

   ;;;;; Errors/linting

  ;; list errors in buffer
  ;;  (keymap-set python-ts-mode-map "C-c e b" #'flymake-show-buffer-diagnostics)
  ;; list errors in minibuffer
  ;;  (keymap-set python-ts-mode-map "C-c e m" #'consult-flymake)
  ;; list errors in project
  ;;  (keymap-set
  ;;   python-ts-mode-map "C-c e p" #'flymake-show-project-diagnostics)
  ;; formatting errors (not applicable)
  ;; (keymap-set python-ts-mode-map "C-c C-n" )
  ;; go to next error
  ;;  (keymap-set python-ts-mode-map "C-c e n" #'flymake-goto-next-error)
  ;; go to previous error.
  ;; (keymap-set python-ts-mode-map "C-c e l" #'flymake-goto-prev-error)

   ;;;;; Variable/function references

  ;; xref-find-definitions
  ;; (keymap-set python-ts-mode-map "M-." #'anaconda-mode-find-definitions)
  ;; xref-find-references
  ;;  (keymap-set python-ts-mode-map "M-r" #'anaconda-mode-find-references)
  ;; xref-find-assignments
  ;;  (keymap-set python-ts-mode-map "M-=" #'anaconda-mode-find-assignments)
  
  (message
   "[%s ; DEBUG; my-lang/matlab-mode-setup]finished loading the defun ; ;"
   (current-time-string)))

;; associate .m file with the matlab-mode (major mode)
(add-to-list 'auto-mode-alist '("\\.m$" . matlab-mode))


;; setup matlab-shell (assumes that matlab is in the PATH).
(setq matlab-shell-command "matlab")
(setq matlab-shell-command-switches (list "-nodesktop"))

(setq matlab-show-mlint-warnings t)                                               ; show linting warnings by default.

;; finally, ensure that any non-standard shebangs are covered. This overrides
;; interpreter-mode-alist. The difference is that interpreter-mode-alist
;; matches strictly the interpreter at the end of the shebang. Magic-mode-alist
;; can match any regular expression against the first line in a file.
(add-to-list 'magic-mode-alist
             '((lambda ()
                 (looking-at "^#!.*matlab")) . matlab-mode))

;; hooks:
(add-hook 'matlab-mode-hook #'matlab-mode-treesit-setup)
(add-hook 'matlab-mode-hook #'my-lang/matlab-mode-setup)

;; advice:
;; Stop an annoying back tab error when you accidentally go backwards at
;; beginning of a terminal line. 
(advice-add 'matlab-shell-delete-backwards-no-prompt :around
            (lambda (orig-fun &rest args)
              "Wrap matlab-shell-delete-backwards-no-prompt to ignore errors at prompt start."
              (ignore-errors (apply orig-fun args))))


(require 'path-support)
(require 'logging-config)
(log/debug :fn 'lang-matlab
           :msg "Ending load of the lang-matlab module."
           :obj t)

(provide 'lang-matlab)
;;; lang-matlab.el ends here

;; LocalWords:  matlab nodesktop mlint linux glnxa
