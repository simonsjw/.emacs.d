;;; custom-loadbalancer-support.el --- LoadBalancer configuration -*- mode: emacs-lisp; lexical-binding: t; -*-

;;; License
;; Copyright (C) 2022
;; SPDX-License-Identifier: MIT

;; Author: Erik Lundstedt, System Crafters Community

;;; Commentary:

;; This file was made with outline-minor-mode in mind
;; and therefore have ";;;+"-comments as headers.
;;; Code:

;;; Configure variables
;; Set defaults for any loadBalancer environmental variables not
;; already set.

(require 'path-support)
(require 'logging-config)
(log/debug :fn 'custom-loadbalancer-support
           :msg "Starting load of the LLM-support module."
           :obj t)

;;;; 1. functions to set/get environmental variables for KDB setup.
;;   --------------------------------------------------------------
(defun loadBalancer/set-env-vars-for-base-config ()
  "Set up the environmental variables needed for the base kdb/q
configuration. "

  ;; Base setup
  ;; ----------
  (unless (getenv "QHOME")
    (setenv "QHOME" "/opt/q/"))
  (unless (getenv "EMBED_Q_ANACONDA_ENV")
    (setenv "EMBED_Q_ANACONDA_ENV" "pyTorch"))
  (unless (getenv "QSPACE")
    (setenv "QSPACE" "/home/simon/q/"))
  (unless (getenv "Q_MAIN_PROJECT_PATH")
    (setenv "Q_MAIN_PROJECT_PATH"
            "/mnt/HDD04_WDD_08TB/workspace/dev-q/"))
  (unless (getenv "PATH")
    (setenv "PATH" (concat (getenv "QHOME") "l64/:" (getenv "PATH"))))

  ;; LoadBalancer Setup
  ;; ------------------
  (unless (getenv "kdb_load_balancer_session_name")
    (setenv "kdb_load_balancer_session_name" "loadBalancer"))
  (unless (getenv "kdb_env_file")
    (setenv "kdb_env_file" "/home/simon/Me/secrets/env.txt"))
  (unless (getenv "kdb_log_dir")
    (setenv "kdb_log_dir" (concat (getenv "QSPACE") "logs")))
  (unless (getenv "kdb_q_executable")
    (setenv "kdb_q_executable" (concat (getenv "QHOME") "l64/q")))
  )

(defun loadBalancer/set-env-vars-for-loadbalancer-gateway ()
  "Get environmental variables for the loadbalancer and gateway
machinery. If not present then set them to a default value. "
  
  ;; LoadBalancer
  ;; ------------
  (unless (getenv "kdb_loadBalancer_PORT")
    (setenv "kdb_loadBalancer_PORT" "5001"))
  (unless (getenv "kdb_loadBalancer_dir")
    (setenv "kdb_loadBalancer_dir"
            (concat (getenv "QSPACE")
                    "loadBalancerFramework/loadBalancer/")))
  (unless (getenv "kdb_loadBalancer_script")
    (setenv "kdb_loadBalancer_script" "loadBalancer.q"))
  (unless (getenv "kdb_loadBalancer_secondary_threads")
    (setenv "kdb_loadBalancer_secondary_threads" "0"))

  ;; Gateway
  ;; -------
  (unless (getenv "kdb_gateway_PORT")
    (setenv "kdb_gateway_PORT" "5003"))
  (unless (getenv "kdb_gateway_dir")
    (setenv "kdb_gateway_dir"
            (concat (getenv "QSPACE")
                    "loadBalancerFramework/gateway/")))
  (unless (getenv "kdb_gateway_script")
    (setenv "kdb_gateway_script" "gateway.q"))
  (unless (getenv "kdb_gateway_secondary_threads")
    (setenv "kdb_gateway_secondary_threads" "0"))
  )

(defun loadBalancer/set-env-vars-for-developer()
  "Set up then environmental variables needed by KDB Developer. "

  ;; AX Libraries 
  ;; ------------
  ;; (additional functionality in Developer)
  (unless (getenv "AXLIBRARIES_HOME")
    (setenv "AXLIBRARIES_HOME"
            "/home/simon/developer/ax-libraries/"))

  ;; Interactive Installer Variables
  ;; -------------------------------
  (unless (getenv "DEVELOPER_TARGET_OS")
    (setenv "DEVELOPER_TARGET_OS" "ubuntu20"))
  (unless (getenv "DEVELOPER_HOME")
    (setenv "DEVELOPER_HOME" "/home/simon/developer"))
  (unless (getenv "DEVELOPER_DATA")
    (setenv "DEVELOPER_DATA" "/home/simon/developer/data"))
  (unless (getenv "DEVELOPER_PORT")
    (setenv "DEVELOPER_PORT" "8080"))
  (unless (getenv "DEVELOPER_USE_TLS")
    (setenv "DEVELOPER_USE_TLS" "no"))
  (unless (getenv "KX_SSL_CERT_FILE")
    (setenv "KX_SSL_CERT_FILE" ""))
  (unless (getenv "KX_SSL_CA_CERT_FILE")
    (setenv "KX_SSL_CA_CERT_FILE" ""))
  (unless (getenv "KX_SSL_KEY_FILE")
    (setenv "KX_SSL_KEY_FILE" ""))
  (unless (getenv "DEVELOPER_USE_AUTH")
    (setenv "DEVELOPER_USE_AUTH" "no"))
  (unless (getenv "DEVELOPER_WORKSPACE_CD")
    (setenv "DEVELOPER_WORKSPACE_CD" "yes"))

  (unless (getenv "DEVELOPER_PLUGIN_PATH")
    (setenv "DEVELOPER_PLUGIN_PATH"
            (concat (getenv "DEVELOPER_HOME") "/plugins")))

  (unless (getenv "DEVELOPER_EDITOR_DISPLAY_ON_EXECUTE")
    (setenv "DEVELOPER_EDITOR_DISPLAY_ON_EXECUTE" "no"))
  
  (unless (getenv "kdb_developer_PORT")
    (setenv "kdb_developer_PORT" "8081"))
  (unless (getenv "kdb_developer_dir")
    (setenv "kdb_developer_dir"
            (concat (getenv "QSPACE")
                    "loadBalancerFramework/developer_client/")))
  (unless (getenv "kdb_developer_script")
    (setenv "kdb_developer_script"
            "/home/simon/developer/launcher.q_"))
  (unless (getenv "kdb_client_secondary_threads")
    (setenv "kdb_client_secondary_threads" "0"))
  (unless (getenv "kdb_developer_conda_env")
    (setenv "kdb_developer_conda_env" "pyTorch"))
  )

(defun loadBalancer/set-env-vars-for-base_q_client()
  "Set up then environmental variables needed by the base q client. "
  (unless (getenv "kdb_client_PORT")
    (setenv "kdb_client_PORT" "8080"))
  (unless (getenv "kdb_client_dir")
    (setenv
     "kdb_client_dir"
     (concat (getenv "QSPACE")
             "loadBalancerFramework/developer_client/")))
  (unless (getenv "kdb_client_script")
    (setenv "kdb_client_script" "/home/simon/developer/launcher.q_"))
  (unless (getenv "kdb_client_conda_env")
    (setenv "kdb_client_conda_env" "pyTorch"))
  )

(defun loadBalancer/set-env-vars-for-dash()
  "Set up then environmental variables needed by KDB Dash. "
  ;; Dash
  ;; ----
  (unless (getenv "kdb_dash_PORT")
    (setenv "kdb_dash_PORT" "10001"))
  (unless (getenv "kdb_dash_dir")
    (setenv "kdb_dash_dir" "/home/simon/dash/"))
  (unless (getenv "kdb_dash_script")
    (setenv "kdb_dash_script" "/home/simon/dash/dash.q"))
  (unless (getenv "kdb_dash_secondary_threads")
    (setenv "kdb_dash_secondary_threads" "0"))
  (unless (getenv "kdb_dash_conda_env")
    (setenv "kdb_dash_conda_env" "base"))
  )

(defun loadBalancer/set-env-vars-for-process-secondary()
  "Set up then environmental variables needed by secondary processes
on the loadbalancer.

A Secondary Process is like a service except that it is not attached
to an HDB so has no memory mapping overhead."
  
  ;; Process Secondary
  ;; -----------------
  (unless (getenv "kdb_process_secondary_PORT")
    (setenv "kdb_process_secondary_PORT" "6070"))
  (unless (getenv "kdb_process_secondary_dir")
    (setenv
     "kdb_process_secondary_dir"
     (concat (getenv "QSPACE")
             "loadBalancerFramework/process_Secondary/")))
  (unless (getenv "kdb_process_secondary_script")
    (setenv "kdb_process_secondary_script" "process_Secondary.q"))
  (unless (getenv "kdb_process_secondary_default_number")
    (setenv "kdb_process_secondary_default_number" "1"))
  (unless (getenv "kdb_process_secondary_secondary_threads")
    (setenv "kdb_process_secondary_secondary_threads" "0"))
  (unless (getenv "kdb_process_secondary_conda_env")
    (setenv "kdb_process_secondary_conda_env" "pyTorch"))
  )

(defun loadBalancer/set-env-vars-for-service-equities()
  "Set up then environmental variables needed by equities services
on the loadbalancer.

A Service is a process linked to an HDB. Multiple services can be
attached to the same HDB so care is needed to avoid mutiple writes to
the same element on disk.

In this case, the Equities HDNBcontains a set of tables with share 
price data. "
  
  ;; Service Equities
  ;; ----------------
  (unless (getenv "kdb_service_equities_PORT")
    (setenv "kdb_service_equities_PORT" "6170"))
  (unless (getenv "kdb_service_equities_dir")
    (setenv
     "kdb_service_equities_dir"
     (concat
      (getenv "QSPACE") "loadBalancerFramework/service_Equities/")))
  (unless (getenv "kdb_service_equities_script")
    (setenv "kdb_service_equities_script" "service_Equities.q"))
  (unless (getenv "kdb_service_equities_default_num")
    (setenv "kdb_service_equities_default_num" "1"))
  (unless (getenv "kdb_service_equities_secondary_threads")
    (setenv "kdb_service_equities_secondary_threads" "3"))
  (unless (getenv "kdb_service_equities_conda_env")
    (setenv "kdb_service_equities_conda_env" "pyTorch")))

(defun loadBalancer/set-env-vars-for-service-ai()
  "Set up then environmental variables needed by ai services
on the loadbalancer.

A Service is a process linked to an HDB. Multiple services can be
attached to the same HDB so care is needed to avoid mutiple writes to
the same element on disk.

In this case, the ai HDB ontains a set of functions integrated into 
pyTorch and tables containing information from neural networks. "

  ;; Service Ai
  ;; ----------
  (unless (getenv "kdb_service_ai_PORT")
    (setenv "kdb_service_ai_PORT" "6270"))
  (unless (getenv "kdb_service_ai_dir")
    (setenv "kdb_service_ai_dir"
            (concat
             (getenv "QSPACE") "loadBalancerFramework/service_Ai/")))
  (unless (getenv "kdb_service_ai_script")
    (setenv "kdb_service_ai_script" "service_Ai.q"))
  (unless (getenv "kdb_service_ai_default_number")
    (setenv "kdb_service_ai_default_number" "1"))
  (unless (getenv "kdb_service_ai_secondary_threads")
    (setenv "kdb_service_ai_secondary_threads" "0"))
  (unless (getenv "kdb_service_ai_conda_env")
    (setenv "kdb_service_ai_conda_env" "pyTorch")))

(defun loadBalancer/set-env-vars-for-service-reddit()
  "Set up then environmental variables needed by reddit services
on the loadbalancer.

A Service is a process linked to an HDB. Multiple services can be
attached to the same HDB so care is needed to avoid mutiple writes to
the same element on disk.

In this case, the Reddit HDB contains a set of data from the Reddit
corpus. "
  
  ;; Service Reddit
  ;; ----------------
  (unless (getenv "kdb_service_ai_PORT")
    (setenv "kdb_service_ai_PORT" "6270"))
  (unless (getenv "kdb_service_ai_dir")
    (setenv "kdb_service_ai_dir"
            (concat
             (getenv "QSPACE") "loadBalancerFramework/service_Ai/")))
  (unless (getenv "kdb_service_ai_script")
    (setenv "kdb_service_ai_script" "service_Ai.q"))
  (unless (getenv "kdb_service_ai_default_number")
    (setenv "kdb_service_ai_default_number" "1"))
  (unless (getenv "kdb_service_ai_secondary_threads")
    (setenv "kdb_service_ai_secondary_threads" "0"))
  (unless (getenv "kdb_service_ai_conda_env")
    (setenv "kdb_service_ai_conda_env" "pyTorch")))

;; THIS IS THE END OF 1. functions to set/get environmental var...



;;;; 2. functions to manage KDB processes. 
;;   -------------------------------------



(defun loadBalancer/find-or-create-frame (frame-name)
  "Find or create a frame with a given FRAME-NAME."
  (let ((frame (car (seq-filter (lambda (f)
                                  (equal (frame-parameter f 'name) frame-name))
                                (frame-list)))))
    (if frame
        (progn
          (select-frame-set-input-focus frame)
          frame)
      (make-frame `((name . ,frame-name))))))

(defun loadBalancer/start-process-in-frame (process-name frame-name)
  "Start a named PROCESS-NAME in a named FRAME-NAME."
  (find-or-create-frame frame-name)
  (let ((buffer-name (format "*%s*" process-name)))
    (unless (get-buffer buffer-name)
      (with-current-buffer (term "/bin/bash")
        (rename-buffer buffer-name)
        (term-send-raw-string (format "./start-%s.sh\n" process-name))))))




;;;;; 1. Function to Check and Manage Ports
;; This is similar to what you might have in your shell scripts, 
;; but adapted to be initiated from Emacs.
(defun loadBalancer/find-next-available-port (start-port)
  "Find the next available port starting from START-PORT."
  (let ((port start-port)
        (used-ports (mapcar (lambda (buf)
                              (with-current-buffer buf
                                (and (boundp 'process-port) process-port)))
                            (buffer-list))))
    (while (member port used-ports)
      (setq port (1+ port)))
    port))


;;;;; 2. Starting a Process in a New Buffer
;; Here’s how you might start a new process in a buffer, creating a
;; new term buffer if one does not exist.
(defun loadBalancer/start-load-balancer-process (process-name start-port)
  "Start a new load balancer process with PROCESS-NAME starting from START-PORT."
  (interactive "sProcess Name: \nnStart Port: ")
  (let ((port (find-next-available-port start-port))
        (buffer-name (format "*%s-%d*" process-name port)))
    (unless (get-buffer buffer-name)
      (with-current-buffer (term "/bin/bash")
        (rename-buffer buffer-name)
        (setq-local process-port port)
        (term-send-raw-string
         (format
          "Start your process command here with port %d\n"
          port))))))


(defun loadBalancer/command-string-to-start-Q-process
    (env_file_text
     conda_env_txt
     script_dir_txt
     q_executable_txt
     script_file_path_txt
     secondary_threads_txt
     port)
  "Create a string that can be used with a terminal to start a
KDB/Q process."
  (format "source /home/simon/anaconda3/etc/profile.d/conda.sh
             source ${env_file}; \
             conda activate ${conda_env}; \
             cd ${script_dir}; \
             /usr/bin/rlwrap -r ${q_executable} ${script_file} \
             -g 1 -s ${secondary_threads} -p ${port} 2>&1"
          env_file_text
          conda_env_txt
          script_dir_txt
          q_executable_txt
          script_file_path_txt
          secondary_threads_txt
          port))

(defun loadBalancer/start-secondary-process ()

  (let*
      ((env_file_txt (getenv "kdb_env_file"))
       (conda_env_txt (getenv "kdb_process_secondary_conda_env"))
       (script_dir_txt (getenv "kdb_process_secondary_dir"))
       (q_executable_txt (getenv "q_executable"))
       (script_file_path_txt (getenv "kdb_process_secondary_script"))
       (secondary_threads_txt
        (getenv "kdb_process_secondary_secondary_threads"))
       (start-port (getenv "kdb_process_secondary_PORT"))
       (port (loadBalancer/find-next-available-port start-port))

       

       (loadBalancer/command-string-to-start-Q-process
        env_file_txt
        conda_env_txt
        script_dir_txt
        q_executable_txt
        script_file_path_txt
        secondary_threads_txt
        port)))

;;;;; 3. Managing and Interacting with the Process

;; You can write functions to send commands to the process, stop it,
;; or restart it.
(defun loadBalancer/send-command-to-process (process-name command)
  "Send a COMMAND to a process with PROCESS-NAME."
  (let ((buffer (get-buffer (format "*%s*" process-name))))
    (when buffer
      (with-current-buffer buffer
        (goto-char (point-max))
        (insert command)
        (term-send-input)))))

(defun loadBalancer/stop-process (process-name)
  "Stop the process with PROCESS-NAME."
  (let ((buffer (get-buffer (format "*%s*" process-name))))
    (when buffer
      (kill-buffer buffer))))



(defun loadBalancer/start-interactive-process (process-name command start-port)
  "Start an interactive process named PROCESS-NAME, running COMMAND starting at START-PORT."
  (interactive "sProcess Name: \nsCommand: \nnStart Port: ")
  (let* ((port (find-next-available-port start-port))
         (buffer-name (format "*%s-%d*" process-name port)))
    (unless (get-buffer buffer-name)
      (let ((buffer (ansi-term "/bin/bash" buffer-name)))
        (setq-local process-port port)
        (with-current-buffer buffer
          (term-send-raw-string (format "%s %d\n" command port)))))))



(defun start-kdb-process (session-name)
  ;; (start-port num-processes)
  "Start multiple KDB processes from START-PORT up to NUM-PROCESSES."
  (interactive
   (list
    (read-number "Start Port: ")
    (read-number "Number of Processes: ")))
  (let* ((env-file (get-env-with-default "kdb-env-file" "/home/simon/Me/secrets/env.txt"))
         (q-executable (get-env-with-default "kdb-q-executable" (concat (getenv "QHOME") "l64/q")))
         ;; (log-dir (get-env-with-default "kdb-log-dir" "/home/simon/q/logs"))
         (session-name (get-env-with-default "kdb-load-balancer-session-name" "loadBalancer"))
         (process-name "kdbProcessSecondary")
         ;; (tmux-window-prefix "pSecondary")
         (script-dir (get-env-with-default "kdb-secondaries-dir" "/home/simon/q/loadBalancerFramework/process_Secondary/"))
         (script-file (get-env-with-default "kdb-process-secondary-script" "process_Secondary.q"))
         (conda-env (get-env-with-default "kdb-process-secondary-conda-env" "base"))
         (secondary-threads (get-env-with-default "kdb-process-secondary-secondary-threads" "0"))
         (end-port (+ start-port num-processes - 1)))
    (dotimes (i num-processes)
      (let* ((port (+ start-port i))
             (command (format "bash -c 'source /home/simon/anaconda3/etc/profile.d/conda.sh && source %s && conda activate %s && cd %s && /usr/bin/rlwrap -r %s %s -g 1 -s %s -p %d 2>&1'"
                              env-file conda-env script-dir q-executable script-file secondary-threads port))
             (buffer-name (format "*kdb-%d*" port)))
        (unless (get-buffer buffer-name)
          (let ((buffer (ansi-term "/bin/bash" buffer-name)))
            (with-current-buffer buffer
              (term-send-raw-string (concat command "\n")))))))))


;;; Example Usage
;;  -------------
;; You can use these functions to manage and interact with your
;; loadBalancer processes. For instance, to start a process, you might
;; call (start-load-balancer-process "loadBalancer" 4000).

;; To send a command, use
;; (send-command-to-process "loadBalancer" "some-command")

;; To stop the process, call
;; (stop-process "loadBalancer")

(log/debug :fn 'custom-loadbalancer-support
           :msg "Ending load of the custom-loadbalancer-support.el module."
           :obj t)

(provide 'custom-loadbalancer-support)
;;; custom-loadbalancer-support.el ends here
