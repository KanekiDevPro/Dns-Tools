#!/bin/bash

# DNS Setup & Test Tool
# Version: 1.4.0
# Description: A professional tool for configuring, testing, and restoring DNS settings with automated line ending fix
# Added: distro-aware package manager, non-interactive mode, improved error handling

# Colors for terminal output
RED="\e[31m"
GREEN="\e[32m"
YELLOW="\e[33m"
BLUE="\e[34m"
CYAN="\e[36m"
RESET="\e[0m"

# Configuration
CONFIG_FILE="/etc/dns-tool.conf"
LOG_FILE="/var/log/dns-tool.log"
VERSION="1.4.0"
TELEGRAM_CHANNEL="@YourChannelName"

# Default DNS Settings
PRIMARY_DNS="1.1.1.1"
SECONDARY_DNS="8.8.8.8"
FALLBACK_DNS="9.9.9.9"

# Flags
NON_INTERACTIVE=0

print_usage() {
    echo -e "${CYAN}Usage: $0 [-y] [primary_dns secondary_dns fallback_dns]${RESET}"
    echo -e "  -y  : Non-interactive mode, use default or provided DNS without prompts"
    echo -e "  If DNS IPs are provided as arguments, they override defaults"
    exit 1
}

log_message() {
    local level="$1"
    local message="$2"
    local timestamp
    timestamp=$(date '+%Y-%m-%d %H:%M:%S')
    echo "[$timestamp] [$level] $message" >> "$LOG_FILE"
    case $level in
        INFO) echo -e "${GREEN}[INFO] $message${RESET}" ;;
        ERROR) echo -e "${RED}[ERROR] $message${RESET}" >&2 ;;
        WARNING) echo -e "${YELLOW}[WARNING] $message${RESET}" ;;
    esac
}

check_root() {
    if [[ $EUID -ne 0 ]]; then
        log_message "ERROR" "This script must be run as root"
        echo -e "${RED}This script must be run as root. Please use sudo.${RESET}"
        exit 1
    fi
}

init_logging() {
    touch "$LOG_FILE" 2>/dev/null || {
        LOG_FILE="/tmp/dns-tool.log"
        log_message "WARNING" "Unable to write to /var/log, using /tmp/dns-tool.log"
    }
}

detect_package_manager() {
    if command -v apt &>/dev/null; then
        PKG_MGR="apt"
    elif command -v dnf &>/dev/null; then
        PKG_MGR="dnf"
    else
        log_message "ERROR" "No supported package manager found (apt or dnf)"
        echo -e "${RED}Error: No supported package manager found (apt or dnf).${RESET}"
        exit 1
    fi
}

install_package() {
    local pkg="$1"
    if [[ "$PKG_MGR" == "apt" ]]; then
        apt install -y "$pkg" &>/dev/null
    else
        dnf install -y "$pkg" &>/dev/null
    fi
    if [[ $? -ne 0 ]]; then
        log_message "ERROR" "Failed to install package: $pkg"
        echo -e "${RED}Error installing package: $pkg${RESET}"
    else
        log_message "INFO" "Installed package: $pkg"
    fi
}

install_dependencies() {
    echo -e "${CYAN}[INFO] Checking and installing required dependencies...${RESET}"
    REQUIRED_CMDS=("ping" "sed" "systemctl" "file" "grep" "cp" "rm" "touch")
    OPTIONAL_CMDS=("dos2unix")

    # Update repos once
    if [[ "$PKG_MGR" == "apt" ]]; then
        apt update -y &>/dev/null
    else
        dnf makecache &>/dev/null
    fi

    for cmd in "${REQUIRED_CMDS[@]}"; do
        if ! command -v "$cmd" &>/dev/null; then
            echo -e "${YELLOW}[WARNING] '$cmd' not found. Installing...${RESET}"
            install_package "$cmd"
        fi
    done

    for cmd in "${OPTIONAL_CMDS[@]}"; do
        if ! command -v "$cmd" &>/dev/null; then
            echo -e "${YELLOW}[INFO] Optional tool '$cmd' not found. Installing...${RESET}"
            install_package "$cmd"
        fi
    done

    echo -e "${GREEN}[INFO] Dependency installation complete.${RESET}"
}

