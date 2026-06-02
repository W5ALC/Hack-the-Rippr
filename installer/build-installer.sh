#!/usr/bin/env bash
# installer/build-installer.sh — Create self-extracting installer

set -euo pipefail

PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../" && pwd)"
DIST_DIR="${PROJECT_ROOT}/dist"
INSTALLER_NAME="hac-da-rippr-installer.run"

log_info() {
    echo "[INFO] $1"
}

log_success() {
    echo "[SUCCESS] $1"
}

log_error() {
    echo "[ERROR] $1" >&2
}

main() {
    log_info "Building self-extracting installer"
    
    # Create dist directory
    mkdir -p "$DIST_DIR"
    
    # Create temporary directory for payload
    local tmpdir
    tmpdir=$(mktemp -d)
    trap "rm -rf '$tmpdir'" EXIT
    
    log_info "Staging files..."
    
    # Copy all necessary files
    cp -r "$PROJECT_ROOT/installer" "$tmpdir/"
    cp -r "$PROJECT_ROOT/systemd" "$tmpdir/"
    cp -r "$PROJECT_ROOT/config" "$tmpdir/"
    cp "$PROJECT_ROOT/hac-da-rippr" "$tmpdir/"
    cp "$PROJECT_ROOT/README.md" "$tmpdir/"
    
    # Create tar archive
    local tar_file="${tmpdir}/payload.tar.gz"
    log_info "Creating archive..."
    (cd "$tmpdir" && tar --exclude=payload.tar.gz -czf payload.tar.gz --owner=0 --group=0 .)
    
    # Get archive size
    local archive_size
    archive_size=$(stat -f%z "$tar_file" 2>/dev/null || stat -c%s "$tar_file")
    
    # Create self-extracting script
    log_info "Creating self-extracting script..."
    cat > "${DIST_DIR}/${INSTALLER_NAME}" <<'STARTER'
#!/usr/bin/env bash
set -euo pipefail

echo "hac-da-rippr Installer"
echo "======================"

if [[ $EUID -ne 0 ]]; then
    echo "Error: This script must be run as root"
    exit 1
fi

TMPDIR=$(mktemp -d)
trap "rm -rf '$TMPDIR'" EXIT

echo "Extracting installer..."

if ! command -v tar >/dev/null; then
    echo "Error: tar not found"
    exit 1
fi

# Extract the archive from the end of this script
ARCHIVE_START=$(($(grep -a -b -o 'PAYLOAD_MARKER' "$0" | cut -d: -f1 | tail -1) + 15))

tail -c +$ARCHIVE_START "$0" | tar -xzf - -C "$TMPDIR"

cd "$TMPDIR"

# Run the appropriate installer script
if [[ -x "$TMPDIR/installer/menu.sh" ]]; then
    exec "$TMPDIR/installer/menu.sh"
else
    echo "Error: installer menu not found"
    exit 1
fi

PAYLOAD_MARKER
STARTER
    
    # Make script executable
    chmod +x "${DIST_DIR}/${INSTALLER_NAME}"
    
    # Append the archive
    log_info "Appending payload..."
    cat "$tar_file" >> "${DIST_DIR}/${INSTALLER_NAME}"
    
    local final_size
    final_size=$(stat -f%z "${DIST_DIR}/${INSTALLER_NAME}" 2>/dev/null || stat -c%s "${DIST_DIR}/${INSTALLER_NAME}")
    
    log_success "Installer created: ${DIST_DIR}/${INSTALLER_NAME}"
    log_info "Archive size: $(numfmt --to=iec $((archive_size)) 2>/dev/null || echo "${archive_size} bytes")"
    log_info "Final size: $(numfmt --to=iec $((final_size)) 2>/dev/null || echo "${final_size} bytes")"
    log_info ""
    log_info "Usage:"
    log_info "  chmod +x ${INSTALLER_NAME}"
    log_info "  sudo ./${INSTALLER_NAME}"
}

main "$@"
