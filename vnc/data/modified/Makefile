.PHONY: build run

# Default values for variables
REPO  ?= dorowu/ubuntu-desktop-lxde-vnc
TAG   ?= latest
# you can choose other base image versions
IMAGE ?= ubuntu:20.04

# choose from supported flavors (see available ones in ./flavors/*.yml)
FLAVOR ?= lxde
# armhf or amd64
ARCH ?= amd64

# These files will be generated from the Jinja templates (.j2 sources)
templates = Dockerfile rootfs/etc/supervisor/conf.d/supervisord.conf

# clink 選擇openCV版本
OPENCV ?= none

# clink 選擇GPU ex: 0 或 0,1
GPUS ?= 0

# clink 設定 PORT
PORT80 ?= 49152

# clink 設定 PORT
PORT443 ?= 49153

# clink 設定 PORT
PORT22 ?= 49154

# clink 設定 PORT
PORT6006 ?= 49155

# clink 設定 PORT
PORT554 ?= 49156

# clink 設定用戶名稱 clink.{學號}
USERSNAME ?= clink.12345678

# clink 設定用戶密碼
USERSPSWD ?= mypassword

# clink 設定ROOT密碼
ROOTPSWD ?= approot

# clink 設定 container名稱 學號
CONTAINERNAME ?= 12345678

# clink 設定 container名稱 學號
WEBSITEPSWD ?= mypassword

# Rebuild the container image
build: $(templates)
	docker build -t $(REPO):$(TAG) .
	# docker build --no-cache -t $(REPO):$(TAG) .

# Test run the container
# the local dir will be mounted under /src read-only
run:
	docker run \
		--gpus '"device=$(GPUS)"' \
		--memory=10g \
		--cpus="6" \
		--shm-size=10g \
		-p $(PORT80):80 -p $(PORT443):443 -p $(PORT22):22 -p $(PORT6006):6006 -p $(PORT554):554\
		-v ${PWD}:/src:ro \
		-v /media/ai/data:/home/$(USERSNAME)/data \
		-v /media/ai/backup:/home/$(USERSNAME)/backup \
		-e USER=$(USERSNAME) -e PASSWORD=$(USERSPSWD) \
		-e ALSADEV=hw:2,0 \
		-e SSL_PORT=443 \
		-e RESOLUTION=1024x768 \
		-e HTTP_PASSWORD=$(WEBSITEPSWD) \
		-e DISPLAY=$(DISPLAY) \
		-v /tmp/.X11-unix:/tmp/.X11-unix \
		-v ${PWD}/ssl:/etc/nginx/ssl \
		--device /dev/snd \
		--name $(CONTAINERNAME) \
		$(REPO):$(TAG)

# Connect inside the running container for debugging
shell:
	docker exec -it ubuntu-desktop-lxde-test bash

# Generate the SSL/TLS config for HTTPS
gen-ssl:
	mkdir -p ssl
	openssl req -x509 -nodes -days 365 -newkey rsa:2048 \
		-keyout ssl/nginx.key -out ssl/nginx.crt

clean:
	rm -f $(templates)

extra-clean:
	docker rmi $(REPO):$(TAG)
	docker image prune -f

# Run jinja2cli to parse Jinja template applying rules defined in the flavors definitions
%: %.j2 flavors/$(FLAVOR).yml
	docker run -v $(shell pwd):/data vikingco/jinja2cli \
		-D flavor=$(FLAVOR) \
		-D image=$(IMAGE) \
		-D localbuild=$(LOCALBUILD) \
		-D arch=$(ARCH) \
		-D opencv_version=$(OPENCV) \
		-D rootpassword=$(ROOTPSWD) \
		-D usersname=$(USERSNAME) \
		$< flavors/$(FLAVOR).yml > $@ || rm $@
