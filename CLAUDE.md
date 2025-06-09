# Working with Ubuntu Dev Setup using Claude Code

This document provides guidance for using Claude Code to work with this Ubuntu development environment setup repository.

## Repository Overview

This repository contains an Ansible-based automation system for setting up Ubuntu development environments. Key components include:

- **Ansible Playbooks**: Automated installation and configuration
- **Dotfiles Management**: GNU Stow-based configuration management
- **Interactive Setup**: User-friendly installation wizard
- **Modular Design**: Role-based component organization

## Key Files and Directories

### Core Files
- `/home/kaiho/ghq/github.com/kaiho/ubuntu-dev-setup/site.yml` - Main Ansible playbook
- `/home/kaiho/ghq/github.com/kaiho/ubuntu-dev-setup/setup.sh` - Interactive installation script
- `/home/kaiho/ghq/github.com/kaiho/ubuntu-dev-setup/ansible.cfg` - Ansible configuration
- `/home/kaiho/ghq/github.com/kaiho/ubuntu-dev-setup/inventory.yml` - Ansible inventory

### Configuration
- `/home/kaiho/ghq/github.com/kaiho/ubuntu-dev-setup/group_vars/all.yml` - Global variables and tool definitions
- `/home/kaiho/ghq/github.com/kaiho/ubuntu-dev-setup/dotfiles/` - Configuration files for various tools

### Roles Structure
- `/home/kaiho/ghq/github.com/kaiho/ubuntu-dev-setup/roles/brew/` - Homebrew installation and management
- `/home/kaiho/ghq/github.com/kaiho/ubuntu-dev-setup/roles/dev/` - Development tools (git, docker, build tools)
- `/home/kaiho/ghq/github.com/kaiho/ubuntu-dev-setup/roles/tools/` - CLI tools and utilities
- `/home/kaiho/ghq/github.com/kaiho/ubuntu-dev-setup/roles/dotfiles/` - Dotfiles management with GNU Stow

## Common Tasks with Claude Code

### Adding New Tools

To add a new CLI tool via Homebrew:
1. Edit `/home/kaiho/ghq/github.com/kaiho/ubuntu-dev-setup/group_vars/all.yml` to add the tool to relevant lists
2. Update the interactive menu in `/home/kaiho/ghq/github.com/kaiho/ubuntu-dev-setup/setup.sh` if needed
3. Modify role tasks in `/home/kaiho/ghq/github.com/kaiho/ubuntu-dev-setup/roles/tools/tasks/main.yml`

### Managing Dotfiles

Dotfiles are organized in `/home/kaiho/ghq/github.com/kaiho/ubuntu-dev-setup/dotfiles/` with subdirectories for each application:
- `git/` - Git configuration
- `zsh/` - Zsh shell configuration
- `vim/` - Vim editor configuration
- `tmux/` - Terminal multiplexer configuration

To add new dotfiles:
1. Create appropriate subdirectory structure
2. Add configuration files
3. Update `/home/kaiho/ghq/github.com/kaiho/ubuntu-dev-setup/roles/dotfiles/tasks/main.yml` to include new stow packages

### Modifying Installation Components

The system uses Ansible tags for modular installation:
- `homebrew` - Package manager setup
- `dev-basic` - Core development tools
- `dev-docker` - Docker and containerization
- `tools-cli` - Command-line utilities
- `tools-git` - Git-related tools
- `dotfiles` - Configuration management

### Testing Changes

Before implementing changes:
1. Test Ansible syntax: `ansible-playbook site.yml --syntax-check`
2. Run in check mode: `ansible-playbook site.yml --check`
3. Test specific components: `ansible-playbook site.yml --tags specific-tag --check`

### Interactive Setup Customization

The `/home/kaiho/ghq/github.com/kaiho/ubuntu-dev-setup/setup.sh` script provides a whiptail-based interface. To modify:
1. Update the options arrays in the script
2. Modify the tag mapping logic
3. Adjust confirmation and execution flow

## Development Workflow

### Making Changes
1. Always test changes in check mode first
2. Use specific tags to test individual components
3. Update documentation when adding new features
4. Maintain the modular structure for flexibility

### Best Practices
- Keep roles focused and single-purpose
- Use meaningful variable names in group_vars
- Maintain consistent file organization
- Test on clean systems when possible
- Document any manual post-installation steps

### Troubleshooting
- Check Ansible logs for detailed error information
- Verify prerequisites (sudo access, internet connection)
- Test individual roles in isolation
- Review variable definitions in group_vars

## File Patterns to Know

- `**/*.yml` - Ansible playbooks and configuration
- `dotfiles/**/*` - User configuration files
- `roles/*/tasks/main.yml` - Ansible role implementations
- `roles/*/vars/main.yml` - Role-specific variables
- `group_vars/all.yml` - Global configuration

This setup provides a robust foundation for automated Ubuntu development environment configuration with flexibility for customization and extension.