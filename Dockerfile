# Built with arch: amd64 flavor: lxde image: nvidia/cuda:11.4.3-cudnn8-devel-ubuntu20.04

################################################################################
# set base system
################################################################################

FROM nvidia/cuda:11.4.3-cudnn8-devel-ubuntu20.04 as system


################################################################################
# get apt sources
################################################################################
# RUN sed 's/mirror:\/\/mirrors\.ubuntu\.com\/mirrors\.txt/http:\/\/mirror01\.idc\.hinet\.net\/ubuntu/' /etc/apt/sources.list | tee /etc/apt/sources.list
# RUN sed -i 's#http://archive.ubuntu.com/ubuntu/#http://free.nchc.org.tw/ubuntu/#' /etc/apt/sources.list
RUN sed -i 's/archive.ubuntu.com/free.nchc.org.tw/g' /etc/apt/sources.list
################################################################################
# install apt packages (1)
################################################################################
ENV DEBIAN_FRONTEND noninteractive
RUN apt update
RUN apt install -y --no-install-recommends software-properties-common curl apache2-utils
RUN apt update
RUN apt install -y --no-install-recommends --allow-unauthenticated \
    supervisor nginx sudo net-tools zenity xz-utils \
    dbus-x11 x11-utils alsa-utils \
    mesa-utils libgl1-mesa-dri
