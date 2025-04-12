#!/bin/bash

# Ensure you are running the script as root
if [[ $EUID -ne 0 ]]; then
   echo "This script must be run as root"
   exit 1
fi

# Variables - You can modify these if needed
VMID=103  # VM ID, make sure it's unique in your Proxmox setup
VMNAME="RustServer"
URL="/var/lib/vz/template/iso/debian-11.3.0-amd64-netinst.iso"  # Path to Debian ISO
STORAGE="Storage"  # Storage pool for the VM
CORES=8  # Number of CPU cores
RAM=12288  # RAM in MB (12GB)
DISK=50  # Disk size in GB
NET_BRIDGE="vmbr0"  # Default network bridge

# Create the VM in Proxmox
echo "Creating VM with ID $VMID..."

# Create VM with specified resources
qm create $VMID --name $VMNAME --cores $CORES --memory $RAM --net0 virtio,bridge=$NET_BRIDGE --boot order=virtio0 --ide2 $STORAGE:cloudinit --ostype l26 --scsihw virtio-scsi-pci --virtio0 $STORAGE:$DISK --cdrom $ISO_PATH

# Start the VM
echo "Starting the VM..."
qm start $VMID

echo "VM $VMNAME created with ID $VMID. It is running with $CORES cores, $RAM MB RAM, and $DISK GB of storage."

# SSH login message
echo "After the VM is booted, you can SSH into it using the Proxmox web console or SSH client."
echo "Follow the installation steps in the VM to set up your Debian OS for Rust server."

# VM Installation Script - Sample Steps for Rust Installation
cat << EOF > /root/install_rust_server.sh
#!/bin/bash

# Update and install dependencies
apt update && apt upgrade -y
apt install -y screen wget curl git

# Install Rust via rustup (Rust installation)
curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh

# Set up Rust for the user
source \$HOME/.cargo/env

# Create directory for the Rust server
mkdir /home/debian/rust_server
cd /home/debian/rust_server

# Install Rust Dedicated Server (assumes SteamCMD is used)
wget https://steamcdn-a.akamaihd.net/client/installer/steamcmd_linux.tar.gz
tar -xvzf steamcmd_linux.tar.gz

# Install Rust Server
./steamcmd.sh +login anonymous +force_install_dir ./rustserver +app_update 258550 validate +quit

# Create a basic start server script
cat <<EOL > start_server.sh
#!/bin/bash
./RustDedicated -batchmode -load --server.ip 0.0.0.0 --server.port 28015 --server.hostname "My Rust Server" --server.maxplayers 100 --server.worldsize 4000 --server.seed 12345 --rcon.port 28016
EOL

chmod +x start_server.sh

echo "Rust server installation is complete. You can now start the server using './start_server.sh'."
EOF

# Make the script executable
chmod +x /root/install_rust_server.sh

echo "Use 'ssh root@<VM_IP>' to log into the VM and run '/root/install_rust_server.sh' to install and configure your Rust server."
