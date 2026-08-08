#!/bin/bash
# Description: Automated package installer with root check

# Enforce root privileges
if [ "$EUID" -ne 0 ]; then
    echo "Error: Please run as root (e.g., sudo ./install_packages.sh)"
    exit 1
fi

PACKAGES=("nginx" "curl" "wget")

# 1. Update package lists ONCE before looping
echo "[INFO] Updating package indices..."
apt-get update -qq

# 2. Loop through packages and install missing ones
for PKG in "${PACKAGES[@]}"; do
    if dpkg -s "$PKG" &> /dev/null; then
        echo "[EXISTS] Package '$PKG' is already installed."
    else
        echo "[INSTALLING] Package '$PKG' is missing. Installing..."
        
        # Directly test command execution in the if statement
        if apt-get install -y "$PKG" &> /dev/null; then
            echo "[SUCCESS] Package '$PKG' installed successfully."
        else
            echo "[ERROR] Failed to install '$PKG'."
        fi
    fi
done