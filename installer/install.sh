#!/usr/bin/env bash
# installer/install.sh — Main installation script

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"
INSTALLER_LOG="/var/log/hac-da-rippr-install.log"

# Source common functions
source "$SCRIPT_DIR/lib.sh"

main() {
    exec > >(tee -a "$INSTALLER_LOG")
    exec 2>&1
    
    log_info "========================================"
    log_info "hac-da-rippr Installation"
    log_info "========================================"
    
    require_root
    
    # Detect distro
    log_info "Detecting Linux distribution..."
    DISTRO=$(detect_distro) || exit 1
    log_success "Distribution: $DISTRO"
    
    # Check internet
    log_info "Checking internet connectivity..."
    check_internet || log_warn "Continuing without internet (may fail at package installation)"
    
    # Detect optical drives
    log_info "Detecting optical drives..."
    if detect_optical_drives; then
        select_optical_drive
    else
        log_warn "No optical drives detected; will use default /dev/sr0"
        DVD_DEVICE="/dev/sr0"
    fi
    
    # Install dependencies
    log_info "Installing dependencies..."
    apt-get update || exit 1
    apt-get install -y \
        handbrake-cli \
        genisoimage \
        eject \
        libnotify-bin \
        util-linux \
        coreutils \
        gawk \
        whiptail \
        libdvd-pkg \
        || exit 1
    log_success "Dependencies installed"
    
    # Install HandBrake executable
    log_info "Installing hac-da-rippr executable..."
    install -m755 "$PROJECT_ROOT/hac-da-rippr" /usr/local/bin/hac-da-rippr || exit 1
    log_success "Executable installed to /usr/local/bin/hac-da-rippr"
    
    # Install systemd service
    log_info "Installing systemd service..."
    install -m644 "$PROJECT_ROOT/systemd/hac-da-rippr.service" /etc/systemd/system/ || exit 1
    log_success "Service file installed"
    
    # Generate config
    log_info "Generating configuration..."
    if [[ ! -f /etc/auto_handbrake.conf ]]; then
        cat > /etc/auto_handbrake.conf <<EOF
# hac-da-rippr Configuration
# Generated: $(date)

DVD_DEVICE="${DVD_DEVICE:-/dev/sr0}"
TARGETPATH="/home/nowhereman/Videos"
MINDURATION="3600"
VIDEO_QUALITY="18"
VIDEO_ENCODER="x264"
ENCODER_PRESET="slow"
AUDIO_ENCODER="copy:ac3,aac"
DEFAULT_AUDIO="eng"
POLL_INTERVAL=30
MAX_RETRIES=3
EOF
        log_success "Configuration created: /etc/auto_handbrake.conf"
    else
        log_warn "Configuration already exists, skipping"
    fi
    
    # Verify HandBrakeCLI
    log_info "Verifying HandBrakeCLI installation..."
    if HandBrakeCLI --version >/dev/null 2>&1; then
        log_success "HandBrakeCLI verified"
    else
        log_error "HandBrakeCLI not found or not working"
        exit 1
    fi
    
    # Test DVD device access
    log_info "Testing DVD device access..."
    if test_drive_access; then
        log_success "DVD device is accessible"
    else
        log_warn "DVD device not currently accessible (may be normal)"
    fi
    
    # Reload systemd
    log_info "Reloading systemd daemon..."
    systemctl daemon-reload || exit 1
    
    # Enable service
    log_info "Enabling hac-da-rippr service..."
    systemctl enable hac-da-rippr || exit 1
    log_success "Service enabled"
    
    # Start service
    log_info "Starting hac-da-rippr service..."
    systemctl start hac-da-rippr || exit 1
    log_success "Service started"
    
    # Final verification
    log_info "Verifying service health..."
    sleep 2
    if systemctl is-active --quiet hac-da-rippr; then
        log_success "Service is running"
    else
        log_warn "Service may not have started successfully"
    fi
    
    log_info "========================================"
    log_success "Installation complete!"
    log_info "========================================"
    log_info "Configuration: /etc/auto_handbrake.conf"
    log_info "Log file: /var/log/hac-da-rippr-install.log"
    log_info "Service status: systemctl status hac-da-rippr"
    log_info "Service logs: journalctl -u hac-da-rippr -f"
}

main "$@"
