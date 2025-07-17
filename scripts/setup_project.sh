#!/bin/bash
# Script: setup_project.sh
# Version: 0.3.13
# Description: Automates initial project setup using recipe-driven YAML configurations for multi-language projects with VSCode and Git integration.
# Purpose: Bootstrap small to monorepo projects across languages (Node, Python, Bash, Perl, etc.) with reproducibility and dependency management.
# Alias: setprj
# Created: 2025-07-12
# Updated: 2025-07-16
# Author: David Mullins
# Contact: david@davit.ie / https://davit.ie
# Git: https://github.com/DavitTec/$(basename "$(pwd)")
# Usage: ./scripts/setup_project.sh [options]
#   Options:
#     -h, --help: Show this help message
#     -v, --version: Show script version
#     -b, --backup: Backup script to archives
#     -s, --vscode: Setup VSCode configuration
#     --recipe <path>: Specify recipe YAML file (default: ./recipes/default.yaml)
#     --verbose <off|on|debug>: Set logging verbosity (default: on)
#     --dry-run: Simulate actions without making changes
# Licence: MIT
# Status: development
####### /HEADER #######

set -euo pipefail # Stricter error handling: exit on errors, unset vars, failed pipes

####### FUNCTIONS #######

# Global variables
declare -g VERBOSE="on"              # Default verbosity: off (no terminal logs), on (info to terminal), debug (all to terminal)
declare -g LAST_LOG_NO_NEWLINE=false # Track if last log ended without newline for continuations
declare -g VERSION
VERSION=$(awk '/^####### \/HEADER #######/ {exit} /^# Version:/ {print $3}' "$0")
declare -g CLEAR_LOGS=true                         # Delete logs at start, default true
declare -g LOG_DIR="./logs"                        # Configurable log directory
declare -g ARCHIVE_DIR="./archives"                # Configurable archive directory
declare -g RECIPE_DEFAULT="./recipes/default.yaml" # Default recipe
declare -g project_name                            # Global project name from recipe
declare -g DRY_RUN=false                           # Dry-run mode flag

# Check script syntax with shellcheck
check_syntax() {
  if command -v shellcheck &>/dev/null; then
    log -d "Running shellcheck on $0"
    if shellcheck -x "$0" >"${LOG_DIR}/shellcheck_$(date '+%Y%m%d').log"; then
      log -d "shellcheck passed"
    else
      log "Warning: shellcheck found issues; see ${LOG_DIR}/shellcheck_$(date '+%Y%m%d').log"
    fi
  else
    log -d "shellcheck not found; skipping syntax check"
  fi
}

# Logging Function
# TODO: #019 Source logging script if available
log() {
  # Usage: log [options] "message"
  # Options:
  #   -d: Debug level message (only to terminal if VERBOSE=debug)
  #   -e: Enable interpretation of backslash escapes (like echo -e)
  #   -n: No newline (like echo -n); sets flag for next log to continue without new timestamp
  # Logs to file always, to terminal based on VERBOSE and level.
  # For continuations after -n, appends without adding a new timestamp.
  local opt=""
  local msg_level="info"
  local echo_opts=""
  local no_newline=false
  OPTIND=1
  while getopts ":den" opt; do
    case "$opt" in
    d) msg_level="debug" ;;
    e) echo_opts="-e" ;;
    n) no_newline=true ;;
    *) log "Invalid option: -$OPTARG" ;;
    esac
  done
  shift $((OPTIND - 1))

  local message="$1"
  [[ -z "$message" ]] && return

  local timestamp
  local script_name
  local log_file
  local log_entry
  timestamp=$(date '+%Y-%m-%d %H:%M:%S')
  script_name=$(basename "${BASH_SOURCE[1]}" .sh)
  log_file="${LOG_DIR}/${script_name}_$(date '+%Y%m%d').log"

  if "$DRY_RUN"; then
    log_entry="[DRY-RUN] [$timestamp] $message"
  elif "$LAST_LOG_NO_NEWLINE"; then
    log_entry="$message"
  else
    log_entry="[$timestamp] $message"
  fi

  if ! "$DRY_RUN"; then
    mkdir -p "$LOG_DIR"
    if "$no_newline"; then
      echo "$echo_opts" -n "$log_entry" >>"$log_file"
    else
      echo "$echo_opts" "$log_entry" >>"$log_file"
    fi
  fi

  # Log to terminal (stderr) based on verbosity
  if [[ "$msg_level" = "info" && "$VERBOSE" != "off" ]]; then
    if "$no_newline"; then
      echo "$echo_opts" -n "$log_entry" >&2
    else
      echo "$echo_opts" "$log_entry" >&2
    fi
  elif [[ "$msg_level" = "debug" && "$VERBOSE" = "debug" ]]; then
    if "$no_newline"; then
      echo "$echo_opts" -n "$log_entry" >&2
    else
      echo "$echo_opts" "$log_entry" >&2
    fi
  fi

  LAST_LOG_NO_NEWLINE=$no_newline
}

