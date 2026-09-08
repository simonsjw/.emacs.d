# Agent entry point for simonsjw/.emacs.d

This repository is an Emacs 30 configuration.  Coding agents (Grok,
Grok Build, and similar) should not wander.

## Start here

1. Read `docs/MAP.org` — feature inventory (file, load phase, depends).
2. Open only the module named in that row and `docs/<feature>.org`.
3. Touch `conf.org` when startup, environment variables, or OS
   dependencies change.  Do not treat tangled `init.el` as source.
4. Follow the `elisp-code-style` skill: checkdoc, outline headings,
   `log/debug`, Emacs-native Flymake / Eglot / VC / `project.el`.

## Invariants

- Feature name = filename stem = `(provide 'feature)`.
- Paths live in `path-support.el` as `my-paths/...`.
- Machine-local state is under `var/$MY_NAME/` and `etc/$MY_NAME/`.
- Keymaps sit in `custom-modules/keymaps/` and are named from the
  module Commentary `Map:` block.
- After adding or renaming a feature, update `docs/MAP.org` in the
  same change.
