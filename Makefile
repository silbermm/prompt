.PHONY: help check check.all

help:
	@fgrep -h "##" $(MAKEFILE_LIST) | fgrep -v fgrep | sed -e 's/\\$$//' | sed -e 's/##//'

check: check.all ## Run linters and checks for all apps.

check.all:
	mix format --check-formatted \
	&& mix graph --fail-above 1  \
	&& mix credo --strict \
	&& mix dialyzer
