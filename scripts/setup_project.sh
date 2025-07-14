#!/bin/bash
# Script: setup_project.sh
# Version: 0.2.5
# Description: Automates initial project setup, including config creation, dependency installation, git init, and file generation based on path inference or YAML config.
# Purpose: Bootstrap small to monorepo projects across languages (Node, Python, Bash, Perl, etc.) with reproducibility, dependency management, and VSCode integration.
# Alias: setprj
# Created: 2025-07-12
# Updated: 2025-07-14
# Author: David Mullins
# Contact: david@davit.ie / https://davit.ie
# Git: https://github.com/DavitTec/$(basename "$(pwd)")
# Usage: ./scripts/setup_project.sh [options]
#   Options:
#     -h, --help: Show this help message
#     -v, --version: Show script version
#     -b, --backup: Backup script to archives
#     -s, --vscode: Setup vscode
#     --config-path <path>: Specify custom path to initial_config.yaml
#     --verbose <off|on|debug>: Set logging verbosity (default: on)
# License: MIT
# Status: development
####### /HEADER #######

set -euo pipefail # Stricter error handling: exit on errors, unset vars, failed pipes

####### FUNCTIONS #######

# Global variables
declare -g VERBOSE="on"              # Default verbosity: off (no terminal logs), on (info to terminal), debug (all to terminal)
declare -g LAST_LOG_NO_NEWLINE=false # Track if last log ended without newline for continuations
declare -g VERSION
VERSION=$(awk '/^####### \/HEADER #######/ {exit} /^# Version:/ {print $3}' "$0")
declare -g CLEAR_LOGS=true # Delete logs at start, default true

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
    *) log "Invalid option: -$OPTARG" ;; # Recursive, but careful
    esac
  done
  shift $((OPTIND - 1))

  local message="$1"
  [[ -z "$message" ]] && return

  local LOG_DIR="logs"
  local timestamp
  local script_name
  local log_file
  local log_entry
  timestamp=$(date '+%Y-%m-%d %H:%M:%S')
  script_name=$(basename "${BASH_SOURCE[1]}" .sh)
  log_file="${LOG_DIR}/${script_name}_$(date '+%Y%m%d').log"

  if "$LAST_LOG_NO_NEWLINE"; then
    log_entry="$message" # Continuation: no timestamp
  else
    log_entry="[$timestamp] $message"
  fi

  # Always log to file
  mkdir -p "$LOG_DIR"
  if "$no_newline"; then
    echo "$echo_opts" -n "$log_entry" >>"$log_file"
  else
    echo "$echo_opts" "$log_entry" >>"$log_file"
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

  # Update flag for next call
  if "$no_newline"; then
    LAST_LOG_NO_NEWLINE=true
  else
    LAST_LOG_NO_NEWLINE=false
  fi
}

