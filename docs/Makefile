
ORG_FILES=$(wildcard crafted-*.org) getting-started-guide.org mit-license.org

docs: custom-emacs.info

custom-emacs.info: $(ORG_FILES)
	emacs -Q --script crafted-docs.el --funcall crafted-docs-export-info
