#!/bin/bash

if [ -z "$1" ]; then
    echo "Enter Dockerfile name"
    exit 1
fi

# Check if Docker or Podman is installed
if ! command -v docker &>/dev/null && ! command -v podman &>/dev/null; then
    echo "Neither Docker nor Podman is installed"
    exit 1
fi

# Function to build and run using the provided command and architecture
build_and_run() {
    local build_cmd=$1
    local run_cmd=$2
    local dockerfile=$3
    local pyinstaller_args=${4:-"--onefile"}
    local architectures=("${!5}")  # Pass architectures as an array

    for arch in "${architectures[@]}"; do
        echo "Building for architecture: $arch"
        # Build command with architecture
        $build_cmd buildx build --platform "$arch" -f "$dockerfile" -t pyinstaller_test_"$arch" . && \
        $run_cmd -v "$(pwd)/test:/src/" pyinstaller_test_"$arch" "pyinstaller main.py $pyinstaller_args"
    done
}

# List of architectures to build for
architectures=("linux/amd64" "linux/arm64" "linux/arm/v7" "linux/ppc64le" "linux/s390x")

# Try Docker first
if command -v docker &>/dev/null; then
    if ! build_and_run "docker" "docker run" "$1" architectures[@]; then
        echo "Docker build failed, trying Podman..."
    fi
fi

# If Docker failed or Podman is the preferred fallback
if command -v podman &>/dev/null; then
    if ! build_and_run "podman" "podman run" "$1" architectures[@]; then
        echo "Podman build failed"
        exit 1
    fi
fi
