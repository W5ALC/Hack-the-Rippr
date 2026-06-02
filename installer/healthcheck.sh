#!/usr/bin/env bash
# installer/healthcheck.sh — Verify installation health

set -euo pipefail

INSTALLER_LOG="/var/log/hac-da-rippr-install.log"

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/lib.sh"

main() {
    exec > >(tee -a "$INSTALLER_LOG")
    exec 2>&1
    
    log_info "========================================"
    log_info "hac-da-rippr Health Check"
    log_info "========================================"
    
    local checks_passed=0
    local checks_failed=0
    
    # Check HandBrakeCLI
    if command_exists HandBrakeCLI; then
        log_success "HandBrakeCLI installed"
        ((checks_passed++))
    else
        log_error "HandBrakeCLI not found"
        ((checks_failed++))
    fi
    
    # Check executable
    if [[ -x /usr/local/bin/hac-da-rippr ]]; then
        log_success "hac-da-rippr executable found"
        ((checks_passed++))
    else
        log_error "hac-da-rippr executable not found"
        ((checks_failed++))
    fi
    
    # Check service file
    if [[ -f /etc/systemd/system/hac-da-rippr.service ]]; then
        log_success "Service file present"
        ((checks_passed++))
    else
        log_error "Service file not found"
        ((checks_failed++))
    fi
    
    # Check config
    if [[ -f /etc/auto_handbrake.conf ]]; then
        log_success "Configuration file found"
        ((checks_passed++))
    else
        log_warn "Configuration file not found (may be first install)"
    fi
    
    # Check service enabled
    if systemctl is-enabled hac-da-rippr >/dev/null 2>&1; then
        log_success "Service is enabled"
        ((checks_passed++))
    else
        log_warn "Service is not enabled"
    fi
    
    # Check service active
    if systemctl is-active --quiet hac-da-rippr; then
        log_success "Service is running"
        ((checks_passed++))
    else
        log_warn "Service is not running"
    fi
    
    # Check optical drives
    if detect_optical_drives; then
        ((checks_passed++))
    else
        log_warn "No optical drives detected"
    fi
    
    # Check target directory
    if [[ -f /etc/auto_handbrake.conf ]]; then
        source /etc/auto_handbrake.conf
        if test_directory_writable "${TARGETPATH:-/home/nowhereman/Videos}"; then
            ((checks_passed++))
        else
            ((checks_failed++))
        fi
    fi
    
    log_info "========================================"
    log_info "Health check results:"
    log_success "Passed: $checks_passed"
    if [[ $checks_failed -gt 0 ]]; then
        log_error "Failed: $checks_failed"
    fi
    log_info "========================================"
    
    if [[ $checks_failed -eq 0 ]]; then
        return 0
    else
        return 1
    fi
}

main "$@"
