# Project summary

Comprehensive Project Summary for `setup_project` (v0.2.5)

<!-- START doctoc generated TOC please keep comment here to allow auto update -->
<!-- DON'T EDIT THIS SECTION, INSTEAD RE-RUN doctoc TO UPDATE -->

**Table of Contents**

- [Overview](#overview)
- [Features](#features)
  - [Key Features](#key-features)
  - [Project Structure](#project-structure)
  - [Current Status](#current-status)
- [GitHub Actions](#github-actions)
- [TODO](#todo)
  - [Missed Items (Not in README.md)](#missed-items-not-in-readmemd)
  - [Recommendations for Next Phase (Testing)](#recommendations-for-next-phase-testing)
- [Installation](#installation)
- [Usage](#usage)
- [Configuration](#configuration)
- [Testing](#testing)
- [Contributing](#contributing)
- [Changelog](#changelog)
- [Documentation](#documentation)
- [License](#license)
- [Contact](#contact)
- [Notes](#notes)
- [References](#references)

<!-- END doctoc generated TOC please keep comment here to allow auto update -->

---

## Overview

The `setup_project` repository, hosted at [https://github.com/DavitTec/setup_project](https://github.com/DavitTec/setup_project), provides a Bash script (`setup_project.sh`) designed to streamline the initialization of development projects across multiple programming languages (Node.js, Python, Bash, Perl, and multi-language setups) with a focus on reproducibily, dependency management, and VSCode integration.

The script automates the creation of essential project files, configures development environments through a YAML-based configuration system (`initial_config.yaml`). It emphasise molecularity, extensible, and integration with tools like VSCode, Git, and package managers (e.g., `pnpm`, `pip`). It parses project details from the directory path or a YAML config (`initial_config.yaml`), sets up Git, generates essential files (README, main.sh, .vscode configs), and handles backups and logging.

The project is licensed under MIT and is in active development, with a focus on robust setup processes for small to monorepo projects.

## Features

- **Multi-Language Support**
- **YAML Configuration**
- **VSCode Integration**
- **Git Setup**
- **Logging**
- **Backup**
- **Extensible**
- **Dependencies**

### Key Features

- **Multi-Language Support**: Infers project language and framework (e.g., Node.js with Next.js, Python, Bash, Perl, or multi-language) from the directory path (e.g., `/opt/davit/development/node_recipe_website_v0.1/`) or YAML config.
- **YAML-Driven Configuration**: Uses `initial_config.yaml` to define project metadata (name, version, author), dependencies, Git settings, and environment variables. Generates a default config if none exists.
- **VSCode Integration**: Creates `.vscode/settings.json` and `launch.json` for debugging, with checks for `code` or `code-insiders` and skips if already present.
- **Git Initialization**: Sets up Git with templates fetched from a custom fork (`https://github.com/DavitTec/gitignore`) or inline defaults, appending `archives/` to `.gitignore`.
- **Logging System**: Configurable verbosity (`off`, `on`, `debug`) with timestamped logs to `logs/` and no-newline support for chained messages. Logs are archived on reset if `CLEAR_LOGS=true`.
- **Backup Mechanism**: Archives script versions to `archives/setup_project_vX.Y.Z.sh`, with plans to extend to other files (e.g., logs, configs).
- **Dependency Management**: Installs global tools (e.g., `git`, `yq`) via `apt` (with partial OS detection for Linux/macOS) and project-specific dependencies (e.g., `prettier`, `conventional-changelog-cli` for Node.js).
- **Extensibility**: Designed for future modularity with external scripts for logging, backup, and Git actions (planned for separate repositories).
- **Reproducibility**: Ensures consistent setups via path inference, YAML configs, and versioned backups.
- **Error Handling**: Uses `set -euo pipefail` and includes checks for command failures (e.g., `git init`, `curl`, `yq` parsing).

### Project Structure

```bash
setup_project/
├── scripts/
│   └── setup_project.sh  # Main script (v0.2.5)
├── logs/                 # Timestamped logs (e.g., setup_project_20250714.log)
├── archives/             # Versioned backups (e.g., setup_project_v0.2.4.sh)
├── .vscode/              # VSCode configs (settings.json, launch.json)
├── README.md             # Project documentation
├── main.sh               # Generated control script
├── .gitignore            # Gitignore template
└── initial_config.yaml   # Optional YAML config
```

### Current Status

- **Version**: 0.2.5 (stable for basic use cases).
- **License**: MIT.
- **Status**: Development, with ongoing work on testing, modularity, and YAML expansion.
- **Known Limitations**:
  - Testing framework missing (planned with `bats`; TODO #025).
  - Limited OS support (Linux/macOS; Windows pending, TODO #014).
  - YAML usage is minimal (more fields can be leveraged; TODO #005, #006).
  - Inline logging/backup functions; external scripts planned (TODO #019, #020).
  - No changelog generation (planned; TODO #024).
- **Future Plans**:
  - Separate repositories for logging, backup, and Git actions.
  - Testing phase with unit tests and dry-run mode.
  - Monorepo support exploration (deferred for simplicity).
  - Enhanced YAML usage for Git remotes, env vars, and VSCode settings.

-

## GitHub Actions

A basic workflow (`.github/workflows/lint-and-test.yml`) lints with ShellCheck and runs the script, verifying generated files. Expand for unit tests (TODO #025).

## TODO

See also main ( [Todo.md](Todo.md) )

### Missed Items (Not in README.md)

- **Manpage Link**: The README omits the manpage link (`https://davit.ie/docs/<project>`; TODO #021). Add a section or verify the URL.
- **Testing Instructions**: Placeholder only; needs `bats` setup instructions.
- **Changelog**: Placeholder only; needs `CHANGELOG.md` generation.
- **Dependencies**: README doesn’t mention `pnpm` for Node.js projects or `pip` for Python.
- **External Scripts**: No mention of planned modularity (logging, backup).
- **Badges**: Missing a badge for test coverage (add once tests exist).

---

### Recommendations for Next Phase (Testing)

1. **Testing Setup (TODO #025)**:
   - Install `bats` (`sudo apt install bats`).
   - Create `tests/setup_project.bats` (as shown previously).
   - Add tests for each function (e.g., `backup`, `setup_vscode`, `generate_readme`).
   - Update GitHub Actions to run `bats tests/setup_project.bats`.

2. **Dry-Run Mode (TODO #010)**:
   - Add `--dry-run` flag to log actions without executing file writes or commands.
   - Example:

     ```bash
     main() {
       local dry_run=false
       while [[ $# -gt 0 ]]; do
         case $1 in
           --dry-run) dry_run=true ;;
           # ... other cases ...
         esac
         shift
       done
       if "$dry_run"; then
         log "Dry-run: Simulating setup"
         # Mock file writes, e.g., log instead of `cat > file`
       fi
       # ... rest of main ...
     }
     ```

3. **External Scripts (TODO #019, #020)**:
   - Start new repositories (e.g., `DavitTec/logging`, `DavitTec/backup`) using `setup_project.sh`.
   - Develop `logging.sh` and `backup.sh` with interfaces compatible with current inline functions.
   - Source them in `setup_project.sh` if present (e.g., `[[ -f "./scripts/logging.sh" ]] && source ./scripts/logging.sh`).

4. **Branching Strategy**:
   - Use `main` for stable releases (e.g., v0.2.5).
   - Create feature branches (e.g., `feature/testing`, `feature/external-logging`) for testing and modularity.
   - Avoid monorepo for now to keep complexity low; revisit after testing phase.

5. **Changelog (TODO #024)**:
   - Add `generate_changelog` function (as suggested previously).
   - Create `CHANGELOG.md` with initial entry:

     ```markdown
     # Changelog

     ## [0.2.5] - 2025-07-14

     - Initial release: Automated project setup with YAML, Git, VSCode, and logging.
     ```

---

## Installation

1. Clone the repository:

   ```bash
   git clone https://github.com/DavitTec/setup_project.git
   cd setup_project
   ```

2. Ensure dependencies:

   ```bash
   sudo apt update && sudo apt install -y git yq
   # For Node.js projects:
   sudo npm install -g pnpm
   ```

3. Run the script:

   ```bash
   ./scripts/setup_project.sh
   ```

## Usage

```bash
./scripts/setup_project.sh [options]
```

**Options**:

- `-h, --help`: Show help message
- `-v, --version`: Show script version
- `-b, --backup`: Backup script to `archives/`
- `-s, --vscode`: Setup VSCode configuration
- `--config-path <path>`: Specify custom `initial_config.yaml` path
- `--verbose <off|on|debug>`: Set logging verbosity (default: on)

**Example**:

```bash
# Full setup
./scripts/setup_project.sh
# Setup only VSCode
./scripts/setup_project.sh -s
# Run with debug logging
./scripts/setup_project.sh --verbose debug
```

## Configuration

The script uses `initial_config.yaml` for settings. Example:

```yaml
project:
  name: test_setup
  version: 0.1.0
  author: davit
  primary_language: bash
git:
  init: true
  template: bash
env:
  NODE_ENV: development
vscode:
  extensions: [esbenp.prettier-vscode]
```

If missing, it’s generated based on the directory path.

## Testing

Testing is planned (using `bats`). Install `bats` and run:

```bash
sudo apt install bats
bats tests/setup_project.bats
```

## Contributing

Contributions are welcome! Please:

1. Fork the repo.
2. Create a feature branch (`git checkout -b feature/xyz`).
3. Commit with [Conventional Commits](https://www.conventionalcommits.org/).
4. Submit a pull request.

## Changelog

See [CHANGELOG.md](CHANGELOG.md) for version history (to be implemented).

## Documentation

Manpage (WIP): [https://davit.ie/docs/setup_project](https://davit.ie/docs/setup_project) (TODO)

## License

MIT License. See [LICENSE](LICENSE) for details.

## Contact

David Mullins - [david@davit.ie](mailto:david@davit.ie) - [https://davit.ie](https://davit.ie)

Project Link: [https://github.com/DavitTec/setup_project](https://github.com/DavitTec/setup_project)

---

## Notes

- **Push to GitHub**: Your v0.2.5 script is stable for release. Push with `README.md`, `.github/workflows/lint-and-test.yml`, and `LICENSE`. Tag as `v0.2.5`.
- **Testing Phase**: Open a new Grok conversation for testing (`feature/testing` branch). Focus on `bats` tests and dry-run mode.
- **External Scripts**: Start `DavitTec/logging` and `DavitTec/backup` repos using `setup_project.sh`. Define clear interfaces (e.g., `log` function with same options).
- **YAML**: Add `generate_env` and `generate_changelog` to leverage more YAML fields.
- **Monorepo**: Defer until testing and external scripts are stable.

This summary and updated README cover all aspects of the project, including missed items. You’re ready to push and move to the testing phase!

---

## References
