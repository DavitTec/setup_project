# Testing Phases

Designing the testing phase for `setup_project` (v0.2.5) is well thought out, and the recipe analogy is a great way to conceptualize the modular setup process. Below, I’ll address your requirements, refine your assumptions, and provide a clear plan for developing test scripts, GitHub Actions, and documentation for a Node.js static website using `pnpm` as the first recipe. I’ll also formalize the folder naming protocol, recipe structure, and testing workflow, ensuring alignment with the project summary provided.

---

## Plan for Testing Phase and Recipe Design

### 1. Folder Naming Protocol and Syntax

To ensure consistency and reproducibility, the folder naming protocol for test projects should follow a structured convention that encodes key metadata about the project. This aligns with the `setup_project.sh` script’s ability to infer details from the directory path.

**Proposed Naming Convention**:

```bash
./tests/<language>_<package_manager>_<project_type>_v<version>/
```

- **language**: Primary programming language (e.g., `node`, `python`, `bash`, `perl`).
- **package_manager**: Tool used for dependency management (e.g., `pnpm`, `npm`, `pip`, `none` for Bash/Perl).
- **project_type**: Type of project (e.g., `html_website`, `markdown_website`, `cli`, `api`).
- **version**: Version of the test project (e.g., `v0.1.0`).

**Examples**:

- `./tests/node_pnpm_html_website_v0.1.0/`
- `./tests/node_pnpm_markdown_website_v0.1.0/`
- `./tests/python_pip_cli_v0.1.0/`
- `./tests/bash_none_script_v0.1.0/`

**Rationale**:

- Matches the script’s path inference logic (e.g., `/opt/davit/development/node_recipe_website_v0.1/`).
- Ensures unique, descriptive test directories.
- Facilitates automation in test scripts and GitHub Actions by parsing components.
- Versioning allows tracking test project evolution.

**Recommendation**:

- Enforce this convention in `setup_project.sh` by validating the directory name during execution (e.g., regex check for `<language>_<package_manager>_<project_type>_v[0-9]+\.[0-9]+\.[0-9]+`).
- Update `initial_config.yaml` generation to reflect parsed components (e.g., set `project.primary_language=node`, `project.package_manager=pnpm`).

---

### 2. Recipe Design and Storage

The concept of "recipes" is an excellent way to modularize project configurations. Each recipe is a YAML file defining the project setup, stored in `./recipes/`, with corresponding documentation in `./docs/recipes/`.

**Recipe Storage**:

- **Location**: `./recipes/<language>_<package_manager>_<project_type>.yaml`
- **Examples**:
  - `./recipes/node_pnpm_html_website.yaml`
  - `./recipes/node_pnpm_markdown_website.yaml`
  - `./recipes/generic_bash.yaml` (default for generic setups)
- **Purpose**: Define project metadata, dependencies, Git settings, VSCode extensions, and other configurations specific to the project type.

**Generic Recipe Example** (`./recipes/generic_bash.yaml`):

```yaml
project:
  name: generic_project
  version: 0.1.0
  author: davit
  primary_language: bash
  package_manager: none
git:
  init: true
  template: bash
env:
  SHELL: /bin/bash
vscode:
  extensions:
    - timonwong.shellcheck
    - foxundermoon.shell-format
dependencies:
  global:
    - git
    - yq
  project: []
logging:
  verbosity: on
  path: logs/
backup:
  enabled: true
  path: archives/
```

**Node.js Static Website Recipe Example** (`./recipes/node_pnpm_html_website.yaml`):

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
  template: node
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

**Key Features of Recipes**:

- **Templating**: Use placeholders (e.g., `{{project.name}}`) for dynamic substitution by `setup_project.sh`.
- **Extensibility**: Allow specification of files to generate (e.g., `index.html`, `package.json`).
- **Dependencies**: Split into `global` (system-wide, e.g., `pnpm`) and `project` (project-specific, e.g., `prettier`).
- **VSCode Integration**: Specify extensions and settings tailored to the project type.

**Documentation** (`./docs/recipes/generic_bash_recipe.md`):

````markdown
# Generic Bash Recipe

This recipe defines a generic Bash project setup for `setup_project.sh`.

## Overview

- **Purpose**: Initialize a Bash project with Git, logging, and VSCode support.
- **File**: `./recipes/generic_bash.yaml`
- **Use Case**: Simple scripts or CLI tools.

## Structure

- **Project Metadata**: Name, version, author.
- **Git**: Initializes with a Bash-specific `.gitignore`.
- **VSCode**: Configures `settings.json` with ShellCheck and shell-format extensions.
- **Dependencies**: Requires `git` and `yq`.
- **Logging**: Enabled with `on` verbosity.
- **Backup**: Archives to `archives/`.

## Usage

```bash
./scripts/setup_project.sh --recipe ./recipes/generic_bash.yaml

```

## Customization

