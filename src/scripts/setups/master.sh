#!/bin/bash

# Function to handle errors
handle_error() {
    echo "Error: $1" >&2
    exit 1
}


# Function to check if the user is root
check_sudo() {
    if [ "$(id -u)" -ne 0 ]; then
        echo "Error: This script requires sudo privileges. Please run it with sudo." >&2
        exit 1
    fi
}
