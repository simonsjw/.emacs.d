;;; lang-vega.el --- Use of Vega visualisations -*- lexical-binding: t; -*-

;; Copyright (C) 2022
;; SPDX-License-Identifier: MIT

;; Author: System Crafters Community
;; Keywords: vega

;;; Commentary:
;; Vega-view currently supports a single interactive function, vega-view,
;; that can be invoked within a top-level form to visualize it as a Vega plot.
;; Currently, three kinds of Vega notation are supported:

;;     JSON, which is passed directly to Vega.
;;     elisp, which is evaluated and converted to JSON before being passed to
;;     Vega.  The elisp Vega specification format is, not coincidentally, the
;;     same as what is produced by called read-json on any Vega JSON
;;     specification.
;;     clojure, which is evaluated in the buffer's current cider context and
;;     converted to JSON before being passed to Vega.  The clojure
;;     specification format is whatever EDN would translate into the JSON
;;     specification you want.  This is, also not coincidentally, the same
;;     format one would use with Oz.

;; When vega-view is invoked it first identifies the preceding sexp (whatever
;; that means for the language of the buffer), performs the mode-specific
;; conversion described above, then pipes it through the Vega command line
;; tools to convert the specification to an SVG drawing.  The drawing -- or
;; the errors produced by Vega while trying to produce it -- are then
;; displayed in an image-mode buffer called *vega*.  (Note that you can toggle
;; between viewing an SVG image in an image-mode buffer as image or text
;; using C-c C-c in that buffer.)
;; JSON
;; Suppose you have a json-mode buffer containing this Vega specification:
;; {
;;     "data": {
;;         "values": [
;;             {"a": "A", "b": 28}, {"a": "B", "b": 55}, {"a": "C", "b": 43},
;;             {"a": "D", "b": 91}, {"a": "E", "b": 81}, {"a": "F", "b": 53},
;;             {"a": "G", "b": 19}, {"a": "H", "b": 87}, {"a": "I", "b": 52}
;;         ]
;;     },
;;     "mark": "bar",
;;     "encoding": {
;;         "x": {"field": "a", "type": "ordinal", "axis": {"labelAngle": 0}},
;;         "y": {"field": "b", "type": "quantitative"}
;;     }
;; }

;; Placing the cursor after the final } and invoking vega-view will bring up a
;; new window (in the Emacs sense of the term) containing an SVG drawing made
;; from this spec.

;;; Packages:

;; (use-package vega-view
;;   :straight (vega-view :type git
;;                        :flavor melpa
;;                        :host github
;;                        :repo "applied-science/emacs-vega-view")
;; :config
;; ;; Set the default commands for Vega
;; (setq vega-view--vega-svg-command "vg2svg"
;;       vega-view--vega-png-command "vg2png"))

(load-file
 (expand-file-name
  "custom-packages/emacs-vega-view/vega-view.el" user-emacs-directory))

;;; File associations:

;; By default this library produces SVG output when used from an emacs that
;; supports SVG. If you would prefer that it produce PNG
;; for example:
;; if your emacs has trouble displaying SVGs or the drawings you are producing
;; would be very, very large as SVG (tens of thousands of embedded data points)
;; --
;; you can set the var vega-view-prefer-png to any truth-y value to
;; prefer PNGs:

(customize-set-variable 'vega-view-prefer-png t)

;;;; Code:

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
(provide 'lang-vega)
;;; crafted-q-mode-support.el ends here

                                                                                  ; LocalWords:  vega fn PNG
