;;; q-loadbalancer.el --- Manage KDB/Q processes via Emacs Lisp

;; Author: Simon Watson  <simon_watson_sjw@hotmail.com>
;; Version: 1.0
;; Keywords: KDB, Q, process management, Emacs Lisp
;; URL: https://github.com/simonsjw/q-loadbalancer
;; Package-Requires: ((emacs "24.3") (q-mode "1.0"))

;;; Commentary:
;;
;; This package provides functionality to manage multiple KDB/Q processes
;; within Emacs.
;; It allows users to start and manage several Q processes, each with a unique
;; configuration.
;; The processes are managed using Emacs buffers, and users can customize
;; settings such as
;; the initialization file, garbage collection, port, number of slaves, and
;; workspace limit.
;;
;; Features:
;; - Start multiple KDB/Q processes with customizable configurations.
;; - Each process runs in its own buffer, allowing interaction and evaluation
;;   of Q scripts.
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

(require 'q-mode)
(require 'cl-lib)

(defgroup q-loadbalancer nil
  "Manage multiple KDB/Q processes."
  :group 'q-mode
  :prefix "q-process-")

(defcustom q-process-list '()
  "List of configurations for KDB/Q processes.

Each entry in the list represents a KDB/Q process configuration with the
following fields:
- Process Name: A string representing the name of the process.
- Q Init File: A file path to an initialization file for the Q process.
- Garbage Collect: A boolean indicating whether garbage collection should be
  enabled.
- Port: An integer specifying the port on which the Q process should run
  (default is 6060).
- Number of Slaves: An integer specifying the number of slave processes to
  start.
- Workspace Limit: An integer specifying the workspace limit for the Q
  process."
  :type '(repeat (list :tag "KDB/Q Process"
                       (string :tag "Process Name")
                       (file :tag "Q Init File" :must-match t)
                       (boolean :tag "Garbage Collect")
                       (integer :tag "Port" :value 6060)
                       (integer :tag "Number of Slaves")
                       (integer :tag "Workspace Limit")))
  :group 'q-loadbalancer)

(defun q-start-process (name init-file garbage-collect port slaves workspace)
  "Start a KDB/Q process named NAME with the given parameters.

NAME is the name of the process.
INIT-FILE is the path to the Q initialization file.
GARBAGE-COLLECT is a boolean indicating if garbage collection should be
  enabled.
PORT is the port number for the Q process.
SLAVES is the number of slave processes to start.
WORKSPACE is the workspace limit for the Q process."
  (let* ((default-directory (if (file-name-absolute-p init-file)
                                (file-name-directory init-file)
                              default-directory))
         (full-init-file (expand-file-name init-file))
         (q-command
          (concat "q "
                  (when
                      (file-exists-p full-init-file)
                    (concat full-init-file " "))
                  (when garbage-collect "-g ")
                  (when
                      (and port (/= port 0)) (format "-p %d " port))
                  (when
                      (and slaves (> slaves 0))
                    (format "-s %d " slaves))
                  (when
                      (and workspace (> workspace 0))
                    (format "-w %d " workspace)))))
    
    (message "Starting KDB/Q process: %s" q-command)
    (make-comint name "q" nil "-q" q-command)))

(defun q-create-process-buffers ()
  "Create buffers for all configured KDB/Q processes in `q-process-list'.

This function iterates over the list of process configurations and starts each
KDB/Q process, creating a buffer for interaction."
  (interactive)
  (cl-loop
   for (name init-file garbage-collect port slaves workspace) in q-process-list
   do (q-start-process name init-file garbage-collect port slaves workspace)))

(defun q-mode-add-menu-item ()
  "Add a custom Q-mode menu item to start processes.

This function adds a new menu item under the Q-mode menu, allowing users to
start configured KDB/Q processes interactively."
  (define-key q-mode-map [menu-bar q-processes]
    (cons "Q Processes"
          (let ((submenu (make-sparse-keymap "Q Processes")))
            (dolist (proc q-process-list)
              (let ((name (car proc)))
                (define-key submenu (vector (intern name))
                  `(menu-item ,name
                              ,(lambda () (interactive)
                                 (q-start-process (car proc)
                                                 (cadr proc)
                                                 (caddr proc)
                                                 (cadddr proc)
                                                 (nth 4 proc)
                                                 (nth 5 proc)))))))
            submenu))))

(add-hook 'q-mode-hook 'q-mode-add-menu-item)

(provide 'q-loadbalancer)

;;; q-loadbalancer.el ends here
