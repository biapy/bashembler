# Biapy Bashlings Makefile

SHELL = /bin/sh

.SUFFIXES: .bash .md .bats

# grep the version from the mix file
VERSION=$(shell git tag --list | tail --lines=1)

# Define pathes.
SOURCE_PATH := ./src
DOC_PATH := ./doc
SPEC_PATH := ./spec
COVERAGE_PATH := ./coverage
RELEASE_PATH := ./bin
RELEASE_FILE := bashembler
SHA512SUM_FILE := $(RELEASE_FILE).sha512

# Define utilities pathes.
SHDOC := ./lib/shdoc/shdoc
SHELLSPEC := bash "$(shell bash -c 'command -v shellspec')"
RM := rm -f
SHELLCHECK_BASH := shellcheck \
	--check-sourced \
	--external-sources \
	--shell='bash'
SHFMT := shfmt -w -d

BASHEMBLER := bash \
	$(shell bash -c "((DEBUG)) && echo -n '--verbose'" ) \
	'src/bashembler.bash' \
	$(shell bash -c "((VERBOSE)) && echo -n '--verbose'" )
SHA512 := shasum --algorithm=512

# Run shellcheck on a .bash file.
define shellcheck_bash_file
	$(SHELLCHECK_BASH) '$(1)';
endef

# Find *.bash files.
BASH_FILES := $(shell find $(SOURCE_PATH) -name "*.bash")
PUBLIC_BASH_FILES := $(sort $(shell find $(SOURCE_PATH) -maxdepth 1 -name "*.bash"))

# Detect sources structure based on found bash scripts.
SOURCE_STRUCTURE := $(sort $(dir $(BASH_FILES)))

# Generates *.md documentation files path
MD_FILES := $(patsubst $(SOURCE_PATH)/%,$(DOC_PATH)/%,$(BASH_FILES:%.bash=%.md))

.PHONY: help all \
	brief  \
	shellcheck-src \
	shfmt \
	test coverage \
	readme-clean doc-clean coverage-clean

###
# Internal rules.
###

$(DOC_PATH)/%.md: $(SOURCE_PATH)/%.bash # Documentation generation rule.
	@mkdir -p $(@D)
	@$(SHDOC) $< > $@

doc-clean: # Remove all generated documentation files.
	@$(RM) $(MD_FILES)
	@echo "Removed generated documentation."

shellcheck: # Run shellcheck on all sources.
	@$(foreach bash_file,$(BASH_FILES),$(call shellcheck_bash_file,$(bash_file)))

shfmt: # Format bash scripts in source path.
	@$(SHFMT) $(BASH_FILES)

coverage-clean: # Remove coverage folder
	@$(RM) -r '$(COVERAGE_PATH)'

build-clean: # Remove built file.
	@$(RM) -r '$(RELEASE_PATH)'

$(RELEASE_PATH)/$(RELEASE_FILE): # Assemble bashembler script for release.
	@mkdir -p '$(RELEASE_PATH)'
	@$(BASHEMBLER) --discard-comments \
		--output='$(RELEASE_PATH)/$(RELEASE_FILE)' \
		'src/bashembler.bash'
	@chmod +x '$(RELEASE_PATH)/$(RELEASE_FILE)'
	@cd '$(RELEASE_PATH)' && $(SHA512) '$(RELEASE_FILE)' > '$(SHA512SUM_FILE)'

###
# Front-end rules.
###

# HELP
# This will output the help for each task
# thanks to https://marmelab.com/blog/2016/02/29/auto-documented-makefile.html
help: ## Display this message.
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' "$(MAKEFILE_LIST)" \
		| sort \
		| awk 'BEGIN {FS = ":.*?## "}; {printf "\033[36m%-30s\033[0m %s\n", $$1, $$2}'

all: clean format check test build doc ## Run tests and generate documentation.

build: $(RELEASE_PATH)/$(RELEASE_FILE) ## Build bashembler.

check: shellcheck ## Run shellcheck on sources.

format: shfmt ## Format files with shfmt.

test: ## Run unit-tests using shellspec.
	$(SHELLSPEC) --format 'd' '$(SPEC_PATH)'

coverage: ## Compute tests coverage
	$(SHELLSPEC) --kcov --format 'd' '$(SPEC_PATH)'

doc: $(MD_FILES) ## Generate documentation from sources using shdoc.

clean: coverage-clean doc-clean build-clean readme-clean ## Remove all generated documentation files and remove functions list from README.md
