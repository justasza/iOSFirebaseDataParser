#!/bin/bash

set -e

echo "Building the project ..."
swift build -c release

BUILD_DIR=".build/release"
APP_NAME=$(basename "$(pwd)")

if [ -f "$BUILD_DIR/$APP_NAME" ]; then
    echo "Build successful. Moving binary to the root directory..."
    mv "$BUILD_DIR/$APP_NAME" .
    echo "Binary moved to: ./$APP_NAME"
else
    echo "Error: Binary not found in $BUILD_DIR. Build might have failed."
    exit 1
fi
