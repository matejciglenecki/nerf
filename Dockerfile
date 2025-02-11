# Define base image.
FROM nvidia/cuda:11.7.1-devel-ubuntu22.04
ENV DEBIAN_FRONTEND=noninteractive
## Set timezone as it is required by some packages.
ENV TZ=Europe/Zagreb
## CUDA architectures, required by tiny-cuda-nn.
ENV TCNN_CUDA_ARCHITECTURES=61
## CUDA Home, required to find CUDA in some packages.
ENV CUDA_HOME="/usr/local/cuda"
ENV CMAKE_CUDA_ARCHITECTURES=61

# Update and upgrade all packages
RUN apt update -y
RUN apt upgrade -y

# Install python
RUN apt install -y git python3 software-properties-common python3-pip python-is-python3

# Install deps
RUN apt-get install -y \
    ca-certificates \
    curl \
    gnupg \
    lsb-release \
    htop \
    ffmpeg \
    wget \
    gcc \
    g++ \
    git \
    cmake \
    build-essential \
    libboost-program-options-dev \
    libboost-filesystem-dev \
    libboost-graph-dev \
    libboost-system-dev \
    libboost-test-dev \
    libeigen3-dev \
    libsuitesparse-dev \
    libfreeimage-dev \
    libmetis-dev \
    libgoogle-glog-dev \
    libgflags-dev \
    libglew-dev \
    qtbase5-dev \
    libqt5opengl5-dev \
    libcgal-dev \
    libqt5gui5 \
    qt5-qmake \
    libxcb-util-dev \
    libprotobuf-dev \
    libatlas-base-dev \
    xz-utils \
    nano \
    unzip

RUN apt-get install -y nvidia-cuda-toolkit-gcc
# Install GLOG (required by ceres).
RUN git clone --branch v0.6.0 https://github.com/google/glog.git --single-branch && \
    cd glog && \
    mkdir build && \
    cd build && \
    cmake .. && \
    make -j && \
    make install && \
    cd ../.. && \
    rm -r glog

# Add glog path to LD_LIBRARY_PATH.
ENV LD_LIBRARY_PATH="${LD_LIBRARY_PATH}:/usr/local/lib"


# # Ceres solver
RUN apt-get install libsuitesparse-dev

RUN wget https://github.com/ceres-solver/ceres-solver/archive/refs/tags/2.1.0.tar.gz &&\
    tar zxf 2.1.0.tar.gz &&\
    cd ceres-solver-2.1.0 &&\
    echo "set(CMAKE_CUDA_ARCHITECTURES 61)" >> CMakeLists.txt &&\
    mkdir build &&\
    cd build &&\
    CMAKE_CUDA_ARCHITECTURES="61" cmake .. -DCMAKE_CUDA_ARCHITECTURES="61" -DBUILD_TESTING=OFF -DBUILD_EXAMPLES=OFF &&\
    make -j 2 &&\
    make install

# Ceras reqs
RUN apt-get install -y sqlite3 \
    libsqlite3-dev \
    libflann-dev


# Compile Colamp
RUN apt-get install -y libfreeimage-dev

# Download Colmap, to /colmap-3.7.tar.gz, unzip to /colmap-3.7/
RUN wget -O /colmap-3.7.tar.gz https://github.com/colmap/colmap/archive/refs/tags/3.7.tar.gz &&\
    tar -xzf /colmap-3.7.tar.gz -C / &&\
    cd /colmap-3.7 &&\
    sed -i '1s/^/set(CMAKE_CUDA_ARCHITECTURES 61)\n/' CMakeLists.txt &&\
    sed -i '1s/^/set(CUDA_NVCC_FLAGS "${CUDA_NVCC_FLAGS} --std c++14")\n/' CMakeLists.txt &&\
    sed -i '1s/^/set(CUDA_NVCC_FLAGS "${CUDA_NVCC_FLAGS} --std c++14")\n/' src/CMakeLists.txt &&\
    mkdir build &&\
    cd build &&\
    cmake .. &&\
    make -j 2 &&\
    make install

# COPY requirements.txt /tmp/requirements.txt
# COPY requirements-dev.txt /tmp/requirements-dev.txt

# Install python packets
# RUN pip install --no-cache-dir --upgrade pip
# RUN pip install --no-cache-dir -r /tmp/requirements.txt
# RUN pip install --no-cache-dir -r /tmp/requirements-dev.txt

# Dependency for nerfstudio that has to be installed AFTER torch
# RUN pip install git+https://github.com/NVlabs/tiny-cuda-nn/#subdirectory=bindings/torch

RUN wget -P / https://ftp.nluug.nl/pub/graphics/blender/release/Blender3.4/blender-3.4.1-linux-x64.tar.xz
RUN tar -xJf /blender-3.4.1-linux-x64.tar.xz
# Set the pretty and obvious prompts
ENV TERM xterm-256color
RUN echo 'export PS1="\A \[\033[1;36m\]\h\[\033[1;34m\] \w \[\033[0;015m\]\\$ \[$(tput sgr0)\]\[\033[0m\]"' >> ~/.bashrc
ENV PATH="${PATH}:/blender-3.4.1-linux-x64"
# Set bash entrypoint location to home directory
# WORKDIR $USER_HOME

CMD ["bash", "-l"]