fix_line_endings() {
    local script_file="$0"
    if file "$script_file" | grep -q "CRLF"; then
        sed -i 's/\r$//' "$script_file" || {
            echo -e "${RED}[ERROR] Failed to fix line endings. Run 'dos2unix $script_file' manually.${RESET}" >&2
            exit 1
        }
        echo -e "${GREEN}[INFO] Fixed Windows-style line endings.${RESET}"
        exec bash "$script_file"
    fi
}

check_prerequisites() {
    log_message "INFO" "Checking prerequisites"

    if ! command -v systemctl &>/dev/null || ! systemctl --version &>/dev/null; then
        log_message "ERROR" "systemctl not found. Please ensure systemd is installed."
        echo -e "${RED}systemctl not found. Please ensure systemd is installed.${RESET}"
        exit 1
    fi

    if ! ping -c 1 8.8.8.8 &>/dev/null; then
        log_message "WARNING" "No internet connectivity detected."
        echo -e "${YELLOW}[WARNING] No internet connectivity detected.${RESET}"
    fi
}

prompt_custom_dns() {
    if [[ $NON_INTERACTIVE -eq 1 ]]; then
        return
    fi

    echo -e "${CYAN}Enter custom DNS servers (leave blank to use defaults: $PRIMARY_DNS, $SECONDARY_DNS, $FALLBACK_DNS):${RESET}"
    read -rp "Primary DNS [default: $PRIMARY_DNS]: " input_primary
    read -rp "Secondary DNS [default: $SECONDARY_DNS]: " input_secondary
    read -rp "Fallback DNS [default: $FALLBACK_DNS]: " input_fallback

    PRIMARY_DNS=${input_primary:-$PRIMARY_DNS}
    SECONDARY_DNS=${input_secondary:-$SECONDARY_DNS}
    FALLBACK_DNS=${input_fallback:-$FALLBACK_DNS}

    log_message "INFO" "Using DNS servers: Primary=$PRIMARY_DNS, Secondary=$SECONDARY_DNS, Fallback=$FALLBACK_DNS"
}

setup_dns() {
    log_message "INFO" "Starting DNS configuration"
    prompt_custom_dns

    if [[ "$PKG_MGR" == "apt" ]]; then
        apt update -y &>/dev/null
        apt install -y systemd-resolved &>/dev/null
    else
        dnf install -y systemd-resolved &>/dev/null
    fi

    systemctl enable systemd-resolved &>/dev/null
    systemctl restart systemd-resolved &>/dev/null

    if [[ ! -f /etc/resolv.conf.backup ]]; then
        cp -f /etc/resolv.conf /etc/resolv.conf.backup
    fi

    ln -sf /run/systemd/resolve/resolv.conf /etc/resolv.conf

    local RESOLVED_CONF="/etc/systemd/resolved.conf"
    if grep -q "\[Resolve\]" "$RESOLVED_CONF"; then
        sed -i "/^\[Resolve\]/,/^\[.*\]/ s/^DNS=.*/DNS=$PRIMARY_DNS $SECONDARY_DNS/" "$RESOLVED_CONF"
        sed -i "/^\[Resolve\]/,/^\[.*\]/ s/^FallbackDNS=.*/FallbackDNS=$FALLBACK_DNS/" "$RESOLVED_CONF"
    else
        echo -e "\n[Resolve]\nDNS=$PRIMARY_DNS $SECONDARY_DNS\nFallbackDNS=$FALLBACK_DNS" >> "$RESOLVED_CONF"
    fi

    sed -i 's/#DNSStubListener=.*/DNSStubListener=yes/' "$RESOLVED_CONF"
    systemctl restart systemd-resolved &>/dev/null

    log_message "INFO" "DNS configuration completed successfully"
    echo -e "${GREEN}✅ DNS configuration completed successfully${RESET}"
}

restore_dns() {
    log_message "INFO" "Restoring DNS configuration"

    if [[ -f /etc/resolv.conf.backup ]]; then
        cp -f /etc/resolv.conf.backup /etc/resolv.conf
        systemctl restart systemd-resolved &>/dev/null
        log_message "INFO" "DNS configuration restored successfully"
        echo -e "${GREEN}✅ DNS configuration restored successfully${RESET}"
    else
        log_message "ERROR" "No backup file found"
        echo -e "${RED}Error: No backup file found. Please run setup first to create a backup.${RESET}"
    fi
}

