ORG_FILES := $(wildcard *.org)

.PHONY: docs

docs: emacs-config.info

emacs-config.info: $(ORG_FILES) my-docs.el
	emacs -Q --script my-docs.el --funcall my-docs-export-info
