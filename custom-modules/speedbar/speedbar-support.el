;;; speedbar.el --- Speedbar modular package loader -*- lexical-binding: t; -*-

;; Copyright (C) 2026 Simon Watson
;; SPDX-License-Identifier: MIT

;; Author: Simon Watson
;; Keywords: speedbar, sr-speedbar, file-tree, icons, pinning

;;; Commentary:
;; Main entry point for the modular Speedbar package.
;; Load with: (require 'speedbar)

;;; Code:


(defvar my-speedbar/use-pretty-icons t
  "If non-nil, use pretty-speedbar icons.
Otherwise use native ezimage icons with file-type support.")

(require 'speedbar-config)
(require 'speedbar-icons)
(require 'speedbar-pinning)
(require 'speedbar-commands)
(require 'speedbar-sort)
(require 'speedbar-keys)

;; Ensure frame-local variables are initialized on new frames
(add-hook 'after-make-frame-functions
          (lambda (frame)
            (with-selected-frame frame
              (setq my-speedbar/pin-project-root nil
                    my-speedbar/current-file nil
                    my-speedbar/file-tree-root nil))))

(provide 'speedbar-support)

;;; speedbar-support.el ends here