# Function to wrap mkdir for dry-run support
dry_mkdir() {
  if "$DRY_RUN"; then
    log "[DRY-RUN] Would create directory: $1"
  else
    mkdir -p "$1"
  fi
}

# Function to wrap cp for dry-run support
dry_cp() {
  if "$DRY_RUN"; then
    log "[DRY-RUN] Would copy: $1 to $2"
  else
    cp "$1" "$2"
  fi
}

# Function to wrap mv for dry-run support
dry_mv() {
  if "$DRY_RUN"; then
    log "[DRY-RUN] Would move: $1 to $2"
  else
    mv "$1" "$2"
  fi
}

# Function to wrap echo for dry-run support
dry_echo() {
  local file="$1"
  local content="$2"
  if "$DRY_RUN"; then
    log "[DRY-RUN] Would write to $file: $content"
  else
    echo "$content" >"$file"
  fi
}

# Function to wrap chmod for dry-run support
dry_chmod() {
  if "$DRY_RUN"; then
    log "[DRY-RUN] Would chmod $1 $2"
  else
    chmod "$1" "$2"
  fi
}

# Function to wrap git for dry-run support
dry_git() {
  if "$DRY_RUN"; then
    log "[DRY-RUN] Would run: git $*"
  else
    git "$@"
  fi
}

# Function to wrap pnpm for dry-run support
dry_pnpm() {
  if "$DRY_RUN"; then
    log "[DRY-RUN] Would run: pnpm $*"
  else
    pnpm "$@"
  fi
}

# Function to wrap curl for dry-run support
dry_curl() {
  if "$DRY_RUN"; then
    log "[DRY-RUN] Would run: curl $*"
  else
    curl "$@"
  fi
}

# Function to backup this script to archives
# TODO: #020 Integrate external backup script
backup() {
  dry_mkdir "$ARCHIVE_DIR"
  local source="./scripts/setup_project.sh"
  local backup_file="$ARCHIVE_DIR/setup_project_v$VERSION.sh"
  dry_cp "$source" "$backup_file"
  log "Backed up $source to $backup_file"
}