# Function to backup this script to archives
# TODO: #020 Integrate external backup script
backup() {
  mkdir -p archives
  local source="./scripts/setup_project.sh"
  local backup_file="archives/setup_project_v$VERSION.sh"
  cp "$source" "$backup_file"
  # TODO: #023 what else to backup
  #       1) probably to gzip all to a external folder
  local timestamp
  timestamp=$(date '+%Y-%m-%d %H:%M:%S')
  echo "[$timestamp] Backed up setup_project.sh"
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
  log "Setting up vscode for development"
  mkdir -p "$vscode_dir"
  local vscode_settings="$vscode_dir/settings.json"
  local vscode_launch="$vscode_dir/launch.json"
  log "Setting up VS Code settings..."
  cat <<EOF >"$vscode_settings"
{
  "editor.formatOnSave": true,
  "editor.codeActionsOnSave": {
    "source.fixAll": true,
    "source.organizeImports": true
  },
  "files.autoSave": "afterDelay",
  "files.autoSaveDelay": 1000,
  "eslint.format.enable": true,
  "eslint.validate": ["typescript", "typescriptreact"],
  "prettier.enable": true,
  "[typescript]": {
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
  log "Generated $vscode_settings"

  cat <<EOF >"$vscode_launch"
{
  "version": "0.2.0",
  "configurations": [
    {
      "type": "bashdb",
      "request": "launch",
      "name": "Bash-Debug (simplest configuration)",
      "program": "\${workspaceFolder}/scripts/setup_project.sh",
      "showDebugOutput": true
    }
  ]
}
EOF
  log "Generated $vscode_launch"
}

# Function to display help/usage
show_help() {
  echo "Usage: $0 [options]"
  echo "Options:"
  echo "  -h, --help: Show this help message"
  echo "  -v, --version: Show script version"
  echo "  -b, --backup: Backup script to archives"
  echo "  -s, --vscode: Setup vscode"
  echo "  --config-path <path>: Specify custom path to initial_config.yaml"
  echo "  --verbose <off|on|debug>: Set logging verbosity (default: on)"
  exit 0
}

# Function to display version
show_version() {
  echo "setup_project.sh version $VERSION"
  exit 0
}

# Function to parse project details from path
parse_path() {
  local full_path=""
  local root_name=""
  local subfolders=()
  full_path="$(pwd)"
  root_name="$(basename "$full_path")"
  IFS='/' read -ra subfolders <<<"$full_path"

  project_name="${root_name%%_v[0-9.]*}" # Global
  version=$(echo "$root_name" | sed -n 's/.*_v\([0-9.]*\).*/\1.0/p') # Global
  [[ -z "$version" ]] && version="$VERSION"

  primary_language="bash" # Global, Default
  frameworks=()          # Global
  if [[ "$full_path" =~ /node/ || "$project_name" =~ ^node_ ]]; then
    primary_language="node"
    if [[ "$full_path" =~ /next/ ]]; then
      frameworks+=("next.js")
    fi
  elif [[ "$full_path" =~ /python/ ]]; then
    primary_language="python"
  elif [[ "$full_path" =~ /perl/ ]]; then
    primary_language="perl"
  elif [[ "$full_path" =~ /bashscripts/ ]]; then
    primary_language="bash"
  elif [[ "$full_path" =~ /monorepo/ ]]; then
    primary_language="multi"
  fi

  author="${subfolders[2]:-$(whoami)}" # Global, e.g., davit from /opt/davit/...

  environment="development"                          # Global
  private="true"                                     # Global
  description="Auto-generated project based on path" # Global

  log -d "Inferred: Name=$project_name, Version=$version, Language=$primary_language, Frameworks=${frameworks[*]}, Author=$author"
}

# Function to create basic initial_config.yaml if missing
create_default_yaml() {
  local config_file="$1"
  parse_path

  local frameworks_joined=""
  frameworks_joined=$(IFS=', '; echo "${frameworks[*]}")

  cat <<EOF >"$config_file"
# initial_config.yaml
config_version: 1.0

project:
  name: $project_name
  version: $version
  author: $author
  description: "$description"
  private: $private
  environment: $environment
  primary_language: $primary_language
  frameworks: [$frameworks_joined]

dependencies:
  global_tools:
    - name: git
      min_version: 2.30
      install_if_missing: true
    - name: yq
      min_version: 4.0
      install_if_missing: true
  project_specific:
    - prettier: ^3.0
    - conventional-changelog-cli: ^2.0

git:
  init: true
  template: Node

env:
  NODE_ENV: development

vscode:
  extensions: [esbenp.prettier-vscode]

post_setup:
  archive_config: true
EOF
  log "Created default $config_file"
}

# Function to install missing global tools (e.g., git, yq)
install_global_tools() {
  local tools
  tools=$(yq e '.dependencies.global_tools[] | .name' "$config_file" || log "Error: yq parse failed for tools")
  for tool in $tools; do
    if ! command -v "$tool" &>/dev/null; then
      local install
      install=$(yq e ".dependencies.global_tools[] | select(.name == \"$tool\") | .install_if_missing" "$config_file" || log "Error: yq parse failed for install flag")
      if [[ "$install" = "true" ]]; then
        log -n "Installing $tool... "
        if sudo apt update && sudo apt install -y "$tool"; then
          log "done"
        else
          log "Error: Installation of $tool failed"
        fi
      fi
    fi
  done
}

# Function to setup git
setup_git() {
  log "GIT: setting up git"
  local init
  init=$(yq e '.git.init' "$config_file" || log "Error: yq parse failed for git.init")
  if [[ "$init" = "true" ]]; then
    git init || log "Error: git init failed"
    local template
    template=$(yq e '.git.template' "$config_file" || log "Error: yq parse failed for git.template")
    URL="https://raw.githubusercontent.com/DavitTec/gitignore/main/${template}.gitignore"
    if curl -s "$URL" > .gitignore; then
      echo -e "\n# Archives\narchives/" >> .gitignore
      log "Git initialized with $template template from fork"
    else
      log "Error: Failed to fetch .gitignore template from fork; falling back to inline"
      if [[ "$template" = "bash" ]]; then
        cat <<EOF > .gitignore
# Temp files
*~
*.swp
*.tmp
*.bak

# Logs and archives
logs/
archives/

# OS/Editor files
.DS_Store
Thumbs.db
.vscode/

# Bash specific
*.sh~
EOF
        log "Used inline bash template"
      fi
    fi
  fi
}

# Function to generate README.md (simulate Create_Readme.sh)
generate_readme() {
  local readme="README.md"
  parse_path
  if [[ -f "$readme" ]]; then
    log "$readme already exists; skipping"
    return
  fi

  cat <<EOF >"$readme"
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

- Initialize: ./main.sh -init
- Install: ./main.sh -i
EOF
  log "Generated $readme"
}

# Function to generate main.sh with standard functions
generate_main_sh() {
  local main_sh="main.sh"
  if [[ -f "$main_sh" ]]; then
    log "$main_sh already exists; skipping"
    return
  fi

  cat <<'EOF' >"$main_sh"
#!/bin/bash
# Script: main.sh
# Version: 0.1.0
# Description: Main control script for project management
# Author: David Mullins
# License: MIT

usage() {
    echo "Usage: $0 [option]"
    echo "Options: -init, -s (setup), -i (install), -u (update), -b (backup), -d (uninstall), -v (version), -h (help)"
}

backup() {
    local version
    version=$(awk '/^####### \/HEADER #######/ {exit} /^# Version:/ {print $3}' ./scripts/setup_project.sh)
    mkdir -p archives
    cp ./scripts/setup_project.sh "archives/setup_project_v$version.sh"
    #Todo: #023 what else to backup
    local timestamp
    timestamp=$(date '+%Y-%m-%d %H:%M:%S')
    echo "[$timestamp] Backed up setup_project.sh"
}

main() {
    case "$1" in
        -init|--initialize) echo "Initializing..." ;;
        -s|--setup) echo "Setting up..." ;;
        -i|--install) echo "Installing..." ;;
        -u|--update) echo "Updating..." ;;
        -b|--backup) backup ;;
        -d|--uninstall) echo "Uninstalling..." ;;
        -v|--version) echo "Version $(awk '/^####### \/HEADER #######/ {exit} /^# Version:/ {print $3}' "$0")" ;;
        -h|--help) usage ;;
        *) usage ;;
    esac
}

