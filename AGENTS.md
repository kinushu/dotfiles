# AGENTS.md

This file provides guidance to AI systems when working with code in this repository.

## Repository Overview

This is a dotfiles repository for macOS and Ubuntu that manages development environment configurations. OS-specific setup is branched via Mitamae roles (see "OS Detection and Privilege Boundaries" below). The repository supports two configuration management approaches:
1. **Mitamae** (recommended): Ruby-based configuration management tool for declarative, idempotent setup
2. **Makefile** (legacy): Traditional shell script-based setup

The repository is organized into modular directories with clear separation between configurations, recipes, and maintenance procedures.

## Key Commands

### Mitamae Commands (Recommended)
```bash
./etc/install_mitamae.sh  # Install mitamae binary (auto-detects OS/arch)

# macOS
./bin/mitamae local roles/darwin.rb --node-json node.json

# Ubuntu (system role needs sudo; user role must NOT be run with sudo)
sudo ./bin/mitamae local roles/ubuntu_system.rb --node-json node.json
./bin/mitamae local roles/ubuntu_user.rb --node-json node.json
```

### Makefile Commands (Legacy)
```bash
make install    # Complete installation (update → deploy → init)
make deploy     # Create symlinks from configs to home directory (OS common, no sudo)
make init       # Run initial environment setup (auto-detects OS; on Ubuntu it runs the sudo-required system role, then the normal-user role — see "OS Detection and Privilege Boundaries" below)
make list       # Show all config files
make test       # Verify environment setup
make update     # Pull latest changes and update submodules
make upgrade    # Update all installed tools and dependencies
make clean      # Remove all symlinks
make deploy-dry-run  # Preview symlink changes without applying
make check-links     # Verify all symlinks are valid
```

### Testing Changes
When modifying configurations, use `make test` to verify the environment is working correctly. The test script checks for proper tool installations and PATH configuration.

## Architecture

### Directory Structure
- `config/`: Template dotfiles tracked with their leading dots so they mirror the home directory layout (key files include `.bash_profile`, `.bashrc`, `.zshrc`, `.vimrc`, `.gitignore_global`, `.gemrc`)
  - `.agents/`: Agent Skills standard directory containing shared skills and global AGENTS.md
  - `.claude/`: Claude Code settings and command definitions. `.claude/commands` and `.claude/skills` are each expanded to `~/.claude/` via `directory_links` (e.g. `~/.claude/skills → config/.claude/skills`). The `.claude/skills` layer is a Claude Code extension layer, distinct from the `.agents/skills` canonical bodies (see Agent Skills below).
  - `.codex/`: Agent-facing guidance specific to this repository
  - `.config/`: Application configs such as `mise/config.toml` (language and runtime versions) and `starship.toml` (prompt configuration)
  - `bin/`: User utility scripts (linked to `~/bin` via directory_links). Contains `md-open`, `create_sandbox_project`.
