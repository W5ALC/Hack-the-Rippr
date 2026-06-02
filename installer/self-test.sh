#!/usr/bin/env bash
# installer/self-test.sh — Self-test mode for hac-da-rippr

set -euo pipefail

INSTALLER_LOG="/var/log/hac-da-rippr-install.log"

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/lib.sh"

main() {
    exec > >(tee -a "$INSTALLER_LOG")
    exec 2>&1
    
    log_info "========================================"
    log_info "hac-da-rippr Self-Test"
    log_info "========================================"
    
    local tests_passed=0
    local tests_failed=0
    
    # Test 1: HandBrakeCLI
    log_info "Test 1: HandBrakeCLI availability"
    if command_exists HandBrakeCLI; then
        local hb_version
        hb_version=$(HandBrakeCLI --version 2>&1 | head -1)
        log_success "HandBrakeCLI found: $hb_version"
        ((tests_passed++))
    else
        log_error "HandBrakeCLI not found"
        ((tests_failed++))
    fi
    
    # Test 2: Optical drives
    log_info "Test 2: Optical drive detection"
    if detect_optical_drives; then
        for drive in "${DRIVES[@]}"; do
            log_success "Optical drive: $drive"
        done
        ((tests_passed++))
    else
        log_warn "No optical drives detected"
    fi
    
    # Test 3: Permissions
    log_info "Test 3: Required permissions"
    if [[ $EUID -eq 0 ]]; then
        log_success "Running with root privileges"
        ((tests_passed++))
    else
        log_warn "Not running as root (may limit functionality)"
    fi
    
    # Test 4: Disk space
    log_info "Test 4: Available disk space"
    local target_dir="${TARGETPATH:-/home/nowhereman/Videos}"
    if [[ -d "$target_dir" ]]; then
        local avail_space
        avail_space=$(df "$target_dir" | awk 'NR==2 {print $4}')
        log_success "Available space in $target_dir: $(numfmt --to=iec $((avail_space*1024)) 2>/dev/null || echo "${avail_space}KB")"
        ((tests_passed++))
    else
        log_warn "Target directory does not exist: $target_dir"
    fi
    
    # Test 5: Config syntax
    log_info "Test 5: Configuration syntax"
    if [[ -f /etc/auto_handbrake.conf ]]; then
        if bash -n /etc/auto_handbrake.conf 2>/dev/null; then
            log_success "Configuration file syntax valid"
            ((tests_passed++))
        else
            log_error "Configuration file has syntax errors"
            ((tests_failed++))
        fi
    else
        log_warn "No configuration file found"
    fi
    
    # Test 6: Systemd status
    log_info "Test 6: Systemd service status"
    if detect_existing_install; then
        local service_status
        service_status=$(systemctl is-active hac-da-rippr 2>/dev/null || echo "inactive")
        if [[ "$service_status" == "active" ]]; then
            log_success "Service is running"
            ((tests_passed++))
        else
            log_warn "Service is not running (status: $service_status)"
        fi
    else
        log_warn "Service not installed"
    fi
    
    # Test 7: DVD device access
    log_info "Test 7: DVD device accessibility"
    if detect_optical_drives; then
        if test_drive_access; then
            ((tests_passed++))
        else
            log_warn "DVD device not currently accessible"
        fi
    fi
    
    log_info "========================================"
    log_success "Passed: $tests_passed"
    if [[ $tests_failed -gt 0 ]]; then
        log_error "Failed: $tests_failed"
        log_info "========================================"
        exit 1
    fi
    log_info "========================================"
    log_success "All self-tests passed!"
    exit 0
}

main "$@"