# Function to setup vscode
# TODO: #016 check code and or vscode-insiders
setup_vscode() {
  local vscode_dir="./.vscode/"
  if ! command -v code &>/dev/null && ! command -v code-insiders &>/dev/null; then
    log "Warning: VSCode (code or code-insiders command) not found; skipping setup"
    return
  fi
  if [[ -f "$vscode_dir/settings.json" && -f "$vscode_dir/launch.json" ]]; then
    log "VSCode setup already exists; skipping"
    return
  fi
  log "Setting up VSCode for development"
  dry_mkdir "$vscode_dir"
  local vscode_settings="$vscode_dir/settings.json"
  local vscode_launch="$vscode_dir/launch.json"
  log "Setting up VS Code settings..."
  dry_echo "$vscode_settings" "$(
    cat <<EOF
{
  "editor.formatOnSave": true,
  "editor.codeActionsOnSave": {
    "source.fixAll": true,
    "source.organiseImports": true
  },
  "files.autoSave": "afterDelay",
  "files.autoSaveDelay": 1000,
  "eslint.format.enable": true,
  "eslint.validate": ["javascript", "html"],
  "prettier.enable": true,
  "[javascript]": {
    "editor.defaultFormatter": "esbenp.prettier-vscode"
  },
  "editor.fontSize": 12,
  "editor.defaultFormatter": "esbenp.prettier-vscode",
  "files.exclude": {
    "archives/*": false
  },
  "editor.tabSize": 2,
  "editor.autoIndent": "advanced",
  "notebook.defaultFormatter": "esbenp.prettier-vscode"
}
EOF
  )"
  log "Generated $vscode_settings"

  dry_echo "$vscode_launch" "$(
    cat <<EOF
{
  "version": "0.2.0",
  "configurations": [
    {
      "type": "node",
      "request": "launch",
      "name": "Bash-Debug (simplest configuration)",
      "program": "\${workspaceFolder}/scripts/setup_project.sh",
      "showDebugOutput": true
    }
  ]
}
EOF
  )"
  log "Generated $vscode_launch"
}

# Function to display help/usage
show_help() {
  echo "Usage: $0 [options]"
  echo "Options:"
  echo "  -h, --help: Show this help message"
  echo "  -v, --version: Show script version"
  echo "  -b, --backup: Backup script to archives"
  echo "  -s, --vscode: Setup VSCode configuration"
  echo "  --recipe <path>: Specify recipe YAML file (default: $RECIPE_DEFAULT)"
  echo "  --verbose <off|on|debug>: Set logging verbosity (default: on)"
  echo "  --dry-run: Simulate actions without making changes"
  exit 0
}

# Function to display version
show_version() {
  echo "setup_project.sh version $VERSION"
  exit 0
}

# Function to parse project details from path
parse_path() {
  local full_path root_name subfolders
  full_path="$PWD"
  root_name=$(basename "$full_path")
  subfolders=()
  IFS='/' read -ra subfolders <<<"$full_path"

  # Extract version from directory
  if [[ "$root_name" =~ ^([a-zA-Z0-9_]+)_v([0-9.]+)$ ]]; then
    version="${BASH_REMATCH[2]}"
  else
    version=$(echo "$root_name" | sed -n 's/.*_v\([0-9.]*\).*/\1.0/p')
    [[ -z "$version" ]] && version="$VERSION"
  fi

  primary_language="bash" # Global, Default
  package_manager="none"
  frameworks=()
  if [[ "$root_name" =~ ^node_ ]]; then
    primary_language="node"
    if [[ "$root_name" =~ _pnpm_ ]]; then
      package_manager="pnpm"
    elif [[ "$root_name" =~ _npm_ ]]; then
      package_manager="npm"
    fi
    if [[ "$full_path" =~ /next/ ]]; then
      frameworks+=("next.js")
    fi
  elif [[ "$full_path" =~ /python/ || "$root_name" =~ ^python_ ]]; then
    primary_language="python"
    package_manager="pip"
  elif [[ "$full_path" =~ /perl/ || "$root_name" =~ ^perl_ ]]; then
    primary_language="perl"
  elif [[ "$full_path" =~ /bashscripts/ || "$root_name" =~ ^bash_ ]]; then
    primary_language="bash"
  elif [[ "$full_path" =~ /monorepo/ || "$root_name" =~ ^multi_ ]]; then
    primary_language="multi"
  fi

  author="${subfolders[3]:-$(whoami)}" # /opt/davit/development/...
  # Unused variables
  # environment="development"
  # private="true"
  description="Auto-generated project based on path"

  log -d "Inferred from path: Version=$version, Language=$primary_language, PackageManager=$package_manager, Frameworks=${frameworks[*]}, Author=$author"
}

