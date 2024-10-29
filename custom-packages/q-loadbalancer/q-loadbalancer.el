;;; q-loadbalancer.el --- Manage KDB/Q processes via Emacs Lisp

;; Author: Your Name <your.email@example.com>
;; Version: 1.2
;; Keywords: KDB, Q, process management, Emacs Lisp
;; URL: https://github.com/yourusername/q-loadbalancer
;; Package-Requires: ((emacs "24.3") (q-mode "1.0"))

;;; Commentary:
;;
;; This package provides functionality to manage multiple KDB/Q processes within Emacs.
;; It allows users to start and manage several Q processes, grouped by type, with each group
;; potentially containing multiple processes. The processes are managed using Emacs buffers,
;; and users can customize settings such as the initialization file, garbage collection, port,
;; number of slaves, workspace limit, conda environment, and process count.
;;
;; Features:
;; - Start multiple KDB/Q processes with customizable configurations.
;; - Processes can be grouped, and multiple instances can be started within a group.
;; - Each process runs in its own buffer, allowing interaction and evaluation of Q scripts.
;; - Customizable settings via Emacs 'custom' interface.
;; - Dynamic menu integration for easy process management.
;;
;; To use this package, add the following to your Emacs configuration:
;;
;;   (require 'q-loadbalancer)
;;
;; You can customize the process configurations by running:
;;
;;   M-x customize-group RET q-loadbalancer RET
;;
;;; Code:

(require 'easymenu)
(require 'cl-lib)


(defgroup q-loadbalancer nil
  "Manage multiple KDB/Q processes."
  :group 'q-mode
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
    (message "Starting KDB/Q process in conda environment '%s': %s"
             conda-env q-command)
    (with-current-buffer process-buffer (q-shell-mode 1))  ; Enable q-shell-mode
    (message "Buffer created for process: %s" name)))


(defun q-create-process-buffers ()
  "Create buffers for all configured KDB/Q processes in `q-process-group-list'.

This function iterates over the list of process group configurations and
starts each KDB/Q process in each group, creating a buffer for interaction."
  (interactive)
  (cl-loop for (group-name init-file garbage-collect start-port slaves workspace conda-env process-count) in q-process-group-list
           do (cl-loop for i from 0 below process-count
                       for port = (+ start-port (* i 10))
                       do (let ((process-name (format "%s_%d" group-name port))
                                )
                            (q-start-process process-name init-file
                                             garbage-collect
                                             port slaves workspace conda-env)))
           )
  )

(defun q-start-process-group (group)
  "Start all processes for a given GROUP from `q-process-group-list'.

GROUP is a list containing the configuration of the process group."
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


(defun q-mode-add-menu-item ()
  "Add a custom Q-mode menu item to start processes."
  (easy-menu-define q-mode-menu q-mode-map "Q Processes Menu"
    `("Q Processes"
      ,@(mapcar (lambda (group)
                  (let ((group-name (car group)))
                    `[,(format "%s" group-name)
                      (lambda () (interactive)
                        (q-start-process-group ',group))]))
                q-process-group-list))))

(add-hook 'q-mode-hook 'q-mode-add-menu-item)

(eval-after-load 'q-mode
  '(q-mode-add-menu-item))

(add-hook 'q-mode-hook 'q-mode-add-menu-item)

(defun q-setup-process-group-programmatically (group-name init-file
                                                          garbage-collect
                                                          start-port slaves
                                                          workspace conda-env
                                                          process-count)
  "Programmatically add or update a KDB/Q process group in
`q-process-group-list'.

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
      (customize-set-variable 'q-process-group-list
                              (append q-process-group-list
                                      (list (list group-name init-file
                                                  garbage-collect start-port
                                                  slaves workspace conda-env
                                                  process-count)))))))

;; Example usage of q-setup-process-group-programmatically to add or update a
;; process group.
;; (q-setup-process-group-programmatically
;;    "Equities" "/path_to_equities/equities_deployment.q" t 6170 3 0 "base" 2)


(provide 'q-loadbalancer)

;;; q-loadbalancer.el ends here

                                        ; LocalWords:  cefhijnptuv
