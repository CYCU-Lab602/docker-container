################################################################################
# set base system
# Built with arch: amd64 flavor: lxde image: nvidia/cuda:11.4.3-cudnn8-devel-ubuntu20.04
################################################################################

FROM nvidia/cuda:11.4.3-cudnn8-devel-ubuntu20.04 as system


################################################################################
# change shell
################################################################################
SHELL ["/bin/bash", "-c"]

################################################################################
# get apt sources
################################################################################
RUN sed -i 's/archive.ubuntu.com/free.nchc.org.tw/g' /etc/apt/sources.list

################################################################################
# install apt packages
################################################################################
ENV DEBIAN_FRONTEND noninteractive
RUN apt-get update \
	&& apt-get install -y --no-install-recommends \
	software-properties-common apache2-utils \
	ca-certificates gnupg patch \
	&& apt-get install -y --no-install-recommends --allow-unauthenticated \
    supervisor nginx sudo net-tools zenity xz-utils \
    dbus-x11 x11-utils alsa-utils \
    mesa-utils libgl1-mesa-dri \
    xvfb x11vnc vim firefox ffmpeg \
	lxde gtk2-engines-murrine \
	gnome-themes-standard gtk2-engines-pixbuf arc-theme \
	&& apt-get install -y gpg-agent ssh openssh-server \
	cmake git wget unzip yasm pkg-config libavcodec-dev \
    libavformat-dev libswscale-dev libavresample-dev libgstreamer1.0-dev \
    libgstreamer-plugins-base1.0-dev libxvidcore-dev x264 libx264-dev \
    libfaac-dev libmp3lame-dev libtheora-dev libvorbis-dev \
    libopencore-amrnb-dev libopencore-amrwb-dev libgtk-3-dev libtbb-dev \
    libatlas-base-dev gfortran libprotobuf-dev protobuf-compiler \
    libgphoto2-dev libeigen3-dev libhdf5-dev doxygen python3-numpy \
	ninja-build gettext ripgrep

################################################################################
# tini to fix subreap
################################################################################
ARG TINI_VERSION=v0.18.0
ADD https://github.com/krallin/tini/releases/download/${TINI_VERSION}/tini /bin/tini
RUN chmod +x /bin/tini

################################################################################
# ffmpeg symlinking
################################################################################
RUN mkdir /usr/local/ffmpeg
RUN ln -s /usr/bin/ffmpeg /usr/local/ffmpeg/ffmpeg

################################################################################
# install miniconda
################################################################################
ENV PYTHON_VERSION 3.10
ENV CONDA_DIR /opt/conda
RUN apt-get update && apt-get install -y curl \
	&& curl -L https://repo.anaconda.com/miniconda/Miniconda3-latest-Linux-x86_64.sh -o /tmp/miniconda.sh \
	&& chmod +x /tmp/miniconda.sh \
	&& bash /tmp/miniconda.sh -b -p /opt/conda/ \
	&& rm -rf /tmp/miniconda.sh \
	&& eval "$(/opt/conda shell.bash hook)" \
	&& /opt/conda/bin/conda init --all

