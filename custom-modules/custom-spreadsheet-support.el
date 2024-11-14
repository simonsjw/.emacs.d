;;; custom-spreadsheet-support.el --- Spreadsheet configuration -*- mode: emacs-lisp; mode: outline-minor; lexical-binding: t; -*-

;;; License
;; Copyright (C) 2022
;; SPDX-License-Identifier: MIT

;; Author: Erik Lundstedt, System Crafters Community

;;; Commentary:

;; configure a spreadsheet like buffer. 

;;; Code:


(load-file "~/.emacs.d/custom-packages/cell-mode/cell-mode.el")
(require 'cell-mode)

;;; Look & Feel
;; change the colouring to match our theme.
;;(Using the customisation group 'cell' provided by the developer.)

;; (defgroup cell nil
;;   "Options for cell-mode."
;;   :group 'applications)

;;; Font locking

;; Do not attempt to use defface since it's already used.
;; instead redefine existing faces.
;;
;; This definition for 'cell-default-face' would be updated
;; overwriting the definition. 
;; 
;; (defface cell-default-face
;;   '((t (:foreground
;;         "black")))
;;   "Face for cells."
;;   :group 'cell)
;;
;; is updated using:
;;
;; `(cell-default-face
;;   ((t (:foreground
;;        ,info-theme-white-grey
;;        :box (:line-width 1
;;                          :color ,info-theme-white-grey)))))
;;

(custom-set-faces

 ;; Define faces for cell-mode
 ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;


 ;; The default face before any modification. 
 ;; ------------------------------------------------------------
 ;; (defface cell-default-face
 ;;   '((t (:foreground
 ;;         "black")))
 ;;   "Face for cells."
 ;;   :group 'cell)

 `(cell-default-face
   ((t (:foreground
        ,info-theme-white-grey
        :box (:line-width 1
                          :color ,info-theme-white-grey)))))


 ;; (defface cell-action-face
 ;;   '((t (:foreground
 ;;         "yellow"
 ;;         :background "red"
 ;;         :bold t :weight bold)))
 ;;   "Face for cells that perform an action." :group 'cell)

 ;; (defface cell-comment-face
 ;;   '((t (:foreground
 ;;         "dodger blue")))
 ;;   "Face for cells that simply label stuff."
 ;;   :group 'cell)

 `(cell-comment-face
   ((t (:foreground
        ,info-theme-bold-code-green
        :box (:line-width 1
                          :color ,info-theme-white-grey)))))

 ;; (defface cell-comment-2-face
 ;;   '((t (:foreground
 ;;         "hot pink" :slant italic :italic t)))
 ;;   "Face for cells that simply label stuff." :group 'cell)

 `(cell-comment-2-face
   ((t (:foreground
        ,info-theme-faded-lime
        :box (:line-width 1
                          :color ,info-theme-white-grey)))))

 ;; (defface cell-file-face
 ;;   '((t (:foreground
 ;;         "yellowgreen")))
 ;;   "Face for simple links to files." :group 'cell)

 ;; (defface cell-cursor-face
 ;;   '((t (:background
 ;;         "hot pink"
 ;;         :foreground "yellow"
 ;;         :box (:line-width 1 :color "magenta"))))
 ;;   "Face for selected cell." :group 'cell)


 `(cell-cursor-face
   ((t (:background
        ,info-theme-grass
        :foreground ,info-theme-sharp-lime
        :box (:line-width 1
                          :color ,info-theme-white-grey)))))
 
 ;; (defface cell-mark-face
 ;;   '((t (:background
 ;;         "yellow" :foreground "red")))
 ;;   "Face for marked cell." :group 'cell)

 ;; (defface cell-selection-face
 ;;   '((t (:background
 ;;         "pale green"
 ;;         :foreground "gray20"
 ;;         :box (:line-width 1 :color "pale green"))))
 ;;   "Face for multi-cell selection." :group 'cell)

 ;; (defface cell-text-face
 ;;   '((t (:foreground "yellow")))
 ;;   "Face for text entry cells." :group 'cell)

 
 ;; Odd and Even column vertical formatting. 
 ;; ------------------------------------------------------------
 ;; (defface cell-blank-face
 ;;   '((t (:background 
 ;;         "wheat" 
 ;;         :box 
 ;;         (:line-width 1 :color "dark khaki"))))
 ;;   "Face for blank cells." :group 'cell)

 `(cell-blank-face
   ((t (:background
        ,info-theme-dark-blue
        :box (:line-width 1
                          :color ,info-theme-white-grey)))))
 ;; (defface cell-blank-odd-face
 ;;   '((t (:background 
 ;;         "cornsilk" 
 ;;         :box 
 ;;         (:line-width 1 :color "dark khaki"))))
 ;;   "Face for blank cells in odd columns" :group 'cell)

 `(cell-blank-odd-face
   ((t (:background
        ,info-theme-blue-steel
        :box (:line-width 1
                          :color ,info-theme-white-grey)))))



 ;; The horisontal and vertical numbering of cells in the sheet.
 ;; ------------------------------------------------------------
 ;; (defface cell-axis-face
 ;;   '((t :foreground "gray50" 
 ;;        :background "gray80" 
 ;;        :box (:line-width 1 :color "grey70")))
 ;;   "Face for numbered axes."  :group 'cell)

 ;; (defface cell-axis-odd-face
 ;;   '((t :foreground "gray50" 
 ;;        :background "gray90" 
 ;;        :box (:line-width 1 :color "grey70")))
 ;;   "Face for numbered axes in odd columns." :group 'cell)

 )


;;; Keybindings



(provide 'custom-spreadsheet-support)
;;; custom-spreadsheet-support.el ends here
