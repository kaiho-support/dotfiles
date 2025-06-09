#!/bin/bash
# Common test utilities and functions

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# Common logging functions
log_info() { echo -e "${BLUE}[INFO]${NC} $*"; }
log_success() { echo -e "${GREEN}[PASS]${NC} $*"; }
log_error() { echo -e "${RED}[FAIL]${NC} $*"; }
log_warning() { echo -e "${YELLOW}[WARN]${NC} $*"; }

# Test result tracking
TESTS_RUN=0
TESTS_PASSED=0
TESTS_FAILED=0

# Test result functions
test_start() {
    ((TESTS_RUN++))
    log_info "Running test: $1"
}

test_pass() {
    ((TESTS_PASSED++))
    log_success "$1"
}

test_fail() {
    ((TESTS_FAILED++))
    log_error "$1"
}

# Test summary
show_test_summary() {
    echo
    log_info "Test Summary:"
    echo "  Total tests run: $TESTS_RUN"
    echo "  Passed: $TESTS_PASSED"
    echo "  Failed: $TESTS_FAILED"
    
    if [[ $TESTS_FAILED -eq 0 ]]; then
        log_success "All tests passed!"
        return 0
    else
        log_error "$TESTS_FAILED test(s) failed"
        return 1
    fi
}

# Cleanup function for tests
cleanup_test_files() {
    local files=("$@")
    for file in "${files[@]}"; do
        if [[ -f "$file" ]]; then
            rm -f "$file"
            log_info "Cleaned up: $file"
        fi
    done
}

# Check if command exists
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# Create temporary test directory
create_test_dir() {
    local test_dir="/tmp/ubuntu-dev-setup-test-$$"
    mkdir -p "$test_dir"
    echo "$test_dir"
}

# Validate YAML syntax
validate_yaml() {
    local file="$1"
    if command_exists python3; then
        python3 -c "import yaml; yaml.safe_load(open('$file'))" 2>/dev/null
    else
        # Basic YAML validation without python
        if [[ -f "$file" ]] && [[ -s "$file" ]]; then
            return 0
        else
            return 1
        fi
    fi
}