- `bin/`: Infrastructure scripts for repository internal use (mitamae, setup, scheduled tasks, etc.)
- `cookbooks/`: Mitamae recipes
  - `dotfiles/`: Symlink management for tracked dotfiles (OS common)
  - `mise/`: mise binary installation and tool version management (OS common; on macOS the binary comes via Homebrew, on Ubuntu via mise's official installer)
  - `homebrew/`: Homebrew installation and the individual `brew install` package list (macOS only)
  - `macos_defaults/`: `defaults write` system settings such as disabling `.DS_Store` on network shares (macOS only)
  - `apt/`: apt package installation — git, tig, zsh, build-essential, curl, vim, less, tree, jq, fzf, ripgrep, trash-cli, locales, ca-certificates, unzip (Ubuntu only, requires sudo)
  - `locale/`: `locale-gen` / `update-locale` setup for UTF-8 locales (Ubuntu only, requires sudo)
  - `zsh/`: oh-my-zsh installation via `git clone` (OS common, runs as a normal user; `chsh` is handled separately — see roles below)
  - `mise_tools/`: Ubuntu-specific CLI tools not available via apt (eza, starship, ghq, yq, peco, jump), installed through mise's `conf.d` mechanism to avoid polluting the dotfiles-managed `config.toml` symlink (Ubuntu only)
- `roles/`: Mitamae role definitions
  - `base.rb`: OS-common, user-level setup (creates base directories under `$HOME` only; must not be run with sudo)
  - `darwin.rb`: macOS entry point — includes `base` + `dotfiles` + Xcode Command Line Tools + `homebrew` + `macos_defaults` + `mise`
  - `ubuntu_system.rb`: Ubuntu entry point requiring sudo — includes `apt` + `locale` + `chsh` (changes the login shell to zsh), plus a stub extension point for `node[:profile] == "desktop"`
  - `ubuntu_user.rb`: Ubuntu entry point for a normal user (no sudo) — includes `base` + `dotfiles` + `zsh` (oh-my-zsh) + `mise` + `mise_tools`
- `etc/`: Legacy setup and maintenance scripts
  - `init/init.sh`: Initial setup logic. Detects the OS via `etc/lib/detect_os.sh` and runs the matching role(s) before falling back to shared tail steps (git config, git-secrets, oh-my-zsh version check, `ghq get`, etc.)
  - `lib/detect_os.sh`: OS/arch detection library, meant to be `source`d. Provides `detect_platform` (returns `darwin` / `ubuntu`, exits non-zero on unsupported OS) and `detect_arch` (returns `amd64` / `arm64`, exits non-zero on unsupported architecture)
  - `test/test.sh`: Environment verification
  - `upgrade/upgrade.sh`: Tool upgrade workflow
- `Brewfile`: Homebrew dependencies (90+ formulae / 50+ casks)
- `node.json`: Mitamae node variables. Defines `directory_links` — a list of directories under `config/` that are symlinked as directories to `~/` (currently `.agents`, `.claude/commands`, `.claude/skills`, `bin`). This enables sharing configurations across the home directory without individual file symlinks. `node.json` intentionally does **not** define `platform` / `arch` keys — OS is auto-detected instead, via mitamae/specinfra's `node[:platform]` inside recipes and via `etc/lib/detect_os.sh`'s `detect_platform`/`detect_arch` in entry scripts.
- `docs/adr/`: Architecture Decision Records in [MADR](https://adr.github.io/madr/) format. Check existing ADRs before making architectural changes. See `docs/adr/README.md` for the full list and naming conventions.
- `etc/install_mitamae.sh`: Mitamae bootstrap script (uses `detect_platform`/`detect_arch` to fetch the correct binary, with checksum verification)

### Configuration Loading Order
1. `.bash_profile` sets up PATH and environment variables
2. `.bashrc` defines aliases and tool configurations
3. `.zshrc` sources `.bash_profile` and configures Oh My Zsh
4. Local customizations via `~/.bashrc.local` (not in version control)

### Version Management
- Multiple languages: Managed by mise (rust-based successor to asdf)
- macOS packages: Managed by Homebrew (`cookbooks/homebrew` installs the binary plus an individual `brew install` package list)
- Ubuntu packages: Managed by apt for OS packages/build dependencies/shell basics (`cookbooks/apt`); CLI tools not packaged in apt are installed via mise's `conf.d` mechanism (`cookbooks/mise_tools`) instead of Homebrew on Linux
- Configuration stored in `config/.config/mise/config.toml`

### OS Detection and Privilege Boundaries
- `etc/lib/detect_os.sh` provides `detect_platform` (`darwin` / `ubuntu`) and `detect_arch` (`amd64` / `arm64`); it is `source`d by entry scripts (`etc/init/init.sh`) and used by `etc/install_mitamae.sh` to fetch the right binary. Unsupported OS/arch combinations exit with a non-zero status rather than silently falling back.
- macOS: `etc/init/init.sh` detects `darwin` and runs `bin/mitamae local roles/darwin.rb --node-json node.json` as a normal user (individual cookbooks such as `homebrew` invoke `sudo` internally only where required, e.g. `/usr/local` ownership).
- Ubuntu: `etc/init/init.sh` detects `ubuntu` and runs, in order, `sudo bin/mitamae local roles/ubuntu_system.rb --node-json node.json` (system changes: apt / locale / chsh — requires root) followed by `bin/mitamae local roles/ubuntu_user.rb --node-json node.json` (user changes: dotfiles / mise / zsh — must run as the normal user so `$HOME` stays owned by that user, not root).
- Desktop profile: `node[:profile] == "desktop"` is the extension point for GUI-only additions (fonts/IME/gsettings). It is currently a guarded no-op stub in `roles/ubuntu_system.rb`; the `server` profile (default) skips it entirely.
- `etc/deploy.sh` (invoked by `make deploy`) is OS-independent and requires no sudo: it only creates dotfiles symlinks and expands templates, regardless of platform.

### Agent Skills

Reusable AI agent skills follow the [Agent Skills](https://agentskills.io/) open standard (SKILL.md format) and are intentionally organized into two layers. Both layers are expanded to the home directory separately via `node.json`'s `directory_links` (there is no symlink from `~/.claude/skills` to `~/.agents/skills`):

- `config/.agents/skills/` — the canonical skill bodies, shared across all tools (Codex CLI, Gemini CLI, Cursor, GitHub Copilot, and Claude Code). Expanded as `~/.agents/skills → config/.agents/skills`.
- `config/.claude/skills/` — the Claude Code extension layer. Expanded separately as `~/.claude/skills → config/.claude/skills`. It contains: (a) thin wrappers for the shared skills, each of which reads the canonical body at `~/.agents/skills/<name>/SKILL.md` first and then adds Claude Code specific steps; (b) Claude Code only skills (e.g. `empirical-prompt-tuning`, `implement-by-codex`, `review-by-codex`); and (c) `scenarios/` evaluation fixtures used for skill quality assessment.

The wrappers deliberately read the `.agents` canonical body before layering on tool specific instructions, so the shared logic stays single-sourced while Claude Code can extend it. Do not collapse the two layers into a single directory or alias them together: doing so would break the wrapper layer and the `scenarios/` fixtures.

Each skill is a directory containing a `SKILL.md` file with YAML frontmatter (`name`, `description`) and markdown instructions.

## Important Patterns

### Working with Mitamae
1. **Adding new cookbooks**: Create a new directory under `cookbooks/` with a `default.rb` file
2. **Modifying configurations**: Edit `node.json` to change platform settings, or `config/.config/mise/config.toml` for language versions
3. **Testing changes**: Run `./bin/mitamae local roles/darwin.rb --node-json node.json` to apply changes idempotently
4. **Adding platform-specific logic**: Use `case node[:platform]` in recipes (see `roles/darwin.rb`) for mitamae-level OS branching; use `detect_platform`/`detect_arch` from `etc/lib/detect_os.sh` for entry-script-level OS branching (see `etc/init/init.sh`)

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

## Code Style Guidelines

- This codebase primarily uses Ruby and Markdown. Prefer Ruby idioms and follow existing code style when making edits.
- **Ruby** (Mitamae recipes): Use Mitamae DSL idioms (`execute`, `directory`, `link` block forms). Add `# frozen_string_literal: true` magic comment where appropriate.
- **Shell** (bash/zsh scripts): Quote all variables. Use `#!/bin/bash` for portable scripts, `#!/bin/zsh` for zsh-specific features.
- **Naming**: Cookbook directories use `snake_case`. Skill names use `kebab-case`.
- **Comments and logs**: Write in standard Japanese (日本語標準語).

## AI Agent Guidelines

These guidelines apply to all AI coding assistants working in this repository:

- If requirements or specifications are unclear, stop and ask the user before proceeding.
- Never use force flags (`-f`, `--force`) in commands.
- Verify changes with `make test` or `make deploy-dry-run` before applying destructive operations.
- Sensitive data (API keys, tokens, credentials) must never be committed. Use local files excluded via `.gitignore`.
