# Docker GPG Key Conflict Fix

## Problem
Error encountered during setup:
```
E:Conflicting values set for option Signed-By regarding source https://download.docker.com/linux/ubuntu/ noble: /etc/apt/keyrings/docker.asc != /etc/apt/keyrings/docker.gpg, E:The list of sources could not be read.
```

## Root Cause
Multiple Docker repository configurations existed simultaneously:
- `/etc/apt/sources.list.d/docker.list` using `/etc/apt/keyrings/docker.asc`
- `/etc/apt/sources.list.d/download_docker_com_linux_ubuntu.list` using `/etc/apt/keyrings/docker.gpg`
- Different architecture specifications (amd64 vs x86_64)

## Solution Applied

### 1. Enhanced Cleanup Process
Updated `roles/dev/tasks/main.yml`:
- More thorough removal of Docker repository files
- Complete cleanup of all Docker GPG keys
- Consistent use of single GPG key format

### 2. Consolidated GPG Key Management
- Use only `/etc/apt/keyrings/docker.gpg`
- Consistent permissions (644)
- Proper architecture detection with `dpkg --print-architecture`

### 3. Repository Dependency Management
- Added conditional dependencies in `roles/dev/meta/main.yml`
- Tagged pre_tasks to avoid unnecessary execution
- Improved task isolation

## Manual Cleanup Commands (if needed)
```bash
# Remove conflicting repository files
sudo find /etc/apt/sources.list.d/ -name "*docker*" -type f -delete

# Remove conflicting GPG keys
sudo rm -f /etc/apt/keyrings/docker.*

# Update package cache
sudo apt update
```

## Testing
To test Docker setup specifically:
```bash
ansible-playbook test_docker_setup.yml --check
```

## Verification
After setup completion, verify:
```bash
# Check repository configuration
grep -r "docker.com" /etc/apt/sources.list.d/

# Check GPG key
ls -la /etc/apt/keyrings/docker*

# Verify Docker installation
docker --version
```

## Prevention
The enhanced cleanup process in the Ansible playbook now:
1. Removes all existing Docker configurations
2. Uses consistent naming and permissions
3. Applies proper architecture detection
4. Maintains single source of truth for Docker setup

This fix ensures clean Docker installation without GPG key conflicts.