# 🚀 Ubuntu Development Environment Setup

An automated, modular setup system for configuring Ubuntu development environments using Ansible with an interactive installer and comprehensive testing suite.

## ✨ Features

- **🎯 Interactive Installation**: User-friendly whiptail interface for component selection
- **🔧 Modular Architecture**: Choose specific development tools and configurations
- **⚡ Automated Configuration**: Ansible-powered installation with proper error handling
- **📁 Dotfiles Management**: GNU Stow-based configuration deployment
- **🛠️ Development Tools**: Git, Docker, Homebrew, and curated CLI utilities
- **🔒 Security-First**: Enhanced security with proper input validation and error handling
- **🧪 Comprehensive Testing**: Automated test suite for reliability and validation

## Documentation

📚 **Comprehensive documentation available in [`docs/`](docs/)**
- Technical documentation and guides
- Bug fix records and troubleshooting
- Development and maintenance notes

## Quick Start

### Interactive Installation (Recommended)

```bash
# Clone this repository
git clone <your-repo-url> ubuntu-dev-setup
cd ubuntu-dev-setup

# Run interactive installer
./setup.sh
```

The interactive installer will:
1. Show a checklist of available components
2. Let you select specific CLI tools to install
3. Confirm your selections before installation
4. Run Ansible with only the selected components

### Manual Installation

```bash
# Run all components
ansible-playbook site.yml

# Run specific components
ansible-playbook site.yml --tags homebrew,dev-basic
ansible-playbook site.yml --tags tools-cli,dotfiles
```

## Installed Tools

### Development Tools (APT)
- git, curl, wget, vim, tmux, zsh, stow
- build-essential, ca-certificates
- Docker CE with Docker Compose

### CLI Tools (Homebrew)
- lsd - Modern ls replacement
- bat - Cat clone with syntax highlighting
- fzf - Fuzzy finder
- ripgrep - Fast text search
- eza - Modern ls replacement
- fd - Simple find alternative
- git-delta - Better diff tool
- lazygit - Git TUI
- gh - GitHub CLI

## Dotfiles Structure

```
dotfiles/
├── git/
│   └── .gitconfig
├── zsh/
│   └── .zshrc
├── vim/
│   └── .vimrc
└── tmux/
    └── .tmux.conf
```

## Available Tags

- `homebrew`: Install Homebrew package manager
- `dev-basic`: Basic development tools (git, curl, vim, etc.)
- `dev-docker`: Docker and Docker Compose
- `tools-cli`: CLI tools (lsd, bat, fzf, ripgrep, etc.)
- `tools-git`: Git tools (lazygit, gh, delta)
- `preferences`: User preferences and shell configuration
- `dotfiles`: Dotfiles management with stow

## Customization

1. **Edit dotfiles**: Modify files in `dotfiles/` directory
2. **Add tools**: Update `group_vars/all.yml`
3. **Custom roles**: Create new roles in `roles/` directory
4. **Modify interactive menu**: Edit `setup.sh` to add/remove options

## Manual Steps After Installation

1. Configure Git user:
   ```bash
   git config --global user.name "Your Name"
   git config --global user.email "your.email@example.com"
   ```

2. Restart shell or source configuration:
   ```bash
   source ~/.zshrc
   ```

3. Log out and back in for Docker group membership to take effect

## Testing

Run the test suite to validate the setup:

```bash
# Test all roles
./tests/test-roles.sh

# Test specific role
./tests/test-roles.sh brew

# Validate syntax only
./tests/validate-syntax.sh
```

## Development

This project includes:

- **CI/CD Pipeline**: GitHub Actions for automated testing
- **Linting**: ansible-lint and yamllint for code quality
- **Testing**: Comprehensive test suite for validation
- **Security**: Enhanced GPG key verification for package sources

## Requirements

- Ubuntu 20.04+ or Debian-based system
- sudo privileges
- Internet connection