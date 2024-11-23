#!/bin/bash

if [ -z "$1" ]; then
    echo "Enter Dockerfile name"
    exit 1
fi

if ! command -v docker &>/dev/null && ! command -v podman &>/dev/null; then
    echo "Neither Docker nor Podman is installed"
    exit 1
fi

build_and_run() {
    local build_cmd=$1
    local run_cmd=$2
    local dockerfile=$3
    local pyinstaller_args=${4:-"--onefile"}
    local platforms=${5:-"linux/amd64,linux/arm64,linux/arm/v7"}  # Default platforms (amd64, arm64, armv7)

    # Check if docker buildx is available
    if command -v docker &>/dev/null && docker buildx version &>/dev/null; then
        # Use buildx for multi-architecture builds
        $build_cmd buildx create --use  # Initialize buildx builder
        $build_cmd buildx build --platform "$platforms" -f "$dockerfile" -t pyinstaller_test . --push && \
        $run_cmd -v "$(pwd)/test:/src/" pyinstaller_test "pyinstaller main.py $pyinstaller_args"
    else
        # Fallback to standard docker build for a single architecture
        $build_cmd -f "$dockerfile" -t pyinstaller_test . && \
        $run_cmd -v "$(pwd)/test:/src/" pyinstaller_test "pyinstaller main.py $pyinstaller_args"
    fi
}

# Try Docker first, then Podman if it fails
if ! build_and_run "docker" "docker run" "$1"; then
    echo "Docker build failed, trying Podman..."
    build_and_run "podman" "podman run" "$1"
fi