main "$@"
EOF
  chmod +x "$main_sh"
  log "Generated $main_sh"
}

# Function to archive config and script
post_setup_actions() {
  local archive
  archive=$(yq e '.post_setup.archive_config' "$config_file" || log "Error: yq parse failed for post_setup")
  if [[ "$archive" = "true" ]]; then
    mkdir -p archives
    mv "$config_file" "archives/initial_config_$(date +%Y%m%d).yaml" || log "Error: Failed to archive config"
  fi
  if [[ -f "main.sh" ]]; then
    ./main.sh -b
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
  # Basic OS detection (expand as needed)
  if [[ "$OSTYPE" == "darwin"* ]]; then
    # macOS: Use brew
    if command -v brew &>/dev/null; then
      brew install yq && log "done (via brew)"
    else
      log "Error: brew not found on macOS"
      return 1
    fi
  elif [[ "$OSTYPE" == "linux-gnu"* ]]; then
    # Linux: Check distro via /etc/os-release
    if [[ -f /etc/os-release ]]; then
      # shellcheck source=/etc/os-release
      # shellcheck disable=SC1091
      source /etc/os-release
      if [[ "$ID" == "ubuntu" || "$ID_LIKE" == "debian" ]]; then
        sudo apt update && sudo apt install -y yq && log "done (via apt)"
      elif [[ "$ID" == "fedora" ]]; then
        sudo dnf install -y yq && log "done (via dnf)"
      else
        # Fallback: wget binary (uncomment for auto-install; prompt for test)
        local confirm=""
        read -p "Unknown distro; install via wget? (y/n): " -r confirm
        if [[ "$confirm" == "y" ]]; then
          if sudo wget https://github.com/mikefarah/yq/releases/download/v4.44.3/$yq_binary -O /usr/local/bin/yq && sudo chmod +x /usr/local/bin/yq; then
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
  local config_file="initial_config.yaml"

  while [[ $# -gt 0 ]]; do
    case $1 in
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
    --config-path)
      config_file="$2"
      shift
      ;;
    --verbose)
      VERBOSE="$2"
      shift
      ;;
    *)
      log "Unknown option: $1"
      show_help
      ;;
    esac
    shift
  done

  # Ensure in project root; create ./scripts if needed
  log "scripts_dir: $PWD/scripts"
  mkdir -p scripts
  # Assume this script is already in ./scripts

  # Move or reset logs if true
  if "$CLEAR_LOGS"; then
    local logfile
    logfile=$(find ./logs -name "setup_project_*.log" -print -quit 2>/dev/null)
    if [[ -n "$logfile" ]]; then
      mkdir -p archives
      mv "$logfile" "./archives/" || log "Error: Failed to move $logfile"
      log "[Reset] $logfile moved to ./archives"
      log "[NEW] ########### Logfile created ##############"
    fi
  fi

  setup_vscode

  if [[ ! -f "$config_file" ]]; then
    create_default_yaml "$config_file"
    log "$config_file file does not exist, creating"
  else
    log "$config_file file already exists, skipping"
  fi

  if ! command -v yq &>/dev/null; then
    if install_yq; then
      yq --version
    else
      log "Error: yq installation failed or skipped; script may fail"
    fi
  fi

  install_global_tools

  project_name=$(yq e '.project.name' "$config_file")
  primary_language=$(yq e '.project.primary_language' "$config_file")

  setup_git
  generate_readme
  generate_main_sh

  # Add dependencies based on language, e.g., if node: pnpm init -y
  if [[ "$primary_language" = "node" ]]; then
    if command -v pnpm &>/dev/null; then
      pnpm init -y
      pnpm add -D prettier conventional-changelog-cli
    else
      log "Error: pnpm not found; skipping Node.js dependencies"
    fi
  elif [[ "$primary_language" = "python" ]]; then
    echo "prettier==3.0" >requirements.txt
  fi

  post_setup_actions

  log "Project setup complete!"
}

