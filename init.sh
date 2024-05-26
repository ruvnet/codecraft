#!/bin/bash

# Define the YAML file to store installation state and error logs
INSTALL_STATE_FILE="install_state.yml"

# Function to check if a command exists
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# Function to log errors
log_error() {
    echo "error: $1" >> $INSTALL_STATE_FILE
}

# Function to check and install prerequisites
install_prerequisites() {
    echo "🔍 Checking prerequisites..."

    # Update OS
    echo "Updating OS..."
    sudo apt-get update || { log_error "Failed to update OS"; return 1; }

    # Install Git
    if ! command_exists git; then
        echo "Installing Git..."
        sudo apt-get install -y git || { log_error "Failed to install Git"; return 1; }
    else
        echo "Git is already installed."
    fi

    # Install Node.js
    if ! command_exists node; then
        echo "Installing Node.js..."
        sudo apt-get install -y nodejs || { log_error "Failed to install Node.js"; return 1; }
    else
        echo "Node.js is already installed."
    fi

    # Install npm
    if ! command_exists npm; then
        echo "Installing npm..."
        sudo apt install -y npm || { log_error "Failed to install npm"; return 1; }
    else
        echo "npm is already installed."
    fi

    # Install Rust
    if ! command_exists rustc; then
        echo "Installing Rust..."
        curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh || { log_error "Failed to install Rust"; return 1; }
    else
        echo "Rust is already installed."
    fi

    # Install Conda
    if ! command_exists conda; then
        echo "Installing Conda..."
        wget https://repo.anaconda.com/archive/Anaconda3-2022.05-Linux-x86_64.sh
        bash Anaconda3-2022.05-Linux-x86_64.sh || { log_error "Failed to install Conda"; return 1; }
    else
        echo "Conda is already installed."
    fi

    # Install Uvicorn
    if ! command_exists uvicorn; then
        echo "Installing Uvicorn..."
        sudo apt install -y uvicorn || { log_error "Failed to install Uvicorn"; return 1; }
    else
        echo "Uvicorn is already installed."
    fi

    echo "✅ Prerequisites installed successfully."
}

# Function to setup backend
setup_backend() {
    echo "Setting up backend..."

    # Clone OpenDevin repository
    if [ ! -d "OpenDevin" ]; then
        echo "Cloning OpenDevin repository..."
        git clone https://github.com/OpenDevin/OpenDevin.git || { log_error "Failed to clone OpenDevin repository"; return 1; }
    else
        echo "OpenDevin repository already cloned."
    fi

    # Change directory to OpenDevin
    echo "Changing directory to OpenDevin..."
    cd OpenDevin || { log_error "Failed to change directory to OpenDevin"; return 1; }

    # Create and activate Conda environment
    echo "Creating and activating Conda environment..."
    conda create -n opendevin python=3.11 -y || { log_error "Failed to create Conda environment"; return 1; }
    conda activate opendevin || { log_error "Failed to activate Conda environment"; return 1; }

    # Install Pipenv
    echo "Installing Pipenv..."
    python -m pip install pipenv || { log_error "Failed to install Pipenv"; return 1; }

    # Install backend dependencies
    echo "Installing backend dependencies..."
    python -m pipenv install -v || { log_error "Failed to install backend dependencies"; return 1; }
    python -m pipenv shell || { log_error "Failed to activate Pipenv shell"; return 1; }

    echo "✅ Backend setup completed successfully."
}

# Function to setup frontend
setup_frontend() {
    echo "Setting up frontend..."

    # Change directory to frontend
    echo "Changing directory to frontend..."
    cd frontend || { log_error "Failed to change directory to frontend"; return 1; }

    # Install frontend dependencies
    echo "Installing frontend dependencies..."
    npm install || { log_error "Failed to install frontend dependencies"; return 1; }

    echo "✅ Frontend setup completed successfully."
}

# Function to start the backend and frontend servers
start_servers() {
    echo "Starting backend and frontend servers..."

    # Start backend server
    echo "Starting backend server..."
    cd ../OpenDevin || { log_error "Failed to change directory to OpenDevin"; return 1; }
    uvicorn opendevin.server.listen:app --port 3000 &
    backend_pid=$!
    echo "Backend server started with PID: $backend_pid"

    # Start frontend server
    echo "Starting frontend server..."
    cd ../frontend || { log_error "Failed to change directory to frontend"; return 1; }
    npm run start -- --port 3001 &
    frontend_pid=$!
    echo "Frontend server started with PID: $frontend_pid"

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

    echo "✅ Backend and frontend servers stopped successfully."
}

# Function to configure API key and workspace directory
configure_settings() {
    echo "Configuring settings..."

    echo -n "Enter your OpenAI API Key: "
    read OPENAI_API_KEY
    export OPENAI_API_KEY=$OPENAI_API_KEY
    echo "OPENAI_API_KEY=$OPENAI_API_KEY" >> .env
    echo "OpenAI API Key set."

    echo -n "Enter the path to your workspace directory: "
    read WORKSPACE_DIR
    export WORKSPACE_DIR=$WORKSPACE_DIR
    echo "WORKSPACE_DIR=$WORKSPACE_DIR" >> .env
    echo "Workspace directory set to $WORKSPACE_DIR."

    echo "✅ Settings configured successfully."
}

# Function to display advanced settings menu
advanced_settings() {
    echo "Advanced Settings"
    echo "1. Set OpenAI API Key"
    echo "2. Set Workspace Directory"
    echo "3. Return to Main Menu"
    echo -n "Enter selection: "
    read adv_selection

    case $adv_selection in
        1)
            echo -n "Enter your OpenAI API Key: "
            read OPENAI_API_KEY
            export OPENAI_API_KEY=$OPENAI_API_KEY
            echo "OPENAI_API_KEY=$OPENAI_API_KEY" >> .env
            echo "OpenAI API Key set."
            ;;
        2)
            echo -n "Enter the path to your workspace directory: "
            read WORKSPACE_DIR
            export WORKSPACE_DIR=$WORKSPACE_DIR
            echo "WORKSPACE_DIR=$WORKSPACE_DIR" >> .env
            echo "Workspace directory set to $WORKSPACE_DIR."
            ;;
        3)
            return
            ;;
        *)
            echo "Invalid selection!"
            ;;
    esac
}

# Function to display the main menu
main_menu() {
    until [ "$selection" = "0" ]; do
        clear
        echo "OpenDevin Installation and Configuration"
        echo "1. Install Prerequisites"
        echo "2. Setup Backend"
        echo "3. Setup Frontend"
        echo "4. Configure Settings"
        echo "5. Advanced Settings"
        echo "6. Start Servers"
        echo "0. Exit"
        echo -n "Enter selection: "
        read selection

        case $selection in
            1)
                install_prerequisites
                ;;
            2)
                setup_backend
                ;;
            3)
                setup_frontend
                ;;
            4)
                configure_settings
                ;;
            5)
                advanced_settings
                ;;
            6)
                start_servers
                ;;
            0)
                echo "Exiting..."
                exit 0
                ;;
            *)
                echo "Invalid selection!"
                ;;
        esac
    done
}

# Check if the installation state file exists
if [ -f "$INSTALL_STATE_FILE" ]; then
    echo "Previous installation detected. Skipping initial installation steps."
    main_menu
else
    echo "No previous installation detected. Starting initial installation."
    touch $INSTALL_STATE_FILE
    main_menu
fi