SHELL=/bin/bash

# черная магия для парсинга неименованных аргументов
# https://stackoverflow.com/a/47008498/1501061
# https://objects.githubusercontent.com/github-production-release-asset-2e65be/216057608/7c26fd00-fbf5-11e9-84e0-09ccee4afe16?X-Amz-Algorithm=AWS4-HMAC-SHA256&X-Amz-Credential=releaseassetproduction%2F20241224%2Fus-east-1%2Fs3%2Faws4_request&X-Amz-Date=20241224T000806Z&X-Amz-Expires=300&X-Amz-Signature=3450f9018ef6d503c0cb06e8d80ed116acfc94fe8f5323ea572dc0ba70912922&X-Amz-SignedHeaders=host&response-content-disposition=attachment%3B%20filename%3Dmodern-make-handbook-ru.pdf&response-content-type=application%2Foctet-stream
ARGS = `arg="$(filter-out $@,$(MAKECMDGOALS))" && echo $${arg:-${1}}`

CONTAINER?=x-kmui
IMAGENAME?=ix-kmui
IMAGETAG?=latest

DOCKERNETWORK?=ix-net
EXPOSED_PORT?=4443

.DEFAULT_GOAL := help


%:
	@:

.PHONY: help

help:
	echo "help! =)"


.PHONY: build run init-network set-restart-always start

build:
	DOCKER_BUILDKIT=1 docker build --rm --no-cache -t $(IMAGENAME):$(IMAGETAG) .

run: init-network
	FIRST_IP=$(hostname -I | awk '{print $1}')
	docker run -d \
		--security-opt=no-new-privileges:true \
		--memory="200m" \
		--memory-swap="300m" \
		--network $(DOCKERNETWORK) \
		--expose=$(EXPOSED_PORT) \
		-p $FIRST_IP:443:$(EXPOSED_PORT) \
		--name $(CONTAINER) \
		$(IMAGENAME):$(IMAGETAG)

init-network:
	docker network create $(DOCKERNETWORK) || true

set-restart-always:
	docker update --restart=on-failure:3 $(CONTAINER)
	# docker update --restart=unless-stopped $(CONTAINER)
	# docker update --restart=always $(CONTAINER)

start:
	docker start $(CONTAINER)

stop:
	docker stop $(CONTAINER)


.PHONY: remove-container purge-docker-images

remove-container:
	docker stop $(CONTAINER) ; docker container remove $(CONTAINER)

purge-docker-images: remove-container
	# удаление образов, не привязанных ни к одному из созданных контейнеров
	# docker rmi $(docker images -f dangling=true -q)
	docker rmi $(IMAGENAME)


.PHONY: image-save image-load

image-save:
	# сохранить образ в архив
	# docker save -o /tmp/idumbp.docker.image.tar idumbp
	docker save -o $(call ARGS,/tmp/idumbp.docker.image.tar) $(IMAGENAME)
	# скинуть сохраненный образ на удаленную машину
	# scp -P 5322 /tmp/idumbp.docker.image.tar  kossmak@206.188.196.148:utils/dumbproxy-km/_tmp/

image-load:
	# загрузить образ из архива
	docker load -i $(call ARGS,/tmp/idumbp.docker.image.tar)


.PHONY: args-debug

# пробуем необязательный параметр
args-debug:
	echo $(call ARGS,default value)
