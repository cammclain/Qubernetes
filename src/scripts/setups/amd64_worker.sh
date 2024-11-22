#! /bin/bash

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

sudo apt-get update && sudo apt-get install -y \
    apt-transport-https \
    ca-certificates \
    curl \
    software-properties-common \
    wget \
    git \
    tor \
    torsocks \


# protocol	Direction	Port Range	Purpose	Used By
# TCP	Inbound	10250	Kubelet API	Self, Control plane
# TCP	Inbound	10256	kube-proxy	Self, Load balancers
# TCP	Inbound	30000-32767	NodePort Services†	All
# REFERENCES:
# - https://kubernetes.io/docs/reference/networking/ports-and-protocols/#node
declare -r REQUIRED_PORTS=(10250 10256 30000-32767)