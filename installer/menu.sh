#!/usr/bin/env bash
# installer/menu.sh — Interactive setup menu

set -euo pipefail

INSTALLER_LOG="/var/log/hac-da-rippr-install.log"

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/lib.sh"

show_main_menu() {
    if command_exists whiptail; then
        whiptail --menu "hac-da-rippr Setup Utility" 15 50 7 \
            1 "Install" \
            2 "Upgrade" \
            3 "Reconfigure" \
            4 "Health Check" \
            5 "Uninstall" \
            6 "View Logs" \
            7 "Exit" \
            3>&1 1>&2 2>&3
    else
        cat <<EOF
========================================
hac-da-rippr Setup Utility
========================================
1. Install
2. Upgrade
3. Reconfigure
4. Health Check
5. Uninstall
6. View Logs
7. Exit
========================================
Enter choice: 
EOF
        read -r choice
        echo "$choice"
    fi
}

main() {
    require_root
    
    while true; do
        choice=$(show_main_menu) || exit 0
        
        case $choice in
            1)
                "$SCRIPT_DIR/install.sh"
                ;;
            2)
                "$SCRIPT_DIR/upgrade.sh"
                ;;
            3)
                "$SCRIPT_DIR/reconfigure.sh"
                ;;
            4)
                "$SCRIPT_DIR/healthcheck.sh"
                ;;
            5)
                "$SCRIPT_DIR/uninstall.sh"
                ;;
            6)
                if command_exists less; then
                    less "$INSTALLER_LOG"
                else
                    tail -n 50 "$INSTALLER_LOG"
                fi
                ;;
            7)
                log_info "Exiting"
                exit 0
                ;;
            *)
                log_error "Invalid choice"
                ;;
        esac
    done
}

main "$@"