test_dns() {
    log_message "INFO" "Starting DNS connectivity test"

    echo -e "${CYAN}📡 Testing DNS connectivity:${RESET}"

    for dns in "$PRIMARY_DNS" "$SECONDARY_DNS"; do
        echo -e "\n${BLUE}Testing $dns:${RESET}"
        if ping -c 3 "$dns" &>/dev/null; then
            log_message "INFO" "Successfully pinged $dns"
            echo -e "${GREEN}✓ Connection to $dns successful${RESET}"
        else
            log_message "ERROR" "Failed to ping $dns"
            echo -e "${RED}✗ Connection to $dns failed${RESET}"
        fi
    done

    echo -e "\n${CYAN}📄 resolv.conf status:${RESET}"
    if [[ -f /etc/resolv.conf ]]; then
        cat /etc/resolv.conf
        log_message "INFO" "Displayed resolv.conf"
    else
        log_message "ERROR" "resolv.conf not found"
        echo -e "${RED}Error: resolv.conf not found${RESET}"
    fi
}

menu() {
    clear
    echo -e "${YELLOW}+------------------------------------------------------------+${RESET}"
    echo -e "${YELLOW}|${RESET}    ${CYAN}🛡️  DNS Setup & Test Tool${RESET}                                 ${YELLOW}|${RESET}"
    echo -e "${YELLOW}|${RESET}    Telegram Channel: ${GREEN}$TELEGRAM_CHANNEL${RESET}                        ${YELLOW}|${RESET}"
    echo -e "${YELLOW}|${RESET}    Version: ${GREEN}$VERSION${RESET}                                           ${YELLOW}|${RESET}"
    echo -e "${YELLOW}+------------------------------------------------------------+${RESET}"
    echo -e "${YELLOW}|${RESET} ${GREEN}Please select an option:${RESET}                               ${YELLOW}|${RESET}"
    echo -e "${YELLOW}+------------------------------------------------------------+${RESET}"
    echo -e "${YELLOW}| 1) Setup and optimize system DNS                           |${RESET}"
    echo -e "${YELLOW}| 2) Test DNS and network status                             |${RESET}"
    echo -e "${YELLOW}| 3) Both (Setup + Test)                                     |${RESET}"
    echo -e "${YELLOW"| 4) Restore DNS from backup                                 |${RESET}"
    echo -e "${YELLOW}| 5) Exit                                                    |${RESET}"
    echo -e "${YELLOW}+------------------------------------------------------------+${RESET}"
    echo -ne "${YELLOW}| Enter option number: ${RESET}"
}

# Parse command line args
while getopts "hy" opt; do
    case $opt in
        h) print_usage ;;
        y) NON_INTERACTIVE=1 ;;
        *) print_usage ;;
    esac
done

shift $((OPTIND -1))

# If positional args given for DNS IPs, override defaults
if [[ $# -ge 1 ]]; then PRIMARY_DNS="$1"; fi
if [[ $# -ge 2 ]]; then SECONDARY_DNS="$2"; fi
if [[ $# -ge 3 ]]; then FALLBACK_DNS="$3"; fi

main() {
    check_root
    init_logging
    detect_package_manager
    install_dependencies
    fix_line_endings
    check_prerequisites
    log_message "INFO" "DNS Tool started"

    while true; do
        if [[ $NON_INTERACTIVE -eq 1 ]]; then
            setup_dns
            test_dns
            exit 0
        else
            menu
            read -r choice

            if [[ ! $choice =~ ^[1-5]$ ]]; then
                log_message "ERROR" "Invalid input: $choice"
                echo -e "${RED}Invalid option! Enter number 1-5.${RESET}"
                read -rp "Press Enter to continue..."
                continue
            fi

            case $choice in
                1) setup_dns ;;
                2) test_dns ;;
                3) setup_dns && test_dns ;;
                4) restore_dns ;;
                5) log_message "INFO" "Exiting DNS Tool"; echo -e "${RED}Exiting...${RESET}"; exit 0 ;;
            esac

            echo -e "\n${YELLOW}Press Enter to return to menu or Ctrl+C to exit...${RESET}"
            read -r
        fi
    done
}

main "$@"
