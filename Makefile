PATH := node_modules/.bin:$(PATH)

.NOTPARALLEL:
.ONESHELL:

tmp := $(shell mktemp -u)

default: tools

tools:
	docker build --build-arg http_proxy=http://10.0.1.43:1080 -t quay.io/hotosm/oam-dynamic-tiler-tools .

server: tools
	docker build --build-arg http_proxy=http://10.0.1.43:1080 -t quay.io/hotosm/oam-dynamic-tiler-server -f server/Dockerfile .

deploy: project.json
	apex deploy

install: project.json

project.json: project.json.hbs node_modules/.bin/interp
	interp < $< > $@

node_modules/.bin/interp:
	npm install

compute-environment: node_modules/.bin/interp
	interp < aws/$@.json.hbs > $(tmp)
	aws batch create-compute-environment --cli-input-json file://$(tmp)
	rm -f $(tmp)

job-queue: node_modules/.bin/interp
	interp < aws/$@.json.hbs > $(tmp)
	aws batch create-job-queue --cli-input-json file://$(tmp)
	rm -f $(tmp)

transcode-job-definition: node_modules/.bin/interp
	interp < aws/$@.json.hbs > $(tmp)
	aws batch register-job-definition --cli-input-json file://$(tmp)
	rm -f $(tmp)

submit-job: node_modules/.bin/interp
	interp < $(job) > $(tmp)
	aws batch submit-job --cli-input-json file://$(tmp)
	rm -f $(tmp)