# Function to generate files from recipe
# shellcheck disable=SC2016
generate_files_from_recipe() {
  local recipe_file="$1"
  log -d "Processing files from recipe: $recipe_file"
  local file_count
  file_count=$(yq e '.files | length' "$recipe_file" || {
    log "Error: yq parse failed for files"
    return 1
  })
  log -d "Found $file_count files to generate"
  if [[ "$file_count" -gt 0 ]]; then
    # Use project.name from YAML
    local yaml_project_name
    yaml_project_name=$(yq e '.project.name' "$recipe_file" || {
      log "Error: yq parse failed for project.name"
      return 1
    })
    for ((i = 0; i < file_count; i++)); do
      local file_path
      local file_content
      file_path=$(yq e ".files[$i].path" "$recipe_file" || {
        log "Error: yq parse failed for file path"
        return 1
      })
      file_content=$(yq e ".files[$i].content" "$recipe_file" || {
        log "Error: yq parse failed for file content"
        return 1
      })
      # Replace placeholders with YAML project metadata

      # Does the following work instead?
      # file_content=$("${file_content//'{{project.name}}'/$yaml_project_name/g}")
      # FIX: next 2 lines with   error
      # shellcheck disable=SC2001
      file_content=$(echo "$file_content" | sed "s/{{project.name}}/$yaml_project_name/g")
      # shellcheck disable=SC2001
      file_content=$(echo "$file_content" | sed "s/{{project.version}}/$version/g")
      dry_mkdir "$(dirname "$file_path")"
      dry_echo "$file_path" "$file_content"
      log "Generated $file_path"
    done
  fi
}

# Function to install missing global tools (e.g., git, yq)
install_global_tools() {
  local tools
  tools=$(yq e '.dependencies.global[] | .name' "$recipe_file" || {
    log "Error: yq parse failed for tools"
    return 1
  })
  for tool in $tools; do
    if ! command -v "$tool" &>/dev/null; then
      local install
      install=$(yq e ".dependencies.global[] | select(.name == \"$tool\") | .install_if_missing" "$recipe_file" || {
        log "Error: yq parse failed for install flag"
        return 1
      })
      if [[ "$install" = "true" ]]; then
        log -n "Installing $tool... "
        if "$DRY_RUN"; then
          log "[DRY-RUN] Would install $tool via apt"
        elif sudo apt update && sudo apt install -y "$tool"; then
          log "done"
        else
          log "Error: Installation of $tool failed"
          return 1
        fi
      fi
    fi
  done
}

# Function to set up git
setup_git() {
  log "GIT: setting up git"
  local init
  init=$(yq e '.git.init' "$recipe_file" || {
    log "Error: yq parse failed for git.init"
    return 1
  })
  if [[ "$init" = "true" ]]; then
    dry_git init || {
      log "Error: git init failed"
      return 1
    }
    local template
    template=$(yq e '.git.template' "$recipe_file" || {
      log "Error: yq parse failed for git.template"
      return 1
    })
    URL="https://raw.githubusercontent.com/DavitTec/gitignore/main/${template}.gitignore"
    if "$DRY_RUN"; then
      log "[DRY-RUN] Would fetch .gitignore from $URL"
      log "[DRY-RUN] Would append to .gitignore: # Archives\narchives/"
      log "Git initialised with $template template from fork"
    else
      if dry_curl -s "$URL" >.gitignore; then
        echo -e "\n# Archives\narchives/" >>.gitignore
        log "Git initialised with $template template from fork"
      else
        log "Error: Failed to fetch .gitignore template from fork; falling back to inline"
        if [[ "$template" = "Node" ]]; then
          dry_echo ".gitignore" "$(
            cat <<EOF
# Node.js
node_modules/
dist/
*.log

# Logs and archives
logs/
archives/

# OS/Editor files
.DS_Store
Thumbs.db
.vscode/
EOF
          )"
          log "Used inline Node template"
        fi
      fi
    fi
  fi
}

