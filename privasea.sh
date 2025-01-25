#!/bin/bash

# Fetching and displaying the logo
curl -s https://raw.githubusercontent.com/zidanaetrna/unichain/refs/heads/main/button_logo_script.sh | bash
sleep 5

# Define colors for output
CLR_SUCCESS='\033[0;32m'  # Green
CLR_INFO='\033[0;36m'     # Cyan
CLR_ERROR='\033[0;31m'    # Red
CLR_RESET='\033[0m'       # Reset color

# Function to print success messages
print_success() {
    echo -e "${CLR_SUCCESS}[✔] $1${CLR_RESET}"
}

# Function to print info messages
print_info() {
    echo -e "${CLR_INFO}[-] $1...${CLR_RESET}"
}

# Function to print error messages
print_error() {
    echo -e "${CLR_ERROR}[✘] $1${CLR_RESET}"
}

# Clear screen before execution
clear
echo -e "${CLR_INFO}========================================"
echo "   Privasea Acceleration Node Installer"
echo -e "========================================${CLR_RESET}\n"

# Step 1: Check and install Docker if missing
if ! command -v docker &> /dev/null; then
    print_info "Docker not found. Installing Docker..."
    
    # Install required dependencies
    sudo apt update
    sudo apt install -y apt-transport-https ca-certificates curl software-properties-common

    # Add Docker’s official GPG key
    curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo apt-key add -

    # Add Docker repository
    sudo add-apt-repository "deb [arch=amd64] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable"

    # Update package index and install Docker
    sudo apt update
    sudo apt install -y docker-ce
    sudo systemctl start docker
    sudo systemctl enable docker

    print_success "Docker installed and running."
else
    print_success "Docker is already installed."
fi

echo ""

# Step 2: Pull the Privasea Docker image
print_info "Downloading Privasea Acceleration Node image..."
if docker pull privasea/acceleration-node-beta:latest; then
    print_success "Docker image successfully downloaded."
else
    print_error "Failed to download Docker image."
    exit 1
fi

echo ""

# Step 3: Create configuration directory
CONFIG_DIR="$HOME/privasea/config"
print_info "Setting up configuration directory at $CONFIG_DIR..."
mkdir -p "$CONFIG_DIR" && print_success "Configuration directory created." || {
    print_error "Failed to create configuration directory."
    exit 1
}

echo ""

# Step 4: Generate Keystore file
print_info "Generating keystore file..."
if docker run -it -v "$CONFIG_DIR:/app/config" privasea/acceleration-node-beta:latest ./node-calc new_keystore; then
    print_success "Keystore file successfully created."
else
    print_error "Failed to generate keystore file."
    exit 1
fi

echo ""

# Step 5: Rename Keystore file
print_info "Renaming keystore file..."
if mv "$CONFIG_DIR"/UTC--* "$CONFIG_DIR/wallet_keystore"; then
    print_success "Keystore file renamed to wallet_keystore."
else
    print_error "Failed to rename keystore file."
    exit 1
fi

echo ""

# Step 6: Confirm if user wants to start the node
read -p "Would you like to start the node now? (y/n): " USER_CHOICE
if [[ "$USER_CHOICE" != "y" ]]; then
    echo -e "${CLR_INFO}Process aborted by user.${CLR_RESET}"
    exit 0
fi

echo ""

# Step 7: Get the keystore password from the user
print_info "Enter the keystore password for node access:"
read -s NODE_PASSWORD
echo ""

# Step 8: Start the Privasea Node
print_info "Starting the Privasea Acceleration Node..."
if docker run -d -v "$CONFIG_DIR:/app/config" -e KEYSTORE_PASSWORD="$NODE_PASSWORD" privasea/acceleration-node-beta:latest; then
    print_success "Node is now running!"
else
    print_error "Failed to start the node."
    exit 1
fi

echo ""

# Final Output
echo -e "${CLR_SUCCESS}========================================"
echo "   Installation Complete!"
echo -e "========================================${CLR_RESET}\n"
echo -e "${CLR_INFO}Configuration stored in:${CLR_RESET} $CONFIG_DIR"
echo -e "${CLR_INFO}Keystore file saved as:${CLR_RESET} wallet_keystore"
echo -e "${CLR_INFO}Entered Keystore Password:${CLR_RESET} $NODE_PASSWORD"
echo ""
