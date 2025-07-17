# setup_project

![GitHub release (latest by date)](https://img.shields.io/github/v/release/DavitTec/setup_project)
![GitHub Actions Workflow Status](https://github.com/DavitTec/setup_project/workflows/Lint/badge.svg)
![Shell](https://img.shields.io/badge/language-Bash-blue)
![VSCode](https://img.shields.io/badge/IDE-VSCode-green)
![GitHub License](https://img.shields.io/github/license/DavitTec/setup_project)

## Description

`setup_project.sh` is a Bash script designed to automate the initialisation of development projects, supporting multiple languages (Node.js, Python, Bash, Perl, etc.) with a focus on reproducible, dependency management, and VSCode integration. It parses project details from the directory path or a YAML config (`initial_config.yaml`), sets up Git, generates essential files (README, main.sh, .vscode configs), and handles backups and logging.

`setup_project.sh` automates the initialisation of development projects, much like baking a cake: you choose a recipe (e.g., Node.js static website, Bash script) and the script sets up the project structure, dependencies, Git, and VSCode configurations. Recipes are YAML files stored in `./recipes/`, defining project metadata, files, and settings.

## Version

0.3.0

---

<!-- START doctoc generated TOC please keep comment here to allow auto update -->

<!-- END doctoc generated TOC please keep comment here to allow auto update -->

## Features

- **Multi-Language Support**: Infers project language (Node.js, Python, Bash, Perl, multi) from path (e.g., `/opt/davit/development/node_recipe_website_v0.1/`).
- **YAML Configuration**: Uses `initial_config.yaml` for customisation project settings (name, version, dependencies, etc.).
- **VSCode Integration**: Generates `.vscode/settings.json` and `launch.json` for debugging.
- **Git Setup**: Initialises Git with templates from a custom fork (`DavitTec/gitignore`) or inline defaults.
- **Logging**: Configurable verbosity (`off`, `on`, `debug`) with timestamped logs to `logs/`.
- **Backup**: Archives script versions to `archives/`.
- **Extensible**: Planned molecularity for external logging and backup scripts.

## Installation

1. Clone the repository:

   ```bash
   git clone https://github.com/DavitTec/setup_project.git
   cd setup_project
   ```

2. Ensure dependencies (`git`, `yq`) are installed:

   ```bash
   sudo apt update && sudo apt install -y git yq
   sudo npm install -g pnpm
   ```

3. Run the script:

   ```bash
   ./scripts/setup_project.sh or
   ./scripts/setup_project.sh --recipe ./recipes/node_pnpm_html_website.yaml
   ```

## Usage

Download into a new folder with a subfolder "./scripts"

```bash
./scripts/setup_project.sh [options]
```

then when config file is created

- Initialize: `./main.sh -init`
- Install: `./main.sh -i`

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

## Project Folder Naming Structure

To ensure reproducibility, target project folders must follow this naming convention:

```bash
<language>_<package_manager>_<project_type>_v<version>
```

- **language**: Primary programming language (e.g., `node`, `python`, `bash`, `perl`).
- **package_manager**: Dependency manager (e.g., `pnpm`, `npm`, `pip`, `none`).
- **project_type**: Type of project (e.g., `html_website`, `cli`, `api`).
- **version**: Project version (e.g., `v0.1.0`).

**Examples**:

- `node_pnpm_html_website_v0.1.0`
- `python_pip_cli_v0.2.0`
- `bash_none_script_v0.1.0`

The script infers project details (name, version, language, package manager) from the directory name if not specified in the recipe.

## Creating a New Recipe

Recipes are YAML files stored in `./recipes/` that define project settings, files, and dependencies. To create a new recipe:

1. Copy an existing recipe (e.g., `./recipes/default.yaml`) or start from scratch.
2. Define the following sections:
   - `project`: Metadata (name, version, author, primary_language, package_manager).
   - `git`: Git initialization settings (init, template).
   - `env`: Environment variables.
   - `vscode`: VSCode extensions and settings.
   - `dependencies`: Global and project-specific dependencies.
   - `logging`: Log verbosity and path.
   - `backup`: Backup settings.
   - `files`: Files to generate with placeholders (e.g., `{{project.name}}`).

**Example Recipe** (`./recipes/node_pnpm_html_website.yaml`):

```yaml
project:
  name: html_website
  version: 0.1.0
  author: davit
  primary_language: node
  package_manager: pnpm
  project_type: html_website
git:
  init: true
  template: Node
env:
  NODE_ENV: development
vscode:
  extensions:
    - esbenp.prettier-vscode
    - dbaeumer.vscode-eslint
dependencies:
  global:
    - git
    - yq
    - pnpm
  project:
    - prettier
    - eslint
    - serve
logging:
  verbosity: debug
  path: logs/
backup:
  enabled: true
  path: archives/
files:
  - path: index.html
    content: |
      <!DOCTYPE html>
      <html>
      <head><title>My Website</title></head>
      <body><h1>Hello, World!</h1></body>
      </html>
  - path: package.json
    content: |
      {
        "name": "{{project.name}}",
        "version": "{{project.version}}",
        "scripts": {
          "start": "serve ."
        }
      }
```

## Cloning Recipes from GitHub

**TODO**: Pre-prepared recipes are available at [https://github.com/DavitTec/setup_project_recipes](https://github.com/DavitTec/setup_project_recipes). To clone:

```bash
git clone https://github.com/DavitTec/setup_project_recipes.git ./recipes
```

## Testing

**TODO**: Tests are located in `./scripts/tests/` and run using BATS:

```bash
sudo apt install bats
bats scripts/tests/node_pnpm_html_website.bats
```

## Changelog

[CHANGELOG.md](CHANGELOG.md)

## Contributing

1. Fork the repo.
2. Create a feature branch (`git checkout -b feature/xyz`).
3. Commit with [Conventional Commits](https://www.conventionalcommits.org/).
4. Submit a pull request.

## License

MIT License. See [LICENSE](LICENSE) for details.

## Contact

David Mullins - [david@davit.ie](mailto:david@davit.ie) - [https://davit.ie](https://davit.ie)

Project Link: [https://github.com/DavitTec/setup_project](https://github.com/DavitTec/setup_project)

---

**Notes**:

- **GitHub Actions**: Below is a basic workflow for linting with ShellCheck and testing (placeholder for future tests).
- **Testing**: Placeholder added; see testing recommendations below.

---