- Edit `project.name` and `project.version` in the YAML.
- Add environment variables under `env`.
- Specify additional VSCode extensions under `vscode.extensions`.

## Testing

Tests for this recipe are located in `./tests/bash_none_script_v0.1.0/`.
Run with:

```bash
bats tests/setup_project.bats
```

**Recommendation**:

- Add a `--recipe <path>` flag to `setup_project.sh` to specify a recipe file (default: `./recipes/generic_bash.yaml`).
- Update `setup_project.sh` to merge recipe settings with directory-inferred settings, prioritizing recipe values.
````

### 3. Testing Structure and Workflow

Your proposed testing structure is solid, and I’ll refine it to ensure clarity and alignment with the recipe approach.

**Testing Directory Structure**:

```shell
setup_project/
├── scripts/
│   └── setup_project.sh
│   └── tests/
│       ├── node_pnpm_html_website.bats
│       ├── node_pnpm_markdown_website.bats
│       └── generic_bash.bats
├── tests/
│   ├── node_pnpm_html_website_v0.1.0/
│   │   ├── scripts/setup_project.sh
│   │   ├── config.yaml
│   │   ├── logs/
│   │   └── archives/
│   ├── node_pnpm_markdown_website_v0.1.0/
│   └── bash_none_script_v0.1.0/
├── logs/
│   └── tests/
│       ├── node_pnpm_html_website_v0.1.0_20250715.log
│       └── generic_bash_20250715.log
├── recipes/
│   ├── generic_bash.yaml
│   ├── node_pnpm_html_website.yaml
│   └── node_pnpm_markdown_website.yaml
├── docs/
│   └── recipes/
│       ├── generic_bash_recipe.md
│       └── node_pnpm_html_website_recipe.md
```

**Test Script Workflow** (for `node_pnpm_html_website`):

1. **Select Recipe**: Choose `./recipes/node_pnpm_html_website.yaml`.
2. **Create Test Directory**: Create `./tests/node_pnpm_html_website_v0.1.0/`.
3. **Copy Files**:
   - Copy `setup_project.sh` to `./tests/node_pnpm_html_website_v0.1.0/scripts/`.
   - Copy `./recipes/node_pnpm_html_website.yaml` to `./tests/node_pnpm_html_website_v0.1.0/config.yaml`.
4. **Run Setup**: Execute `./tests/node_pnpm_html_website_v0.1.0/scripts/setup_project.sh --config-path ./tests/node_pnpm_html_website_v0.1.0/config.yaml --verbose debug`.
5. **Verify Output**:
   - Check generated files (e.g., `index.html`, `package.json`, `.vscode/settings.json`).
   - Compare logs in `./tests/node_pnpm_html_website_v0.1.0/logs/` with expected log patterns.
6. **Report Results**: Pass if files match expected structure and logs contain no errors; fail otherwise.

**Test Script Example** (`./scripts/tests/node_pnpm_html_website.bats`):

```bash
#!/usr/bin/env bats

setup() {
  TEST_DIR="./tests/node_pnpm_html_website_v0.1.0"
  RECIPE="./recipes/node_pnpm_html_website.yaml"
  mkdir -p "$TEST_DIR/scripts" "$TEST_DIR/logs" "$TEST_DIR/archives"
  cp "./scripts/setup_project.sh" "$TEST_DIR/scripts/"
  cp "$RECIPE" "$TEST_DIR/config.yaml"
}

teardown() {
  rm -rf "$TEST_DIR"
}

@test "node_pnpm_html_website: setup creates expected files" {
  run bash "$TEST_DIR/scripts/setup_project.sh" --config-path "$TEST_DIR/config.yaml" --verbose debug
  [ "$status" -eq 0 ]
  [ -f "$TEST_DIR/index.html" ]
  [ -f "$TEST_DIR/package.json" ]
  [ -f "$TEST_DIR/.vscode/settings.json" ]
  [ -f "$TEST_DIR/.gitignore" ]
}

@test "node_pnpm_html_website: log contains success message" {
  run bash "$TEST_DIR/scripts/setup_project.sh" --config-path "$TEST_DIR/config.yaml" --verbose debug
  [ "$status" -eq 0 ]
  log_file=$(ls "$TEST_DIR/logs/" | tail -n 1)
  grep -q "Setup completed successfully" "$TEST_DIR/logs/$log_file"
}

@test "node_pnpm_html_website: package.json has correct name" {
  run bash "$TEST_DIR/scripts/setup_project.sh" --config-path "$TEST_DIR/config.yaml" --verbose debug
  [ "$status" -eq 0 ]
  grep -q '"name": "html_website"' "$TEST_DIR/package.json"
}
```

**Testing Logs**:

- Stored in `./logs/tests/<test_name>_<date>.log` (e.g., `./logs/tests/node_pnpm_html_website_v0.1.0_20250715.log`).
- Use `setup_project.sh`’s logging system with `--verbose debug` for detailed output.
- Compare logs against expected patterns (e.g., “Setup completed successfully”, no “ERROR” messages).

