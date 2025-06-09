#!/bin/bash
# Syntax validation tests

# Source common test utilities
source "$(dirname "$0")/test_common.sh"

test_ansible_syntax() {
    test_start "Ansible syntax validation"
    
    # Test main playbook syntax
    if ! ansible-playbook --syntax-check site.yml; then
        test_fail "Main playbook syntax check failed"
        return 1
    fi
    
    test_pass "Main playbook syntax check passed"
    
    # Test each role individually
    local roles=("brew" "dev" "tools" "preferences" "dotfiles")
    for role in "${roles[@]}"; do
        if [ -d "roles/$role" ]; then
            log_info "Checking role: $role"
            if ! ansible-playbook --syntax-check site.yml --tags "$role"; then
                log_error "Role $role syntax check failed"
                return 1
            fi
        else
            log_warning "Role directory not found: roles/$role"
        fi
    done
    
    # Test inventory syntax
    if ! ansible-inventory --list > /dev/null; then
        log_error "Inventory syntax check failed"
        return 1
    fi
    
    # Test YAML syntax of configuration files
    local yaml_files=(
        "site.yml"
        "inventory.yml"
        "group_vars/all.yml"
    )
    
    for file in "${yaml_files[@]}"; do
        if [ -f "$file" ]; then
            log_info "Checking YAML syntax: $file"
            if ! python3 -c "import yaml; yaml.safe_load(open('$file'))" 2>/dev/null; then
                log_error "YAML syntax error in $file"
                return 1
            fi
        fi
    done
    
    log_success "All syntax checks passed"
    return 0
}

test_ansible_lint() {
    log_info "Running ansible-lint if available..."
    
    if command -v ansible-lint >/dev/null 2>&1; then
        if ansible-lint site.yml; then
            log_success "ansible-lint passed"
            return 0
        else
            log_warning "ansible-lint found issues (not failing test)"
            return 0
        fi
    else
        log_info "ansible-lint not available, skipping"
        return 0
    fi
}

test_variable_definitions() {
    log_info "Validating variable definitions..."
    
    # Check if required variables are defined
    local required_vars=(
        "target_user"
        "target_home"
        "homebrew_path"
        "dev_packages"
        "cli_tools"
    )
    
    for var in "${required_vars[@]}"; do
        if ! grep -q "^$var:" group_vars/all.yml; then
            log_error "Required variable '$var' not found in group_vars/all.yml"
            return 1
        fi
    done
    
    # Check for undefined variables in tasks
    local undefined_vars=()
    
    # Use a simple grep to find potential undefined variables
    while IFS= read -r line; do
        if [[ $line =~ \{\{[[:space:]]*([a-zA-Z_][a-zA-Z0-9_]*)[[:space:]]*\}\} ]]; then
            local var_name="${BASH_REMATCH[1]}"
            if ! grep -q "^$var_name:" group_vars/all.yml && 
               ! grep -q "ansible_" <<< "$var_name" &&
               ! grep -q "item" <<< "$var_name"; then
                undefined_vars+=("$var_name")
            fi
        fi
    done < <(find roles -name "*.yml" -exec cat {} \;)
    
    if [ ${#undefined_vars[@]} -gt 0 ]; then
        log_warning "Potentially undefined variables found: ${undefined_vars[*]}"
    fi
    
    log_success "Variable definition check completed"
    return 0
}