;;; custom-fileFormat-support.el --- Support for navigating files   -*- lexical-binding: t; -*-

;;; Commentary:

;;;Declare functions and imports


;;; Code: 
(require 'path-support)
(require 'logging-config)
(log/debug :fn 'fileFormat-support
           :msg "Starting load of the fileFormat-support module."
           :obj t)

;; packages
(use-package vlf)
(use-package csv-mode)
(use-package dotenv-mode)


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



;;;; Markdown formatted files
;;   ------------------------

(use-package markdown-mode
  :ensure t                                                                       ; Install automatically if missing
  :defer t                                                                        ; Load lazily for efficiency
  :mode ("\\.md\\'" . markdown-mode)                                              ; Auto-associate .md files
  :hook (markdown-mode . visual-line-mode)
  ;; :custom-face
  ;; ;; Inline code: Distinct blue, monospaced for readability
  ;; (markdown-inline-code-face ((t (:family "Courier" :weight normal))))            ; :foreground "#00BFFF"                                                                                  ; :background "#F0F8FF"
  ;; ;; Headers: Progressive scaling with bold and colour gradients
  ;; (markdown-header-face-1 ((t (:height 1.5 :weight bold))))                       ; :foreground "#00008B"
  ;; (markdown-header-face-2 ((t (:height 1.3 :weight bold))))                       ; :foreground "#0000CD"
  ;; (markdown-header-face-3 ((t (:height 1.2 :weight bold))))                       ; :foreground "#4169E1"
  ;; ;; Add more header levels as needed, e.g., 4-6
  ;; ;; Other elements: Bold, italic, links for emphasis
  ;; (markdown-bold-face ((t (:weight bold))))                                       ; :foreground "#FF0000"
  ;; (markdown-italic-face ((t (:slant italic))))                                    ; :foreground "#808080"
  ;; (markdown-link-fxace ((t (:underline t))))                                      ; :foreground "#1E90FF"
  :config
  ;; Any post-load config can go here; currently none needed for basics
  )

;;;; Very Large Files (vlf)
;;   ----------------------
;; ensure vlf is used automatically.
(custom-set-variables
 '(vlf-application 'dont-ask))

;;;; .env files
;;   ----------
;; support additional file extensions such as `.env.test' with this major mode.
(add-to-list 'auto-mode-alist '("\\.env\\..*\\'" . dotenv-mode))

;;;; CSV formatted files
;;   -------------------
(add-to-list 'auto-mode-alist '("\\.csv\\'\\|\\.CSV\\'" . csv-mode))
(customize-set-variable 'csv-align-mode t)

;;;; JSON formatted files
;;   --------------------

;; apply json-ts-mode to file name suffix .json/ .JSON or .jsonl/ .JSONL
(add-to-list 'auto-mode-alist '("\\.json\\'\\|\\.JSON\\'" . json-ts-mode))
(add-to-list 'auto-mode-alist '("\\.jsonl\\'\\|\\.JSONL\\'" . json-ts-mode))

;; apply this mode to any file up to 2GB in size.
(setq treesit-max-buffer-size 2000000000)

(defun my-fileFormat-support/json-ts-mode-setup ()
  "Custom configurations for json-ts-mode."

  ;; Remove the fill column indicator.
  (display-fill-column-indicator-mode -1)
  
  ;; Set the fringe mode specifically for json-ts-mode
  (set-fringe-mode '(12 . 5))

  ;; Enable treesit-fold-mode
  (require 'treesit-fold)
  (treesit-fold-mode 1)
  ;; Enable treesit-fold-indicators-mode
  (treesit-fold-indicators-mode 1)


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


;;;; TOML formatted files
;;   --------------------
(add-to-list 'auto-mode-alist '("\\.toml\\'\\|\\.TOML\\'" . toml-ts-mode))

(defun my-fileFormat-support/toml-ts-mode-setup ()
  "Custom configurations for toml-ts-mode."
  (require 'treesit-fold)
  
  (setq display-fill-column-indicator-column 50)                                  ; Edge
  (setq fill-column 50)                                                           ; Column beyond which line wrapping occurs if it is activated.
  (setq comment-fill-column 270)                                                  ; Colujmn to use for 'comment-indent'. If nil, use 'fill-column' instead.
  (setq comment-column 52)                                                        ; Column to indent right-margin comments to.
  (display-fill-column-indicator-mode 1)                                          ; show fill column indicator 
  
  ;; Set the fringe mode specifically for json-ts-mode
  (set-fringe-mode '(12 . 5))

  ;; Enable treesit-fold-mode
  (treesit-fold-mode 1)
  ;; Enable treesit-fold-indicators-mode
  (treesit-fold-indicators-mode 1))

;; Add the custom setup to toml-ts-mode-hook
(add-hook 'toml-ts-mode-hook #'my-fileFormat-support/toml-ts-mode-setup)


(log/debug :fn 'fileFormat-support
           :msg "Finishing load of the fileFormat-support module."
           :obj t)


(provide 'fileFormat-support)
;;; fileFormat-support.el ends here
