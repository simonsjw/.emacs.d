
(defcustom dape-configs
  `((attach
     modes nil
     ensure (lambda (config)
              (unless (plist-get config 'port)
                (user-error "Missing `port' property")))
     host "localhost"
     :request "attach")
    (launch
     modes nil
     command-cwd dape-command-cwd
     ensure (lambda (config)
              (unless (plist-get config 'command)
                (user-error "Missing `command' property")))
     :request "launch")
    ,(let* ((extension-directory
             (expand-file-name
              (file-name-concat dape-adapter-dir "bash-debug" "extension")))
            (bashdb-dir (file-name-concat extension-directory "bashdb_dir")))
       `(bash-debug
         modes (sh-mode bash-ts-mode)
         ensure (lambda (config)
                  (dape-ensure-command config)
                  (let ((dap-debug-server-path
                         (car (plist-get config 'command-args))))
                    (unless (file-exists-p dap-debug-server-path)
                      (user-error "File %S does not exist" dap-debug-server-path))))
         command "node"
         command-args (,(file-name-concat extension-directory "out" "bashDebug.js"))
         fn (lambda (config)
              (thread-first config
                            (plist-put :pathBashdbLib ,bashdb-dir)
                            (plist-put :pathBashdb (file-name-concat ,bashdb-dir "bashdb"))
                            (plist-put :env `(:BASHDB_HOME ,bashdb-dir . ,(plist-get config :env)))))
         :type "bashdb"
         :cwd dape-cwd
         :program dape-buffer-default
         :args []
         :pathBash "bash"
         :pathCat "cat"
         :pathMkfifo "mkfifo"
         :pathPkill "pkill"))
    ,@(let ((codelldb
             `( ensure dape-ensure-command
                command-cwd dape-command-cwd
                command ,(file-name-concat dape-adapter-dir
                                           "codelldb"
                                           "extension"
                                           "adapter"
                                           "codelldb")
                port :autoport
                :type "lldb"
                :request "launch"
                :cwd "."))
            (common `(:args [] :stopOnEntry nil)))
        `((codelldb-cc
           modes (c-mode c-ts-mode c++-mode c++-ts-mode)
           command-args ("--port" :autoport)
           ,@codelldb
           :program "a.out"
           ,@common)
          (codelldb-rust
           modes (rust-mode rust-ts-mode)
           command-args ("--port" :autoport
                         "--settings" "{\"sourceLanguages\":[\"rust\"]}")
           ,@codelldb
           :program (file-name-concat "target" "debug"
                                      (car (last (file-name-split
                                                  (directory-file-name (dape-cwd))))))
           ,@common)))
    (cpptools
     modes (c-mode c-ts-mode c++-mode c++-ts-mode)
     ensure dape-ensure-command
     command-cwd dape-command-cwd
     command ,(file-name-concat dape-adapter-dir
                                "cpptools"
                                "extension"
                                "debugAdapters"
                                "bin"
                                "OpenDebugAD7")
     fn (lambda (config)
          ;; For MI=GDB the :program path need to be absolute
          (let ((program (plist-get config :program)))
            (if (file-name-absolute-p program)
                config
              (thread-last (tramp-file-local-name (dape--guess-root config))
                           (expand-file-name program)
                           (plist-put config :program)))))
     :type "cppdbg"
     :request "launch"
     :cwd "."
     :program "a.out"
     :MIMode ,(seq-find 'executable-find '("lldb" "gdb")))
    ,@(let ((debugpy
             `( modes (python-mode python-ts-mode)
                ensure (lambda (config)
                         (dape-ensure-command config)
                         (let ((python (dape-config-get config 'command)))
                           (unless (zerop
                                    (call-process-shell-command
                                     (format "%s -c \"import debugpy.adapter\"" python)))
                             (user-error "%s module debugpy is not installed" python))))
                command "python"
                command-args ("-m" "debugpy.adapter" "--host" "0.0.0.0" "--port" :autoport)
                port :autoport
                :request "launch"
                :type "python"
                :cwd dape-cwd))
            (common
             `( :args []
                :justMyCode nil
                :console "integratedTerminal"
                :showReturnValue t
                :stopOnEntry nil)))
        `((debugpy ,@debugpy
                   :program dape-buffer-default
                   ,@common)
          (debugpy-module ,@debugpy
                          :module (car (last (file-name-split
                                              (directory-file-name default-directory))))
                          ,@common)))
    (dlv
     modes (go-mode go-ts-mode)
     ensure dape-ensure-command
     command "dlv"
     command-args ("dap" "--listen" "127.0.0.1::autoport")
     command-cwd dape-command-cwd
     command-insert-stderr t
     port :autoport
     :request "launch"
     :type "debug"
     :cwd "."
     :program ".")
    (flutter
     ensure dape-ensure-command
     modes (dart-mode)
     command "flutter"
     command-args ("debug_adapter")
     command-cwd dape-command-cwd
     :type "dart"
     :cwd "."
     :program "lib/main.dart"
     :toolArgs ["-d" "all"])
    (gdb
     ensure (lambda (config)
              (dape-ensure-command config)
              (let* ((default-directory
                      (or (dape-config-get config 'command-cwd)
                          default-directory))
                     (command (dape-config-get config 'command))
                     (output (shell-command-to-string (format "%s --version" command)))
                     (version (save-match-data
                                (when (string-match "GNU gdb \\(?:(.*) \\)?\\([0-9.]+\\)" output)
                                  (string-to-number (match-string 1 output))))))
                (unless (>= version 14.1)
                  (user-error "Requires gdb version >= 14.1"))))
     modes (c-mode c-ts-mode c++-mode c++-ts-mode)
     command-cwd dape-command-cwd
     command "gdb"
     command-args ("--interpreter=dap")
     defer-launch-attach t
     :request "launch"
     :program "a.out"
     :args []
     :stopAtBeginningOfMainSubprogram nil)
    (godot
     modes (gdscript-mode)
     port 6006
     :request "launch"
     :type "server")
    ,@(let ((js-debug
             `( ensure ,(lambda (config)
                          (dape-ensure-command config)
                          (when-let ((runtime-executable
                                      (dape-config-get config :runtimeExecutable)))
                            (dape--ensure-executable runtime-executable))
                          (let ((dap-debug-server-path
                                 (car (plist-get config 'command-args))))
                            (unless (file-exists-p dap-debug-server-path)
                              (user-error "File %S does not exist" dap-debug-server-path))))
                command "node"
                command-args (,(expand-file-name
                                (file-name-concat dape-adapter-dir
                                                  "js-debug"
                                                  "src"
                                                  "dapDebugServer.js"))
                              :autoport)
                port :autoport)))
        `((js-debug-node
           modes (js-mode js-ts-mode)
           ,@js-debug
           :type "pwa-node"
           :cwd dape-cwd
           :program dape-buffer-default
           :console "internalConsole")
          (js-debug-ts-node
           modes (typescript-mode typescript-ts-mode)
           ,@js-debug
           :type "pwa-node"
           :runtimeExecutable "ts-node"
           :cwd dape-cwd
           :program dape-buffer-default
           :console "internalConsole")
	  (js-debug-node-attach
           modes (js-mode js-ts-mode typescript-mode typescript-ts-mode)
           ,@js-debug
           :type "pwa-node"
	   :request "attach"
	   :port 9229)
          (js-debug-chrome
           modes (js-mode js-ts-mode typescript-mode typescript-ts-mode)
           ,@js-debug
           :type "pwa-chrome"
           :url "http://localhost:3000"
           :webRoot dape-cwd)))
    ,@(let ((lldb-common
             `( modes ( c-mode c-ts-mode
                        c++-mode c++-ts-mode
                        rust-mode rust-ts-mode rustic-mode)
                ensure dape-ensure-command
                command-cwd dape-command-cwd
                :cwd "."
                :program "a.out")))
        `((lldb-vscode
           command "lldb-vscode"
           :type "lldb-vscode"
           ,@lldb-common)
          (lldb-dap
           command "lldb-dap"
           :type "lldb-dap"
           ,@lldb-common)))
    (netcoredbg
     modes (csharp-mode csharp-ts-mode)
     ensure dape-ensure-command
     command "netcoredbg"
     command-args ["--interpreter=vscode"]
     :request "launch"
     :cwd dape-cwd
     :program (if-let ((dlls
                        (file-expand-wildcards
                         (file-name-concat "bin" "Debug" "*" "*.dll"))))
                  (file-relative-name (file-relative-name (car dlls)))
                ".dll")
     :stopAtEntry nil)
    (ocamlearlybird
     ensure dape-ensure-command
     modes (tuareg-mode caml-mode)
     command "ocamlearlybird"
     command-args ("debug")
     :type "ocaml"
     :program (file-name-concat (dape-cwd) "_build" "default" "bin"
                                (concat (file-name-base (dape-buffer-default)) ".bc"))
     :console "internalConsole"
     :stopOnEntry nil
     :arguments [])
    (rdbg
     modes (ruby-mode ruby-ts-mode)
     ensure dape-ensure-command
     command "rdbg"
     command-args ("-O" "--host" "0.0.0.0" "--port" :autoport "-c" "--" :-c)
     fn (lambda (config)
          (plist-put config 'command-args
                     (mapcar (lambda (arg)
                               (if (eq arg :-c) (plist-get config '-c) arg))
                             (plist-get config 'command-args))))
     port :autoport
     command-cwd dape-command-cwd
     :type "Ruby"
     ;; -- examples:
     ;; rails server
     ;; bundle exec ruby foo.rb
     ;; bundle exec rake test
     -c (concat "ruby " (dape-buffer-default)))
    (jdtls
     modes (java-mode java-ts-mode)
     ensure (lambda (config)
              (let ((file (dape-config-get config :filePath)))
                (unless (and (stringp file) (file-exists-p file))
                  (user-error "Unable to locate :filePath `%s'" file))
                (with-current-buffer (find-file-noselect file)
                  (unless (and (featurep 'eglot) (eglot-current-server))
                    (user-error "No eglot instance active in buffer %s" (current-buffer)))
                  (unless (seq-contains-p (eglot--server-capable :executeCommandProvider :commands)
        			          "vscode.java.resolveClasspath")
        	    (user-error "Jdtls instance does not bundle java-debug-server, please install")))))
     fn (lambda (config)
          (with-current-buffer
              (find-file-noselect (dape-config-get config :filePath))
            (if-let ((server (eglot-current-server)))
	        (pcase-let ((`[,module-paths ,class-paths]
			     (eglot-execute-command server
                                                    "vscode.java.resolveClasspath"
					            (vector (plist-get config :mainClass)
                                                            (plist-get config :projectName))))
                            (port (eglot-execute-command server
		                                         "vscode.java.startDebugSession" nil)))
	          (thread-first config
                                (plist-put 'port port)
			        (plist-put :modulePaths module-paths)
			        (plist-put :classPaths class-paths)))
              server)))
     ,@(cl-flet ((resolve-main-class (key)
                   (ignore-errors
                     (let* ((main-classes
                             (with-no-warnings
                               (eglot-execute-command
                                (eglot-current-server)
                                "vscode.java.resolveMainClass"
                                (file-name-nondirectory
                                 (directory-file-name (dape-cwd))))))
                            (main-class
                             (or (seq-find (lambda(val)
                                             (equal (plist-get val :filePath)
                                                    (buffer-file-name)))
                                           main-classes)
                                 (aref main-classes 0))))
                       (plist-get main-class key)))))
         `(:filePath
           ,(lambda ()
              (or (resolve-main-class :filePath)
                  (expand-file-name (dape-buffer-default) (dape-cwd))))
           :mainClass
           ,(lambda () (resolve-main-class :mainClass))
           :projectName
           ,(lambda () (resolve-main-class :projectName))))
     :args ""
     :stopOnEntry nil
     :type "java"
     :request "launch"
     :vmArgs " -XX:+ShowCodeDetailsInExceptionMessages"
     :console "integratedConsole"
     :internalConsoleOptions "neverOpen")
    (xdebug
     modes (php-mode php-ts-mode)
     ensure (lambda (config)
              (dape-ensure-command config)
              (let ((dap-debug-server-path
                     (car (plist-get config 'command-args))))
                (unless (file-exists-p dap-debug-server-path)
                  (user-error "File %S does not exist" dap-debug-server-path))))
     command "node"
     command-args (,(expand-file-name
                     (file-name-concat dape-adapter-dir
                                       "php-debug"
                                       "extension"
                                       "out"
                                       "phpDebug.js")))
     :type "php"
     :port 9003))
  "This variable holds the dape configurations as an alist.
In this alist, the car element serves as a symbol identifying each
configuration.  Each configuration, in turn, is a property list (plist)
where keys can be symbols or keywords.

Symbol keys (Used by dape):
- fn: Function or list of functions, takes config and returns config.
  If list functions are applied in order.
  See `dape-default-config-functions'.
- ensure: Function to ensure that adapter is available.
- command: Shell command to initiate the debug adapter.
- command-args: List of string arguments for the command.
- command-cwd: Working directory for the command, if not supplied
  `default-directory' will be used.
- command-env: Property list (plist) of environment variables to
  set when running the command.  Keys can be strings, symbols or
  keywords.
- command-insert-stderr: If non nil treat stderr from adapter as
  stderr output from debugged program.
- prefix-local: Path prefix for Emacs file access.
- prefix-remote: Path prefix for debugger file access.
- host: Host of the debug adapter.
- port: Port of the debug adapter.
- modes: List of modes where the configuration is active in `dape'
  completions.
- compile: Executes a shell command with `dape-compile-fn'.
- defer-launch-attach: If launch/attach request should be sent
  after initialize or configurationDone.  If nil launch/attach are
  sent after initialize request else it's sent after
  configurationDone.  This key exist to accommodate the two different
  interpretations of the DAP specification.
  See: GDB bug 32090.

Note: The char - carries special meaning when reading options in
`dape' and therefore should not be used be used as an key.
See `dape-history-add'.

Connection to Debug Adapter:
- If command is specified and not port, dape communicates with the
  debug adapter through stdin/stdout.
- If host and port are specified, dape connects to the debug adapter.
  If command is specified, dape waits until the command initializes
  before connecting to host and port.

Keywords in configuration:
  Keywords (symbols starting with colon) are transmitted to the
  adapter during the initialize and launch/attach requests.  Refer to
  `json-serialize' for detailed information on how dape serializes
  these keyword elements.  Dape uses nil as false.

Functions and symbols:
  - If a value is a function, its return value replaces the key's
    value before execution.  The function is called with no arguments.
  - If a value is a symbol, it resolves recursively before execution."
  :type '(alist :key-type (symbol :tag "Name")
                :value-type
                (plist :options
                       (((const :tag "List of modes where config is active in `dape' completions" modes) (repeat function))
                        ((const :tag "Ensures adapter availability" ensure) function)
                        ((const :tag "Transforms configuration at runtime" fn) (choice function (repeat function)))
                        ((const :tag "Shell command to initiate the debug adapter" command) (choice string symbol))
                        ((const :tag "List of string arguments for command" command-args) (repeat string))
                        ((const :tag "List of environment variables to set when running the command" command-env)
                         (plist :key-type (restricted-sexp :match-alternatives (stringp symbolp keywordp) :tag "Variable")
                                :value-type (string :tag "Value")))
                        ((const :tag "Treat stderr from adapter as program output" command-insert-stderr) boolean)
                        ((const :tag "Working directory for command" command-cwd) (choice string symbol))
                        ((const :tag "Path prefix for Emacs file access" prefix-local) string)
                        ((const :tag "Path prefix for debugger file access" prefix-remote) string)
                        ((const :tag "Host of debug adapter" host) string)
                        ((const :tag "Port of debug adapter" port) natnum)
                        ((const :tag "Compile cmd" compile) string)
                        ((const :tag "Use configurationDone as trigger for launch/attach" defer-launch-attach) boolean)
                        ((const :tag "Adapter type" :type) string)
                        ((const :tag "Request type launch/attach" :request) string)))))

