#!/bin/bash
# Integration and system tests

test_system_dependencies() {
    log_info "Testing system dependencies..."
    
    # Check if running on supported system
    if [ ! -f /etc/os-release ]; then
        log_error "Cannot determine OS version"
        return 1
    fi
    
    source /etc/os-release
    if [[ ! "$ID" =~ ^(ubuntu|debian)$ ]]; then
        log_warning "Unsupported OS detected: $ID (tests may not be accurate)"
    fi
    
    # Check essential commands
    local essential_commands=("apt" "python3" "curl" "wget")
    for cmd in "${essential_commands[@]}"; do
        if ! command -v "$cmd" >/dev/null 2>&1; then
            log_error "Essential command not found: $cmd"
            return 1
        fi
    done
    
    # Check sudo access
    if ! sudo -n true 2>/dev/null; then
        log_warning "Sudo access required for full setup"
    fi
    
    # Check internet connectivity
    if ! curl -s --connect-timeout 5 https://github.com >/dev/null; then
        log_error "Internet connectivity required"
        return 1
    fi
    
    log_success "System dependencies check passed"
    return 0
}

test_package_installation() {
    log_info "Testing package installation readiness..."
    
    # Test APT package manager
    log_info "Checking APT package manager..."
    if ! apt list --installed >/dev/null 2>&1; then
        log_error "APT package manager not working properly"
        return 1
    fi
    
    # Test if we can update package lists
    if ! sudo apt update >/dev/null 2>&1; then
        log_error "Cannot update APT package lists"
        return 1
    fi
    
    # Check available packages from our list
    local dev_packages=("git" "curl" "wget" "vim" "tmux" "zsh" "build-essential")
    local missing_packages=()
    
    for package in "${dev_packages[@]}"; do
        if ! apt-cache show "$package" >/dev/null 2>&1; then
            missing_packages+=("$package")
        fi
    done
    
    if [ ${#missing_packages[@]} -gt 0 ]; then
        log_error "Packages not available: ${missing_packages[*]}"
        return 1
    fi
    
    # Test Homebrew installation requirements
    log_info "Checking Homebrew installation requirements..."
    
    # Check if linuxbrew directory is writable or can be created
    local homebrew_path="/home/linuxbrew/.linuxbrew"
    if [ -d "$homebrew_path" ]; then
        if [ ! -w "$homebrew_path" ]; then
            log_warning "Homebrew directory exists but is not writable: $homebrew_path"
        fi
    else
        # Check if we can create the parent directory
        if ! sudo mkdir -p "$(dirname "$homebrew_path")" 2>/dev/null; then
            log_error "Cannot create Homebrew parent directory"
            return 1
        fi
    fi
    
    log_success "Package installation readiness check passed"
    return 0
}

test_service_configuration() {
    log_info "Testing service configuration..."
    
    # Test if systemd is available (for Docker service)
    if ! systemctl --version >/dev/null 2>&1; then
        log_warning "systemd not available (Docker service management may not work)"
    fi
    
    # Test user group management
    if ! groups >/dev/null 2>&1; then
        log_error "Cannot check user groups"
        return 1
    fi
    
    # Test if we can add users to groups (needed for Docker)
    if ! sudo usermod --help >/dev/null 2>&1; then
        log_error "usermod command not available"
        return 1
    fi
    
    # Test file permissions and ownership changes
    local test_file="$TEMP_DIR/test_permissions"
    touch "$test_file"
    
    if ! chmod 644 "$test_file"; then
        log_error "Cannot change file permissions"
        return 1
    fi
    
    if ! chown "$(id -u):$(id -g)" "$test_file"; then
        log_error "Cannot change file ownership"
        return 1
    fi
    
    rm -f "$test_file"
    
    log_success "Service configuration check passed"
    return 0
}

test_dotfiles_setup() {
    log_info "Testing dotfiles setup requirements..."
    
    # Check if stow is available or can be installed
    if ! command -v stow >/dev/null 2>&1; then
        if ! apt-cache show stow >/dev/null 2>&1; then
            log_error "GNU Stow not available for installation"
            return 1
        fi
    fi
    
    # Test dotfiles directory structure
    local dotfiles_source="$PROJECT_DIR/dotfiles"
    if [ ! -d "$dotfiles_source" ]; then
        log_error "Dotfiles source directory not found: $dotfiles_source"
        return 1
    fi
    
    # Check dotfiles packages
    local expected_packages=("git" "zsh" "vim" "tmux")
    for package in "${expected_packages[@]}"; do
        if [ ! -d "$dotfiles_source/$package" ]; then
            log_warning "Dotfiles package not found: $package"
        fi
    done
    
    # Test stow operation in a safe way
    local test_dotfiles="$TEMP_DIR/test_dotfiles"
    local test_target="$TEMP_DIR/test_home"
    mkdir -p "$test_dotfiles/test_package/.config"
    mkdir -p "$test_target"
    
    echo "test config" > "$test_dotfiles/test_package/.config/test.conf"
    
    if command -v stow >/dev/null 2>&1; then
        cd "$test_dotfiles"
        if stow -t "$test_target" test_package 2>/dev/null; then
            if [ -L "$test_target/.config/test.conf" ]; then
                log_success "Stow operation test passed"
            else
                log_error "Stow operation did not create expected symlink"
                return 1
            fi
            stow -t "$test_target" -D test_package 2>/dev/null
        else
            log_error "Stow operation test failed"
            return 1
        fi
        cd "$PROJECT_DIR"
    fi
    
    rm -rf "$test_dotfiles" "$test_target"
    
    log_success "Dotfiles setup check passed"
    return 0
}

test_homebrew_environment() {
    log_info "Testing Homebrew environment..."
    
    # Check if Homebrew is already installed
    if command -v brew >/dev/null 2>&1; then
        log_info "Homebrew already installed"
        
        # Test brew commands
        if ! brew --version >/dev/null 2>&1; then
            log_error "Homebrew installation is broken"
            return 1
        fi
        
        # Test if we can install packages
        if ! brew search git >/dev/null 2>&1; then
            log_error "Cannot search Homebrew packages"
            return 1
        fi
        
        log_success "Existing Homebrew installation is functional"
    else
        log_info "Homebrew not installed (will be installed by setup)"
        
        # Check installation requirements
        local required_tools=("curl" "git")
        for tool in "${required_tools[@]}"; do
            if ! command -v "$tool" >/dev/null 2>&1; then
                log_error "Required tool for Homebrew installation not found: $tool"
                return 1
            fi
        done
    fi
    
    log_success "Homebrew environment check passed"
    return 0
}