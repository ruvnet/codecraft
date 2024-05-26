#!/bin/bash

# Function to check if a command exists
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# Function to check and install required system dependencies for Playwright
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

# Function to check and install required Python packages
install_python_packages() {
    echo "Checking required Python packages..."

    packages=("fastapi" "uvicorn" "uvloop" "litellm" "toml" "termcolor" "docker" "python-docx" "h11" "contourpy" "cycler" "hnswlib" "playwright")

    for package in "${packages[@]}"; do
        if ! python -c "import $package" &> /dev/null; then
            echo "$package is not installed. Installing $package..."
            pip install $package || { echo "Failed to install $package"; exit 1; }
        else
            echo "$package is already installed."
        fi
    done
}

# Function to install libGL
install_libgl() {
    echo "Checking for libGL.so.1..."

    if ! ldconfig -p | grep -q libGL.so.1; then
        echo "libGL.so.1 is not installed. Installing libGL..."
        sudo apt-get update && sudo apt-get install -y libgl1-mesa-glx || { echo "Failed to install libGL"; exit 1; }
    else
        echo "libGL.so.1 is already installed."
    fi
}

# Function to install Playwright and its browsers
install_playwright_and_browsers() {
    echo "Checking Playwright installation and installing browsers..."

    pip install playwright || { echo "Failed to install Playwright"; exit 1; }

    echo "Installing Playwright browsers..."
    playwright install || { echo "Failed to install Playwright browsers"; exit 1; }
}

# Function to install Poetry
install_poetry() {
    echo "Checking Poetry installation..."

    if ! command_exists poetry; then
        echo "Poetry is not installed. Installing Poetry..."
        curl -sSL https://install.python-poetry.org | python3 - || { echo "Failed to install Poetry"; exit 1; }
    else
        echo "Poetry is already installed."
    fi
}

# Function to install Python dependencies using Poetry
install_python_dependencies() {
    echo "Installing Python dependencies using Poetry..."

    cd OpenDevin || { echo "Failed to change directory to OpenDevin"; exit 1; }
    poetry install || { echo "Failed to install Python dependencies"; exit 1; }
    cd ..
}

# Function to install frontend dependencies using npm
install_frontend_dependencies() {
    echo "Installing frontend dependencies using npm..."

    cd OpenDevin/frontend || { echo "Failed to change directory to OpenDevin/frontend"; exit 1; }
    npm install || { echo "Failed to install frontend dependencies"; exit 1; }
    cd ../..
}

# Function to ensure the frontend/dist directory exists
ensure_frontend_dist() {
    echo "Ensuring frontend/dist directory exists..."

    cd OpenDevin/frontend || { echo "Failed to change directory to OpenDevin/frontend"; exit 1; }
    npm run build || { echo "Failed to build frontend"; exit 1; }
    cd ../..
}

# Function to kill processes using specific ports
kill_ports() {
    ports=("3000" "3001")

    for port in "${ports[@]}"; do
        if lsof -i:$port -t &> /dev/null; then
            echo "Killing process using port $port..."
            kill -9 $(lsof -i:$port -t) || { echo "Failed to kill process using port $port"; exit 1; }
        else
            echo "No process using port $port."
        fi
    done
}

# Function to start the backend server
start_backend() {
    echo "Starting backend server..."
    cd OpenDevin || { echo "Failed to change directory to OpenDevin"; exit 1; }
    poetry run uvicorn opendevin.server.listen:app --port 3000 &
    backend_pid=$!
    echo "Backend server started with PID: $backend_pid"
    cd ..
}

# Function to start the frontend server
start_frontend() {
    echo "Starting frontend server..."
    cd OpenDevin/frontend || { echo "Failed to change directory to OpenDevin/frontend"; exit 1; }
    npm run start -- --port 3001 &
    frontend_pid=$!
    echo "Frontend server started with PID: $frontend_pid"
    cd ../..
}

# Install required system dependencies for Playwright
install_playwright_system_deps

# Install required Python packages
install_python_packages

# Install libGL
install_libgl

# Install Playwright and its browsers
install_playwright_and_browsers

# Install Poetry
install_poetry

# Install Python dependencies
install_python_dependencies

# Install frontend dependencies
install_frontend_dependencies

# Ensure the frontend/dist directory exists
ensure_frontend_dist

# Kill processes using ports 3000 and 3001
kill_ports

# Start the backend server
start_backend

# Start the frontend server
start_frontend

# Wait for user input to stop the servers
echo "Press any key to stop the servers..."
read -n 1
echo "Stopping servers..."

# Stop backend server
echo "Stopping backend server..."
kill $backend_pid
wait $backend_pid 2>/dev/null
echo "Backend server stopped."

# Stop frontend server
echo "Stopping frontend server..."
kill $frontend_pid
wait $frontend_pid 2>/dev/null
echo "Frontend server stopped."

echo "OpenDevin servers stopped successfully."
