;;; q-loadbalancer.el --- Manage KDB/Q processes via Emacs Lisp

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

(defgroup q-loadbalancer nil
  "Manage multiple KDB/Q processes."
  :group 'q-script-mode
  :prefix "q-process-")

(defcustom q-process-group-list '()
  "List of configurations for KDB/Q process groups.

Each entry in the list represents a KDB/Q process group configuration with the
following fields:
- Group Name: A string representing the name of the process group.
- Q Init File: A file path to an initialization file for the Q processes in
  the group.
- Garbage Collect: A boolean indicating whether garbage collection should be
  enabled.
- Start Port: An integer specifying the starting port for the group.
- Number of Slaves: An integer specifying the number of slave processes to
  start per process.
- Workspace Limit: An integer specifying the workspace limit for the Q
  processes.
- Conda Environment: A string specifying the conda environment to activate
  before starting the Q processes (default is `base').
- Process Count: An integer specifying the number of processes in the group.

Ports for each process in the group are generated in intervals of 10, starting
from the Start Port."
  :type '(repeat (list :tag "KDB/Q Process Group"
                       (string :tag "Group Name")
                       (file :tag "Q Init File" :must-match t)
                       (boolean :tag "Garbage Collect")
                       (integer :tag "Start Port" :value 6060)
                       (integer :tag "Number of Slaves")
                       (integer :tag "Workspace Limit")
                       (string :tag "Conda Environment" :value "base")
                       (integer :tag "Process Count")))
  :group 'q-loadbalancer)


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
        nil) ;; Port is not in use
    (file-error t))) ;; Port is in use



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


(defun q-loadbalancer-mode/setup-process-group (group-name
                                                init-file
                                                garbage-collect
                                                start-port slaves
                                                workspace conda-env
                                                process-count)
  "Programmatically add/update a KDB/Q process group in `q-process-group-list'.

GROUP-NAME is the name of the process group.
INIT-FILE is the path to the Q initialization file.
GARBAGE-COLLECT is a boolean indicating if garbage collection should be
enabled.
START-PORT is the starting port number for the Q processes in the group.
SLAVES is the number of slave processes to start per process.
WORKSPACE is the workspace limit for the Q processes.
CONDA-ENV is the conda environment to activate before starting the Q processes.
PROCESS-COUNT is the number of processes in the group.

If a group with the same GROUP-NAME already exists, it will be updated with
the new parameters."
  (let ((existing (assoc group-name q-process-group-list)))
    (if existing
        (setf (cdr existing) (list init-file garbage-collect start-port slaves
                                   workspace conda-env process-count))
      (setq q-process-group-list
            (append q-process-group-list
                    (list (list group-name init-file
                                garbage-collect start-port
                                slaves workspace conda-env
                                process-count)))))))

;; Example usage of q-loadbalancer-mode/setup-process-group to add or update a
;; process group.
;; (q-loadbalancer-mode/setup-process-group
;;    "Equities" "/path_to_equities/equities_deployment.q" t 6170 3 0 "base" 2)

;; ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
;; with the functionality needed now in place, load up the other scripts in the
;; package that will use it.
(let* ((loadBalancer-file-name (or load-file-name buffer-file-name))
       (loadBalancerPackageDirectory
        (file-name-directory (expand-file-name loadBalancer-file-name)))
       )
  (message loadBalancerPackageDirectory)
  (load-file (concat loadBalancerPackageDirectory "q-parse.el"))
  (load-file (concat loadBalancerPackageDirectory "process-groups.el")))

;; ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
;;; Define Menu and keymaps:
;; Define the common menu and key bindings available for both `q-script-mode'
;; and `q-loadbalancer-mode'.
;;
;; As a point of principle, we use the same menu and key map for the
;; `q-script-mode' and the `q-loadbalancer-mode'.  This means that
;; functionality specific to the `q-loadbalancer-mode' must have provision to
;; allow for reasonable defaults to capture similar behaviour from a buffer
;; under `q-script-mode'.
;; (for instance remembering the last process buffer used under
;; `q-loadbalancer-mode' and sending commands to that since `q-script-mode'
;; buffers do not have direct access to a q process).

(defvar q-script-mode-map
  (let ((map (make-sparse-keymap)))
    ;; Define additional key bindings if needed here
    map)
  "Keymap for `q-script-mode' and `q-loadbalancer-mode'.")


;; Attach the menu to both q-script-mode and q-loadbalancer-mode
(defun q-loadbalancer-mode/setup-menu ()
  "Setup Q Processes menu for `q-script-mode'."
  (easy-menu-define q-loadbalancer-menu q-script-mode-map "Q Processes Menu"
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
                 q-process-group-list)))))


;; ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
;;; Define Modes:
;; Define major modes for q-scripts and q-process buffers.

(defvar q-loadbalancer-mode-syntax-table)
(defvar q-font-lock-defaults)
(declare-function comint-mode "cominit")

;; This is the mode for q script buffers.
(define-derived-mode q-script-mode prog-mode "Q-Script"
  "Major mode for editing Q scripts."
  :keymap q-loadbalancer-menu-map
  :syntax-table q-loadbalancer-mode-syntax-table
  (setq font-lock-defaults q-font-lock-defaults))
;; Hook in the default menu and keymaps.
(add-hook 'q-script-mode-hook 'q-loadbalancer-mode/setup-menu)


;; This is the mode for q process buffers.
;; (define-derived-mode q-loadbalancer-mode comint-mode "Q-LoadBalancer"
;;   "Major mode for interacting with a Q interpreter."
;;   :keymap q-loadbalancer-menu-map
;;   :syntax-table q-loadbalancer-mode-syntax-table
;;   (setq font-lock-defaults q-font-lock-defaults))

