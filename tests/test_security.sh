#!/bin/bash
# Security and permission tests

test_file_permissions() {
    log_info "Testing file permissions and security..."
    
    # Check for world-writable files (security risk)
    local world_writable=()
    while IFS= read -r -d '' file; do
        world_writable+=("$file")
    done < <(find . -type f -perm /o+w -print0 2>/dev/null || true)
    
    if [ ${#world_writable[@]} -gt 0 ]; then
        log_warning "World-writable files found: ${world_writable[*]}"
    fi
    
    # Check script permissions
    local scripts=(
        "setup.sh"
        "tests/test_runner.sh"
    )
    
    for script in "${scripts[@]}"; do
        if [ -f "$script" ]; then
            if [ ! -x "$script" ]; then
                log_error "Script not executable: $script"
                return 1
            fi
        fi
    done
    
    # Check for proper ownership of critical files
    local critical_files=(
        "site.yml"
        "ansible.cfg"
        "group_vars/all.yml"
    )
    
    for file in "${critical_files[@]}"; do
        if [ -f "$file" ]; then
            # Check if file is owned by current user
            local file_owner=$(stat -c "%U" "$file")
            local current_user=$(whoami)
            
            if [ "$file_owner" != "$current_user" ]; then
                log_warning "File not owned by current user: $file (owned by $file_owner)"
            fi
        fi
    done
    
    log_success "File permissions check completed"
    return 0
}

test_sensitive_data() {
    log_info "Scanning for sensitive data exposure..."
    
    # Patterns to search for sensitive data
    local sensitive_patterns=(
        "password"
        "passwd"
        "secret"
        "token"
        "key"
        "api_key"
        "private_key"
        "ssh_key"
    )
    
    local found_sensitive=()
    
    # Search in YAML files
    for pattern in "${sensitive_patterns[@]}"; do
        local matches=$(grep -r -i "$pattern" . --include="*.yml" --include="*.yaml" 2>/dev/null | grep -v "test_security.sh" || true)
        if [ -n "$matches" ]; then
            # Check if it's actually sensitive (not just a comment or variable name)
            while IFS= read -r line; do
                if [[ "$line" =~ :[[:space:]]*[\"\']*[a-zA-Z0-9+/]{8,}[\"\']*[[:space:]]*$ ]]; then
                    found_sensitive+=("$line")
                fi
            done <<< "$matches"
        fi
    done
    
    if [ ${#found_sensitive[@]} -gt 0 ]; then
        log_error "Potential sensitive data found:"
        printf '%s\n' "${found_sensitive[@]}"
        return 1
    fi
    
    # Check for SSH keys in dotfiles
    local ssh_key_files=()
    while IFS= read -r -d '' file; do
        ssh_key_files+=("$file")
    done < <(find dotfiles -name "*id_rsa*" -o -name "*id_ed25519*" -o -name "*id_ecdsa*" -print0 2>/dev/null || true)
    
    if [ ${#ssh_key_files[@]} -gt 0 ]; then
        log_warning "SSH key files found in dotfiles: ${ssh_key_files[*]}"
        log_warning "Ensure these are public keys only or properly secured"
    fi
    
    # Check for hardcoded credentials in scripts
    local credential_patterns=("--password" "--token" "--key" "export.*PASSWORD" "export.*TOKEN")
    
    for pattern in "${credential_patterns[@]}"; do
        local matches=$(grep -r "$pattern" . --include="*.sh" --include="*.yml" 2>/dev/null | grep -v "test_security.sh" || true)
        if [ -n "$matches" ]; then
            log_warning "Potential hardcoded credentials found:"
            echo "$matches"
        fi
    done
    
    log_success "Sensitive data scan completed"
    return 0
}

test_security_config() {
    log_info "Testing security configuration..."
    
    # Check Ansible configuration for security best practices
    if [ -f "ansible.cfg" ]; then
        # Check if host key checking is disabled (security concern)
        if grep -q "host_key_checking.*False" ansible.cfg; then
            log_warning "Host key checking is disabled in ansible.cfg (consider enabling for production)"
        fi
        
        # Check for privilege escalation settings
        if grep -q "become.*True" ansible.cfg; then
            log_info "Privilege escalation enabled in ansible.cfg"
        fi
    fi
    
    # Check playbook security settings
    if [ -f "site.yml" ]; then
        # Check for become usage
        if grep -q "become: yes\|become: true" site.yml; then
            log_info "Privilege escalation used in playbook"
        fi
        
        # Check for fact gathering (can expose sensitive info)
        if grep -q "gather_facts: no\|gather_facts: false" site.yml; then
            log_info "Fact gathering disabled (good for security)"
        else
            log_info "Fact gathering enabled (consider if all facts are needed)"
        fi
    fi
    
    # Check for secure file handling in roles
    local insecure_patterns=("chmod 777" "chmod 666" "mode: '777'" "mode: '666'")
    
    for pattern in "${insecure_patterns[@]}"; do
        local matches=$(grep -r "$pattern" roles/ 2>/dev/null || true)
        if [ -n "$matches" ]; then
            log_error "Insecure file permissions found:"
            echo "$matches"
            return 1
        fi
    done
    
    # Check for proper use of become in tasks
    local become_issues=$(grep -r "sudo:" roles/ 2>/dev/null || true)
    if [ -n "$become_issues" ]; then
        log_warning "Direct sudo usage found (consider using 'become:' instead):"
        echo "$become_issues"
    fi
    
    # Check for shell injection vulnerabilities
    local shell_tasks=$(grep -r "shell:\|command:" roles/ 2>/dev/null || true)
    if [ -n "$shell_tasks" ]; then
        log_info "Shell/command tasks found - verify input sanitization"
        
        # Check for variables in shell commands (potential injection)
        local var_in_shell=$(echo "$shell_tasks" | grep "{{.*}}" || true)
        if [ -n "$var_in_shell" ]; then
            log_warning "Variables used in shell commands - verify sanitization"
        fi
    fi
    
    log_success "Security configuration check completed"
    return 0
}

test_docker_security() {
    log_info "Testing Docker security configuration..."
    
    # Check if Docker daemon is running as root (expected)
    if command -v docker >/dev/null 2>&1; then
        if docker info >/dev/null 2>&1; then
            # Check Docker version for known vulnerabilities
            local docker_version=$(docker --version | grep -o '[0-9]\+\.[0-9]\+\.[0-9]\+' | head -1)
            log_info "Docker version: $docker_version"
            
            # Check if user is in docker group
            if groups | grep -q docker; then
                log_info "User is in docker group (allows non-root Docker usage)"
            else
                log_warning "User not in docker group (will need sudo for Docker commands)"
            fi
        else
            log_warning "Docker daemon not running or not accessible"
        fi
    else
        log_info "Docker not installed (will be installed by setup)"
    fi
    
    # Check for Docker security best practices in configuration
    local docker_configs=()
    while IFS= read -r -d '' file; do
        docker_configs+=("$file")
    done < <(find . -name "*docker*" -type f -print0 2>/dev/null || true)
    
    for config in "${docker_configs[@]}"; do
        # Check for privileged containers
        if grep -q "privileged.*true" "$config" 2>/dev/null; then
            log_warning "Privileged Docker container configuration found in $config"
        fi
        
        # Check for host network mode
        if grep -q "network.*host" "$config" 2>/dev/null; then
            log_warning "Host network mode found in $config (potential security risk)"
        fi
    done
    
    log_success "Docker security check completed"
    return 0
}

test_repository_security() {
    log_info "Testing repository security..."
    
    # Check .gitignore for sensitive files
    if [ -f ".gitignore" ]; then
        local sensitive_extensions=("*.key" "*.pem" "*.p12" "*.pfx" "id_rsa" "id_ed25519")
        local missing_patterns=()
        
        for pattern in "${sensitive_extensions[@]}"; do
            if ! grep -q "$pattern" .gitignore; then
                missing_patterns+=("$pattern")
            fi
        done
        
        if [ ${#missing_patterns[@]} -gt 0 ]; then
            log_warning "Consider adding these patterns to .gitignore: ${missing_patterns[*]}"
        fi
    else
        log_warning ".gitignore file not found - consider creating one"
    fi
    
    # Check for committed sensitive files
    if [ -d ".git" ]; then
        local committed_secrets=$(git log --all --full-history --source -- "*.key" "*.pem" "*password*" "*secret*" 2>/dev/null | head -10 || true)
        if [ -n "$committed_secrets" ]; then
            log_warning "Potential sensitive files found in git history"
        fi
    fi
    
    log_success "Repository security check completed"
    return 0
}