# Function to generate README.md
# shellcheck disable=SC2016
generate_readme() {
  local readme="README.md"
  if [[ -f "$readme" ]]; then
    log "$readme already exists; skipping"
    return
  fi

  dry_echo "$readme" "$(
    cat <<EOF
# $project_name

## Description

$description

## Version

$version

## Author

$author

## Setup

Run ./main.sh -s

## Usage

- Initialise: ./main.sh -init
- Install: ./main.sh -i
EOF
  )"
  log "Generated $readme"
}

# Function to generate main.sh with standard functions
# shellcheck disable=SC2016
generate_main_sh() {
  local main_sh="main.sh"
  if [[ -f "$main_sh" ]]; then
    log "$main_sh already exists; skipping"
    return
  fi

  dry_echo "$main_sh" "$(
    cat <<EOF
#!/bin/bash
# Script: main.sh
# Version: 0.1.0
# Description: Main control script for project management
# Author: David Mullins
# Licence: MIT

usage() {
    echo "Usage: \$0 [option]"
    echo "Options: -init, -s (setup), -i (install), -u (update), -b (backup), -d (uninstall), -v (version), -h (help)"
}

backup() {
    local version
    version=\$(awk '/^####### \/HEADER #######/ {exit} /^# Version:/ {print \$3}' ./scripts/setup_project.sh)
    mkdir -p archives
    cp ./scripts/setup_project.sh "archives/setup_project_v\$version.sh"
    local timestamp
    timestamp=\$(date '+%Y-%m-%d %H:%M:%S')
    echo "[\$timestamp] Backed up setup_project.sh"
}

main() {
    case "\$1" in
        -init|--initialise) echo "Initialising..." ;;
        -s|--setup) echo "Setting up..." ;;
        -i|--install) echo "Installing..." ;;
        -u|--update) echo "Updating..." ;;
        -b|--backup) backup ;;
        -d|--uninstall) echo "Uninstalling..." ;;
        -v|--version) echo "Version \$(awk '/^####### \/HEADER #######/ {exit} /^# Version:/ {print \$3}' "\$0")" ;;
        -h|--help) usage ;;
        *) usage ;;
    esac
}

main "\$@"
EOF
  )"
  dry_chmod +x "$main_sh"
  log "Generated $main_sh"
}

# Function to archive recipe
post_setup_actions() {
  local archive
  archive=$(yq e '.post_setup.archive_config' "$recipe_file" || {
    log "Error: yq parse failed for post_setup"
    return 1
  })
  if [[ "$archive" = "true" ]]; then
    dry_mkdir "$ARCHIVE_DIR"
    local timestamp
    timestamp=$(date '+%Y%m%d%H%M%S')
    dry_cp "$recipe_file" "$ARCHIVE_DIR/recipe_$timestamp.yaml" || {
      log "Error: Failed to archive recipe"
      return 1
    }
    log "Archived recipe to $ARCHIVE_DIR/recipe_$timestamp.yaml"
  fi
  if [[ -f "main.sh" ]]; then
    if "$DRY_RUN"; then
      log "[DRY-RUN] Would run: ./main.sh -b"
    else
      ./main.sh -b
    fi
  fi
}

