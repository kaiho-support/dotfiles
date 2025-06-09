#!/bin/bash
# setup.sh specific tests

# Source common test utilities
source "$(dirname "$0")/test_common.sh"

test_setup_script_help() {
    test_start "setup.sh --help functionality"
    
    if ./setup.sh --help > /dev/null 2>&1; then
        test_pass "Help option works correctly"
        return 0
    else
        test_fail "Help option failed"
        return 1
    fi
}

test_setup_script_structure() {
    log_info "Testing setup.sh script structure..."
    
    # Check if script is executable
    if [ ! -x "setup.sh" ]; then
        log_error "setup.sh is not executable"
        return 1
    fi
    
    # Check for required functions
    local required_functions=(
        "check_prerequisites"
        "check_ansible"
        "show_main_menu"
        "run_ansible"
        "main"
    )
    
    for func in "${required_functions[@]}"; do
        if ! grep -q "^$func()" setup.sh; then
            log_error "Required function missing: $func"
            return 1
        fi
    done
    
    log_success "Script structure is valid"
    return 0
}

test_setup_script_syntax() {
    log_info "Testing setup.sh bash syntax..."
    
    if bash -n setup.sh; then
        log_success "Bash syntax is valid"
        return 0
    else
        log_error "Bash syntax errors found"
        return 1
    fi
}

test_non_interactive_mode() {
    log_info "Testing non-interactive mode functionality..."
    
    # Test environment variable method
    if NON_INTERACTIVE=true TEST_MODE=true timeout 30 ./setup.sh > /dev/null 2>&1; then
        log_success "Non-interactive mode via environment variables works"
    else
        log_error "Non-interactive mode via environment variables failed"
        return 1
    fi
    
    # Test command line flag method
    if timeout 30 ./setup.sh --non-interactive --test > /dev/null 2>&1; then
        log_success "Non-interactive mode via command line flags works"
    else
        log_error "Non-interactive mode via command line flags failed"
        return 1
    fi
    
    return 0
}

test_tag_generation() {
    log_info "Testing tag generation logic..."
    
    # Source the script to access functions (in a subshell)
    (
        source setup.sh > /dev/null 2>&1
        
        # Test basic tag generation
        local test_selections='"homebrew" "dev-basic" "tools-cli"'
        local test_cli_tools='"lsd" "bat" "fzf"'
        
        local tags=$(generate_ansible_tags "$test_selections" "$test_cli_tools")
        
        if [[ "$tags" == *"homebrew"* ]] && [[ "$tags" == *"dev-basic"* ]] && [[ "$tags" == *"tools-cli"* ]]; then
            log_success "Tag generation works correctly"
            return 0
        else
            log_error "Tag generation failed: $tags"
            return 1
        fi
    )
    
    return $?
}

test_cli_tools_vars_creation() {
    log_info "Testing CLI tools variables file creation..."
    
    (
        source setup.sh > /dev/null 2>&1
        
        local test_tools='"lsd" "bat" "fzf"'
        local vars_file=$(create_cli_tools_vars "$test_tools")
        
        if [ -f "$vars_file" ]; then
            # Check if file contains expected content
            if grep -q "selected_cli_tools:" "$vars_file" && grep -q "lsd" "$vars_file"; then
                log_success "CLI tools variables file creation works"
                rm -f "$vars_file"
                return 0
            else
                log_error "CLI tools variables file has incorrect content"
                rm -f "$vars_file"
                return 1
            fi
        else
            log_error "CLI tools variables file was not created"
            return 1
        fi
    )
    
    return $?
}

test_prerequisite_checks() {
    log_info "Testing prerequisite checks..."
    
    (
        source setup.sh > /dev/null 2>&1
        
        # These should pass in our environment
        if check_prerequisites > /dev/null 2>&1; then
            log_success "Prerequisite checks pass"
            return 0
        else
            log_error "Prerequisite checks failed"
            return 1
        fi
    )
    
    return $?
}

# Main test runner for setup.sh
run_setup_tests() {
    echo "=== Setup Script Tests ==="
    echo
    
    local failed_tests=0
    
    if ! test_setup_script_syntax; then
        ((failed_tests++))
    fi
    
    if ! test_setup_script_structure; then
        ((failed_tests++))
    fi
    
    if ! test_setup_script_help; then
        ((failed_tests++))
    fi
    
    if ! test_non_interactive_mode; then
        ((failed_tests++))
    fi
    
    if ! test_tag_generation; then
        ((failed_tests++))
    fi
    
    if ! test_cli_tools_vars_creation; then
        ((failed_tests++))
    fi
    
    if ! test_prerequisite_checks; then
        ((failed_tests++))
    fi
    
    echo
    if [ $failed_tests -eq 0 ]; then
        log_success "All setup script tests passed!"
        return 0
    else
        log_error "$failed_tests setup script test(s) failed"
        return 1
    fi
}

# Run tests if script is executed directly
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    cd "$(dirname "$0")/.."
    run_setup_tests
fi