#!/usr/bin/env bash
# installer/lib.sh — Common functions for installer suite

set -euo pipefail

# Colors for terminal output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Logging
log_info() {
    printf "${BLUE}[INFO]${NC} %s\n" "$1" | tee -a "${INSTALLER_LOG:-/dev/null}"
}

log_success() {
    printf "${GREEN}[PASS]${NC} %s\n" "$1" | tee -a "${INSTALLER_LOG:-/dev/null}"
}

log_warn() {
    printf "${YELLOW}[WARN]${NC} %s\n" "$1" | tee -a "${INSTALLER_LOG:-/dev/null}"
}

log_error() {
    printf "${RED}[ERROR]${NC} %s\n" "$1" >&2 | tee -a "${INSTALLER_LOG:-/dev/null}"
}

# Require root
require_root() {
    if [[ $EUID -ne 0 ]]; then
        log_error "This script must be run as root"
        exit 1
    fi
}

# Detect Linux distribution
detect_distro() {
    if [[ ! -f /etc/os-release ]]; then
        log_error "Cannot determine Linux distribution"
        return 1
    fi
    
    source /etc/os-release
    
    case "${ID,,}" in
        ubuntu|debian|linuxmint|pop)
            echo "${ID}"
            return 0
            ;;
        *)
            log_error "Unsupported distribution: $ID"
            return 1
            ;;
    esac
}

# Check if command exists
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# Detect optical drives
detect_optical_drives() {
    mapfile -t DRIVES < <(find /dev -maxdepth 1 -name 'sr*' -o -name 'cd*' | sort)
    
    if [[ ${#DRIVES[@]} -eq 0 ]]; then
        log_warn "No optical drives detected"
        return 1
    fi
    
    log_info "Found ${#DRIVES[@]} optical drive(s)"
    return 0
}

# Select optical drive
select_optical_drive() {
    local count=${#DRIVES[@]}
    
    if [[ $count -eq 0 ]]; then
        log_error "No optical drives found"
        return 1
    elif [[ $count -eq 1 ]]; then
        DVD_DEVICE="${DRIVES[0]}"
        log_success "Selected optical drive: $DVD_DEVICE"
        return 0
    else
        # Multiple drives - use whiptail if available
        if command_exists whiptail; then
            local options=()
            for drive in "${DRIVES[@]}"; do
                options+=("$drive" "Optical Drive")
            done
            DVD_DEVICE=$(whiptail --menu "Select optical drive" 15 50 "$count" "${options[@]}" 3>&1 1>&2 2>&3) || return 1
            log_success "Selected optical drive: $DVD_DEVICE"
            return 0
        else
            log_error "Multiple drives found but whiptail not installed. Defaulting to ${DRIVES[0]}"
            DVD_DEVICE="${DRIVES[0]}"
            return 0
        fi
    fi
}

# Check if system has internet
check_internet() {
    if ping -c 1 8.8.8.8 >/dev/null 2>&1; then
        log_success "Internet connection verified"
        return 0
    else
        log_warn "No internet connection detected"
        return 1
    fi
}

# Test drive accessibility
test_drive_access() {
    if [[ ! -e "$DVD_DEVICE" ]]; then
        log_error "DVD device not found: $DVD_DEVICE"
        return 1
    fi
    
    if ! dd if="$DVD_DEVICE" bs=1 count=1 of=/dev/null 2>/dev/null; then
        log_error "Cannot read from DVD device: $DVD_DEVICE"
        return 1
    fi
    
    log_success "DVD device is accessible: $DVD_DEVICE"
    return 0
}

# Detect existing installation
detect_existing_install() {
    if systemctl list-unit-files | grep -q '^hac-da-rippr.service'; then
        return 0  # Exists
    fi
    return 1  # Doesn't exist
}

# Backup existing config
backup_config() {
    local config="$1"
    if [[ -f "$config" ]]; then
        local backup="${config}.bak.$(date +%Y%m%d_%H%M%S)"
        cp "$config" "$backup"
        log_success "Backed up config: $backup"
    fi
}

# Test directory writability
test_directory_writable() {
    local dir="$1"
    
    if [[ ! -d "$dir" ]]; then
        log_warn "Directory does not exist: $dir (will be created)"
        mkdir -p "$dir" || return 1
    fi
    
    if [[ ! -w "$dir" ]]; then
        log_error "Directory is not writable: $dir"
        return 1
    fi
    
    log_success "Directory is writable: $dir"
    return 0
}
