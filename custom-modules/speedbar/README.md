# Speedbar Modular Package

This is a modular package of functionality to support the inbuilt emacs `speedbar`.

## Directory Structure

```
speedbar/
├── speedbar-support.el      ; Main entry point (require this)
├── speedbar-config.el       ; Core settings + faces
├── speedbar-icons.el        ; Pretty icons + re-entrant setup
├── speedbar-pinning.el      ; Directory protection + pinning logic
├── speedbar-commands.el     ; All interactive commands
├── speedbar-sort.el         ; sort files and directories by name, update date or type
├── speedbar-keys.el         ; Key bindings and mode hooks
└── README.md                ; This file
```

## How to Use

1. Copy the `speedbar/` folder into your `~/.emacs.d/custom-modules/` (or any directory in your `load-path`).
2. Add this to your init file:

```elisp
(add-to-list 'load-path "~/.emacs.d/custom-modules/speedbar")
(require 'speedbar-support)
```

Or with `use-package`:

```elisp
(use-package speedbar-support
  :load-path "~/.emacs.d/custom-modules/speedbar"
  :demand t)
```

## Key Features

- **Daemon + client safe** pretty icons (re-applied on every frame)
- **Project pinning** with click protection (`my-speedbar/pin-current-directory`)
- Clean separation of concerns


## Module Overview

| Module                 | Responsibility                                         |
|------------------------|--------------------------------------------------------|
| `speedbar-config.el`   | `custom-set-variables` and faces                       |
| `speedbar-icons.el`    | `my-speedbar/setup-pretty-icons`                       |
| `speedbar-pinning.el`  | Directory click protection + pinning                   |
| `speedbar-commands.el` | Interactive functions (`toggle`, `go-workspace`, etc.) |
| `speedbar-sort.el`     | Sort documents/folders in the file tree view           |
| `speedbar-keys.el`     | All key bindings                                       |
|                        |                                                        |

## Notes

- `speedbar-pinning.el` contains the advanced directory protection logic.
- All functions have the `my-speedbar/` prefix.
- Logging is via custom `logging-config`.

Created: 2026-05-21
Author: Simon Watson (reorganized by Grok)
