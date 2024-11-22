#!/bin/bash

## Master node setup script! 
## This script is used to setup the master node of the cluster.
## It will install the necessary packages and configure a DEBIAN!!!! based system for operating as the master node of the Q8S project.
## It will setup the Kubeadm cluster and install the necessary packages for the master node.
## It will also setup the necessary certificates and keys for the master node.
## It will also setup the necessary network policies for the master node.
## It will also setup the necessary storage for the master node.
## It will also setup the necessary monitoring for the master node.


## References:
# - https://kubernetes.io/docs/reference/setup-tools/kubeadm/
# - https://kubernetes.io/docs/setup/production-environment/tools/kubeadm/install-kubeadm/
# - https://kubernetes.io/docs/setup/production-environment/tools/kubeadm/create-cluster-kubeadm/

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


# Check required Kubernetes control plane ports
# TCP	Inbound	6443	Kubernetes API server	All
# TCP	Inbound	2379-2380	etcd server client API	kube-apiserver, etcd
# TCP	Inbound	10250	Kubelet API	Self, Control plane
# TCP	Inbound	10259	kube-scheduler	Self
# TCP	Inbound	10257	kube-controller-manager	Self
# REFERENCES:
# - https://kubernetes.io/docs/reference/ports-and-protocols/
declare -r REQUIRED_PORTS=(6443 2379 2380 10250 10259 10257)

check_ports() {
    local port
    local unavailable_ports=()
    
    # Check all ports in parallel using background processes
    for port in "${REQUIRED_PORTS[@]}"; do
        nc -z localhost "$port" &>/dev/null &
    done

    # Wait for all background processes to complete
    wait

    # Verify results
    for port in "${REQUIRED_PORTS[@]}"; do
        if ! nc -z localhost "$port" &>/dev/null; then
            unavailable_ports+=("$port")
        fi
    done

    # Report all unavailable ports at once if any
    if [ ${#unavailable_ports[@]} -ne 0 ]; then
        echo "Error: The following required ports are not available: ${unavailable_ports[*]}" >&2
        return 1
    fi

    return 0
}



# Swap configuration
# The default behavior of a kubelet is to fail to start if swap memory is detected on a node. 
# This function ensures swap is completely disabled on Debian systems.
check_swap() {
    echo "Checking and disabling swap..."
    
    # First disable all active swap
    if [ -n "$(swapon --show)" ]; then
        echo "Active swap detected. Disabling all swap devices..."
        sudo swapoff -a || {
            echo "Error: Failed to disable active swap" >&2
            return 1
        }
    fi

    # Remove swap entries from /etc/fstab
    if grep -q -E '^[^#].*\sswap\s' /etc/fstab; then
        echo "Removing swap entries from /etc/fstab..."
        sudo sed -i '/\sswap\s/d' /etc/fstab || {
            echo "Error: Failed to remove swap entries from /etc/fstab" >&2
            return 1
        }
    fi

    # Disable swap in systemd if present
    if [ -f /etc/systemd/system/swap.target ]; then
        echo "Disabling systemd swap target..."
        sudo systemctl mask swap.target || {
            echo "Error: Failed to mask swap.target" >&2
            return 1
        }
    fi

    # Remove any swap files
    local swap_files=$(find /etc -type f -name "*.swap")
    if [ -n "$swap_files" ]; then
        echo "Removing swap files..."
        for file in $swap_files; do
            sudo rm -f "$file" || {
                echo "Error: Failed to remove swap file: $file" >&2
                return 1
            }
        done
    fi

    # Verify swap is disabled
    if [ -n "$(swapon --show)" ]; then
        echo "Error: Failed to completely disable swap" >&2
        return 1
    fi

    echo "Swap has been successfully disabled"
    return 0
}
