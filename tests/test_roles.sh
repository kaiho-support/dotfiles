#!/bin/bash
# Role structure and task validation tests

test_role_structure() {
    local role_filter="$1"
    log_info "Validating role structure..."
    
    local roles=("brew" "dev" "tools" "preferences" "dotfiles")
    [ -n "$role_filter" ] && roles=("$role_filter")
    
    for role in "${roles[@]}"; do
        test_single_role_structure "$role" || return 1
    done
    
    log_success "All role structures are valid"
    return 0
}

test_single_role_structure() {
    local role="$1"
    log_info "Testing role structure: $role"
    
    # Check if role directory exists
    if [ ! -d "roles/$role" ]; then
        log_error "Role directory not found: roles/$role"
        return 1
    fi
    
    # Check required directories and files
    local required_items=(
        "roles/$role/tasks"
        "roles/$role/tasks/main.yml"
    )
    
    local optional_items=(
        "roles/$role/vars/main.yml"
        "roles/$role/handlers/main.yml"
        "roles/$role/meta/main.yml"
        "roles/$role/defaults/main.yml"
        "roles/$role/files"
        "roles/$role/templates"
    )
    
    # Check required items
    for item in "${required_items[@]}"; do
        if [ ! -e "$item" ]; then
            log_error "Required item missing: $item"
            return 1
        fi
    done
    
    # Check optional items and warn if missing common ones
    for item in "${optional_items[@]}"; do
        if [ ! -e "$item" ] && [[ "$item" =~ (vars|handlers)/main\.yml$ ]]; then
            log_info "Optional item not found: $item"
        fi
    done
    
    # Validate main.yml structure
    if [ -f "roles/$role/tasks/main.yml" ]; then
        test_tasks_structure "roles/$role/tasks/main.yml" || return 1
    fi
    
    log_success "Role $role structure is valid"
    return 0
}

test_tasks_structure() {
    local tasks_file="$1"
    log_info "Validating tasks structure: $tasks_file"
    
    # Check if tasks file has proper YAML structure
    if ! python3 -c "
import yaml
import sys
try:
    with open('$tasks_file') as f:
        data = yaml.safe_load(f)
    if not isinstance(data, list):
        print('Tasks file should contain a list of tasks')
        sys.exit(1)
    for task in data:
        if not isinstance(task, dict):
            print('Each task should be a dictionary')
            sys.exit(1)
        if 'name' not in task:
            print('Task missing name field')
            sys.exit(1)
except Exception as e:
    print(f'Error parsing tasks file: {e}')
    sys.exit(1)
" 2>/dev/null; then
        log_error "Tasks structure validation failed for $tasks_file"
        return 1
    fi
    
    # Check for common task issues
    if grep -q "sudo:" "$tasks_file"; then
        log_warning "Found 'sudo:' directive in $tasks_file (consider using 'become:')"
    fi
    
    if grep -q "shell:" "$tasks_file" && ! grep -q "changed_when:" "$tasks_file"; then
        log_info "Shell tasks found without changed_when in $tasks_file (consider adding for idempotency)"
    fi
    
    log_success "Tasks structure is valid for $tasks_file"
    return 0
}

test_role_tasks() {
    local role_filter="$1"
    log_info "Validating role tasks..."
    
    local roles=("brew" "dev" "tools" "preferences" "dotfiles")
    [ -n "$role_filter" ] && roles=("$role_filter")
    
    for role in "${roles[@]}"; do
        test_single_role_tasks "$role" || return 1
    done
    
    log_success "All role tasks are valid"
    return 0
}

test_single_role_tasks() {
    local role="$1"
    log_info "Testing role tasks: $role"
    
    if [ ! -f "roles/$role/tasks/main.yml" ]; then
        log_error "Tasks file not found: roles/$role/tasks/main.yml"
        return 1
    fi
    
    # Test dry run for this specific role
    if ! ansible-playbook site.yml --tags "$role" --check --diff > /dev/null 2>&1; then
        log_error "Dry run failed for role: $role"
        return 1
    fi
    
    # Check for best practices in tasks
    local tasks_file="roles/$role/tasks/main.yml"
    
    # Check for proper task naming
    local unnamed_tasks=$(grep -n "^- " "$tasks_file" | grep -v "name:" | wc -l)
    if [ "$unnamed_tasks" -gt 0 ]; then
        log_warning "Found $unnamed_tasks unnamed tasks in $tasks_file"
    fi
    
    # Check for proper error handling
    if grep -q "ignore_errors: yes" "$tasks_file"; then
        log_info "Found ignore_errors in $tasks_file (verify if necessary)"
    fi
    
    # Check for hardcoded paths
    if grep -q "/home/" "$tasks_file" && ! grep -q "ansible_env.HOME\|target_home" "$tasks_file"; then
        log_warning "Found hardcoded home paths in $tasks_file"
    fi
    
    log_success "Role $role tasks are valid"
    return 0
}

test_role_dependencies() {
    log_info "Testing role dependencies..."
    
    # Check meta/main.yml files for dependencies
    for role_dir in roles/*/; do
        local role=$(basename "$role_dir")
        local meta_file="$role_dir/meta/main.yml"
        
        if [ -f "$meta_file" ]; then
            log_info "Checking dependencies for role: $role"
            
            # Validate meta file syntax
            if ! python3 -c "import yaml; yaml.safe_load(open('$meta_file'))" 2>/dev/null; then
                log_error "Invalid YAML in $meta_file"
                return 1
            fi
            
            # Check if dependencies exist
            local deps=$(grep -A 10 "dependencies:" "$meta_file" | grep "role:" | sed 's/.*role: *//; s/ *$//' || true)
            for dep in $deps; do
                if [ ! -d "roles/$dep" ]; then
                    log_error "Dependency not found: $dep (required by $role)"
                    return 1
                fi
            done
        fi
    done
    
    log_success "Role dependencies check completed"
    return 0
}