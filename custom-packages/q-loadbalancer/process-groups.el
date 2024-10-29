;;; process-groups.el --- Manage KDB/Q processes via Emacs Lisp

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



;; define the loadbalancer. 
(let ((process-name "loadbalancer")
      (port (string-to-number(getenv "kdb_loadBalancer_PORT")))
      (process-directory (getenv "kdb_loadBalancer_dir"))
      (process-script (getenv "kdb_loadBalancer_script"))
      (secondary-threads
       (string-to-number
        (or (getenv "kdb_loadBalancer_secondary_threads") "1")))
      (process-count
       (string-to-number
        (or (getenv "kdb_loadBalancer_default_num") "0")))
      (conda-environment
       (or (getenv "kdb_loadBalancer_conda_env") "base"))
      )
  (q-setup-process-group-programmatically
   process-name 
   (concat process-directory process-script)
   t
   port
   secondary-threads
   0                                                                           ; workspace limit - 0 removes any restrictions on upper memory size used by the process. 
   conda-environment
   process-count))

;; define the gateway. 
(let ((process-name "gateway")
      (port (string-to-number(getenv "kdb_gateway_PORT")))
      (process-directory (getenv "kdb_gateway_dir"))
      (process-script (getenv "kdb_gateway_script"))
      (secondary-threads
       (string-to-number
        (or (getenv "kdb_gateway_secondary_threads") "1")))
      (process-count
       (string-to-number
        (or (getenv "kdb_gateway_default_num") "0")))
      (conda-environment
       (or (getenv "kdb_gateway_conda_env") "base"))
      )
  (q-setup-process-group-programmatically
   process-name 
   (concat process-directory process-script)
   t
   port
   secondary-threads
   0                                                                           ; workspace limit - 0 removes any restrictions on upper memory size used by the process. 
   conda-environment
   process-count))

;; define the secondary processes. 
(let ((process-name "process_secondary")
      (port (string-to-number(getenv "kdb_process_secondary_PORT")))
      (process-directory (getenv "kdb_process_secondary_dir"))
      (process-script (getenv "kdb_process_secondary_script"))
      (secondary-threads
       (string-to-number
        (or (getenv "kdb_process_secondary_secondary_threads") "1")))
      (process-count
       (string-to-number
        (or (getenv "kdb_process_secondary_default_num") "0")))
      (conda-environment
       (or (getenv "kdb_process_secondary_conda_env") "base"))
      )
  (q-setup-process-group-programmatically
   process-name 
   (concat process-directory process-script)
   t
   port
   secondary-threads
   0                                                                           ; workspace limit - 0 removes any restrictions on upper memory size used by the process. 
   conda-environment
   process-count))

;; define the equities hdb. 
(let ((process-name "service_equities")
      (port (string-to-number(getenv "kdb_service_equities_PORT")))
      (process-directory (getenv "kdb_service_equities_dir"))
      (process-script (getenv "kdb_service_equities_script"))
      (secondary-threads
       (string-to-number
        (or (getenv "kdb_service_equities_secondary_threads") "1")))
      (process-count
       (string-to-number
        (or (getenv "kdb_service_equitie_sdefault_num") "0")))
      (conda-environment
       (or (getenv "kdb_service_equities_conda_env") "base"))
      )
  (q-setup-process-group-programmatically
   process-name 
   (concat process-directory process-script)
   t
   port
   secondary-threads
   0                                                                           ; workspace limit - 0 removes any restrictions on upper memory size used by the process. 
   conda-environment
   process-count))

;; define the ai hdb. 
(let ((process-name "service_ai")
      (port (string-to-number(getenv "kdb_service_ai_PORT")))
      (process-directory (getenv "kdb_service_ai_dir"))
      (process-script (getenv "kdb_service_ai_script"))
      (secondary-threads
       (string-to-number
        (or (getenv "kdb_service_ai_secondary_threads") "1")))
      (process-count
       (string-to-number
        (or (getenv "kdb_service_ai_default_num") "0")))
      (conda-environment
       (or (getenv "kdb_service_ai_conda_env") "base"))
      )
  (q-setup-process-group-programmatically
   process-name 
   (concat process-directory process-script)
   t
   port
   secondary-threads
   0                                                                           ; workspace limit - 0 removes any restrictions on upper memory size used by the process. 
   conda-environment
   process-count))

;; define the reddit hdb. 
(let ((process-name "service_reddit")
      (port (string-to-number(getenv "kdb_service_reddit_PORT")))
      (process-directory (getenv "kdb_service_reddit_dir"))
      (process-script (getenv "kdb_service_reddit_script"))
      (secondary-threads
       (string-to-number
        (or (getenv "kdb_service_reddit_secondary_threads") "1")))
      (process-count
       (string-to-number
        (or (getenv "kdb_service_reddit_default_num") "0")))
      (conda-environment
       (or (getenv "kdb_service_reddit_conda_env") "base"))
      )
  (q-setup-process-group-programmatically
   process-name 
   (concat process-directory process-script)
   t
   port
   secondary-threads
   0                                                                           ; workspace limit - 0 removes any restrictions on upper memory size used by the process. 
   conda-environment
   process-count))

;; define the client. 
(let ((process-name "client")
      (port (string-to-number(getenv "kdb_client_PORT")))
      (process-directory (getenv "kdb_client_dir"))
      (process-script (getenv "kdb_client_script"))
      (secondary-threads
       (string-to-number
        (or (getenv "kdb_client_secondary_threads") "0")))
      (process-count
       (string-to-number
        (or (getenv "kdb_client_default_num") "1")))
      (conda-environment
       (or (getenv "kdb_client_conda_env") "base"))
      )
  (q-setup-process-group-programmatically
   process-name 
   (concat process-directory process-script)
   t
   port
   secondary-threads
   0   ; workspace limit - 0 removes any restrictions on upper memory size used by the process. 
   conda-environment
   process-count))


;; define the dash. 
(let ((process-name "dash")
      (port (string-to-number(getenv "kdb_dash_PORT")))
      (process-directory (getenv "kdb_dash_dir"))
      (process-script (getenv "kdb_dash_script"))
      (secondary-threads
       (string-to-number
        (or (getenv "kdb_dash_secondary_threads") "0")))
      (process-count
       (string-to-number
        (or (getenv "kdb_dash_default_num") "1")))
      (conda-environment
       (or (getenv "kdb_dash_conda_env") "base"))
      )
  (q-setup-process-group-programmatically
   process-name 
   (concat process-directory process-script)
   t
   port
   secondary-threads
   0                                                                           ; workspace limit - 0 removes any restrictions on upper memory size used by the process. 
   conda-environment
   process-count))

(provide 'process-groups)

;;; process-groups.el ends here

