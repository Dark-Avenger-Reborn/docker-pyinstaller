#!/bin/bash

# Ensure architecture argument is passed or use default (all architectures)
ARCHITECTURES=${ARCHITECTURES:-"arm32v7 arm64 x86_64 i386 x86"}

if [ -z "$1" ]; then
    echo "Enter Dockerfile name"
    exit 1
fi

if ! command -v docker &>/dev/null && ! command -v podman &>/dev/null; then
    echo "Neither Docker nor Podman is installed"
    exit 1
fi

# Function to build and run the container for the specified architecture
build_and_run() {
    local build_cmd=$1
    local run_cmd=$2
    local dockerfile=$3
    local pyinstaller_args=${4:-"--onefile"}
    local arch=$5

    echo "Building for architecture: $arch"

    $build_cmd --platform "$arch" -f "$dockerfile" -t pyinstaller_test:$arch . && \
    $run_cmd --platform "$arch" -v "$(pwd)/test:/src/" pyinstaller_test:$arch pyinstaller main.py $pyinstaller_args
}

# Try building for each architecture in the ARCHITECTURES list
for arch in $ARCHITECTURES; do
    if ! build_and_run "docker build" "docker run" "$1" "$arch"; then
        echo "Docker build failed for $arch, trying Podman..."
        if ! build_and_run "podman build" "podman run" "$1" "$arch"; then
            echo "Podman build failed for $arch. Skipping..."
        fi
    fi
done

echo "Build process completed."