RUN apt autoclean -y
RUN apt autoremove -y
RUN rm -rf /var/lib/apt/lists/*

################################################################################
# install apt packages (1)
# install debs error if combine together
################################################################################
RUN apt update
RUN apt install -y --no-install-recommends --allow-unauthenticated \
    xvfb x11vnc vim firefox
RUN apt autoclean -y
RUN apt autoremove -y
RUN rm -rf /var/lib/apt/lists/*
RUN apt update
RUN apt install -y gpg-agent

################################################################################
# google chrome for vnc
################################################################################
RUN curl -LO https://dl.google.com/linux/direct/google-chrome-stable_current_amd64.deb \
    && (dpkg -i ./google-chrome-stable_current_amd64.deb || apt-get install -fy) \
    && curl -sSL https://dl.google.com/linux/linux_signing_key.pub | apt-key add \
    && rm google-chrome-stable_current_amd64.deb \
    && rm -rf /var/lib/apt/lists/*

################################################################################
# useless ifs (?)
################################################################################





################################################################################
# install apt packages (2)
# Additional packages require ~600MB (libreoffice pinta language-pack-zh-hant language-pack-gnome-zh-hant firefox-locale-zh-hant libreoffice-l10n-zh-tw)
################################################################################
RUN apt update
RUN apt install -y --no-install-recommends --allow-unauthenticated \
    lxde gtk2-engines-murrine gnome-themes-standard gtk2-engines-pixbuf gtk2-engines-murrine arc-theme
RUN apt autoclean -y
RUN apt autoremove -y
RUN rm -rf /var/lib/apt/lists/*

################################################################################
# tini to fix subreap
################################################################################
ARG TINI_VERSION=v0.18.0
ADD https://github.com/krallin/tini/releases/download/${TINI_VERSION}/tini /bin/tini
RUN chmod +x /bin/tini

################################################################################
# ffmpeg
################################################################################
RUN apt update
RUN apt install -y --no-install-recommends --allow-unauthenticated ffmpeg
RUN rm -rf /var/lib/apt/lists/*
RUN mkdir /usr/local/ffmpeg
RUN ln -s /usr/bin/ffmpeg /usr/local/ffmpeg/ffmpeg

################################################################################
# python library
################################################################################
COPY rootfs/usr/local/lib/web/backend/requirements.txt /tmp/
RUN apt-get update
RUN dpkg-query -W -f='${Package}\n' > /tmp/a.txt
RUN apt-get install -y python3-pip python3-dev build-essential
RUN pip3 install setuptools wheel && pip3 install -r /tmp/requirements.txt
RUN ln -s /usr/bin/python3 /usr/local/bin/python
RUN dpkg-query -W -f='${Package}\n' > /tmp/b.txt
RUN apt-get remove -y `diff --changed-group-format='%>' --unchanged-group-format='' /tmp/a.txt /tmp/b.txt | xargs`
RUN apt-get autoclean -y
RUN apt-get autoremove -y
RUN rm -rf /var/lib/apt/lists/*
RUN rm -rf /var/cache/apt/* /tmp/a.txt /tmp/b.txt

################################################################################
# install miniconda
################################################################################
ENV PYTHON_VERSION 3.10
RUN curl -L https://repo.anaconda.com/miniconda/Miniconda3-latest-Linux-x86_64.sh -o /tmp/miniconda.sh
RUN sudo chmod +x /tmp/miniconda.sh
RUN sudo bash /tmp/miniconda.sh -b -p /opt/conda/
RUN rm -rf /tmp/miniconda.sh
RUN eval "$(/opt/conda shell.bash hook)"

################################################################################
# SSH
################################################################################
RUN apt-get update
RUN apt-get install -y ssh gedit openssh-server nano
RUN apt-get autoclean -y
RUN apt-get autoremove -y
RUN rm -rf /var/lib/apt/lists/*
RUN mkdir /var/run/sshd
RUN echo 'root:yHrvUU7K5R0ArGEzWPm3hmgDLjrhdtveQWsGrJ4oJznkvxqhJxr1nqyKMF7KpPxn' | chpasswd
RUN sed -i 's/#Port 22/Port 22/' /etc/ssh/sshd_config
RUN sed -i 's/#PermitRootLogin prohibit-password/PermitRootLogin yes/' /etc/ssh/sshd_config
RUN sed -i 's/#PasswordAuthentication yes/PasswordAuthentication yes/' /etc/ssh/sshd_config


################################################################################
# install apt packages (3)
################################################################################
RUN apt-get update
RUN apt-get install -y \
    build-essential \
    cmake \
    git \
    wget \
    unzip \
    yasm \
    pkg-config \
    libavcodec-dev \
    libavformat-dev \
    libswscale-dev \
    libavresample-dev \
    libgstreamer1.0-dev \
    libgstreamer-plugins-base1.0-dev \
    libxvidcore-dev \
    x264 \
    libx264-dev \
    libfaac-dev \
    libmp3lame-dev \
    libtheora-dev \
    libvorbis-dev \
    libopencore-amrnb-dev \
    libopencore-amrwb-dev \
    libgtk-3-dev \
    libtbb-dev \
    libatlas-base-dev \
    gfortran \
    libprotobuf-dev \
    protobuf-compiler \
    libprotobuf-dev \
    protobuf-compiler \
    libgphoto2-dev \
    libeigen3-dev \
    libhdf5-dev \
    doxygen \
    python3-dev \
    python3-pip \
    python3-numpy
RUN rm -rf /var/lib/apt/lists/*

WORKDIR /

################################################################################
# builder
################################################################################
FROM nvidia/cuda:11.4.3-cudnn8-devel-ubuntu20.04 as builder

RUN apt-get update
RUN apt-get install -y --no-install-recommends curl ca-certificates gnupg patch

################################################################################
# nodejs
################################################################################
RUN curl -fsSL https://deb.nodesource.com/setup_current.x | bash - \
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
    && yarn build
RUN sed -i 's#app/locale/#novnc/app/locale/#' /src/web/dist/static/novnc/app/ui.js


################################################################################
# merge
################################################################################
FROM system
LABEL maintainer="noah@c-link.com.tw"
COPY --from=builder /src/web/dist/ /usr/local/lib/web/frontend/
COPY rootfs /
RUN ln -sf /usr/local/lib/web/frontend/static/websockify /usr/local/lib/web/frontend/static/novnc/utils/websockify && \
    chmod +x /usr/local/lib/web/frontend/static/websockify/run

################################################################################
# expose ssh and vnc port
################################################################################
EXPOSE 80
EXPOSE 22

################################################################################
# remove sudo (optional)
# RUN apt-get purge sudo -y
################################################################################


################################################################################
# post process (1)
################################################################################
WORKDIR /
RUN git clone https://github.com/wolfcw/libfaketime.git
WORKDIR /libfaketime/src
RUN make install

################################################################################
# set timezone
################################################################################
RUN echo "Asia/Taipei" > /etc/timezone
RUN dpkg-reconfigure -f noninteractive tzdata

################################################################################
# post process (2)
################################################################################
WORKDIR /root
ENV HOME=/home/ubuntu
ENV SHELL=/bin/bash
HEALTHCHECK --interval=30s --timeout=5s CMD curl --fail http://127.0.0.1:6079/api/health
ENTRYPOINT ["/startup.sh"]
