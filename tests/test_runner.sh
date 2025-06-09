#!/bin/bash
# Advanced test runner for Ubuntu Dev Setup
# Usage: ./tests/test_runner.sh [options]

set -euo pipefail

# Configuration
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"
LOG_DIR="$PROJECT_DIR/tests/logs"
TEMP_DIR="$PROJECT_DIR/tests/temp"

# Source common test utilities
source "$SCRIPT_DIR/test_common.sh"
readonly YELLOW='\033[1;33m'
readonly BLUE='\033[0;34m'
readonly PURPLE='\033[0;35m'
readonly CYAN='\033[0;36m'
readonly NC='\033[0m'

# Logging functions
log_info() { echo -e "${BLUE}[INFO]${NC} $*"; }
log_success() { echo -e "${GREEN}[PASS]${NC} $*"; }
log_error() { echo -e "${RED}[FAIL]${NC} $*"; }
log_warning() { echo -e "${YELLOW}[WARN]${NC} $*"; }
log_test() { echo -e "${PURPLE}[TEST]${NC} $*"; }

# Test counters
TESTS_RUN=0
TESTS_PASSED=0
TESTS_FAILED=0
START_TIME=$(date +%s)

# Initialize test environment
init_test_env() {
    mkdir -p "$LOG_DIR" "$TEMP_DIR"
    cd "$PROJECT_DIR"
    
    # Create test log
    local timestamp=$(date '+%Y%m%d_%H%M%S')
    export TEST_LOG="$LOG_DIR/test_run_$timestamp.log"
    touch "$TEST_LOG"
    
    log_info "Test environment initialized"
    log_info "Project directory: $PROJECT_DIR"
    log_info "Log directory: $LOG_DIR"
    log_info "Test log: $TEST_LOG"
}

# Execute test with error handling
run_test() {
    local test_name="$1"
    local test_function="$2"
    
    ((TESTS_RUN++))
    log_test "Running: $test_name"
    
    if $test_function 2>&1 | tee -a "$TEST_LOG"; then
        ((TESTS_PASSED++))
        log_success "$test_name"
        return 0
    else
        ((TESTS_FAILED++))
        log_error "$test_name"
        return 1
    fi
}

# Cleanup function
cleanup() {
    local exit_code=$?
    rm -rf "$TEMP_DIR"
    
    local end_time=$(date +%s)
    local duration=$((end_time - START_TIME))
    
    echo
    echo "=== Test Summary ==="
    echo "Tests run: $TESTS_RUN"
    echo "Passed: $TESTS_PASSED"
    echo "Failed: $TESTS_FAILED"
    echo "Duration: ${duration}s"
    echo "Log file: $TEST_LOG"
    
    if [ $TESTS_FAILED -eq 0 ]; then
        log_success "All tests passed!"
        exit 0
    else
        log_error "$TESTS_FAILED test(s) failed"
        exit 1
    fi
}

# Set trap for cleanup
trap cleanup EXIT

# Export logging functions for use in test modules
export -f log_info log_success log_error log_warning log_test

# Load test modules
source "$SCRIPT_DIR/test_syntax.sh"
source "$SCRIPT_DIR/test_roles.sh"
source "$SCRIPT_DIR/test_integration.sh"
source "$SCRIPT_DIR/test_security.sh"

# Main function
main() {
    local test_type="${1:-all}"
    local role_filter="${2:-}"
    
    echo "=== Ubuntu Dev Setup Test Suite ==="
    echo "Test type: $test_type"
    [ -n "$role_filter" ] && echo "Role filter: $role_filter"
    echo
    
    init_test_env
    
    case "$test_type" in
        "syntax")
            run_test "Ansible Syntax Check" test_ansible_syntax
            ;;
        "roles")
            run_test "Role Structure Validation" "test_role_structure $role_filter"
            run_test "Role Task Validation" "test_role_tasks $role_filter"
            ;;
        "integration")
            run_test "System Dependencies" test_system_dependencies
            run_test "Package Installation" test_package_installation
            run_test "Service Configuration" test_service_configuration
            ;;
        "security")
            run_test "File Permissions" test_file_permissions
            run_test "Sensitive Data" test_sensitive_data
            run_test "Security Configuration" test_security_config
            ;;
        "all"|*)
            # Run all tests
            run_test "Ansible Syntax Check" test_ansible_syntax
            run_test "Role Structure Validation" "test_role_structure $role_filter"
            run_test "Role Task Validation" "test_role_tasks $role_filter"
            run_test "System Dependencies" test_system_dependencies
            run_test "Package Installation" test_package_installation
            run_test "Service Configuration" test_service_configuration
            run_test "File Permissions" test_file_permissions
            run_test "Sensitive Data" test_sensitive_data
            run_test "Security Configuration" test_security_config
            ;;
    esac
}

# Show usage
show_usage() {
    cat << EOF
Usage: $0 [test_type] [role_filter]

Test Types:
  all         - Run all tests (default)
  syntax      - Ansible syntax validation
  roles       - Role structure and task validation
  integration - Integration and system tests
  security    - Security and permission tests

Role Filter:
  Specific role name (brew, dev, tools, preferences, dotfiles)

Examples:
  $0                    # Run all tests
  $0 syntax             # Run syntax tests only
  $0 roles brew         # Test brew role only
  $0 integration        # Run integration tests only

Options:
  -h, --help           Show this help message

EOF
}

# Parse arguments
case "${1:-}" in
    -h|--help)
        show_usage
        exit 0
        ;;
    *)
        main "$@"
        ;;
esac