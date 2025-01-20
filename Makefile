.PHONY: reset check* test*

APP_NAME ?= `grep 'app:' mix.exs | sed -e 's/\[//g' -e 's/ //g' -e 's/app://' -e 's/[:,]//g'`
APP_VSN ?= `grep 'version:' mix.exs | cut -d '"' -f2`
BUILD ?= `git rev-parse --short HEAD`

REPO = "codeberg.org"

help:
	@fgrep -h "##" $(MAKEFILE_LIST) | fgrep -v fgrep | sed -e 's/\\$$//' | sed -e 's/##//'

check: check.all ## Run linters and checks for all apps.
build_image: image.build ## Build a docker image with correct tags
push_image: image.push ## Push the image to docker hub

check.all:
	mix format --check-formatted \
	&& mix graph --fail-above 1  \
	&& mix credo --strict \
	&& mix dialyzer

image.build:
	docker build -t $(REPO)/ahappydeath/prompt-base:latest --file Dockerfile.baseimage .

image.push:
	docker push $(REPO)/ahappydeath/prompt-base:latest
