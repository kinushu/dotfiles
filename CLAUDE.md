# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Repository Overview

This is a dotfiles repository for macOS that manages development environment configurations. The repository supports two configuration management approaches:
1. **Mitamae** (recommended): Ruby-based configuration management tool for declarative, idempotent setup
2. **Makefile** (legacy): Traditional shell script-based setup

The repository is organized into modular directories with clear separation between configurations, recipes, and maintenance procedures.

## Key Commands

### Mitamae Commands (Recommended)
```bash
./etc/install_mitamae.sh  # Install mitamae binary
./bin/mitamae local roles/darwin.rb --node-json node.json  # Run complete Mitamae setup
```

### Makefile Commands (Legacy)
```bash
make install    # Complete installation (update → deploy → init)
make deploy     # Create symlinks from configs to home directory
make init       # Run initial environment setup
make list       # Show all config files
make test       # Verify environment setup
make update     # Pull latest changes and update submodules
make upgrade    # Update all installed tools and dependencies
make clean      # Remove all symlinks
```

### Testing Changes
When modifying configurations, use `make test` to verify the environment is working correctly. The test script checks for proper tool installations and PATH configuration.

## Architecture

### Directory Structure
- `config/`: All configuration files organized by tool/purpose
  - `shell/`: Bash and Zsh configurations
  - `git/`: Git global configuration
  - `vim/`: Vim configuration
  - `editor/`: Other editor configurations
  - `claude/`: Claude Code configuration (symlinked to ~/.claude/)
- `bin/`: User scripts (symlinked to ~/bin)
- `cookbooks/`: Mitamae recipes for different components
  - `dotfiles/`: Symlink management
  - `mise/`: Version management for multiple languages via mise
- `roles/`: Mitamae role definitions
  - `base.rb`: Cross-platform base configuration
  - `darwin.rb`: macOS-specific configuration
- `etc/`: Legacy setup and maintenance scripts
  - `init/init.sh`: Initial setup logic
  - `test/test.sh`: Environment verification
  - `upgrade/upgrade.sh`: Tool upgrade logic
- `Brewfile`: Homebrew dependencies (90+ formulae, 50+ casks)
- `node.json`: Mitamae configuration variables
- `etc/install_mitamae.sh`: Mitamae bootstrap script

### Configuration Loading Order
1. `.bash_profile` sets up PATH and environment variables
2. `.bashrc` defines aliases and tool configurations
3. `.zshrc` sources `.bash_profile` and configures Oh My Zsh
4. Local customizations via `~/.bashrc.local` (not in version control)

### Version Management
- Multiple languages: Managed by mise (rust-based successor to asdf)
- macOS packages: Managed by Homebrew
- Configuration stored in `config/.config/mise/config.toml`

## Important Patterns

### Working with Mitamae
1. **Adding new cookbooks**: Create a new directory under `cookbooks/` with a `default.rb` file
2. **Modifying configurations**: Edit `node.json` to change platform settings, or `config/.config/mise/config.toml` for language versions
3. **Testing changes**: Run `./bin/mitamae local roles/darwin.rb --node-json node.json` to apply changes idempotently
4. **Adding platform-specific logic**: Use `case node[:platform]` in recipes

### Adding New Configurations
1. Place config files in appropriate `config/` subdirectory
2. For Mitamae: Update relevant cookbook in `cookbooks/`
3. For Makefile: Update `Makefile` if new deployment logic is needed
4. Add any required setup to appropriate cookbook or `etc/init/init.sh`
5. Update tests in `etc/test/test.sh` to verify setup

### Modifying Shell Configuration
- Common settings go in `.bashrc`
- PATH and environment setup goes in `.bash_profile`
- Zsh-specific settings go in `.zshrc`
- Machine-specific settings go in `~/.bashrc.local`

### Security Considerations
- Repository uses git-secrets to prevent AWS credential commits
- Sensitive configurations should go in local files, not version control