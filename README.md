# setup_project

![GitHub release (latest by date)](https://img.shields.io/github/v/release/DavitTec/setup_project)
![GitHub license](https://img.shields.io/github/license/DavitTec/setup_project)
![GitHub Actions Workflow Status](https://github.com/DavitTec/setup_project/workflows/Lint/badge.svg)
![Shell](https://img.shields.io/badge/language-Bash-blue)
![VSCode](https://img.shields.io/badge/IDE-VSCode-green)

## Description

`setup_project.sh` is a Bash script designed to automate the initialization of development projects, supporting multiple languages (Node.js, Python, Bash, Perl, etc.) with a focus on reproducibility, dependency management, and VSCode integration. It parses project details from the directory path or a YAML config (`initial_config.yaml`), sets up Git, generates essential files (README, main.sh, .vscode configs), and handles backups and logging.

## Version

0.2.5

## Features

- **Multi-Language Support**: Infers project language (Node.js, Python, Bash, Perl, multi) from path (e.g., `/opt/davit/development/node_recipe_website_v0.1/`).
- **YAML Configuration**: Uses `initial_config.yaml` for customizable project settings (name, version, dependencies, etc.).
- **VSCode Integration**: Generates `.vscode/settings.json` and `launch.json` for debugging.
- **Git Setup**: Initializes Git with templates from a custom fork (`DavitTec/gitignore`) or inline defaults.
- **Logging**: Configurable verbosity (`off`, `on`, `debug`) with timestamped logs to `logs/`.
- **Backup**: Archives script versions to `archives/`.
- **Extensibility**: Planned modularity for external logging and backup scripts.

## Installation

1. Clone the repository:

   ```bash
   git clone https://github.com/DavitTec/setup_project.git
   cd setup_project

2. Ensure dependencies (`git`, `yq`) are installed:

   ```bash
   sudo apt update && sudo apt install -y git yq
   ```

3. Run the script:

   ```bash
   ./scripts/setup_project.sh
   ```

## Usage

Download into a new folder with a subfolder "./scripts"

```bash
./scripts/setup_project.sh [options]
```

then when config file is created

```bash
- Initialize: ./main.sh -init
- Install: ./main.sh -i
```bash

**Options**:

- `-h, --help`: Show help message
- `-v, --version`: Show script version
- `-b, --backup`: Backup script to `archives/`
- `-s, --vscode`: Setup VSCode configuration
- `--config-path <path>`: Specify custom `initial_config.yaml` path
- `--verbose <off|on|debug>`: Set logging verbosity (default: on)

**Example**:

```bash
# Full setup in /opt/davit/development/test_setup
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
```

If missing, it’s generated based on the directory path.

## Contributing

Contributions are welcome! Please:

1. Fork the repo.
2. Create a feature branch (`git checkout -b feature/xyz`).
3. Commit with [Conventional Commits](https://www.conventionalcommits.org/).
4. Submit a pull request.

## Testing

(TODO: Add testing instructions once implemented.)

## Changelog

(TODO: Add CHANGELOG.md with versioning details.)

## License

MIT License. See [LICENSE](LICENSE) for details.

## Contact

David Mullins - [david@davit.ie](mailto:david@davit.ie) - [https://davit.ie](https://davit.ie)

Project Link: [https://github.com/DavitTec/setup_project](https://github.com/DavitTec/setup_project)

**Notes**:

- **Badges**: Added GitHub release, license, workflow status, and language/IDE badges. Update URLs when the repo is live.
- **GitHub Actions**: Below is a basic workflow for linting with ShellCheck and testing (placeholder for future tests).
- **Changelog**: Placeholder added; see below for setup.
- **Testing**: Placeholder added; see testing recommendations below.

---
