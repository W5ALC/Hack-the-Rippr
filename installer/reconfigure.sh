#!/usr/bin/env bash
# installer/reconfigure.sh — Reconfigure existing installation

set -euo pipefail

INSTALLER_LOG="/var/log/hac-da-rippr-install.log"

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/lib.sh"

main() {
    exec > >(tee -a "$INSTALLER_LOG")
    exec 2>&1
    
    log_info "========================================"
    log_info "hac-da-rippr Reconfiguration"
    log_info "========================================"
    
    require_root
    
    if ! detect_existing_install; then
        log_error "No installation found"
        exit 1
    fi
    
    CONFIG_FILE="/etc/auto_handbrake.conf"
    TEMP_CONFIG="${CONFIG_FILE}.tmp"
    
    # Load current config
    if [[ -f "$CONFIG_FILE" ]]; then
        source "$CONFIG_FILE"
    fi
    
    log_info "Current configuration loaded"
    
    # Re-detect drives
    log_info "Re-detecting optical drives..."
    if detect_optical_drives; then
        select_optical_drive
    fi
    
    # Interactive prompts with whiptail if available
    if command_exists whiptail; then
        TARGETPATH=$(whiptail --inputbox "Target directory for ripped videos" 8 50 "${TARGETPATH:-/home/nowhereman/Videos}" 3>&1 1>&2 2>&3) || TARGETPATH="${TARGETPATH:-/home/nowhereman/Videos}"
        MINDURATION=$(whiptail --inputbox "Minimum title duration (seconds)" 8 50 "${MINDURATION:-3600}" 3>&1 1>&2 2>&3) || MINDURATION="${MINDURATION:-3600}"
        VIDEO_QUALITY=$(whiptail --inputbox "Video quality (CRF, 18=lossless, 23=default)" 8 50 "${VIDEO_QUALITY:-18}" 3>&1 1>&2 2>&3) || VIDEO_QUALITY="${VIDEO_QUALITY:-18}"
    fi
    
    # Test directory
    if ! test_directory_writable "$TARGETPATH"; then
        log_error "Target directory is not writable"
        exit 1
    fi
    
    # Backup current config
    backup_config "$CONFIG_FILE"
    
    # Write new config
    log_info "Writing new configuration..."
    cat > "$CONFIG_FILE" <<EOF
# hac-da-rippr Configuration
# Updated: $(date)

DVD_DEVICE="${DVD_DEVICE:-/dev/sr0}"
TARGETPATH="${TARGETPATH:-/home/nowhereman/Videos}"
MINDURATION="${MINDURATION:-3600}"
VIDEO_QUALITY="${VIDEO_QUALITY:-18}"
VIDEO_ENCODER="${VIDEO_ENCODER:-x264}"
ENCODER_PRESET="${ENCODER_PRESET:-slow}"
AUDIO_ENCODER="${AUDIO_ENCODER:-copy:ac3,aac}"
DEFAULT_AUDIO="${DEFAULT_AUDIO:-eng}"
POLL_INTERVAL=${POLL_INTERVAL:-30}
MAX_RETRIES=${MAX_RETRIES:-3}
EOF
    log_success "Configuration updated"
    
    # Restart service
    log_info "Restarting service..."
    systemctl restart hac-da-rippr || exit 1
    log_success "Service restarted"
    
    log_info "========================================"
    log_success "Reconfiguration complete!"
    log_info "========================================"
}

main "$@"