# Function to install yq
install_yq() {
  log -n "Installing yq... "
  local arch
  arch=$(uname -m)
  local yq_binary="yq_linux_amd64"
  if [[ "$arch" == "aarch64" || "$arch" == "arm64" ]]; then
    yq_binary="yq_linux_arm64"
  fi
  if [[ "$OSTYPE" == "darwin"* ]]; then
    if command -v brew &>/dev/null; then
      if "$DRY_RUN"; then
        log "[DRY-RUN] Would install yq via brew"
      else
        brew install yq && log "done (via brew)"
      fi
    else
      log "Error: brew not found on macOS"
      return 1
    fi
  elif [[ "$OSTYPE" == "linux-gnu"* ]]; then
    if [[ -f /etc/os-release ]]; then
      # shellcheck disable=SC1091
      source /etc/os-release
      if [[ "$ID" == "ubuntu" || "$ID_LIKE" == "debian" ]]; then
        if "$DRY_RUN"; then
          log "[DRY-RUN] Would install yq via apt"
        else
          sudo apt update && sudo apt install -y yq && log "done (via apt)"
        fi
      elif [[ "$ID" == "fedora" ]]; then
        if "$DRY_RUN"; then
          log "[DRY-RUN] Would install yq via dnf"
        else
          sudo dnf install -y yq && log "done (via dnf)"
        fi
      else
        local confirm=""
        read -p "Unknown distro; install via wget? (y/n): " -r confirm
        if [[ "$confirm" == "y" ]]; then
          if "$DRY_RUN"; then
            log "[DRY-RUN] Would install yq via wget: https://github.com/mikefarah/yq/releases/download/v4.44.3/$yq_binary"
          elif sudo wget https://github.com/mikefarah/yq/releases/download/v4.44.3/$yq_binary -O /usr/local/bin/yq && sudo chmod +x /usr/local/bin/yq; then
            log "done (via wget)"
          else
            log "Error: wget failed"
            return 1
          fi
        else
          log "Skipped yq install"
          return 1
        fi
      fi
    else
      log "Error: Unable to detect Linux distro"
      return 1
    fi
  else
    log "Error: Unsupported OS: $OSTYPE"
    return 1
  fi
}

# Main function
main() {
  local script_path script_name
  script_path="$0"
  script_name=$(basename "$script_path")
  log "Starting script: $script_name, Path: $script_path, Version: $VERSION"
  log -d "Entering main function"
  log -d "Current directory: $PWD"
  local recipe_file="$RECIPE_DEFAULT"

  check_syntax

  while [[ $# -gt 0 ]]; do
    case $1 in
    --recipe)
      recipe_file="$2"
      shift
      ;;
    -h | --help) show_help ;;
    -b | --backup)
      backup
      exit 0
      ;;
    -s | --vscode)
      setup_vscode
      exit 0
      ;;
    -v | --version) show_version ;;
    --verbose)
      VERBOSE="$2"
      shift
      ;;
    --dry-run)
      DRY_RUN=true
      log "Dry-run mode enabled"
      ;;
    *)
      log "Unknown option: $1"
      show_help
      ;;
    esac
    shift
  done

  log "scripts_dir: $PWD/scripts"
  dry_mkdir ./scripts
  dry_mkdir ./recipes

  if [[ ! -f "$recipe_file" ]]; then
    log "Error: Recipe file $recipe_file not found"
    exit 1
  fi
  log "Using recipe: $recipe_file"

  # Copy recipe to target recipes/ folder
  local recipe_basename
  recipe_basename=$(basename "$recipe_file")
  # What if source and target pats are the same?
  #dry_cp "$recipe_file" "./recipes/$recipe_basename"
  log "WARNING: SKIPPED: Copied recipe to ./recipes/$recipe_basename"

  # Set LOG_DIR and ARCHIVE_DIR based on recipe
  LOG_DIR=$(yq e '.logging.path // "./logs"' "$recipe_file" || {
    log "Error: yq parse failed for logging.path"
    return 1
  })
  ARCHIVE_DIR=$(yq e '.backup.path // "./archives"' "$recipe_file" || {
    log "Error: yq parse failed for backup.path"
    return 1
  })

  if "$CLEAR_LOGS"; then
    local logfile
    logfile=$(find "$LOG_DIR" -name "setup_project_*.log" -print -quit 2>/dev/null)
    if [[ -n "$logfile" ]]; then
      dry_mkdir "$ARCHIVE_DIR"
      dry_mv "$logfile" "$ARCHIVE_DIR/" || {
        log "Error: Failed to move $logfile"
        return 1
      }
      log "[Reset] $logfile moved to $ARCHIVE_DIR"
      log "[NEW] ########### Logfile created ##############"
    fi
  fi

  # Set global project_name from recipe
  project_name=$(yq e '.project.name' "$recipe_file" || {
    log "Error: yq parse failed for project.name"
    return 1
  })
  primary_language=$(yq e '.project.primary_language' "$recipe_file" || {
    log "Error: yq parse failed for primary_language"
    return 1
  })

  setup_vscode
  parse_path
  install_global_tools
  setup_git
  generate_readme
  generate_main_sh
  generate_files_from_recipe "$recipe_file"
  post_setup_actions

  if [[ "$primary_language" = "node" ]]; then
    if command -v pnpm &>/dev/null; then
      # Skip pnpm init if package.json exists from recipe
      if [[ ! -f "package.json" ]]; then
        dry_pnpm init
        log "Initialised package.json with pnpm"
        # Update package.json name to match recipe
        if "$DRY_RUN"; then
          log "[DRY-RUN] Would update package.json name to $project_name"
        else
          jq ".name = \"$project_name\"" package.json >tmp.json && dry_mv tmp.json package.json
          log "Updated package.json name to $project_name"
        fi
      else
        log "package.json already exists from recipe; skipping pnpm init"
      fi
      dry_pnpm add -D prettier conventional-changelog-cli serve
      log "Installed Node.js dependencies: prettier, conventional-changelog-cli, serve"
    else
      log "Error: pnpm not found; skipping Node.js dependencies"
    fi
  elif [[ "$primary_language" = "python" ]]; then
    dry_echo "requirements.txt" "prettier==3.0"
    log "Generated requirements.txt for Python"
  fi

  log "Project setup complete!"
  log -d "Exiting main function"
}

