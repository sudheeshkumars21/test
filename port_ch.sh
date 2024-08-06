#!/bin/bash

# Define the list of ports to check
ports=("1515" "1514" "443" "8765")

# Function to check if a port is open using telnet
check_port() {
  local ip=$1
  local port=$2

  # Using telnet to check if the port is open
  (echo quit | telnet "$ip" "$port" 2>&1) | grep -q 'Connected'

  if [ $? -eq 0 ]; then
    echo "Port $port is open on $ip."
  else
    echo "Port $port is closed on $ip."
  fi
}

# Function to process a single IP
process_ip() {
  local ip=$1
  local user=$2
  local pass=$3

  # Ping the IP address
  if ping -c 3 "$ip" &> /dev/null; then
    # Check SSH authentication
    if sshpass -p "$pass" ssh -o StrictHostKeyChecking=no "$user@$ip" exit &> /dev/null; then
      echo "SSH authentication successful for $ip."

      # Check the predefined ports
      for port in "${ports[@]}"; do
        check_port "$ip" "$port"
      done
    else
      echo "SSH authentication failed for $ip."
    fi
  else
    echo "Ping to $ip failed. The system is not reachable."
  fi
}

# Ensure required commands are available
for cmd in telnet sshpass; do
  if ! command -v $cmd &> /dev/null; then
    echo "$cmd command not found. Please install it."
    exit 1
  fi
done

# Get the directory of the script
script_dir=$(dirname "$(realpath "$0")")

# Path to the IP list file
ip_list_file="$script_dir/ip_list.txt"

# Ask whether to use a single IP or a list of IPs
read -p "Do you want to use a single IP or a list of IPs? (single/list): " choice

if [ "$choice" == "single" ]; then
  read -p "Enter the IP address: " ip
  read -p "Enter SSH username: " user
  read -sp "Enter SSH password: " pass
  echo
  process_ip "$ip" "$user" "$pass"
elif [ "$choice" == "list" ]; then
  if [ ! -f "$ip_list_file" ]; then
    echo "File ip_list.txt not found in the script's directory!"
    exit 1
  fi

  # Read and process each IP from the list file
  while IFS= read -r ip; do
    if [[ -n "$ip" ]]; then
      read -p "Enter SSH username for $ip: " user
      read -sp "Enter SSH password for $ip: " pass
      echo
      echo "Processing IP: $ip"
      process_ip "$ip" "$user" "$pass"
    else
      echo "No IP address found in the file."
    fi
  done < "$ip_list_file"
else
  echo "Invalid choice. Please enter 'single' or 'list'."
  exit 1
fi
