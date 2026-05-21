;;; custom-fileFormat-support.el --- Support for navigating files   -*- lexical-binding: t; -*-

;;; Commentary:

;;;Declare functions and imports


;;; Code:
(require 'path-support)
(require 'logging-config)
(log/debug :fn 'fileFormat-support
           :msg "Starting load of the fileFormat-support module."
           :obj t)


;;;; Visudo editing the sudo file
;;   ----------------------------

;; flymake back-end
;; ----------------
(defun etc-sudoers-flymake-backend (report-fn &rest _args)
  "Flymake backend for etc-sudoers-mode using visudo -c.
This function saves the buffer to a temporary file and runs 'visudo -c -f'
to check for syntax errors.  It reports diagnostics via REPORT-FN."
  (let* ((temp-file (make-temp-file "sudoers-flymake" nil ".tmp"))
         (buffer-content (buffer-substring-no-properties (point-min) (point-max)))
         (output-buffer (generate-new-buffer "*sudoers-flymake-output*"))
         (proc nil))
    (with-temp-file temp-file
      (insert buffer-content))
    (setq proc (make-process
                :name "sudoers-visudo-check"
                :buffer output-buffer
                :command (list "sudo" "visudo" "-c" "-f" temp-file)
                :sentinel
                (lambda (proc _event)
                  (when (eq (process-status proc) 'exit)
                    (unwind-protect
                        (if (zerop (process-exit-status proc))
                            (funcall report-fn nil)  ; No errors
                          (let (diags)
                            (with-current-buffer output-buffer
                              (goto-char (point-min))
                              (while (re-search-forward "^[^:]+:\$$   [0-9]+\   $$: \$$ .*\ \$\$\$" nil t)
                                (let ((line (string-to-number (match-string 1)))
                                      (msg (match-string 2)))
                                  (push (flymake-make-diagnostic (current-buffer)
                                                                 (cons line 1)
                                                                 (cons line (line-end-position line))
                                                                 :error msg)
                                        diags))))
                            (funcall report-fn (nreverse diags))))
                      (delete-file temp-file)
                      (kill-buffer output-buffer))))))))

;; Add the backend to Flymake for etc-sudoers-mode
(add-hook 'etc-sudoers-mode-hook
          (lambda ()
            (add-hook 'flymake-diagnostic-functions #'etc-sudoers-flymake-backend nil t)
            (flymake-mode 1)))

(use-package etc-sudoers-mode
  :ensure t
  :mode
  (("/etc/sudoers\\'" . etc-sudoers-mode)
   ("/etc/sudoers\\.d/.*\\'" . etc-sudoers-mode)
   ("\\.sudoers\\'" . etc-sudoers-mode))
  ;; No :hook for flycheck-mode now
  :config
  (global-set-key (kbd "C-c v") #'etc-sudoers-mode-visudo))






;;;; Very Large Files (vlf)
;;   ----------------------
(use-package vlf)
;; ensure vlf is used automatically.
(custom-set-variables
 '(vlf-application 'dont-ask))

;;;; .env files
;;   ----------
(use-package dotenv-mode)
;; support additional file extensions such as `.env.test' with this major mode.
(add-to-list 'auto-mode-alist '("\\.env\\..*\\'" . dotenv-mode))


;;;; CSV formatted files
;;   -------------------
(use-package csv-mode)
(add-to-list 'auto-mode-alist '("\\.csv\\'\\|\\.CSV\\'" . csv-mode))
(customize-set-variable 'csv-align-mode t)


;; Yaml formatted files
;; --------------------
(use-package yaml-pro
  :ensure t
  :hook (yaml-ts-mode . yaml-pro-mode))

;; install: npm install -g yaml-language-server
(with-eval-after-load 'eglot
  (when (executable-find "yaml-language-server")
    (setq eglot-server-programs
          (assq-delete-all 'yaml-mode eglot-server-programs))
    (setq eglot-server-programs
          (assq-delete-all 'yaml-ts-mode eglot-server-programs))
    (add-to-list 'eglot-server-programs
                 '((yaml-mode yaml-ts-mode) . ("yaml-language-server" "--stdio")))))
(add-to-list 'auto-mode-alist '("\\.ya?ml\\'" . yaml-ts-mode))

(defun my-fileFormat-support/yaml-ts-mode-setup ()
  "Custom configurations for yaml-ts-mode."
  (require 'treesit-fold)
  (when (fboundp 'eglot-ensure)
    (eglot-ensure))
  (treesit-fold-mode 1)
  (treesit-fold-indicators-mode 1)
  (display-fill-column-indicator-mode 1)
  (setq display-fill-column-indicator-column 80
        fill-column 80))

;;;; JSON formatted files
;;   --------------------
;; install: npm install -g vscode-langservers-extracted
(with-eval-after-load 'eglot
  (when (executable-find "vscode-json-languageserver")
    (add-to-list 'eglot-server-programs
                 '((json-mode json-ts-mode) . ("vscode-json-languageserver" "--stdio")))))

;; apply this mode to any file up to 2GB in size.
(setq treesit-max-buffer-size 2000000000)

(defun my-fileFormat-support/json-ts-mode-setup ()
  "Custom configurations for json-ts-mode."
  (require 'treesit-fold)
  (eglot-ensure)
  (treesit-fold-mode 1)
  (treesit-fold-indicators-mode 1)
  (setq display-fill-column-indicator-column 80)                                  ; Edge
  (setq fill-column 140                                                            ; Column beyond which line wrapping occurs if it is activated.
        comment-fill-column 140                                                    ; Colujmn to use for 'comment-indent'. If nil, use 'fill-column' instead.
        comment-column 142)                                                        ; Column to indent right-margin comments to.
  (display-fill-column-indicator-mode 1)                                          ; show fill column indicator 
  
  ;; Set the fringe mode specifically for json-ts-mode
  (set-fringe-mode '(12 . 5))

  ;; Note the below is the work of Eshel Yaron at
  ;; [[https://eshelyaron.com/posts/2023-05-17-orientation-in-json-documents-with-emacs-and-tree-sitter.html][eshelyaron.com]]
  (defun my-json/json-path-to-position (pos)
    "Return the JSON path from the document's root to the element at POS.

The path is represented as a list of strings and integers,
corresponding to the object keys and array indices that lead from
the root to the element at POS."
    (named-let loop ((node (treesit-node-at pos)) (acc nil))
      (if-let ((parent (treesit-parent-until
                        node
                        (lambda (n)
                          (member (treesit-node-type n)
                                  '("pair" "array"))))))
          (loop parent
                (cons
                 (pcase (treesit-node-type parent)
                   ("pair"
                    (treesit-node-text
                     (treesit-node-child (treesit-node-child parent 0) 1) t))
                   ("array"
                    (named-let check ((i 1))
                      (if (< pos (treesit-node-end (treesit-node-child parent i)))
                          (/ (1- i) 2)
                        (check (+ i 2))))))
                 acc))
        acc)))

  (defun my-json/json-path-at-point (point &optional kill)
    "Display the JSON path at POINT.  When KILL is non-nil, kill it too.

Interactively, POINT is point and KILL is the prefix argument."
    (interactive "d\nP" json-ts-mode)
    (let ((path (mapconcat (lambda (o) (format "%s" o))
                           ( my-json/json-path-to-position point)
                           ".")))
      (if kill
          (progn (kill-new path) (message "Copied: %s" path))
        (message path))
      path))

  )

;; Add the custom setup to json-ts-mode-hook
(add-hook 'json-ts-mode-hook #'my-fileFormat-support/json-ts-mode-setup)
;; apply json-ts-mode to file name suffix .json/ .JSON or .jsonl/ .JSONL
(add-to-list 'auto-mode-alist '("\\.json\\'\\|\\.JSON\\'" . json-ts-mode))
(add-to-list 'auto-mode-alist '("\\.jsonl\\'\\|\\.JSONL\\'" . json-ts-mode))


;;;; TOML formatted files
;;   --------------------
(with-eval-after-load 'eglot
  ;; TOML
  ;; Use https://taplo.tamasfe.dev/ for editing toml files.
  ;; install: cargo install taplo-cli --features lsp
  (when (executable-find "taplo")
    (setq eglot-server-programs
          (assq-delete-all 'toml-ts-mode eglot-server-programs))
    (add-to-list 'eglot-server-programs
                 '(toml-ts-mode . ("taplo" "lsp" "stdio")))))

(defun my-fileFormat-support/toml-ts-mode-setup ()
  "Custom configurations for toml-ts-mode."
  (require 'treesit-fold)
  (eglot-ensure)
  (treesit-fold-mode 1)
  (treesit-fold-indicators-mode 1)
  (setq display-fill-column-indicator-column 80)                                  ; Edge
  (setq fill-column 100                                                            ; Column beyond which line wrapping occurs if it is activated.
        comment-fill-column 100                                                    ; Colujmn to use for 'comment-indent'. If nil, use 'fill-column' instead.
        comment-column 102)                                                        ; Column to indent right-margin comments to.
  (display-fill-column-indicator-mode 1)                                          ; show fill column indicator 
  
  )

;; Add the custom setup to toml-ts-mode-hook
(add-hook 'toml-ts-mode-hook #'my-fileFormat-support/toml-ts-mode-setup)
(add-to-list 'auto-mode-alist '("\\.toml\\'\\|\\.TOML\\'" . toml-ts-mode))


(log/debug :fn 'fileFormat-support
           :msg "Finishing load of the fileFormat-support module."
           :obj t)


(provide 'fileFormat-support)
;;; fileFormat-support.el ends here
