# Built with arch: amd64 flavor: lxde image: nvidia/cuda:11.4.3-cudnn8-devel-ubuntu20.04
#
################################################################################
# base system
################################################################################

FROM nvidia/cuda:11.4.3-cudnn8-devel-ubuntu20.04 as system


# RUN sed 's/mirror:\/\/mirrors\.ubuntu\.com\/mirrors\.txt/http:\/\/mirror01\.idc\.hinet\.net\/ubuntu/' /etc/apt/sources.list | tee /etc/apt/sources.list

RUN sed -i 's#http://archive.ubuntu.com/ubuntu/#http://free.nchc.org.tw/ubuntu/#' /etc/apt/sources.list;

# built-in packages
ENV DEBIAN_FRONTEND noninteractive
RUN apt update \
    && apt install -y --no-install-recommends software-properties-common curl apache2-utils \
    && apt update \
    && apt install -y --no-install-recommends --allow-unauthenticated \
        supervisor nginx sudo net-tools zenity xz-utils \
        dbus-x11 x11-utils alsa-utils \
        mesa-utils libgl1-mesa-dri \
    && apt autoclean -y \
    && apt autoremove -y \
    && rm -rf /var/lib/apt/lists/*
# install debs error if combine together
RUN apt update \
    && apt install -y --no-install-recommends --allow-unauthenticated \
        xvfb x11vnc \
        vim-tiny firefox ttf-ubuntu-font-family ttf-wqy-zenhei  \
    && apt autoclean -y \
    && apt autoremove -y \
    && rm -rf /var/lib/apt/lists/*
RUN apt update \
    && apt install -y gpg-agent \
    && curl -LO https://dl.google.com/linux/direct/google-chrome-stable_current_amd64.deb \
    && (dpkg -i ./google-chrome-stable_current_amd64.deb || apt-get install -fy) \
    && curl -sSL https://dl.google.com/linux/linux_signing_key.pub | apt-key add \
    && rm google-chrome-stable_current_amd64.deb \
    && rm -rf /var/lib/apt/lists/*




RUN apt update \
    && apt install -y --no-install-recommends --allow-unauthenticated \
        lxde gtk2-engines-murrine gnome-themes-standard gtk2-engines-pixbuf gtk2-engines-murrine arc-theme \
        # lxde gtk2-engines-murrine gnome-themes-standard gtk2-engines-pixbuf gtk2-engines-murrine \
    && apt autoclean -y \
    && apt autoremove -y \
    && rm -rf /var/lib/apt/lists/*
# Additional packages require ~600MB
# libreoffice  pinta language-pack-zh-hant language-pack-gnome-zh-hant firefox-locale-zh-hant libreoffice-l10n-zh-tw

# tini to fix subreap
ARG TINI_VERSION=v0.18.0
ADD https://github.com/krallin/tini/releases/download/${TINI_VERSION}/tini /bin/tini
RUN chmod +x /bin/tini

# ffmpeg
RUN apt update \
    && apt install -y --no-install-recommends --allow-unauthenticated \
        ffmpeg \
    && rm -rf /var/lib/apt/lists/* \
    && mkdir /usr/local/ffmpeg \
    && ln -s /usr/bin/ffmpeg /usr/local/ffmpeg/ffmpeg

# python library
COPY rootfs/usr/local/lib/web/backend/requirements.txt /tmp/
RUN apt-get update \
    && dpkg-query -W -f='${Package}\n' > /tmp/a.txt \
    && apt-get install -y python3-pip python3-dev build-essential \
	&& pip3 install setuptools wheel && pip3 install -r /tmp/requirements.txt \
    && ln -s /usr/bin/python3 /usr/local/bin/python \
    && dpkg-query -W -f='${Package}\n' > /tmp/b.txt \
    && apt-get remove -y `diff --changed-group-format='%>' --unchanged-group-format='' /tmp/a.txt /tmp/b.txt | xargs` \
    && apt-get autoclean -y \
    && apt-get autoremove -y \
    && rm -rf /var/lib/apt/lists/* \
    && rm -rf /var/cache/apt/* /tmp/a.txt /tmp/b.txt

# Lab602
# install conda
ENV PYTHON_VERSION 3.10

# conda and test dependencies
RUN curl -L https://repo.anaconda.com/miniconda/Miniconda3-latest-Linux-x86_64.sh -o /tmp/miniconda.sh \
    && sudo chmod +x /tmp/miniconda.sh \
    && sudo bash /tmp/miniconda.sh -b -p /opt/conda/ \
    && rm -rf /tmp/miniconda.sh \
    && eval "$(/opt/conda shell.bash hook)" \
#    && sudo /opt/conda/bin/conda install -y -c conda-canary -c defaults -c conda-forge \
#        conda conda-package-handling \
#        python=$PYTHON_VERSION pycosat requests ruamel_yaml cytoolz \
#        anaconda-client nbformat \
#        pytest pytest-cov pytest-timeout mock responses pexpect xonsh \
#        flake8 \
#    && sudo /opt/conda/bin/conda clean --all --yes
#
#RUN sudo /opt/conda/bin/pip install codecov radon \
#    && sudo rm -rf ~root/.cache/pip
#
#RUN sudo /opt/conda/bin/pip install -r /tmp/requirements.txt \
#    && sudo rm -rf ~root/.cache/pip
#
## conda-build and test dependencies
#RUN sudo /opt/conda/bin/conda install -y -c defaults -c conda-forge \
#        conda-build patch git \
#        perl pytest-xdist pytest-catchlog pytest-mock \
#        filelock jinja2 conda-verify pkginfo \
#        glob2 beautifulsoup4 chardet pycrypto \
#    && sudo /opt/conda/bin/conda clean --all --yes

# Lab602
# SSH工具安裝
RUN apt-get update \
    && apt-get install -y \
        ssh \
        gedit \
        openssh-server \
        nano \
    && apt-get autoclean -y \
    && apt-get autoremove -y \
    && rm -rf /var/lib/apt/lists/*
RUN mkdir /var/run/sshd
RUN echo 'root:yHrvUU7K5R0ArGEzWPm3hmgDLjrhdtveQWsGrJ4oJznkvxqhJxr1nqyKMF7KpPxn' | chpasswd
RUN sed -i 's/#Port 22/Port 22/' /etc/ssh/sshd_config
RUN sed -i 's/#PermitRootLogin prohibit-password/PermitRootLogin yes/' /etc/ssh/sshd_config
RUN sed -i 's/#PasswordAuthentication yes/PasswordAuthentication yes/' /etc/ssh/sshd_config

# Lab602
# 安裝 openCV
# 
# RUN apt-get update \
#     && apt-get install -y \
#         build-essential \
#         cmake \
#         git \
#         wget \
#         unzip \
#         yasm \
#         pkg-config \
#         libswscale-dev \
#         libtbb2 \
#         libtbb-dev \
#         libjpeg-dev \
#         libpng-dev \
#         libtiff-dev \
#         libavformat-dev \
#         libpq-dev \
#         qt5-default \
#         libgtk2.0-dev \
#     && rm -rf /var/lib/apt/lists/*

# RUN pip install numpy

# WORKDIR /

# RUN wget https://github.com/opencv/opencv_contrib/archive/.zip \
#     && unzip .zip \
#     && rm .zip

# RUN wget https://github.com/opencv/opencv/archive/.zip \
#     && unzip .zip \
#     && mkdir /opencv-/cmake_binary \
#     && cd /opencv-/cmake_binary \
#     && cmake -DBUILD_TIFF=ON \
#             -DBUILD_opencv_java=OFF \
#             -DWITH_CUDA=ON \
#             -DWITH_OPENGL=ON \
#             -DWITH_OPENCL=ON \
#             -DWITH_IPP=ON \
#             -DWITH_TBB=ON \
#             -DBUILD_NEW_PYTHON_SUPPORT=ON \
#             -DWITH_EIGEN=ON \
#             -DWITH_V4L=ON \
#             -DWITH_QT=ON \
#             -DBUILD_TESTS=OFF \
#             -DENABLE_FAST_MATH=1 \
#             -DCUDA_FAST_MATH=1 \
#             -DBUILD_PERF_TESTS=OFF \
#             -DWITH_GTK=ON \
#             -DCMAKE_BUILD_TYPE=RELEASE \
#             -DOPENCV_GENERATE_PKGCONFIG=ON \
#             -DCUDA_TOOLKIT_ROOT_DIR=/usr/local/cuda-11.1 \
#             -DCMAKE_INSTALL_PREFIX=/usr/local \
#             -DPYTHON_EXECUTABLE=$(which python) \
#             -DPYTHON_INCLUDE_DIR=$(python -c "from distutils.sysconfig import get_python_inc; print(get_python_inc())") \
#             -DPYTHON_PACKAGES_PATH=$(python -c "from distutils.sysconfig import get_python_lib; print(get_python_lib())") \
#             -DWITH_CUBLAS=1 \
#             -DOPENCV_EXTRA_MODULES_PATH=/opencv_contrib-/modules \
#             .. \
#     && make -j$(nproc) \
#     && make install \
#     && echo "/usr/local/lib" >> /etc/ld.so.conf.d/opencv.conf \
#     && ldconfig \
#     && echo "PKG_CONFIG_PATH=$PKG_CONFIG_PATH:/usr/local/lib/pkgconfig" | tee -a /etc/bash.bashrc \
#     && echo "export PKG_CONFIG_PATH" | tee -a /etc/bash.bashrc \
#     && rm /.zip \
#     && rm -r /opencv- \
#     && rm -r /opencv_contrib-

RUN apt-get update \
    && apt-get install -y \
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
        python3-numpy \
    && rm -rf /var/lib/apt/lists/*

# RUN pip3 install numpy

WORKDIR /

# -D CUDA_ARCH_BIN=8.6 算力查詢 https://developer.nvidia.com/zh-cn/cuda-gpus#compute 

#RUN wget -O opencv_contrib-.zip https://github.com/opencv/opencv_contrib/archive/.zip \
#    && unzip opencv_contrib-.zip \
#    && rm opencv_contrib-.zip
#
#RUN wget https://github.com/opencv/opencv/archive/.zip \
#    && unzip .zip \
#    && mkdir /opencv-/cmake_binary \
#    && cd /opencv-/cmake_binary \
#    && cmake   -D CMAKE_BUILD_TYPE=RELEASE \
#		-D OPENCV_GENERATE_PKGCONFIG=ON \
#		-D CMAKE_C_COMPILER=/usr/bin/gcc-7 \
#		-D CMAKE_INSTALL_PREFIX=/usr/local \
#		-D INSTALL_PYTHON_EXAMPLES=ON \
#		-D INSTALL_C_EXAMPLES=OFF \
#		-D WITH_TBB=ON \
#		-D WITH_CUDA=ON \
#        -D WITH_OPENMP=ON \
#        -D ENABLE_PRECOMPILED_HEADERS=OFF \
#		-D ENABLE_FAST_MATH=1 \
#		-D CUDA_FAST_MATH=1 \
#		-D WITH_CUBLAS=1 \
#		-D WITH_V4L=ON \
#		-D WITH_QT=OFF \
#		-D WITH_OPENGL=ON \
#		-D WITH_GSTREAMER=ON \
#		-D OPENCV_PC_FILE_NAME=opencv.pc \
#		-D OPENCV_ENABLE_NONFREE=ON \
#		-D OPENCV_EXTRA_MODULES_PATH=/opencv_contrib-/modules \
#		-D WITH_CUDNN=ON \
#		-D OPENCV_DNN_CUDA=ON \
#		-D CUDA_ARCH_BIN=7.5 \
#		.. \
#    && make -j$(nproc) \
#    && make install \
#    && echo "/usr/local/lib" >> /etc/ld.so.conf.d/opencv.conf \
#    && ldconfig \
#    && echo "PKG_CONFIG_PATH=\$PKG_CONFIG_PATH:/usr/local/lib/pkgconfig" | tee -a /etc/bash.bashrc \
#    && echo "export PKG_CONFIG_PATH" | tee -a /etc/bash.bashrc
    # && rm /.zip \
    # && rm -r /opencv-* \
    # && rm -r /opencv_*

# 
################################################################################
# builder
################################################################################
FROM nvidia/cuda:11.4.3-cudnn8-devel-ubuntu20.04 as builder



RUN apt-get update \
    && apt-get install -y --no-install-recommends curl ca-certificates gnupg patch

# nodejs
#RUN curl -sL https://deb.nodesource.com/setup_current.x | bash - \
#    && apt-get install -y nodejs
    
RUN curl -fsSL https://deb.nodesource.com/setup_current.x | bash - \
    && apt-get install -y nodejs

# yarn
RUN curl -sS https://dl.yarnpkg.com/debian/pubkey.gpg | apt-key add - \
    && echo "deb https://dl.yarnpkg.com/debian/ stable main" | tee /etc/apt/sources.list.d/yarn.list \
    && apt-get update \
    && apt-get install -y yarn

# build frontend
COPY web /src/web
RUN cd /src/web \
    && yarn \
    && yarn build
RUN sed -i 's#app/locale/#novnc/app/locale/#' /src/web/dist/static/novnc/app/ui.js



################################################################################
# merge
################################################################################
FROM system
LABEL maintainer="fcwu.tw@gmail.com"

COPY --from=builder /src/web/dist/ /usr/local/lib/web/frontend/
COPY rootfs /
RUN ln -sf /usr/local/lib/web/frontend/static/websockify /usr/local/lib/web/frontend/static/novnc/utils/websockify && \
	chmod +x /usr/local/lib/web/frontend/static/websockify/run


EXPOSE 80

# Lab602 SSH要開port 22
EXPOSE 22

# Lab602 移除SUDO功能
# RUN apt-get purge sudo -y

WORKDIR /
RUN git clone https://github.com/wolfcw/libfaketime.git
WORKDIR /libfaketime/src
RUN make install

RUN echo "Asia/Taipei" > /etc/timezone
RUN dpkg-reconfigure -f noninteractive tzdata

WORKDIR /root
ENV HOME=/home/ubuntu \
    SHELL=/bin/bash
HEALTHCHECK --interval=30s --timeout=5s CMD curl --fail http://127.0.0.1:6079/api/health
ENTRYPOINT ["/startup.sh"]