################################################################################
# python library for vnc
################################################################################
COPY rootfs/usr/local/lib/web/backend/requirements.txt /tmp/
RUN dpkg-query -W -f='${Package}\n' > /tmp/a.txt \
	&& apt-get install -y --no-install-recommends python3-pip python3-dev build-essential \
	&& pip3 install setuptools wheel && pip3 install -r /tmp/requirements.txt \
	&& ln -s /usr/bin/python3 /usr/local/bin/python \
	&& dpkg-query -W -f='${Package}\n' > /tmp/b.txt \
	&& apt-get remove -y `diff --changed-group-format='%>' --unchanged-group-format='' /tmp/a.txt /tmp/b.txt | xargs` \
	&& rm -rf /var/lib/apt/lists/* \
	&& rm /tmp/a.txt /tmp/b.txt

################################################################################
# ssh
################################################################################
RUN mkdir /var/run/sshd \
	&& echo 'root:yHrvUU7K5R0ArGEzWPm3hmgDLjrhdtveQWsGrJ4oJznkvxqhJxr1nqyKMF7KpPxn' | chpasswd \
	&& sed -i 's/#Port 22/Port 22/' /etc/ssh/sshd_config \
	&& sed -i 's/#PermitRootLogin prohibit-password/PermitRootLogin yes/' /etc/ssh/sshd_config \
	&& sed -i 's/#PasswordAuthentication yes/PasswordAuthentication yes/' /etc/ssh/sshd_config

################################################################################
# builder
################################################################################
FROM nvidia/cuda:11.4.3-cudnn8-devel-ubuntu20.04 as builder


################################################################################
# nodejs
################################################################################
RUN apt-get update && apt-get install -y curl \
	&& curl -fsSL https://deb.nodesource.com/setup_current.x | bash - \
	&& apt-get install -y nodejs

################################################################################
# yarn
################################################################################
RUN curl -sS https://dl.yarnpkg.com/debian/pubkey.gpg | apt-key add - \
    && echo "deb https://dl.yarnpkg.com/debian/ stable main" | tee /etc/apt/sources.list.d/yarn.list \
    && apt-get update \
    && apt-get install -y yarn

################################################################################
# build frontend
################################################################################
COPY web /src/web
RUN cd /src/web \
    && yarn \
    && yarn build \
	&& sed -i 's#app/locale/#novnc/app/locale/#' /src/web/dist/static/novnc/app/ui.js


################################################################################
# merge
################################################################################
FROM system
LABEL maintainer="noah@c-link.com.tw"
COPY --from=builder /src/web/dist/ /usr/local/lib/web/frontend/
COPY rootfs /
RUN ln -sf /usr/local/lib/web/frontend/static/websockify \
	/usr/local/lib/web/frontend/static/novnc/utils/websockify \
    && chmod +x /usr/local/lib/web/frontend/static/websockify/run

################################################################################
# expose ssh and vnc port
################################################################################
EXPOSE 80
EXPOSE 22

################################################################################
# set timezone
################################################################################
RUN rm -rf /etc/localtime \
	&& ln -s /usr/share/zoneinfo/Asia/Taipei /etc/localtime

###############################################################################
# neovim
###############################################################################
RUN mkdir /home/repos \
	&& git clone https://github.com/neovim/neovim /home/repos/neovim \
	&& cd /home/repos/neovim \
	&& git checkout stable \
	&& make CMAKE_BUILD_TYPE=RelWithDebInfo && make install

################################################################################
# yolov7
################################################################################
RUN git clone https://github.com/popshia/clink-yolov7 /home/repos/yolov7 \
	&& cd /home/repos/yolov7 && /opt/conda/bin/conda create -n v7 python=3.9 -y \
	&& source /opt/conda/etc/profile.d/conda.sh && conda activate v7 \
	&& pip install -r /home/repos/yolov7/requirements.txt && conda deactivate

################################################################################
# fish
################################################################################
RUN apt-add-repository -y ppa:fish-shell/release-3 \
	&& apt-get update \
	&& apt-get install -y fish \
	&& /opt/conda/bin/conda init --all

################################################################################
# gh cli
################################################################################
RUN mkdir -p -m 755 /etc/apt/keyrings && wget -qO- https://cli.github.com/packages/githubcli-archive-keyring.gpg | sudo tee /etc/apt/keyrings/githubcli-archive-keyring.gpg > /dev/null \
	&& chmod go+r /etc/apt/keyrings/githubcli-archive-keyring.gpg \
	&& echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/githubcli-archive-keyring.gpg] https://cli.github.com/packages stable main" | sudo tee /etc/apt/sources.list.d/github-cli.list > /dev/null \
	&& apt-get update \
	&& apt-get install gh -y

################################################################################
# apt upgrade & cleanup
################################################################################
RUN apt-get update \
	&& apt-get upgrade -y \
	&& apt-get autoclean -y \
	&& apt-get autoremove -y

################################################################################
# nodejs
################################################################################
RUN curl -fsSL https://deb.nodesource.com/setup_current.x | bash - \
	&& apt-get install -y nodejs

################################################################################
# postprocess
################################################################################
RUN chsh -s /usr/bin/fish
HEALTHCHECK --interval=30s --timeout=5s \
CMD curl --fail http://127.0.0.1:6079/api/health
ENTRYPOINT ["/startup.sh"]
