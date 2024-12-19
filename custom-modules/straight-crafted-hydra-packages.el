;;; straight-crafted-hydra-packages.el --- packages for implementing hydras -*- lexical-binding: t; -*-

;; Copyright (C) 2022
;; SPDX-License-Identifier: MIT

;; Author: System Crafters Community

;;; Commentary:

;; Hydra packages

;;; Code:
(require 'custom-logging-config)

(use-package hydra)
(use-package pretty-hydra)
(use-package symbol-navigation-hydra)
(use-package use-package-hydra)
(use-package major-mode-hydra)

(provide 'straight-crafted-hydra-packages)
;;; straight-crafted-hydra-packages.el ends here
