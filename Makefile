.PHONY: build run

# Default values for variables
REPO  ?= dorowu/ubuntu-desktop-lxde-vnc
TAG   ?= latest
# you can choose other base image versions
IMAGE ?= ubuntu:20.04
# IMAGE ?= nvidia/cuda:10.1-cudnn7-devel-ubuntu18.04
# choose from supported flavors (see available ones in ./flavors/*.yml)
FLAVOR ?= lxde
# armhf or amd64
ARCH ?= amd64

# These files will be generated from teh Jinja templates (.j2 sources)
templates = Dockerfile rootfs/etc/supervisor/conf.d/supervisord.conf

<<<<<<< HEAD
||||||| d54b98b
# clink 選擇openCV版本
OPENCV ?= 

# clink 選擇GPU ex: 0 或 0,1
GPUS ?= 0

# clink 設定 PORT
PORT80 ?= 10370

# clink 設定 PORT
PORT443 ?= 10372

# clink 設定 PORT
PORT22 ?= 10371

# clink 設定 PORT
PORT6006 ?= 10373

# clink 設定 PORT
PORT554 ?= 10374

# clink 設定用戶名稱 clink.{學號}
USERSNAME ?= test

# clink 設定用戶密碼
USERSPSWD ?= 0800

# clink 設定ROOT密碼
ROOTPSWD ?= yHrvUU7K5R0ArGEzWPm3hmgDLjrhdtveQWsGrJ4oJznkvxqhJxr1nqyKMF7KpPxn

# clink 設定 container名稱 學號
CONTAINERNAME ?= test

# clink 設定 container名稱 學號
WEBSITEPSWD ?= 0800

=======
# clink 選擇openCV版本
OPENCV ?=

# clink 選擇GPU ex: 0 或 0,1
GPUS ?= 0

# clink 設定 PORT
PORT80 ?= 10370

# clink 設定 PORT
PORT443 ?= 10372

# clink 設定 PORT
PORT22 ?= 10371

# clink 設定 PORT
PORT6006 ?= 10373

# clink 設定 PORT
PORT554 ?= 10374

# clink 設定用戶名稱 clink.{employee_name}
USERSNAME ?= test

# clink 設定用戶密碼
USERSPSWD ?= 0800

# clink 設定ROOT密碼
ROOTPSWD ?= yHrvUU7K5R0ArGEzWPm3hmgDLjrhdtveQWsGrJ4oJznkvxqhJxr1nqyKMF7KpPxn

# clink 設定 container名稱
CONTAINERNAME ?= test

# clink 設定 container名稱
WEBSITEPSWD ?= 0800

>>>>>>> refs/remotes/origin/clink
# Rebuild the container image
build: $(templates)
	docker build -t $(REPO):$(TAG) .

# Test run the container
# the local dir will be mounted under /src read-only
run:
	docker run --privileged --rm \
		-p 6080:80 -p 6081:443 \
		-v ${PWD}:/src:ro \
		-e USER=doro -e PASSWORD=mypassword \
		-e ALSADEV=hw:2,0 \
		-e SSL_PORT=443 \
		-e RELATIVE_URL_ROOT=approot \
		-e OPENBOX_ARGS="--startup /usr/bin/galculator" \
		-v ${PWD}/ssl:/etc/nginx/ssl \
		--device /dev/snd \
		--name ubuntu-desktop-lxde-test \
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
		$< flavors/$(FLAVOR).yml > $@ || rm $@