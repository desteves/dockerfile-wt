# Use the official Python 3 Alpine base image
FROM python:3.12-alpine

RUN apk update && apk add --no-cache bash
RUN apk add --no-cache build-base cmake git libtool autoconf automake swig curl jq
RUN apk add --no-cache lz4
RUN apk add --no-cache zlib
# RUN apk add --no-cache libexecinfo
# Step 1: Install libsnappy-dev
RUN apk add --no-cache snappy-dev

# Step 2: Install libsodium-dev
RUN apk add --no-cache libsodium

# Step 3: Install zstd-dev
RUN apk add --no-cache zstd-dev
RUN apk add --no-cache gcc g++


# Fetch the latest WiredTiger release tarball dynamically using GitHub API
RUN export WIREDTIGER_URL=$(curl -s https://api.github.com/repos/wiredtiger/wiredtiger/releases/latest | jq -r '.tarball_url') && \
    curl -L $WIREDTIGER_URL -o wiredtiger.tar.gz

# Create the /wiredtiger directory and extract tar directly into it
RUN mkdir /wiredtiger && \
    tar -xzf wiredtiger.tar.gz --strip-components=1 -C /wiredtiger && \
    rm wiredtiger.tar.gz

# Set up the source directory explicitly
WORKDIR /wiredtiger

# Create the build directory inside /wiredtiger
RUN mkdir /wiredtiger/build

# Configure the build using cmake, explicitly pointing to the source directory (/wiredtiger)
# and the output build directory (/wiredtiger/build)
RUN cmake -S /wiredtiger -B /wiredtiger/build \
    -DCMAKE_BUILD_TYPE=Release \
    -DENABLE_WERROR=1 \
    -DCMAKE_C_FLAGS="-Wno-error=array-bounds" \
    -DPYTHON_EXECUTABLE=$(which python3)


# Build WiredTiger (compile wt utility) inside /wiredtiger/build
RUN cmake --build /wiredtiger/build

# Add the wt utility to PATH
RUN ln -s /wiredtiger/build/wt /usr/local/bin/wt

# Set the entrypoint to run wt dump by default
ENTRYPOINT ["wt", "dump"]
