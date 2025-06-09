# Use the official Python 3 base image (Debian-based)
FROM python:3.12

# Install necessary build tools and libraries
RUN apt-get update && apt-get install -y \
    build-essential \
    cmake \
    gcc \
    g++ \
    linux-headers-amd64 \
    git \
    libtool \
    autoconf \
    automake \
    swig \
    curl \
    jq \
    liblz4-dev \
    zlib1g-dev \
    libsnappy-dev \
    libsodium-dev \
    libzstd-dev \
    python3-dev \
    && apt-get clean

# Fetch the WiredTiger release dynamically
RUN export WIREDTIGER_URL=$(curl -s https://api.github.com/repos/wiredtiger/wiredtiger/releases/latest | jq -r '.tarball_url') && \
    curl -L $WIREDTIGER_URL -o wiredtiger.tar.gz

# Extract the source to /wiredtiger
RUN mkdir /wiredtiger && \
    tar -xzf wiredtiger.tar.gz --strip-components=1 -C /wiredtiger && \
    rm wiredtiger.tar.gz

# Set up the build directory
WORKDIR /wiredtiger
RUN mkdir /wiredtiger/build

# Configure the WiredTiger build
RUN cmake -S /wiredtiger -B /wiredtiger/build \
    -DCMAKE_BUILD_TYPE=Release \
    -DENABLE_WERROR=0 \
    -DENABLE_QPL=0 \  
    -DCMAKE_C_FLAGS="-Wno-error=array-bounds -O0" \
    -DPYTHON_EXECUTABLE=$(which python3)

# Build WiredTiger
RUN cmake --build /wiredtiger/build

# Add `wt` utility to PATH
RUN ln -s /wiredtiger/build/wt /usr/local/bin/wt

# Set the entrypoint to run `wt dump` by default
ENTRYPOINT ["wt", "dump"]