(define-derived-mode q-loadbalancer-mode comint-mode "Q-loadBalancer"
  "Major mode for interacting with a q interpreter via the load balancer."
  :syntax-table q-loadbalancer-mode-syntax-table
  (add-hook
   (make-local-variable 'comint-output-filter-functions) 'comint-strip-ctrl-m)
  (setq comint-prompt-regexp "^\\(q)+\\|[^:]*:[0-9]+>\\)")
  (setq font-lock-defaults q-font-lock-defaults)
  (set (make-local-variable 'comint-process-echoes) nil)
  (set (make-local-variable 'comint-password-prompt-regexp) "[Pp]assword")
  (q-paren-ignore)

  ;; Add the logging font-lock keywords
  (font-lock-add-keywords
   nil                                                                         ; Apply to the current buffer
   `(
     (,
      (rx (group "[")                                                          ;  1: Opening bracket
          (group (= 4 digit))                                                  ;  2: Four-digit year
          (group ".")                                                          ;  3: Dot separator
          (group (= 2 digit))                                                  ;  4: Two-digit month
          (group ".")                                                          ;  5: Dot separator
          (group (= 2 digit))                                                  ;  6: Two-digit day
          (group "D")                                                          ;  7: `D' character
          (group (= 2 digit))                                                  ;  8: Two-digit hour
          (group ":")                                                          ;  9: Colon separator
          (group (= 2 digit))                                                  ; 10: Two-digit minute
          (group ":")                                                          ; 11: Colon separator
          (group (= 2 digit))                                                  ; 12: Two-digit second
          (group ".")                                                          ; 13: Dot separator
          (group (+ digit))                                                    ; 14: One or more digits (fractional seconds)
          (group ";")                                                          ; 15: Semicolon separator
          (group (+ (not (any ";"))))                                          ; 16: First field (non-semicolon characters)
          (group ";")                                                          ; 17: Semicolon separator
          (group (+ (not (any ";"))))                                          ; 18: Second field (non-semicolon characters)
          (group ";")                                                          ; 19: Semicolon separator
          (group (+ (not (any "]"))))                                          ; 20: Third field (non-closing-bracket characters)
          (group "]:")                                                         ; 21: Closing bracket and colon
          (group (+ (not (any ";"))))                                          ; 22: Fourth field (non-semicolon characters)
          (group ";")                                                          ; 23: Semicolon separator
          (group (0+ any) line-end))                                           ; 24: Everything from here to the end of the line

      ;; Highlighting groups
      (1 'q-log-delimiter-face t)                                              ;  1: Opening bracket
      (2 'q-log-datetime-face t)                                               ;  2: Four-digit year
      (3 'q-log-datetime-face t)                                               ;  3: Dot separator
      (4 'q-log-datetime-face t)                                               ;  4: Two-digit month
      (5 'q-log-datetime-face t)                                               ;  5: Dot separator
      (6 'q-log-datetime-face t)                                               ;  6: Two-digit day
      (7 'q-log-datetime-face t)                                               ;  7: `D' character
      (8 'q-log-datetime-face t)                                               ;  8: Two-digit hour
      (9 'q-log-datetime-face t)                                               ;  9: Colon separator
      (10 'q-log-datetime-face t)                                              ; 10: Two-digit minute
      (11 'q-log-datetime-face t)                                              ; 11: Colon separator
      (12 'q-log-datetime-face t)                                              ; 12: Two-digit second
      (13 'q-log-datetime-face t)                                              ; 13: Dot separator
      (14 'q-log-datetime-face t)                                              ; 14: One or more digits (fractional seconds)
      (15 'q-log-delimiter-face t)                                             ; 15: Semicolon separator
      (16 'q-log-process-face t)                                               ; 16: Process (non-semicolon characters)
      (17 'q-log-delimiter-face t)                                             ; 17: Semicolon separator
      (18 (let ((log-level (match-string 18)))                                 ; 18: Log Level (non-semicolon characters) - Conditional face based on text content
            (cond
             ((or (string= log-level "ERROR") (string= log-level "FATAL"))
              'q-log-level-err-face)
             ((string= log-level "WARN") 'q-log-level-warn-face)
             ((or (string= log-level "INFO") (string= log-level "DEBUG")
                  (string= log-level "SILENT"))
              'q-log-level-info-face)))
          t)
      (19 'q-log-delimiter-face t)                                             ; 19: Semicolon separator
      (20 'q-log-process-face t)                                               ; 20: Current function (non-closing-bracket characters)
      (21 'q-log-delimiter-face t)                                             ; 21: Closing bracket and colon
      (22 'q-log-message-face t)                                               ; 22: Fourth field (non-semicolon characters)
      (23 'q-log-delimiter-face t)                                             ; 23: Semicolon separator
      (24 'q-log-object-face t))                                               ; 24: Everything from here to the end of the line
     )
   )
  )

;; Hook in the default menu and keymaps.
(add-hook 'q-loadbalancer-mode-hook 'q-loadbalancer-mode/setup-menu)
(add-hook 'q-script-mode-hook 'q-loadbalancer-mode/setup-menu)

(provide 'q-loadbalancer)

;;; q-loadbalancer.el ends here

                                        ; LocalWords:  cefhijnptuv
                                        ; LocalWords:  loadbalancer
                                        ; LocalWords:  simonsjw
                                        ; LocalWords:  LoadBalancer
                                        ; LocalWords:  keymaps
                                        ; LocalWords:  cominit
