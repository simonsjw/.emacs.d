;;; q-loadbalancer.el --- Manage KDB/Q processes via Emacs Lisp -*- lexical-binding: t; -*-

;; Author: Simon Watson
;; Version: 1.2
;; Keywords: KDB, Q, process management
;; URL: https://github.com/simonsjw/q-loadbalancer
;; Package-Requires: (Emacs "24.3")

;;; Commentary:

;; This package provides functionality to manage multiple KDB/Q processes
;; within Emacs.
;; It allows users to start and manage several Q processes, grouped by type,
;; with each group potentially containing multiple processes.

;;; Code:


(require 'easymenu)
(require 'cl-lib)

(defvar comint-prompt-regexp)
(defvar q-script-mode-syntax-table)
(defvar q-process-group-list)
(defvar q-font-lock-defaults)

(declare-function comint-mode "comint")
(declare-function q-script-mode-syntax-setup "q-parse")
(declare-function q-paren-ignore "q-parse")
(declare-function q-setup-log-output-font-lock "q-parse")
(declare-function q-syntax-propertize "q-parse")

(setq debug-on-error t)

;; ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
;; Load up the scripts to provide functionality.
(let* ((loadBalancer-file-name (or load-file-name buffer-file-name))
       (loadBalancerPackageDirectory
        (file-name-directory (expand-file-name loadBalancer-file-name)))
       )
  (message loadBalancerPackageDirectory)

  (load-file (concat loadBalancerPackageDirectory "q-parse.el"))
  (load-file (concat loadBalancerPackageDirectory "process-groups.el"))
 ;; (load-file (concat loadBalancerPackageDirectory "q-modeline.el"))
  (load-file (concat loadBalancerPackageDirectory "q-ibuffer.el")))

;; ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
;; Define the q-script Menus, keys and major mode.
(defvar q-script-mode-map
  (let ((map (make-sparse-keymap)))
    ;; Define keybindings here
    map)
  "Keymap for `q-script-mode'.")

;; Add a test menu to q-shared-mode-map
;; (easy-menu-define q-test-menu q-script-mode-map "Test Menu."
;;   '("Test Menu"
;;     ["Test Item" (message "Test item selected")]))

;;Define and attach the menu to `q-shared-mode-map`
(easy-menu-define q-script-menu q-script-mode-map "Q Processes Menu."
  `("Q Process Management"
    ("Add Process Group:"
     ,@(mapcar (lambda (group)
                 (let ((group-name (car group)))
                   `[,(format "%s" group-name)
                     (lambda () (interactive)
                       (q-start-process-group ',group))]))
               q-process-group-list))
    ("Add Process:"
     ,@(mapcar (lambda (group)
                 (let ((group-name (car group)))
                   `[,(format "%s" group-name)
                     (lambda () (interactive)
                       (q-start-single-process ',group))]))
               q-process-group-list))))

;; Ensure that `q-shared-mode-map` is used as the keymap for both modes
(define-derived-mode q-script-mode prog-mode "Q-Script"
  "Major mode for editing Q scripts."
  :keymap q-script-mode-map
  :syntax-table q-script-mode-syntax-table
  ;;(set-syntax-table q-script-mode-syntax-table)
  ;;(use-local-map q-script-mode-map)
  
  ;; Use the syntax-propertize function for context-sensitive parsing
  (setq-local syntax-propertize-function #'q-syntax-propertize)
  ;; Comment variables
  ;; (setq-local comment-start "/ ")
  ;; (setq-local comment-end "")
  ;; (setq-local comment-start-skip "\\(?:^\\|\\s-\\)/+\\s-*")
  ;;(setq-local comment-use-syntax t)  - this is obsolete and has been set to constant to stop people setting it. 
  ;; Comment column for alignment
  ;; (setq-local comment-column 60)
  ;; Use default comment indentation function
  ;; (setq-local comment-indent-function #'comment-indent-default)
  ;; Ensure that comment commands work properly
  ;; (comment-normalize-vars)
  (setq font-lock-defaults q-font-lock-defaults)
  )


;; ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
;; Define the q-loadbalancer menus, keys and major mode.

(defvar q-loadbalancer-mode-map
  (let ((map (make-sparse-keymap)))
    ;; Define keybindings here
    map)
  "Keymap for `q-script-mode'.")

;;Define and attach the menu to `q-shared-mode-map`
(easy-menu-define q-loadbalancer-menu  q-loadbalancer-mode-map "Q Processes Menu."
  `("Q Process Management"
    ("Add Process Group:"
     ,@(mapcar (lambda (group)
                 (let ((group-name (car group)))
                   `[,(format "%s" group-name)
                     (lambda () (interactive)
                       (q-start-process-group ',group))]))
               q-process-group-list))
    ("Add Process:"
     ,@(mapcar (lambda (group)
                 (let ((group-name (car group)))
                   `[,(format "%s" group-name)
                     (lambda () (interactive)
                       (q-start-single-process ',group))]))
               q-process-group-list))))

(define-derived-mode q-loadbalancer-mode comint-mode "Q-LoadBalancer"
  "A major mode for interacting with a Q interpreter."
  :keymap  q-loadbalancer-mode-map
  :syntax-table q-script-mode-syntax-table
  ;; (use-local-map q-loadbalancer-mode-map)

  ;; Use the syntax-propertize-function for context-sensitive parsing
  (setq-local syntax-propertize-function #'q-syntax-propertize)
  
  (add-hook
   (make-local-variable 'comint-output-filter-functions) 'comint-strip-ctrl-m)
  (setq comint-prompt-regexp "^\\(q)+\\|[^:]*:[0-9]+>\\)")
  (setq font-lock-defaults q-font-lock-defaults)
  (set (make-local-variable 'comint-process-echoes) nil)
  (set (make-local-variable 'comint-password-prompt-regexp) "[Pp]assword")
  (q-paren-ignore)
  ;; Add the logging font-lock keywords
  ;;(q-setup-log-output-font-lock)
  )


;; (defgroup q-loadbalancer nil
;;   "Manage multiple KDB/Q processes."
;;   :group 'q-script-mode
;;   :prefix "q-process-")

;; ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
;; Q-Process creation functionality
;; Having created the modes, now provide the functionality needed when using
;; them.

(defun q-find-next-available-port (start-port increment)
  "Find the next available port starting from START-PORT.

Port numbers are incremented by INCREMENT."
  (let ((port start-port))
    (while (q-port-in-use-p port)
      (setq port (+ port increment)))
    port))

(defun q-port-in-use-p (port)
  "Check if PORT is in use.

Returns t if the PORT is already in use, nil otherwise."
  (condition-case nil
      (let ((process (make-network-process :name "q-port-test"
                                           :host 'local
                                           :service port
                                           :server t
                                           :noquery t)))
        (when process
          (delete-process process))
        nil)                                                                   ; Port is not in use
    (file-error t)))                                                           ; Port is in use


(defun q-start-process (name init-file garbage-collect port slaves workspace
                             conda-env)
  "Start a KDB/Q process named NAME with the given parameters.

NAME is the name of the process.
INIT-FILE is the path to the Q initialization file.
GARBAGE-COLLECT is a boolean indicating if garbage collection should be
enabled.
PORT is the port number for the Q process.
SLAVES is the number of slave processes to start.
WORKSPACE is the workspace limit for the Q process.
CONDA-ENV is the conda environment to activate before starting the Q process."
  ;;  (setq debug-on-error 1)
  (let*
      ((default-directory
        (if (file-name-absolute-p init-file)
            (file-name-directory init-file)
          default-directory))
       (full-init-file (expand-file-name init-file))
       (buffer-name (format "*Q PROC: %s*" name))                              ; Dynamically set buffer name
       (q-command
        (concat "q "
                (when (file-exists-p full-init-file)
                  (concat full-init-file " "))
                (when garbage-collect "-g 1 ")                                 ; Update to use -g 1 for garbage collection on
                (when (and port (/= port 0)) (format "-p %d " port))
                (when (and slaves (> slaves 0)) (format "-s %d " slaves))
                (when (and workspace (> workspace 0))
                  (format "-w %d " workspace))))
       (command-to-run
        (concat "source ~/anaconda3/etc/profile.d/conda.sh && conda activate "
                conda-env " && " q-command))
       (process-buffer (make-comint-in-buffer name buffer-name "bash" nil "-c"
                                              command-to-run)))
    (message "%s to run: %s" name command-to-run)
    (message "Starting KDB/Q process in conda environment '%s': %s"
             conda-env q-command)
    (with-current-buffer process-buffer
      (q-loadbalancer-mode))                                                   ; Enable q-load-balancer-mode to communicate with q processes.
    (display-buffer process-buffer)                                            ; Display the buffer in a window
    (message "Buffer created for process: %s" name)))

(defun q-start-single-process (group)
  "Start a single process for a given GROUP from `q-process-group-list'.

Finds the next available port starting from the group's start port, and starts
a single process."
  (let* ((group-name (nth 0 group))
         (init-file (nth 1 group))
         (garbage-collect (nth 2 group))
         (start-port (nth 3 group))
         (slaves (nth 4 group))
         (workspace (nth 5 group))
         (conda-env (nth 6 group))
         ;; Ignore the process count
         (port (q-find-next-available-port start-port 10))
         (process-name (format "%s_%d" group-name port)))
    (message "STARTING NEW PROCESS
name: %s,
init-file: %s,
garbage-collect: %s,
port: %s,
slaves: %s,
workspace: %s,
conda-env: %s"
             process-name
             init-file
             garbage-collect
             port
             slaves
             workspace
             conda-env)
    (q-start-process process-name
                     init-file
                     garbage-collect
                     port
                     slaves
                     workspace
                     conda-env)))

(defun q-start-process-group (group)
  "Start all processes for a given GROUP from `q-process-group-list'.

GROUP is a list containing the configuration of the process group."

  ;;  (setq debug-on-error 1)
  (let ((group-name (nth 0 group)))
    (cl-loop for i from 0 below (nth 7 group)
             for port = (+ (nth 3 group) (* i 10))
             do (let ((process-name (format "%s_%d" group-name port)))
                  (message "STARTING NEW PROCESS
name: %s,
init-file: %s,
garbage-collect: %s,
port: %s,
slaves: %s,
workspace: %s,
conda-env: %s"
                           process-name
                           (nth 1 group)
                           (nth 2 group)
                           port
                           (nth 4 group)
                           (nth 5 group)
                           (nth 6 group))
                  (q-start-process process-name
                                   (nth 1 group)
                                   (nth 2 group)
                                   port
                                   (nth 4 group)
                                   (nth 5 group)
                                   (nth 6 group))))))



(provide 'q-loadbalancer)

;;; q-loadbalancer.el ends here
                                                                                 ; LocalWords:  cefhijnptuv
                                                                                 ; LocalWords:  loadbalancer
                                                                                 ; LocalWords:  simonsjw
                                                                                 ; LocalWords:  LoadBalancer
                                                                                 ; LocalWords:  keymaps
                                                                                 ; LocalWords:  cominit
                                                                                 ; LocalWords:  assword
                                                                                 ; LocalWords:  defgroup
                                                                                 ; LocalWords:  comint
