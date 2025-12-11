#!/bin/bash

# Milestone Status - Show current progress through deployment pipeline

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
MILESTONE_DIR="$PROJECT_ROOT/.milestones"

echo "=========================================="
echo "Ahab Deployment Pipeline Status"
echo "=========================================="
echo ""

# Create milestone directory if it doesn't exist
mkdir -p "$MILESTONE_DIR"

# Function to get milestone status
get_milestone_status() {
    local milestone_num=$1
    local status_file="$MILESTONE_DIR/milestone-${milestone_num}.status"
    
    if [ -f "$status_file" ]; then
        local status
        status=$(grep "MILESTONE_${milestone_num}_STATUS=" "$status_file" | cut -d'=' -f2)
        echo "$status"
    else
        echo "NOT_STARTED"
    fi
}

# Function to get milestone timestamp
get_milestone_time() {
    local milestone_num=$1
    local status_file="$MILESTONE_DIR/milestone-${milestone_num}.status"
    local time_field=$2  # START_TIME or END_TIME
    
    if [ -f "$status_file" ]; then
        local timestamp
        timestamp=$(grep "MILESTONE_${milestone_num}_${time_field}=" "$status_file" 2>/dev/null | cut -d'=' -f2)
        echo "$timestamp"
    else
        echo ""
    fi
}

# Function to display milestone status
show_milestone() {
    local num=$1
    local title=$2
    local description=$3
    local status
    status=$(get_milestone_status $num)
    
    case "$status" in
        "COMPLETED")
            local icon="✅"
            local status_text="COMPLETED"
            local end_time
            end_time=$(get_milestone_time $num "END_TIME")
            ;;
        "RUNNING")
            local icon="🔄"
            local status_text="IN PROGRESS"
            local end_time=""
            ;;
        "FAILED")
            local icon="❌"
            local status_text="FAILED"
            local end_time=""
            ;;
        *)
            local icon="⭕"
            local status_text="NOT STARTED"
            local end_time=""
            ;;
    esac
    
    printf "%-3s Milestone %d: %-30s [%s]\n" "$icon" "$num" "$title" "$status_text"
    printf "    %s\n" "$description"
    
    if [ -n "$end_time" ]; then
        printf "    Completed: %s\n" "$end_time"
    fi
    
    echo ""
}

# Show all milestones
show_milestone 1 "Workstation Verification" "Verify workstation VM is properly configured"
show_milestone 2 "Target Server Definition" "Define and configure target servers"
show_milestone 3 "Connectivity Verification" "Test SSH connectivity to targets"
show_milestone 4 "Vagrant Test Deployment" "Test deployment on vanilla VM"
show_milestone 5 "Playbook Verification" "Validate Ansible playbooks"
show_milestone 6 "Real Server Deployment" "Deploy to actual target server"
show_milestone 7 "Final System Verification" "Comprehensive system validation"
show_milestone 8 "Production Readiness" "Validate production readiness"

# Calculate overall progress
completed_count=0
total_count=8

for i in {1..8}; do
    status=$(get_milestone_status $i)
    if [ "$status" = "COMPLETED" ]; then
        completed_count=$((completed_count + 1))
    fi
done

progress_percent=$((completed_count * 100 / total_count))

echo "=========================================="
echo "Overall Progress: $completed_count/$total_count milestones ($progress_percent%)"
echo "=========================================="

if [ $completed_count -eq 0 ]; then
    echo ""
    echo "🚀 Getting Started:"
    echo "  1. Ensure workstation is running: make install"
    echo "  2. Start with first milestone: make milestone-1"
    echo ""
elif [ $completed_count -eq 8 ]; then
    echo ""
    echo "🎉 Congratulations! All milestones completed!"
    echo "Your deployment pipeline is fully operational."
    echo ""
else
    # Find next milestone to run
    next_milestone=0
    for i in {1..8}; do
        status=$(get_milestone_status $i)
        if [ "$status" != "COMPLETED" ]; then
            next_milestone=$i
            break
        fi
    done
    
    if [ $next_milestone -gt 0 ]; then
        echo ""
        echo "📋 Next Step:"
        echo "  make milestone-$next_milestone"
        echo ""
    fi
fi

echo "Commands:"
echo "  make milestone-status     # Show this status"
echo "  make milestone-reset      # Reset all progress"
echo "  make milestone-N          # Run specific milestone (1-8)"

# Show any failed milestones
failed_milestones=""
for i in {1..8}; do
    status=$(get_milestone_status $i)
    if [ "$status" = "FAILED" ]; then
        if [ -z "$failed_milestones" ]; then
            failed_milestones="$i"
        else
            failed_milestones="$failed_milestones, $i"
        fi
    fi
done

if [ -n "$failed_milestones" ]; then
    echo ""
    echo "⚠️  Failed Milestones: $failed_milestones"
    echo "   Re-run failed milestones to retry"
fi