;; LLM-support.el --- LLM integration with gptel + Org-roam + Aidermacs for Simon Watson -*- lexical-binding: t; -*-

;; Author: Grok (on behalf of Simon Watson)
;; Version: 0.3.0
;; Keywords: ai, gptel, org-roam, aidermacs, complex-systems
;; Created: March 2026

;;; Commentary:
;; Clean, native integration of gptel + Org-roam + Aidermacs for Simon Watson.
;;
;; Features:
;;   - Full xAI Grok backend with Feb 2026 model list
;;   - Local Ollama (Qwen3-Coder + GLM-4.7-Flash)
;;   - Four gptel presets (research/coding/chat/tagging) — switch interactively or in code
;;   - @preset support in gptel buffers
;;   - New gptel chats via Org-roam directory
;;   - FULL Aidermacs integration (AI pair-programming with Aider CLI)
;;     • Transient menu (C-c l a)
;;     • Architect mode default (reasoning + editing models)
;;     • Reuses your xAI key & Ollama models
;;     • Ediff integration, file watching, prompt files (.aider.prompt.org)
;;   - Buffer-local preset application (no global leakage)
;;   - Ready for Relysium coding workflows
;;
;; External requirements (install once outside Emacs):
;;   1. Aider CLI (required by Aidermacs):
;;      python -m pip install --upgrade aider-install
;;      aider-install
;;   2. (Optional but recommended) vterm for better UI:
;;      M-x package-install RET vterm RET
;;
;; Usage:
;;   (require 'LLM-support)
;;   M-x my-llm/new-chat          or   C-c l n
;;   M-x my-llm/aidermacs-menu    or   C-c l a
;;
;; Aidermacs quick start:
;;   - C-c l a → transient menu (Magit-style)
;;   - . (dot) → start session in current directory
;;   - f / F   → add current file (C-u for read-only)
;;   - r       → Architect change on region
;;   - g       → accept proposed changes
;;   - 3       → switch to Architect mode permanently
;;
;; Prompt-file mode (auto-enabled for .aider.prompt.org):
;;   C-c C-c   → send region/block
;;   C-c C-n   → send line-by-line

;;; Code:
(require 'path-support)
(require 'logging-config)

(log/debug :fn 'LLM-support
           :msg "Starting load of the LLM-support module."
           :obj t)


(use-package gptel
  :ensure t)

(use-package aidermacs
  :ensure t)

(require 'gptel)
(require 'org-roam)

;; ----------------------------------------------------------------------------
;; 1. Model & Backend Definitions
;; ----------------------------------------------------------------------------

(defvar my-llm/grok-models
  '((grok-4-1-fast-reasoning
     :context-window 2000000
     :input-cost 0.20
     :output-cost 0.50
     :capabilities (tool-use json reasoning))
    (grok-4-1-fast-non-reasoning
     :context-window 2000000
     :input-cost 0.20
     :output-cost 0.50
     :capabilities (tool-use json))
    (grok-code-fast-1
     :context-window 256000
     :input-cost 0.20
     :output-cost 1.50
     :capabilities (tool-use json reasoning))
    (grok-4-fast-reasoning
     :context-window 2000000
     :input-cost 0.20
     :output-cost 0.50
     :capabilities (tool-use json reasoning))
    (grok-4-fast-non-reasoning
     :context-window 2000000
     :input-cost 0.20
     :output-cost 0.50
     :capabilities (tool-use json))
    (grok-4-0709
     :context-window 256000
     :input-cost 3.00
     :output-cost 15.00
     :capabilities (tool-use json reasoning))
    (grok-3-mini
     :context-window 131072
     :input-cost 0.30
     :output-cost 0.50
     :capabilities (tool-use json reasoning))
    (grok-3
     :context-window 131072
     :input-cost 3.00
     :output-cost 15.00
     :capabilities (tool-use json reasoning))
    (grok-2-vision-1212
     :context-window 32768
     :input-cost 2.00
     :output-cost 10.00
     :capabilities (tool-use json media)
     :mime-types ("image/jpeg" "image/png" "image/gif" "image/webp")))
  "Curated Grok language models (Feb 2026 xAI console screenshot).
Structured exactly as `gptel-make-xai' expects.")

(defvar my-llm/xai-backend nil
  "Stored xAI/Grok backend object for reuse.")

(defvar my-llm/ollama-backend nil
  "Stored Ollama backend object for reuse.")

(defvar my-llm/chat-directory nil
  "Directory where all LLM chat Org files are saved (Org-roam indexed).")

(defvar my-llm/file-output-directory nil
  "Directory for file attachments in LLM chats.")

(defvar my-llm/ollama-local-models
  '((qwen3-coder-next:latest
     :context-window 262144
     :capabilities (tool-use json reasoning))
    (glm-4.7-flash:latest
     :context-window 128000
     :capabilities (tool-use json reasoning)))
  "Local Ollama models with gptel capabilities.")

;; ----------------------------------------------------------------------------
;; 2. Setup Functions (gptel + directories)
;; ----------------------------------------------------------------------------

(defun my-llm/setup-grok-xai ()
  "Create and store the xAI backend with full model list."
  (interactive)
  (let ((backend (gptel-make-xai "xAI"
                   :key (lambda () (getenv "XAI_API_KEY"))
                   :stream t
                   :models my-llm/grok-models)))
    (setq my-llm/xai-backend backend)
    (log/info :fn 'my-llm/setup-grok-xai
              :msg "✅ xAI backend ready with 9 models."
              :obj t)))

(defun my-llm/setup-ollama-local ()
  "Create and store the Ollama backend."
  (interactive)
  (let ((backend (gptel-make-ollama "Ollama"
                   :host "localhost:11434"
                   :stream t
                   :models my-llm/ollama-local-models)))
    (setq my-llm/ollama-backend backend)
    (log/info :fn 'my-llm/setup-ollama-local
              :msg "✅ Ollama backend ready."
              :obj t)))

(defun my-llm/setup-chat-directory ()
  "Ensure the LLM chat directory exists."
  (setq my-llm/chat-directory
        (expand-file-name "llm-chats/" (or org-directory "~/Documents/org/")))
  (unless (file-directory-p my-llm/chat-directory)
    (make-directory my-llm/chat-directory t))
  my-llm/chat-directory)

(defun my-llm/setup-file-output-directory ()
  "Ensure attachments directory exists."
  (setq my-llm/file-output-directory
        (expand-file-name "attachments/" my-llm/chat-directory))
  (unless (file-directory-p my-llm/file-output-directory)
    (make-directory my-llm/file-output-directory t)))

(defun my-llm/setup-presets ()
  "Register the four gptel presets."
  (gptel-make-preset 'research
    :description "Complex systems, AI, maths, research"
    :backend "xAI"
    :model 'grok-4-fast-reasoning
    :system "You are Grok by xAI. Assist with complex systems research, AI, maths and Emacs. Be truthful, precise and wry.")

  (gptel-make-preset 'coding
    :description "Emacs Lisp / Python coding"
    :backend "Ollama"
    :model "qwen3-coder-next:latest"
    :system "Expert Emacs Lisp / Python coder. Prioritise efficiency then clarity.")

  (gptel-make-preset 'chat
    :description "General chat / assistant"
    :backend "xAI"
    :model 'grok-4-fast-reasoning
    :system "You are Grok by xAI. Assist with responses to a chat buffer in Emacs. Be truthful, precise and wry.")

  (gptel-make-preset 'tagging
    :description "Concise tag extractor"
    :backend "Ollama"
    :model "glm-4.7-flash:latest"
    :system "Concise tag extractor. Output ONLY :tag1: :tag2: ... line."))

;; ----------------------------------------------------------------------------
;; 3. Preset Switching (Interactive + Programmatic)
;; ----------------------------------------------------------------------------

(defun my-llm/switch-preset (&optional preset)
  "Switch to a gptel preset buffer-locally.

If PRESET is a symbol (e.g. 'chat), use it directly.
If called interactively, offer `completing-read' of all defined presets."
  (interactive)
  (let ((chosen (or preset
                    (intern-soft
                     (completing-read "Preset: "
                                      (mapcar #'car gptel--known-presets)
                                      nil t)))))
    (if chosen
        (progn
          (gptel--apply-preset chosen
                               (lambda (sym val)
                                 (set (make-local-variable sym) val)))
          (message "✅ Preset %s applied buffer-locally" chosen)
          (log/info :fn 'my-llm/switch-preset
                    :msg "Preset applied buffer-locally"
                    :obj chosen))
      (user-error "No preset chosen"))))

;; ----------------------------------------------------------------------------
;; 4. New Chat — Pure gptel (no Org-roam capture)
;; ----------------------------------------------------------------------------

(defun my-llm/new-chat ()
  "Create a new LLM chat using pure gptel.
Applies 'chat preset buffer-locally and saves to Org-roam directory."
  (interactive)
  (my-llm/setup-chat-directory)
  
  (let ((buf (gptel "xAI Chat" nil nil)))  ; ← no system prompt needed
    (with-current-buffer buf
      (my-llm/switch-preset 'chat)
      (let* ((timestamp (format-time-string "%Y%m%d%H%M%S"))
             (filename (expand-file-name (format "%s-xAI-chat.org" timestamp)
                                         my-llm/chat-directory)))
        (setq buffer-file-name filename)
        (org-mode)
        (erase-buffer)
        (insert "** User\n\n** Assistant\n")
        (gptel-mode 1)
        (goto-char (point-max))
        (save-buffer)
        (org-roam-db-sync)
        (log/info :fn 'my-llm/new-chat
                  :msg "✅ New LLM chat ready — type under ** User and press C-c RET"
                  :obj t)))))

;; ----------------------------------------------------------------------------
;; 4. New Chat — Pure gptel (no Org-roam capture)
;; ----------------------------------------------------------------------------

(defun my-llm/new-chat ()
  "Create a new LLM chat using the 'chat preset (Grok by xAI).
Applies preset *after* `gptel-mode' so the PROPERTIES header is correct."
  (interactive)
  (my-llm/setup-chat-directory)
  
  (let ((buf (gptel "xAI Chat" nil nil)))
    (with-current-buffer buf
      (org-mode)
      (gptel-mode 1)                    ; ← MUST come FIRST
      (my-llm/switch-preset 'chat)      ; ← now the header updates correctly
      (let* ((timestamp (format-time-string "%Y%m%d%H%M%S"))
             (filename (expand-file-name (format "%s-xAI-chat.org" timestamp)
                                         my-llm/chat-directory)))
        (setq buffer-file-name filename)
        (erase-buffer)
        (insert "** User\n\n** Assistant\n")
        (goto-char (point-max))
        (save-buffer)
        (org-roam-db-sync)
        (log/info :fn 'my-llm/new-chat
                  :msg "✅ New Grok chat ready — type under ** User and press C-c RET"
                  :obj t)))))

;; ----------------------------------------------------------------------------
;; 5. Aidermacs Setup — AI Pair Programming (NEW SECTION)
;; ----------------------------------------------------------------------------

(defun my-llm/setup-aidermacs ()
  "Configure Aidermacs with your existing xAI + Ollama models.
Uses Architect mode by default (best for complex coding).
Reuses XAI_API_KEY and Ollama from your environment."
  (interactive)
  (setq aidermacs-default-chat-mode 'architect)     ; reasoning + editing models
  (setq aidermacs-default-model "xai/grok-4-fast-reasoning") ; fallback
  (setq aidermacs-architect-model "xai/grok-4-fast-reasoning")
  (setq aidermacs-editor-model "ollama/qwen3-coder-next:latest") ; fast local edits
  (setq aidermacs-weak-model "ollama/glm-4.7-flash:latest")     ; for commits/summaries
  (setq aidermacs-backend 'vterm)                  ; better UI (fallback to comint)
  (setq aidermacs-show-diff-after-change t)
  (setq aidermacs-auto-commits nil)                ; safer for Relysium workflows
  (setq aidermacs-auto-accept-architect nil)       ; you review everything

  ;; Optional: global read-only files (e.g. your AI rules)
  ;; (setq aidermacs-global-read-only-files '("~/.aider/AI_RULES.md"))

  (log/info :fn 'my-llm/setup-aidermacs
            :msg "✅ Aidermacs configured with Grok + Qwen3-Coder (Architect mode)"
            :obj t))

;; Helper commands (call from anywhere)
(defun my-llm/aidermacs-menu ()
  "Open the Aidermacs transient menu (C-c l a)."
  (interactive)
  (aidermacs-transient-menu))

(defun my-llm/aidermacs-start-grok ()
  "Start Aidermacs session using Grok-4-fast-reasoning."
  (interactive)
  (let ((aidermacs-default-model "xai/grok-4-fast-reasoning")
        (aidermacs-architect-model "xai/grok-4-fast-reasoning"))
    (aidermacs-start-session)))

(defun my-llm/aidermacs-start-qwen ()
  "Start Aidermacs session using local Qwen3-Coder (fast & private)."
  (interactive)
  (let ((aidermacs-default-model "ollama/qwen3-coder-next:latest")
        (aidermacs-architect-model "ollama/qwen3-coder-next:latest"))
    (aidermacs-start-session)))

;; ----------------------------------------------------------------------------
;; 6. Initialisation
;; ----------------------------------------------------------------------------

(defun my-llm/init ()
  "One-time initialisation of LLM support (gptel + Aidermacs)."
  (my-llm/setup-grok-xai)
  (my-llm/setup-ollama-local)
  (my-llm/setup-chat-directory)
  (my-llm/setup-file-output-directory)
  (my-llm/setup-presets)
  (my-llm/setup-aidermacs)               ; ← new

  (add-hook 'gptel-mode-hook #'gptel--prettify-preset)

  (setq gptel-default-mode 'org-mode)
  (setq gptel-log-level 'debug)
  (setq gptel-prompt-prefix-alist '((org-mode . "** User\n")))
  (setq gptel-response-prefix-alist '((org-mode . "** Assistant\n")))

  (global-set-key (kbd "C-c l n") #'my-llm/new-chat)
  (global-set-key (kbd "C-c l a") #'my-llm/aidermacs-menu)   ; ← new

  (log/info :fn 'my-llm/init
            :msg "LLM-support fully initialised. C-c l n (chat) • C-c l a (Aidermacs)"
            :obj t))

(with-eval-after-load 'gptel
  (my-llm/init))

;; Local coding model for programming buffers (gptel)
(add-hook 'prog-mode-hook
          (lambda ()
            (setq-local gptel-backend my-llm/ollama-backend
                        gptel-model "qwen3-coder-next:latest")))


(log/debug :fn 'LLM-support
           :msg "Ending load of the LLM-support module."
           :obj t)

(provide 'LLM-support)
;;; LLM-support.el ends here
