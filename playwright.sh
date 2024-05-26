#!/bin/bash

# Check if a command exists
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# Install required system dependencies for Playwright
install_playwright_system_deps() {
    echo "Installing Playwright system dependencies..."

    sudo apt-get update && sudo apt-get install -y \
        libwoff1 \
        libopus0 \
        libwebpdemux2 \
        libharfbuzz-icu0 \
        libenchant-2-2 \
        libhyphen0 \
        libflite1 \
        libegl1 \
        libgudev-1.0-0 \
        libevdev2 \
        libgles2 \
        gstreamer1.0-libav || { echo "Failed to install Playwright system dependencies"; exit 1; }
}

# Install Playwright and its browsers
install_playwright_and_browsers() {
    echo "Installing Playwright and its browsers..."

    pip install playwright || { echo "Failed to install Playwright"; exit 1; }
    playwright install || { echo "Failed to install Playwright browsers"; exit 1; }
}

# Main setup function
main_setup() {
    install_playwright_system_deps
    install_playwright_and_browsers
}

# Execute the main setup function
main_setup
