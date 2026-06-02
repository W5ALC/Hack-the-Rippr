#!/usr/bin/env bash
# installer/upgrade.sh — Upgrade existing installation

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"
INSTALLER_LOG="/var/log/hac-da-rippr-install.log"

source "$SCRIPT_DIR/lib.sh"

main() {
    exec > >(tee -a "$INSTALLER_LOG")
    exec 2>&1
    
    log_info "========================================"
    log_info "hac-da-rippr Upgrade"
    log_info "========================================"
    
    require_root
    
    if ! detect_existing_install; then
        log_error "No existing installation found. Run 'install.sh' instead."
        exit 1
    fi
    
    log_info "Existing installation detected"
    
    # Backup current config
    log_info "Backing up current configuration..."
    backup_config /etc/auto_handbrake.conf
    
    # Stop service
    log_info "Stopping hac-da-rippr service..."
    systemctl stop hac-da-rippr || log_warn "Service may not have been running"
    log_success "Service stopped"
    
    # Replace executable
    log_info "Upgrading executable..."
    install -m755 "$PROJECT_ROOT/hac-da-rippr" /usr/local/bin/hac-da-rippr || exit 1
    log_success "Executable upgraded"
    
    # Update service file
    log_info "Updating service file..."
    install -m644 "$PROJECT_ROOT/systemd/hac-da-rippr.service" /etc/systemd/system/ || exit 1
    
    # Reload systemd
    log_info "Reloading systemd daemon..."
    systemctl daemon-reload || exit 1
    
    # Restart service
    log_info "Restarting service..."
    systemctl start hac-da-rippr || exit 1
    log_success "Service restarted"
    
    # Verify
    sleep 2
    if systemctl is-active --quiet hac-da-rippr; then
        log_success "Service is running after upgrade"
    else
        log_error "Service failed to start after upgrade"
        exit 1
    fi
    
    log_info "========================================"
    log_success "Upgrade complete!"
    log_info "========================================"
}

main "$@"
