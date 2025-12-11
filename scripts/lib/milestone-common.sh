#!/bin/bash

# Common functions for milestone scripts

# Function to record milestone failure
record_milestone_failure() {
    local milestone_num=$1
    local error_message=$2
    local milestone_file=$3
    
    echo "MILESTONE_${milestone_num}_STATUS=FAILED" >> "$milestone_file"
    echo "MILESTONE_${milestone_num}_ERROR=$error_message" >> "$milestone_file"
}

# Function to show error and exit
show_error_and_exit() {
    local error_message=$1
    local fix_instructions=$2
    local milestone_num=$3
    local milestone_file=$4
    
    echo "❌ ERROR: $error_message"
    echo ""
    echo "To fix this:"
    echo "$fix_instructions"
    echo ""
    
    record_milestone_failure "$milestone_num" "$error_message" "$milestone_file"
    exit 1
}

# Function to test vagrant SSH
test_vagrant_ssh() {
    vagrant ssh -c "echo 'SSH test successful'" >/dev/null 2>&1
}

# Function to get system info
get_system_memory() {
    vagrant ssh -c "free -m | awk '/^Mem:/ {print \$2}'" 2>/dev/null | tr -d '\r'
}

get_system_cpus() {
    vagrant ssh -c "nproc" 2>/dev/null | tr -d '\r'
}

get_system_disk() {
    vagrant ssh -c "df -h / | awk 'NR==2 {print \$2}'" 2>/dev/null | tr -d '\r'
}

# Function to get software versions
get_docker_version() {
    vagrant ssh -c "docker --version" 2>/dev/null | tr -d '\r'
}

get_ansible_version() {
    vagrant ssh -c "ansible --version | head -1" 2>/dev/null | tr -d '\r'
}