####### MAIN #######
main "$@"

######## FOOTER #######

# End of script

######## TODO #######
# TODO: #001 [OS] Add OS detection for install commands (e.g., brew for mac)
# TODO: #002 [OS] Handle multi-language more robustly (e.g., generate multiple dep files)
# TODO: #003 [README] Integrate actual Create_Readme.sh if exists
# TODO: #004 [ERROR] Add error handling for commands
# TODO: #005 [YAML] Support custom git remote from YAML
# TODO: #006 [Config] Generate .env from YAML env section
# TODO: #007 [Vscode] VSCode settings generation
# TODO: #008 [TEST] Test on monorepo paths
# TODO: #009 [Logging] Enhance log function with more levels or colours if needed
# TODO: #010 [TEST] Completed: Added --dry-run mode to simulate actions
# TODO: #011 [UI] Prompt/flag for tool installations (e.g., --no-install)
# TODO: #012 [SHELLCHECK] Completed: Added shellcheck directives and automatic check
# TODO: #013 [Backup] Make backup() in main.sh use setup_project.sh's version
# TODO: #014 [WIN] Add support for Windows (e.g., via WSL detection)
# TODO: #015 [YAML] Detect architecture for yq binary downloads
# TODO: #016 [Vscode] Add check for VSCode installation
# TODO: #017 [Gitignore] Add a "bash" gitignore template to https://github/DavitTec/gitignore/
# TODO: #018 [Gitignore] Add a function for modifying ".gitignore"
# TODO: #019 [Logging] Integrate external logging script
# TODO: #020 [Backup] Integrate external backup script
# TODO: #021 [Manpages] Fix manpage: https://davit.ie/docs/setup_project
# TODO: #022 [Logging] Build and source logging script if available
# TODO: #023 [BACKUP] What else to backup (e.g., gzip to external folder)
# TODO: #024 [Changelog] Add changelog generation with conventional-changelog
# TODO: #025 [Testing] Add unit tests with bats
# TODO: #026 [Recipes] Support merging multiple recipes and creating new recipes with unique names in ./recipes/