####### MAIN #######
main "$@"

######## FOOTER #######

# End of script

######## TODO #######
# TODO: #001 [OS] Add OS detection for install commands (e.g., brew for mac)  # Partially done for yq
# TODO: #002 [OS] Handle multi-language more robustly (e.g., generate multiple dep files)
# TODO: #003 [README] Integrate actual Create_Readme.sh if exists
# TODO: #004 [ERROR] Add error handling for commands  # Expanded
# TODO: #005 [YAML] Support custom git remote from YAML
# TODO: #006 [Config] Generate .env from YAML env section
# TODO: #007 [Vscode] VSCode settings generation
# TODO: #008 [TEST] Test on monorepo paths
# TODO: #009 [Logging] Enhance log function with more levels or colors if needed
# TODO: #010 [TEST] Add --dry-run mode to simulate actions
# TODO: #011 [UI] Prompt/flag for tool installations (e.g., --no-install)
# TODO: #012 [SHELLCHECK] Run shellcheck automatically or add directives
# TODO: #013 [Backup] Make backup() in main.sh use setup_project.sh's version  # Fixed
# TODO: #014 [WIN] Add support for Windows (e.g., via WSL detection)
# TODO: #015 [YAML] Detect architecture for yq binary downloads  # Done
# TODO: #016 [Vscode] Add check for VSCode installation  # Done
# TODO: #017 [Gitignore] Add a "bash" gitignore template to https://github/DavitTec/gitignore/
# TODO: #018 [Gitignore] Add a function for modifying ".gitignore"
# TODO: #019 [Logging] Integrate external logging script
# TODO: #020 [Backup] Integrate external backup script
# TODO: #021 [Manpages] Fix manpage: https://davit.ie/docs/$(basename "$(pwd)")
# TODO: #022 [Logging] Build and source logging script if available
# TODO: #023 [BACKUP] What else to backup (e.g., gzip to external folder)
# TODO: #024 [Changelog] Add changelog generation with conventional-changelog
# TODO: #025 [Testing] Add unit tests with bats
