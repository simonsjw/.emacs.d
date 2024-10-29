;;; custom-summary-config.el --- Crafted Emacs splash screen  -*- lexical-binding: t; -*-

;; Copyright (C) 2023
;; SPDX-License-Identifier: MIT

;; Author: System Crafters Community

;;; Commentary:

;; Provide a fancy splash screen similar to the Emacs default splash
;; screen or the Emacs about page.

;;; Code:
(require 'projectile)

(defgroup crafted-startup '()
  "Startup configuration for Crafted Emacs."
  :tag "Crafted Startup"
  :group 'crafted)

(defcustom crafted-startup-concise-splash nil
  "Show a more concise Crafted Emacs Splash screen, without the logo."
  :type 'boolean
  :group 'crafted-startup)

(defcustom crafted-startup-inhibit-splash nil
  "Disable the Crafted Emacs Splash screen"
  :type 'boolean
  :group 'crafted-startup)

(defvar crafted-startup-screen-inhibit-startup-screen nil)

(defcustom crafted-startup-graphical-logo "image"
  "Show a logo on the splash screen when in a graphical environment.
When set to \"image\", it will display the image defined in
`fancy-splash-image', when set to \"ascii\", it will display the
contents of `crafted-startup-ascii-logo'.
For everything else, it will not display a logo."
  :type 'string
  :group 'crafted-startup)

(defcustom crafted-startup-terminal-logo t
  "Show a logo on the splash screen when in a terminal.
When set to non-nil, it will display the contents of
`crafted-startup-ascii-logo'."
  :type 'boolean
  :group 'crafted-startup)

(defcustom crafted-startup-recentf-count 10
  "The number of recent files to display on the splash screen"
  :type 'number
  :group 'crafted-startup)

(defcustom crafted-startup-project-count 10
  "The number of projects to display on the splash screen"
  :type 'number
  :group 'crafted-startup)

(defface crafted-greeting-face
  '((t (:inherit font-lock-comment-face :weight bold :height 1.5)))
  "Face for the welcoming message."
  :group 'crafted-faces)

(customize-set-variable 'fancy-splash-image
                        (expand-file-name
                         "etc/images/blackhole.png"
                         user-emacs-directory))
;; Make sure 1st line is as wide as widest.
(defconst crafted-startup-ascii-logo
  '(
    "                                                                                                                                                                                                                                                          "
    "                                                                                                                     %%%%%%%%%%%%%%%                                                                                                                      "
    "                                                                                                               %###*##%%%%%%%%%%%%%%#*###%                                                                                                                "
    "                                                                                                          %##*%%                         %%#*#%%                                                                                                          "
    "                                                                                                      %%##%                                   %%##%%                                                                                                      "
    "                                                                                                   %**%                                           %%##                                                                                                    "
    "                                                                                                %##%                                                 %%#%%                                                                                                "
    "                                                                                              #*%%                                                      %#*%                                                                                              "
    "                                                                                           %##%                                                            %#%                                                                                            "
    "                                                                                         %##%                                                                %##                                                                                          "
    "                                                                                       %#%                                                                     %*#                                                                                        "
    "                                                                                     %#%                                                                         %##                                                                                      "
    "                                                                                    %#                           %%*#*+*##**###*#**+*##%%                          %*%                                                                                    "
    "                                                                                  %#%                        %***#%                   %##**#%                        %*                                                                                   "
    "                                                                                 #%                       %*+%                              #+*%                       #%                                                                                 "
    "                                                                               %*%                     %**%                                    #*#%                     %#                                                                                "
    "                                                                              #%                     #*%                                          #*%                     *%                                                                              "
    "                                                                            %*%                   %**%                 %%%######%%                  %*#%                   ##                                                                             "
    "                                                                           %#                   %*#%              ##=+**#%%%%%%%##**++%%              %*#                   %#                                                                            "
    "                                                                          %#                  %#*            %#***%                   %#*+#%            %*%                   #%                                                                          "
    "                                                                         #%                  #*%           *+*%%                          %#+*%           %*%                  #%                                                                         "
    "                                                                        #%                 %*%          %**%                                  #+*%          *#                  #%                                                                        "
    "                                                                       #%                 ##%         #+#%             %#*+*++++*#%             %**%         %+%                 %%                                                                       "
    "                                                                      #                  *%         #+#          %#*==+*#%%%  %%%##+=+*%          %*+%         *#                 %%                                                                      "
    "                                                                     #%                %*%        %+#         %+=+#%                  %#++#%        %**%        #*                 %%                                                                     "
    "                                                                    #                 %*         *#        %*=*                            ==%         +#        %*                 %%                                                                    "
    "                                                                   #                 ##        #*%       %++#        %##*+++++++**#%        %#=*%       %+%        +%                %%                                                                   "
    "                                                                  *                 #%        *#       %=+%       #=-=+#%%%%  %%%%#+==+%       %=#        *%        *                 %%                                                                  "
    "                                                                 #                 #%       %+%      %*+%     %*=+#%     %%%%%%%      %*==#%     #=#       #*        *%                #%                                                                 "
    "                                                                #%                *%       %*       #=%     #=+%    %*---:==++=-:--=#%   %#=+%     #=%      %+        *%                #%                                                                "
    "                                                               #%                #%       ##      %+#     #-*   %*--+*%            %*=-+#%  %++%    %+*      %+%       *%                #%                                                               "
    "                                                              %%                #%       ##      %=%    #=#%  #--*%   %**=::--:-=*#%  %%*-=%  %+=%    #+       *%       *%                #                                                               "
    "                                                             %#                #%       *%      #+    %=+% %*-+% %%*:::+*#%%  %%#*=::=#%  %-=%  %-*    %=%      +%       *%                *                                                              "
    "                                                            %#                #%       *%      *#    #=%  *-#   *:=*%               %%+--#  %+-#  #=%    +%      *%       *%               %#                                                             "
    "                                                            *                %#       *%      +%   %+*  #-*  %=:*%                      %=.*% %==%  =#    +#      +%       *                %#                                                            "
    "                                                           *                %#       *%      +#   %=%  +=% %+-#                           %+:*  #-#  ++    +#      *%       *                %#                                                           "
    "                                                          #                 *       +%      +%   %-% %:#  #.#                                +-%  =+  #=    +#      *%      %#                %%                                                          "
    "                                                         #%                *%      *%      +%   %=  #-% %-+%             %######%             #:*  #=% %=%   *#      *%      #%                #%                                                         "
    "                                                        #                 #%      #%      +%   %=  #-  %.%           #=:. .---:. .:*            +:  %:% %=    +%      *%      +                 #%                                                        "
    "                                                       %%                %#      %#      *#   %=  *=  #:%         #=.:+#         %*=.:*%         #:% %-% %=    +%      +       *                 #%                                                       "
    "                                                      #%                 +      %*      *#    =  *=  +-%        #:.+%                %=.=%        #.% %:% %=    =       +      %#                 #%                                                      "
    "                                                     #%                 *      %+      #*   %-% #=  *=        %::#                     %+.*%       %:% %-% #*    =%     %*      %#                 #%                                                     "
    "                                                    #%                 *%      +      %+    =% %-  *-%       *.+%                        %=:%       %:% %-  *#   %=      %*      #%                 #%                                                    "
    "                                                  %*%                 *%      *%     %=    *# %:% %:       %-.%                            * *       #:  #+  =%   %+      ##      *%                 %#                                                   "
    "                                                 %#                  #%      +%      =%   %+  =% %.%      %:+                               %.+       #=  +# %-    #*      *%      #%                 %*%                                                 "
    "                                               %*%                  #%      *%      +%    =  #+  :%      %.+                                 %:=       =*  -% %+    +%      *%      *%                  #%                                                "
    "                                             %##                   *%      *%      *#    +% %:  +*       :*                                   %:+       :% %-  +%    =%      *%      ##                  %#%                                              "
    "                                            *#                    +       #%      %+    %+  -  %:       :=                                     %.#      %:  +#  -     =       =       %*                    ##                                            "
    "                                        %%#%                   %*#       *#       =     =  #+  :%      *:                                       % %      ++  -% #*    %*       +%      %*%                   %%#%%                                        "
    "                                      ###                     #*%       +%       +     *%  :  +*       .%                                        #:       :% #+  +%    *%       *#       #*%                    %#*%                                      "
    "                                  %###                      #*%       %+%       #*    %=  +# %:       :*                                          :#      %-  =% %=     =%       #*%       #*%                     %#*%%                                  "
    "                              %#*#%                      %**%       %+#        %=     -% %-  :#      #.                                           %.       =# %-  ##    %+        %+#        %+#                      %%###                               "
    "                         %%#*#%                       %**#        %**%        %=     *#  =% #=       :#                                            -*      %.  +#  =%    #+         %+#%       %**#%                       ###%%%                         "
    "                     %##*%%%                       ##*#%        #+#%         %=%     =  %= %:%      %:                                             %:       *+ %-  %=     #+          %+*%        %#**%                       %%#*#%                      "
    "                %%#*#%%                        %#*##         %*+#           *+      -%  -  **       =*                                              :%       :% #*  *#     %=%          %*+#%        %#+*#%                        %%*##%%                "
    "            %###%%                         %**##%         %*+*%           %=#      +%  *# %:%        %                                              *=       #-  -%  =%      *+%           %***%         %#+*#%                         %%*##%            "
    "       %%#*#                         %%#*+#%          %#++%             #=#       **  %-  =%       #:                                               %.        -# %-   -%      %++%             #++#%          %***#%                         %###%        "
    "    %##%%                        %#***%%          #*++#%            %#++#      %#=#  %:% #=        =*                                                .%        :% *+  %+=%      %*=#%             ##++#%          %%**#%                         %##%     "
    "   ##                          %+*            #+++%               %==*        *-#   %:%  .%        :                                                 =*        #=  *=   %+-*       %+==%               #++*%           %**                           *    "
    "  #%                          ##           *+*#              %#+=*#       %+=+%   #-=% #:%        %.                                                 #-         +-% %-=%   #+=#%      %#+=*%              %%*+%          %*%                          #%  "
    "  #                           +           #%               %++#%        #-+%    *:*% #:-%         %:                                                 #:          #:=% %-=%   %#-+%        %*=*                *%          %#                           #  "
    "  #                           %*%         %+%             *+%          =*     %-*% #:=#           #-                                                 %.%           #-=% %=+     %+#          %=%             #+         %#*                           %%  "
    "  %*%                           %+*%       %#+*%          +           #+      +#  %-%            %.-                                                 % -             %:   =%     %-            +          %*+%        %#*%                           %#   "
    "    ##%                            #**#%%     %#*+#%%     #=*%%        #=*#%  %=-+#+--+#%%%     *.-%                                                  #.:%     %%#+=::##=-*  %%#==%        %%+=     %%##+*#     %%%*+#%                            %*%    "
    "     %%##                             %%#**#*%    %%#+***#% %#==+*%      %#===+*%%*+--==--::-++*.=%                                                    %:.*+=-:--==--=+#%#++==+#%     %#++=+#% %#**+*%%%    #**+##%                             %#*%      "
    "        %#*#%%                               %#*+***%%%%%%#*++**###*+==+*+*#%%%%#+===++**===---::::::-++*##%%%%%                          %%%%%#*+*=-::::::---==+*+*+-==*#%%%%#**++=++*%###+=+*#% %%%#*#*+##%                              %%###%         "
    "            %%####%%                               %%###+****#%%%%###****++***++++++++=+++=====+=+===--:::....::::---================--:::::...::::-====++=====++*=*++++++++***+***+*###% %%#*****#%#%                               %%%###%%%            "
    "                   %#*###%%%                                   %#*+***+*#%%%%%%#*+*+**+**##%****++=--:::::--==----:::::::::::::::::::::-----==--:::::-==++****%##*+**++++*#%%%%%#*+***+*#%                                   %%%#*##*%                    "
    "                         %%%%#####%%%%                                  %%%#%##**#****###########******++*******++++++==+=+====+=++=++++++******++*******#######%###****#**##%#%%                                  %%%%######%%%%                         "
    "                                     %####***%%%                                            %#**+#***++++**#%%% #########################% %%%#*++++*****+*##%                                           %%%#***####%                                     "
    "                                              %%%%########%%%%%%                                            %%%%%%%%%%##############%%%%%%%%%                                             %%%%%#########%%%%                                              "
    "                                                           %%%%%####****#####%%                                                                                           %%######***#####%%%%%                                                           "
    "                                                                             %%#######*#*###%%%%%%%%%%%%%%                                      %%%%%%%%%%%%%#####**######%%%                                                                             "
    "                                                                                            %%%%%%%%%%%%%%%###*************###*************####%%%%%%%%%%%%%%%                                                                                            "
    "                                                                                                                                                                                                                                                          "
    "                                                                                                                                                                                                                                                          "
    "                                                                                                                                                                                                                                                          "
    "                                                                                                                                                                                                                                                          "
    "                                                                                                                                                                                                                                                          "
    "                                                                              %  #%  #   # %% *%*%       #%                                    #%       #%#% *  *   #  #   #                                                                              "
    "                                                                              #   #  *   = %+ ###+       *.                                   # %       . :% + %*  %#  *   #                                                                              "
    "                                                                              #   *  #%  *% +% -%:        *.%                                *.%       #+%= #% *%  *  %%  %%                                                                              "
    "                                                                              %%  %%  *  %# %# +%#+        *.#                              =.%        : =  -  +   +  #   #                                                                               "
    "                                                                               #   #  +   +  -  - :%        %.=%                          %:=%        +*%= ## %#  #%  *   #                                                                               "
    "                                                                               #   #  %#  *% %# +#%-         %=.*                        =.#          : =% =  +   +  %%  %%                                                                               "
    "                                                                               %%  %%  +   =  = %- =#          #::#%                  %+.=           :%%= %* %+  %#  *   #                                                                                "
    "                                                                                #   +  #%  *% #* #+ :#           #-.=#              *-.+%           =*%:  -  *%  *% %#  %#                                                                                "
    "                                                                                #%  #% %*  %+  =% =#%:%            %+:.-=*%%%%%#*=:.-#             *= =# *%  +   *  *   %%                                                                                "
    "                                                                                %%   *  *%  *%  = %-%%.%              %#+=-::::-=*#%              += +* %+  +%  *%  #   #                                                                                 "
    "                                                                                 #   #%  +   -  #*  :% :%                                        == *+  -  %#  %*  #%   %                                                                                 "
    "                                                                                 %%   *  #%  %*  ** %-%%-+                                     %-* ++ %=%  +   *% %*   #                                                                                  "
    "                                                                                  #   #%  +   *%  *#  :# +-%                                  *.% =*  =%  =%  %#  *   %%                                                                                  "
    "                                                                                  %%   *  %*   =%  +*  =+ #:*                               %==%%-# %=%  *#  %+  %#   #                                                                                   "
    "                                                                                   #   %#  ##   =%  +*  #:%%+.*                            +.# #-%  -%  ##   +%  *   %%                                                                                   "
    "                                                                                    #   *%  *%   =%  #=% %=+%%=:*%                      %+-* #-+  #=%  **   *%  #%   *                                                                                    "
    "                                                                                    %%   +   +%   =%  %=%  #-*%%+:=#                 %+:-#%%==%  +*   *#   *%  %#   #                                                                                     "
    "                                                                                     #   %*   +%   =%   ++%  #-+% #=-:+*%%%%%%%%%#+=:-*%%#==%  %=%   *#   ##  %*   %#                                                                                     "
    "                                                                                     %#   %*  %+%   **   %=*   #=-+% %#*==-:::--=+##%%%=:+%  %+*%   +%   ##   +    #                                                                                      "
    "                                                                                      %%   %#   *%   #=%   #=*%   #=-=+#%%%%% %%%%*=--+%   %+=%   #=    *#   *    #                                                                                       "
    "                                                                                       %%   ##   *%   %+#   %*=+%    %#*++==--==++#%%   %#=+%   %+*    *%   +%   #%                                                                                       "
    "                                                                                        %%   ##   #*    #=%    %+-*%%                %#=-*     #=     +%   +    #                                                                                         "
    "                                                                                         #%   ##   %+%   %*+%     %*==+*##%%%%%%##*==+#%     #=#    #*   %*%   #%                                                                                         "
    "                                                                                          #    %*    +#    %+=%        %#**++++**#         #-#     +#   %+    #%                                                                                          "
    "                                                                                           %%   %*%   #+%    %*+*%                     %#++#     #+%   ##    #%                                                                                           "
    "                                                                                            ##    *%   %**%     %#=+*%              %+==#%     %+%    *%    *%                                                                                            "
    "                                                                                             %#    #*%   %**%       #*+==++****++==**%       %+*    %*%   %#                                                                                              "
    "                                                                                              %#%   %*%    %**%            %%%%            *+%     *#    %#                                                                                               "
    "                                                                                                #%    #*%     #+*#%                    %#+*%     %*%   %#%                                                                                                "
    "                                                                                                 %*%   %#*%      #**+##%         %%%*+*#%      %+#    %#                                                                                                  "
    "                                                                                                   ##     *+%         %#++*+****+*#%        %#*#    %#%                                                                                                   "
    "                                                                                                    %#%    %%*#%                          %**%    %%#                                                                                                     "
    "                                                                                                      %#%      **#%%                  %%+*%      ##                                                                                                       "
    "                                                                                                        %##%      %***###%%   %%%##*+##%      %##                                                                                                         "
    "                                                                                                           #*#          %%##**#%%%         %#*%                                                                                                           "
    "                                                                                                              #*#%%                    %%##%                                                                                                              "
    "                                                                                                                %%%*###%          %##*#%%                                                                                                                 "
    "                                                                                                                      %%%#%####%#%%                                                                                                                       "
    "                                                                                                                                                                                                                                                          "
    "                                                                                                                                                                                                                                                          "
    )
  "A list of strings representing the lines of an ASCII logo for the
splash screen. Make sure the first line is as wide as the widest
line or the centering will by off.")

(defun crafted-startup--center-with-face (str &optional face)
  "Center the face calculating the number of spaces needing pre-pending.
Return the text with as many prepended spaces as needed."
  (let* ((str-mid (/ (length str) 2))
         (line-width (window-max-chars-per-line nil face)))
    (concat
     (make-string (abs (- (/ line-width 2) str-mid)) ? ) ;;fill spaces
     str)))

(defun recenter-crafted-content (&optional concise)
  "Recenter the logo and welcome message in the crafted splash screen."
  ;; Check if the current buffer is the splash buffer
  (when (string= (buffer-name) "*Crafted Emacs*") 
    (let ((inhibit-read-only t))
      ;; Clear the existing logo and welcome message
      (erase-buffer)
      (insert "\n")     
      ;; Redraw the logo
      (crafted-startup-splash-head)
      (insert "\n\n")
      ;; Redraw the welcome message
      (apply #'fancy-splash-insert
             `(:face (crafted-greeting-face)
                     ,(crafted-startup--center-with-face
                       crafted-welcome-text
                       'crafted-greeting-face)))
      (insert "\n")
      ;; Redraw any additional content you want here
      (dolist (text crafted-startup-text)         ;; the rest of the text
        (apply #'fancy-splash-insert text)
        (insert "\n"))
      
      ;; draw the crafted-module list.
      ;; -----------------------------
      (mapc
       (lambda (f)
         (insert "\n")
         (funcall f)
         (skip-chars-backward "\n")
         (delete-region (point) (point-max))
         (insert "\n"))
       crafted-startup-module-list)

      (skip-chars-backward "\n")
      (delete-region (point) (point-max))
      (insert "\n")
      (crafted-startup-tail concise)
      )))


(defconst crafted-welcome-text " Welcome." "First text on the splash screen.")

(defconst crafted-startup-text
  `((:face variable-pitch
           :link ("View Crafted Emacs Manual"
                  ,(lambda (_button) (info "crafted-emacs")))
           "\tView the Crafted Emacs manual using Info\n"
           "\n"))
  "A list of texts to show in the middle part of splash screens.
Each element in the list should be a list of strings or pairs
`:face FACE', like `fancy-splash-insert' accepts them.")

(defcustom crafted-startup-module-list '(crafted-startup-diary
                                         crafted-startup-recentf
                                         crafted-startup-projects)
  "List of functions to call to display \"modules\" on the splash
screen.  Functions are called in the order listed.  See
`crafted-startup-recentf' as an example.  Current list provided
 by Crafted Emacs is `crafted-startup-diary',
 `crafted-startup-projects', `crafted-startup-recentf'"
  :type '(repeat function)
  :group 'crafted-startup)

(defun crafted-startup-splash-head ()
  (if (display-graphic-p)
      (cond
       ((string= crafted-startup-graphical-logo
                 "image") (crafted-startup--splash-head-image))
       ((string= crafted-startup-graphical-logo
                 "ascii") (crafted-startup--splash-head-ascii))
       (t nil)) ;;do nothing in all other cases
    ;; ASCII art in the terminal?
    (when crafted-startup-terminal-logo
      (crafted-startup--splash-head-ascii))))

(defun crafted-startup--splash-head-image ()
  "Insert the head part of the splash screen into the current buffer."
  (let* ((image-file (fancy-splash-image-file))
	 (img (create-image image-file))
	 (text-width (window-width))
	 (image-width (and img (car (image-size img)))))
    (when img
      (insert "\n\n\n")
      (when (> text-width image-width)
        ;; Center the image
        (insert (propertize " " 'display
                            `(space :align-to (+ ,(- (/ text-width 2) 0)
                                                 (-0.5 . ,img)))))
        (insert-image img))
      (insert "\n"))))

(defun crafted-startup--splash-head-ascii ()
  "Insert the contents of `crafted-startup-ascii-logo' into the
 splash screen as a logo."
  (let* ((logo-face 'fixed-pitch)
         (first-line (car crafted-startup-ascii-logo))
         (line-width (window-max-chars-per-line nil logo-face))
         (spaces
          (make-string
           (abs (- (/ line-width 2)
                   (/ (length first-line) 2)))
           ? )))
    (dolist (line crafted-startup-ascii-logo)
      (fancy-splash-insert :face logo-face (concat spaces line "\n")))
    (insert "\n")))

(defun crafted-startup-tail (&optional concise)
  "Insert the tail part of the splash screen into the current buffer."
  (fancy-splash-insert
   :face 'variable-pitch
   "\nTo start...     "
   :link
   `("Open a File"
     ,(lambda (_button) (call-interactively 'find-file))
     "Specify a new file's name, to edit the file")
   "     "
   :link
   `("Open Home Directory"
     ,(lambda (_button) (dired "~"))
     "Open your home directory, to operate on its files")
   "     "
   :link
   `("Open Crafted Emacs Home Directory"
     ,(lambda (_button) (dired crafted-emacs-home))
     "Open the Crafted Emacs configuration directory, to operate on its files")
   "     "
   :link
   `("Customize Crafted Emacs"
     ,(lambda (_button) (customize-group 'crafted))
     "Change initialization settings including this screen")
   "\n")

  (fancy-splash-insert
   :face '(variable-pitch (:height 0.7))
   "\n\nTurn this screen off by adding:\n"
   :face '(default font-lock-keyword-face)
   "`(customize-set-variable 'crafted-startup-inhibit-splash t)'\n"
   :face '(variable-pitch (:height 0.7))
   " to your initialization file (usually init.el)\n"
   "Or check the box and click the link below, which will do the same thing.")

  (fancy-splash-insert
   :face 'variable-pitch "\n"
   :link `("Dismiss this startup screen"
           ,(lambda (_button)
              (when crafted-startup-screen-inhibit-startup-screen
                (customize-set-variable 'crafted-startup-inhibit-splash t)
                (customize-mark-to-save 'crafted-startup-inhibit-splash)
                (custom-save-all))
              (quit-windows-on "*Crafted Emacs*" t)))
   "  ")
  (when custom-file
    (let ((checked (create-image "checked.xpm"
                                 nil nil :ascent 'center))
          (unchecked (create-image "unchecked.xpm"
                                   nil nil :ascent 'center)))
      (insert-button
       " "
       :on-glyph checked
       :off-glyph unchecked
       'checked nil 'display unchecked 'follow-link t
       'action (lambda (button)
                 (if (overlay-get button 'checked)
                     (progn (overlay-put button 'checked nil)
                            (overlay-put button 'display
                                         (overlay-get button :off-glyph))
                            (setq crafted-startup-screen-inhibit-startup-screen
                                  nil))
                   (overlay-put button 'checked t)
                   (overlay-put button 'display
                                (overlay-get button :on-glyph))
                   (setq crafted-startup-screen-inhibit-startup-screen t))))))
  (fancy-splash-insert :face '(variable-pitch (:height 0.9))
                       " Never show it again."))

(defun format-diary-entry-with-faces (start end)
  "Format the diary entry in the current buffer from START to END using existing faces."
  (interactive "r") ;; Use the selected region or ask for range interactively
  (save-excursion
    (goto-char start)
    (while (re-search-forward "^\\(Sunrise.*\\)$" end t) ;; Match the first line
      (add-text-properties
       (match-beginning 1) (match-end 1) 
       '(face 'org-scheduled-today))) ;; Use 'org-scheduled-today' face for the entire first line

    (goto-char start)
    (while (re-search-forward "^\\([^:]+:\\)\\s-*\\([^:]+:\\)\\s-*\\(TODO\\)\\s-*\\(.*\\)$" end t) 
      ;; Regex: match phrases before and after colons and the word TODO
      (add-text-properties
       (match-beginning 1) (match-end 1) 
       '(face 'org-level-2)) ;; Use 'org-level-2' face for the first phrase before the first colon
      (add-text-properties
       (match-beginning 2) (match-end 2) 
       '(face 'org-level-3)) ;; Use 'org-level-3' face for the phrase before the second colon
      (add-text-properties
       (match-beginning 3) (match-end 3) 
       '(face 'org-todo)) ;; Use 'org-todo' face for the word "TODO"
      (add-text-properties
       (match-beginning 4) (match-end 4) 
       '(face 'default))))) ;; Use the default face for the text after the second colon


(defun crafted-startup-diary ()
  (require 'diary-lib nil :noerror)
  (if (and diary-file (file-exists-p diary-file))
      (if (file-readable-p diary-file)
          (let* ((today (decode-time nil nil 'integer))
                 (mm (decoded-time-month today))
                 (dd (decoded-time-day today))
                 (yy (decoded-time-year today))
                 (entries
                  (mapcar #'cadr (diary-list-entries (list mm dd yy) 1 t))))
            (fancy-splash-insert
             :face '(variable-pitch font-lock-string-face italic)
             (condition-case entries
                 (if (not (seq-empty-p entries))
                     "Diary Entries for Today:\n"
                   "No diary entries for today\n")
               (error "\n")))
            (condition-case entries
                (if (not (seq-empty-p entries))
                    (dolist (entry entries)
                      (fancy-splash-insert
                       :face 'default
                       (format "    %s\n" entry)))
                  "\n")
              (error "\n")))
        (fancy-splash-insert
         :face '(variable-pitch font-lock-string-face italic)
         "Diary file is not readable\n"))
    (fancy-splash-insert
     :face '(variable-pitch font-lock-string-face italic)
     "No diary file\n")))

(defun crafted-startup-recentf ()
  (fancy-splash-insert
   :face '(variable-pitch font-lock-string-face italic)
   (condition-case recentf-list
       (if (not (seq-empty-p recentf-list))
           "Recent Files:\n           "
         "\n")
     (error "\n")))
  (condition-case recentf-list
      (if (not (seq-empty-p recentf-list))
          (dolist (file (seq-take recentf-list crafted-startup-recentf-count))
            (fancy-splash-insert
             :link `(,file ,(lambda (_button) (find-file file)))
             "\n    "))
        "\n")
    (error "\n")))

(defun crafted-startup-project-list ()
  "Retrieve a list of projects from Projectile."
  (when (featurep 'projectile)
    (projectile-relevant-known-projects)))


(defun summary-config/open-projectile-project (project-path)
  (message "project... ")
  (message project-path)
  (projectile-switch-project-by-name project-path))


(defun crafted-startup-projects ()
  (let ((recent-projects (seq-take (projectile-relevant-known-projects)
                                   crafted-startup-project-count)))
    (when recent-projects
      (fancy-splash-insert
       :face '(variable-pitch font-lock-string-face italic) "Projects:\n"))
    (dolist (project-path recent-projects)
      (let ((project-name (projectile-project-name project-path)))
        (fancy-splash-insert :face 'default "    • ")
        (fancy-splash-insert
         :link `(,project-name
                 ,(lambda (_button)
                    (when (projectile-project-p project-path)
                      (summary-config/open-projectile-project project-path)))
                 "Switch to project"))
        (insert "\n")))))  ;; Ensure each project is on a new line


(defun crafted-startup-screen ()
  "Calls `crafted-startup--display-startup-screen' with
`crafted-startup-concise-splash'."
  (crafted-startup--display-startup-screen crafted-startup-concise-splash)
  (tab-line-mode t))

(defun crafted-startup--display-startup-screen (&optional concise)
  "Display fancy startup screen.

If CONCISE is non-nil, display a concise version of the splash
screen in another window.  This function can be bound to
`initial-buffer-choice' which will run this function when Emacs
starts.  See the variable documenation for
`initial-buffer-choice' for more information."
  (interactive)
  (message "Loading Crafted Startup Screen")
  
  (let ((splash-buffer (get-buffer-create "*Crafted Emacs*")))
    (with-current-buffer splash-buffer
      ;;(add-hook 'window-state-change-hook #'recenter-crafted-content nil t)
      
      (let ((inhibit-read-only t))
        
        ;; draw the main welcome splash
        ;; ----------------------------
        (erase-buffer)                              ;; erase existing layout.
        
        ;; Here is where a default directory can be set if needed.
        ;; (setq default-directory command-line-default-directory)
        
        (make-local-variable 'crafted-startup-screen-inhibit-startup-screen)
        (if pure-space-overflow
            (insert pure-space-overflow-message))
        
        (unless concise                             ;; display the logo
          (crafted-startup-splash-head))
        (insert "\n\n")
        (apply #'fancy-splash-insert                ;; insert welcome text
               `(:face (crafted-greeting-face)
                       ,(crafted-startup--center-with-face
                         crafted-welcome-text
                         'crafted-greeting-face)))
        (insert "\n")
        (dolist (text crafted-startup-text)         ;; the rest of the text
          (apply #'fancy-splash-insert text)
          (insert "\n"))
        
        
        ;; draw the crafted-module list.
        ;; -----------------------------
        (mapc (lambda (f)
                (insert "\n")
                (funcall f)
                (skip-chars-backward "\n")
                (delete-region (point) (point-max))
                (insert "\n"))
              crafted-startup-module-list)
        
        (skip-chars-backward "\n")
        (delete-region (point) (point-max))
        (insert "\n")
        (crafted-startup-tail concise))
      
      (use-local-map splash-screen-keymap)
      (setq-local browse-url-browser-function 'eww-browse-url)
      (setq tab-width 22
            buffer-read-only t)
      (set-buffer-modified-p nil)
      (if (and view-read-only (not view-mode))
          (view-mode-enter nil 'kill-buffer))
      (goto-char (point-min))
      (forward-line (if concise 2 4)))

    
    ;; Manage how the splash screen content is displayed.
    ;; -------------------------------------------------
    (if concise
        (progn
          (display-buffer splash-buffer)
          ;; If the splash screen is in a split window, fit it.
          (let ((window (get-buffer-window splash-buffer t)))
            (or (null window)
                (eq window (selected-window))
                (eq window (next-window window))
                (fit-window-to-buffer window))
            splash-buffer)) ;; return the buffer
      (switch-to-buffer splash-buffer)))

  (let ((start (point))
        (end (progn (when (search-forward "\n\n" nil t)
                      (match-beginning 0)))))

    (message "start: %s end: %s" start end)
    ;; Apply formatting to the diary entries
    (when (and start end)
      (format-diary-entry-with-faces start end)))
  (goto-char (point-min))) ; ensure the buffer is displayed from the top.

(defun my-extended-keyboard-quit ()
  "Execute `keyboard-quit` and optionally `recenter-crafted-content`
 in *Crafted Emacs* buffer."
  (interactive)
  (keyboard-quit)  ;; Original C-g behavior
  ;; Only run `recenter-crafted-content` if in *Crafted Emacs* buffer
  (when (string= (buffer-name) "*Crafted Emacs*")
    (recenter-crafted-content)))

;; Remap C-g to the new function
(global-set-key (kbd "C-g") 'my-extended-keyboard-quit)

(provide 'custom-summary-config)
;;; custom-summary-config.el ends here