**Recommendations**:

- Use `bats` for testing, as planned (TODO #025).
- Add a `--dry-run` flag to `setup_project.sh` (as suggested in the summary) to simulate setups without file writes, useful for testing without modifying the filesystem.
- Store expected log patterns in `./scripts/tests/expected_logs/` (e.g., `node_pnpm_html_website_expected.log`) for comparison.

---

### 4. GitHub Actions Workflow

The GitHub Actions workflow should lint the script, run tests for each recipe, and verify outputs. Below is an updated workflow for the Node.js static website recipe.

**Workflow File** (`.github/workflows/test.yml`):

```yaml
name: Test setup_project

on:
  push:
    branches: [main, feature/*]
  pull_request:
    branches: [main]

jobs:
  lint:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - name: Install ShellCheck
        run: sudo apt-get install -y shellcheck
      - name: Lint setup_project.sh
        run: shellcheck scripts/setup_project.sh

  test-node-pnpm-html-website:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - name: Install dependencies
        run: |
          sudo apt-get update
          sudo apt-get install -y bats git yq
          sudo npm install -g pnpm
      - name: Run tests
        run: bats scripts/tests/node_pnpm_html_website.bats
      - name: Archive test logs
        if: always()
        uses: actions/upload-artifact@v4
        with:
          name: test-logs
          path: logs/tests/
```

**Key Features**:

- **Linting**: Runs ShellCheck on `setup_project.sh`.
- **Testing**: Executes `bats` tests for the `node_pnpm_html_website` recipe.
- **Artifacts**: Uploads test logs for debugging failed runs.
- **Triggers**: Runs on pushes to `main` or `feature/*` branches and pull requests to `main`.

**Recommendation**:

- Add separate jobs for each recipe (e.g., `test-generic-bash`, `test-node-pnpm-markdown-website`) as they are developed.
- Update the workflow to include test coverage badges once tests are stable (TODO in summary).

---

### 5. Developing the Node.js Static Website Recipe

**Recipe File** (`./recipes/node_pnpm_html_website.yaml`):
Already provided above. This recipe sets up a basic static website with `pnpm`, `prettier`, `eslint`, and `serve`, plus VSCode integration.

**Test Script** (`./scripts/tests/node_pnpm_html_website.bats`):
Already provided above. Tests file creation, log contents, and `package.json` accuracy.

**Documentation** (./docs/recipes/[node_pnpm_html_website_recipe.md](recipes/node_pnpm_html_website_recipe.md))

---

### 6. Next Steps and Recommendations

1. **Implement Generic Recipe**:
   - Create `./recipes/generic_bash.yaml` and `./docs/recipes/generic_bash_recipe.md`.
   - Develop corresponding test script (`./scripts/tests/generic_bash.bats`).
   - Test with `./tests/bash_none_script_v0.1.0/`.

2. **Enhance setup_project.sh**:
   - Add `--recipe` flag support.
   - Implement `--dry-run` mode for testing (TODO #010).
   - Add log comparison logic to verify expected outputs.

3. **Expand Recipes**:
   - Develop `node_pnpm_markdown_website.yaml` next, focusing on Markdown-based static sites (e.g., using a static site generator like `vitepress`).
   - Plan for Python, Bash, and Perl recipes.

4. **GitHub Actions**:
   - Add jobs for each recipe as they are developed.
   - Include coverage reporting once tests are comprehensive.

5. **Documentation**:
   - Update `README.md` to include recipe usage and testing instructions.
   - Add manpage link (`https://davit.ie/docs/setup_project`) once verified (TODO #021).

6. **External Scripts** (TODO #019, #020):
   - Start `DavitTec/logging` and `DavitTec/backup` repos using `setup_project.sh`.
   - Develop interfaces for `logging.sh` and `backup.sh` to replace inline functions.

7. **Changelog** (TODO #024):
   - Generate `CHANGELOG.md` with `generate_changelog` function.
   - Include v0.2.5 release notes.

---

### Summary

- **Folder Naming**: Use `<language>_<package_manager>_<project_type>_v<version>` (e.g., `node_pnpm_html_website_v0.1.0`).
- **Recipes**: Store in `./recipes/` as YAML files (e.g., `node_pnpm_html_website.yaml`), with documentation in `./docs/recipes/`.
- **Testing**: Use `bats` in `./scripts/tests/`, with test projects in `./tests/<test_name>/` and logs in `./logs/tests/`.
- **Workflow**: Start with `node_pnpm_html_website`, test locally, and integrate into GitHub Actions.
- **Next Steps**: Implement generic Bash recipe, enhance `setup_project.sh`, and expand to other recipes.

This plan provides a clear path to develop and test the Node.js static website recipe, with a scalable structure for additional recipes. Let me know if you need further details or assistance with implementing specific components!
