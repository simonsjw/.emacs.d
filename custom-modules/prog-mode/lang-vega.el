;;; lang-vega.el --- Vega-view visualisations. -*- lexical-binding: t; -*-

;; Copyright (C) 2026 Simon Watson
;; SPDX-License-Identifier: MIT

;; Author: Simon Watson

;;; Commentary:

;; Language module for Vega visualisations via `vega-view'.
;; Requires the Vega CLI tools on PATH.  Load from `init.el'.
;;
;; Map:
;;   Feature:    lang-vega
;;   Load-after: path-support logging-config
;;   Load-phase: lang
;;   Keymaps:    none
;;   Docs:       docs/lang-vega.org
;;   OS:         vega vega-lite vega-cli node

;;; Code:

(defcustom my-fn-vega/default-vega-spec 'vega
  "The Vega format to use with `vega-view'.  Can be `vega' or `vega-light'."
  :type 'symbol
  :group 'vega-view)

(defun my-fn-vega/set-vega-spec-type (specification-type)
  "Set the Vega specification given a SPECIFICATION-TYPE."
  (if (eq specification-type 'vega-light)
      (progn
        (customize-set-variable
         'vega-view--vega-svg-command "vl2svg"
         "The local command to be invoked to convert a Vega-Lite JSON spec to SVG.")
        (customize-set-variable
         'vega-view--vega-png-command "vl2png"
         "The local command to be invoked to convert a Vega-Lite JSON spec to PNG."))
    (progn
      (customize-set-variable
       'vega-view--vega-svg-command "vg2svg"
       "The local command to be invoked to convert a Vega JSON spec to SVG.")
      (customize-set-variable
       'vega-view--vega-png-command "vg2png"
       "The local command to be invoked to convert a Vega JSON spec to PNG."))))

(defun my-fn-vega/change-vega-spec-type (chosen-specification-type)
  "Interactive function to change the Vega specification.
CHOSEN-SPECIFICATION-TYPE can be `vega' or `vega-light'.  This is an interactive
 wrapper for `my-fn-vega/set-vega-spec-type'."
  (interactive
   (list
    (completing-read
     "Choose specification type (vega or vega-light): "
     '("vega" "vega-light"))))
  (my-fn-vega/set-vega-spec-type (intern chosen-specification-type)))

;; Set the specification used by vega-view to the default.
(my-fn-vega/set-vega-spec-type my-fn-vega/default-vega-spec)


;; Hooks

;;; Provision


(log/debug :fn 'lang-vega
           :msg "Finnishing load of the lang-vega module."
           :obj t)
(provide 'lang-vega)
;;; lang-vega.el ends here
