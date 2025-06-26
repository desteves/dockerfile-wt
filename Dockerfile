# Use the official Python 3 base image (Debian-based)
FROM  --platform=linux/amd64 python:3.12

# Install necessary build tools and libraries
RUN apt-get update && apt-get install -y \
    build-essential \
    cmake \
    gcc \
    g++ \
    libstdc++-12-dev \
    git \
    libtool \
    autoconf \
    automake \
    swig \
    curl \
    jq \
    liblz4-dev \
    zlib1g-dev \
    libmemkind-dev \
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
    # -DENABLE_SNAPPY=1 \
    -DHAVE_BUILTIN_EXTENSION_SNAPPY=1 \
    -DCMAKE_BUILD_TYPE=Release \
    -DENABLE_WERROR=0 \
    -DENABLE_QPL=0 \
    -DCMAKE_C_FLAGS="-O0 -Wno-error -Wno-format-overflow -Wno-error=array-bounds -Wno-error=format-overflow -Wno-error=nonnull" \
    -DPYTHON_EXECUTABLE=$(which python3)

# Build WiredTiger
RUN cmake --build /wiredtiger/build

# Add `wt` utility to PATH
RUN ln -s /wiredtiger/build/wt /usr/local/bin/wt

# Set the entrypoint to run `wt` by default
ENTRYPOINT ["wt"]