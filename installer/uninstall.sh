#!/usr/bin/env bash
# installer/uninstall.sh — Remove installation

set -euo pipefail

INSTALLER_LOG="/var/log/hac-da-rippr-install.log"

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/lib.sh"

main() {
    exec > >(tee -a "$INSTALLER_LOG")
    exec 2>&1
    
    log_info "========================================"
    log_info "hac-da-rippr Uninstall"
    log_info "========================================"
    
    require_root
    
    if ! detect_existing_install; then
        log_error "No installation found"
        exit 1
    fi
    
    # Prompt for preservation options
    log_info "Uninstall options:"
    
    KEEP_CONFIG=0
    KEEP_VIDEOS=0
    KEEP_LOGS=0
    
    if command_exists whiptail; then
        if whiptail --yesno "Keep configuration file?" 8 50; then
            KEEP_CONFIG=1
        fi
        if whiptail --yesno "Keep ripped videos?" 8 50; then
            KEEP_VIDEOS=1
        fi
        if whiptail --yesno "Keep log files?" 8 50; then
            KEEP_LOGS=1
        fi
    fi
    
    # Stop service
    log_info "Stopping service..."
    systemctl stop hac-da-rippr 2>/dev/null || true
    systemctl disable hac-da-rippr 2>/dev/null || true
    log_success "Service stopped and disabled"
    
    # Remove executable
    log_info "Removing executable..."
    rm -f /usr/local/bin/hac-da-rippr
    log_success "Executable removed"
    
    # Remove service file
    log_info "Removing service file..."
    rm -f /etc/systemd/system/hac-da-rippr.service
    systemctl daemon-reload
    log_success "Service file removed"
    
    # Handle config
    if [[ $KEEP_CONFIG -eq 0 ]]; then
        log_info "Removing configuration..."
        rm -f /etc/auto_handbrake.conf
        log_success "Configuration removed"
    else
        log_info "Keeping configuration: /etc/auto_handbrake.conf"
    fi
    
    # Handle logs
    if [[ $KEEP_LOGS -eq 0 ]]; then
        log_info "Removing logs..."
        rm -f /var/log/hac-da-rippr*.log*
        log_success "Logs removed"
    else
        log_info "Keeping logs"
    fi
    
    log_info "========================================"
    log_success "Uninstall complete!"
    log_info "========================================"
}

main "$@"
