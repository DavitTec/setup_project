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
