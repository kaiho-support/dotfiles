#!/bin/bash

# Ubuntu Development Environment Setup - Interactive Installer
# Using whiptail for interactive selection and Ansible for installation

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Temporary files tracking
TEMP_FILES=()

# Cleanup function
cleanup() {
    local exit_code=$?
    if [[ ${#TEMP_FILES[@]} -gt 0 ]]; then
        print_status "Cleaning up temporary files..."
        for temp_file in "${TEMP_FILES[@]}"; do
            if [[ -f "$temp_file" ]]; then
                rm -f "$temp_file"
            fi
        done
    fi
    exit $exit_code
}

# Set signal handlers
trap cleanup EXIT
trap 'cleanup; exit 130' INT  # Ctrl+C
trap 'cleanup; exit 143' TERM # Termination signal

# Function to print colored output
print_status() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

print_title() {
    echo -e "\n${BLUE}=== $1 ===${NC}\n"
}

# Common package management functions
update_package_cache() {
    local force_update=${1:-false}
    if [[ "$force_update" == "true" ]] || [[ ! -f /var/cache/apt/pkgcache.bin ]] || [[ $(($(date +%s) - $(stat -c %Y /var/cache/apt/pkgcache.bin))) -gt 3600 ]]; then
        print_status "Updating package cache..."
        if ! sudo apt-get update; then
            print_error "Failed to update package cache"
            exit 1
        fi
    fi
}

install_packages() {
    local packages=("$@")
    if [[ ${#packages[@]} -gt 0 ]]; then
        update_package_cache
        print_status "Installing packages: ${packages[*]}"
        if ! sudo apt-get install -y "${packages[@]}"; then
            print_error "Failed to install packages: ${packages[*]}"
            exit 1
        fi
    fi
}

# Check prerequisites
check_prerequisites() {
    local missing_deps=()
    
    # Check for sudo
    if ! command -v sudo &> /dev/null; then
        print_error "sudo is required but not installed"
        exit 1
    fi
    
    # Check for curl
    if ! command -v curl &> /dev/null; then
        missing_deps+=("curl")
    fi
    
    # Check for git
    if ! command -v git &> /dev/null; then
        missing_deps+=("git")
    fi
    
    # Install missing dependencies
    if [ ${#missing_deps[@]} -gt 0 ]; then
        install_packages "${missing_deps[@]}"
    fi
}

# Check if whiptail is installed
check_whiptail() {
    if ! command -v whiptail &> /dev/null; then
        install_packages whiptail
    fi
}

# Check if ansible is installed
check_ansible() {
    if ! command -v ansible-playbook &> /dev/null; then
        print_status "Installing Ansible..."
        install_packages software-properties-common
        
        if ! sudo add-apt-repository --yes --update ppa:ansible/ansible; then
            print_error "Failed to add Ansible repository"
            exit 1
        fi
        
        install_packages ansible
    fi
}

# Main menu for selecting components
show_main_menu() {
    # Check for non-interactive mode
    if [ "$NON_INTERACTIVE" = "true" ]; then
        echo '"homebrew" "dev-basic" "dev-docker" "tools-cli" "tools-git" "dotfiles"'
        return 0
    fi
    
    local choices
    choices=$(whiptail --title "Ubuntu Development Environment Setup" \
        --checklist "Select components to install:" 20 80 10 \
        "homebrew" "Homebrew package manager" ON \
        "dev-basic" "Basic development tools (git, curl, etc.)" ON \
        "dev-docker" "Docker and Docker Compose" ON \
        "tools-cli" "Modern CLI tools (lsd, bat, fzf, etc.)" ON \
        "tools-git" "Git tools (lazygit, gh, delta)" ON \
        "dotfiles" "Dotfiles management with stow" ON \
        3>&1 1>&2 2>&3)
    
    if [ $? -eq 0 ]; then
        echo $choices
    else
        echo "CANCELLED"
    fi
}

# CLI tools selection menu
show_cli_tools_menu() {
    # Check for non-interactive mode
    if [ "$NON_INTERACTIVE" = "true" ]; then
        echo '"lsd" "bat" "fzf" "ripgrep" "eza" "fd"'
        return 0
    fi
    
    local choices
    choices=$(whiptail --title "CLI Tools Selection" \
        --checklist "Select CLI tools to install:" 20 80 10 \
        "lsd" "Modern ls replacement with colors and icons" ON \
        "bat" "Cat clone with syntax highlighting" ON \
        "fzf" "Command-line fuzzy finder" ON \
        "ripgrep" "Fast text search tool" ON \
        "eza" "Modern, maintained replacement for ls" ON \
        "fd" "Simple, fast find alternative" ON \
        "git-delta" "Better diff tool" OFF \
        "lazygit" "Simple terminal UI for git commands" OFF \
        "gh" "GitHub CLI tool" OFF \
        3>&1 1>&2 2>&3)
    
    if [ $? -eq 0 ]; then
        echo $choices
    else
        echo "CANCELLED"
    fi
}

# Generate ansible tags based on selections
generate_ansible_tags() {
    local selections="$1"
    local cli_tools="$2"
    local tags=""
    
    # Process main selections
    if [[ $selections == *"homebrew"* ]]; then
        tags="${tags}homebrew,"
    fi
    
    if [[ $selections == *"dev-basic"* ]]; then
        tags="${tags}dev-basic,"
    fi
    
    if [[ $selections == *"dev-docker"* ]]; then
        tags="${tags}dev-docker,"
    fi
    
    if [[ $selections == *"tools-cli"* ]]; then
        tags="${tags}tools-cli,"
    fi
    
    if [[ $selections == *"tools-git"* ]]; then
        tags="${tags}tools-git,"
    fi
    
    if [[ $selections == *"dotfiles"* ]]; then
        tags="${tags}dotfiles,"
    fi
    
    # Remove trailing comma
    tags=${tags%,}
    echo $tags
}

# Create dynamic variables file for CLI tools
create_cli_tools_vars() {
    local cli_tools="$1"
    local vars_file="/tmp/selected_cli_tools.yml"
    
    # Track temporary file for cleanup
    TEMP_FILES+=("$vars_file")
    
    echo "---" > "$vars_file"
    echo "selected_cli_tools:" >> "$vars_file"
    
    # Parse selected tools with proper input validation
    cli_tools=$(echo "$cli_tools" | tr -d '"' | tr -cd '[:alnum:][:space:]-_.')
    IFS=' ' read -ra TOOLS <<< "$cli_tools"
    for tool in "${TOOLS[@]}"; do
        # Validate tool name contains only safe characters
        if [[ "$tool" =~ ^[a-zA-Z0-9_-]+$ ]]; then
            echo "  - $tool" >> "$vars_file"
        fi
    done
    
    echo $vars_file
}

# Run ansible playbook with selected tags
run_ansible() {
    local tags="$1"
    local vars_file="$2"
    
    print_status "Running Ansible playbook with tags: $tags"
    
    # Test mode - dry run only
    if [ "$TEST_MODE" = "true" ]; then
        print_status "TEST MODE: Running dry-run only"
        print_status "Note: Some sudo-required tasks may show failures - this is expected in test mode"
        if [ -n "$vars_file" ]; then
            ansible-playbook site.yml --tags "$tags" --extra-vars "@$vars_file" --check --diff
        else
            ansible-playbook site.yml --tags "$tags" --check --diff
        fi
        local exit_code=$?
        if [ $exit_code -ne 0 ]; then
            print_warning "Test mode completed with warnings/errors (expected due to sudo requirements)"
            return 0  # Don't fail the script in test mode
        fi
        return $exit_code
    fi
    
    # Normal mode with password prompt
    if [ -n "$vars_file" ]; then
        ansible-playbook site.yml --tags "$tags" --extra-vars "@$vars_file" --ask-become-pass
    else
        ansible-playbook site.yml --tags "$tags" --ask-become-pass
    fi
}

# Confirmation dialog
confirm_installation() {
    local selections="$1"
    local cli_tools="$2"
    
    # Check for non-interactive mode
    if [ "$NON_INTERACTIVE" = "true" ]; then
        print_status "Non-interactive mode: Auto-confirming installation"
        return 0
    fi
    
    local message="You have selected the following components:\n\n"
    message="${message}Main Components:\n"
    
    if [[ $selections == *"homebrew"* ]]; then
        message="${message}  ✓ Homebrew package manager\n"
    fi
    if [[ $selections == *"dev-basic"* ]]; then
        message="${message}  ✓ Basic development tools\n"
    fi
    if [[ $selections == *"dev-docker"* ]]; then
        message="${message}  ✓ Docker and Docker Compose\n"
    fi
    if [[ $selections == *"tools-cli"* ]]; then
        message="${message}  ✓ CLI tools: $cli_tools\n"
    fi
    if [[ $selections == *"tools-git"* ]]; then
        message="${message}  ✓ Git tools\n"
    fi
    if [[ $selections == *"dotfiles"* ]]; then
        message="${message}  ✓ Dotfiles management\n"
    fi
    
    message="${message}\nDo you want to proceed with the installation?"
    
    whiptail --title "Confirm Installation" --yesno "$message" 20 80
}

# Main execution
main() {
    print_status "Starting Ubuntu Development Environment Setup"
    
    # Check prerequisites
    check_prerequisites
    check_whiptail
    check_ansible
    
    # Show main menu
    print_status "Showing component selection menu..."
    selections=$(show_main_menu)
    
    if [ "$selections" = "CANCELLED" ]; then
        print_warning "Installation cancelled by user"
        exit 0
    fi
    
    # Show CLI tools menu if CLI tools were selected
    cli_tools=""
    vars_file=""
    if [[ $selections == *"tools-cli"* ]]; then
        print_status "Showing CLI tools selection menu..."
        cli_tools=$(show_cli_tools_menu)
        
        if [ "$cli_tools" = "CANCELLED" ]; then
            print_warning "Installation cancelled by user"
            exit 0
        fi
        
        # Create variables file for selected CLI tools
        if [ -n "$cli_tools" ]; then
            vars_file=$(create_cli_tools_vars "$cli_tools")
        fi
    fi
    
    # Confirm installation
    if ! confirm_installation "$selections" "$cli_tools"; then
        print_warning "Installation cancelled by user"
        exit 0
    fi
    
    # Generate ansible tags
    tags=$(generate_ansible_tags "$selections" "$cli_tools")
    
    if [ -z "$tags" ]; then
        print_error "No components selected for installation"
        exit 1
    fi
    
    # Run ansible playbook
    print_status "Starting installation process..."
    if run_ansible "$tags" "$vars_file"; then
        print_status "Installation completed successfully!"
        
        print_status "Next steps:"
        echo "  1. Restart your shell or run: source ~/.bashrc"
        echo "  2. Configure Git user: git config --global user.name 'Your Name'"
        echo "  3. Configure Git email: git config --global user.email 'your@email.com'"
        echo "  4. Log out and back in for Docker group membership to take effect"
    else
        print_error "Installation failed. Please check the output above for errors."
        exit 1
    fi
    
    # Cleanup
    if [ -n "$vars_file" ] && [ -f "$vars_file" ]; then
        rm -f "$vars_file"
    fi
}

# Show usage information
show_usage() {
    cat << EOF
Ubuntu Development Environment Setup

Usage: $0 [OPTIONS]

Options:
  --non-interactive    Run in non-interactive mode (auto-select all components)
  --help, -h          Show this help message
  --test              Test mode (dry run without actual installation)

Examples:
  $0                          # Interactive mode (default)
  $0 --non-interactive        # Auto-install all components
  $0 --test                   # Test run without installation

Environment Variables:
  NON_INTERACTIVE=true        # Same as --non-interactive
  TEST_MODE=true              # Same as --test

EOF
}

# Parse command line arguments and run main
parse_args_and_run() {
    while [[ $# -gt 0 ]]; do
        case $1 in
            --non-interactive)
                export NON_INTERACTIVE="true"
                shift
                ;;
            --test)
                export TEST_MODE="true"
                shift
                ;;
            --help|-h)
                show_usage
                exit 0
                ;;
            *)
                echo "Unknown option: $1"
                show_usage
                exit 1
                ;;
        esac
    done
    
    # Run main function after parsing arguments
    main
}

# Call the function with all arguments
parse_args_and_run "$@"