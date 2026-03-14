;;; vterm-support.el --- vterm support for emacs setup   -*- lexical-binding: t; -*-

;; Copyright (C) 2025
;; SPDX-License-Identifier: MIT

;; Author: Simon Watson
;; Keywords: vterm, bash, terminal

;;; Commentary:

;;; Code:
(require 'path-support)
(require 'logging-config)
(log/debug :fn 'vterm-support
           :msg "Starting load of the vterm-support module."
           :obj t)

(defun my-vterm/cd-to-current-dir ()
  "Change directory in the vterm buffer to the directory of the active buffer.
  
  This function retrieves the directory from the current buffer (using
  `default-directory` if no file is visited, or the file's directory otherwise).
  It then switches to the `*vterm*` buffer, sends a 'cd' command to the shell,
  and switches back to the original buffer.
  
  Assumptions:
  - A vterm buffer named `*vterm*` exists and is running a shell.
  - The shell in vterm supports the 'cd' command (e.g., bash, zsh).
  
  If multiple vterm buffers are needed, extend this with buffer selection."
  (interactive)
  (let* ((orig-buffer (current-buffer))
         (dir (if buffer-file-name
                  (file-name-directory buffer-file-name)
                default-directory))
         (vterm-buffer (get-buffer "*vterm*")))
    (if (not vterm-buffer)
        (user-error "No vterm buffer found named *vterm*")
      (switch-to-buffer vterm-buffer)
      (vterm-send-string (concat "cd " (shell-quote-argument dir) "\n"))
      (switch-to-buffer orig-buffer))))


(with-eval-after-load 'vterm

  ;; go to location of active file in vterm.
  (global-set-key (kbd "C-c g f") #'my-vterm/cd-to-current-dir)
  
  (define-key vterm-mode-map
              (kbd "C-c g h")
              (lambda ()
                "Send 'cd ~/' command to the vterm shell.
This interactive function sends the directory change command for the home
directory to the vterm process. It assumes:

The current buffer is in vterm-mode.
The shell supports 'cd ~/' (e.g., bash, zsh).

Flow:

Construct the command string.
Send it to vterm with a newline to execute."
                (interactive)
                (vterm-send-string "cd ~/\n")))

  (define-key vterm-mode-map
              (kbd "C-c g w")
              (lambda ()
                "Send 'cd /mnt/HDD04_WDD_08TB/workspace' command to vterm shell.
This interactive function sends the directory change command for the workspace
to the vterm process. It assumes:

The current buffer is in vterm-mode.
The shell supports 'cd' with absolute paths.
The path exists and is accessible.

Flow:

Define the target path.
Quote it safely (though no spaces here).
Send the command with a newline."
                (interactive)
                (let ((path "/mnt/HDD04_WDD_08TB/workspace"))
                  (vterm-send-string (concat "cd "
                                             (shell-quote-argument path) "\n"))))))


(log/debug :fn 'vterm-support
           :msg "Finishing load of the vterm-support module."
           :obj t)

(provide 'vterm-support)
;;; vterm-support.el ends here
