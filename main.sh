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
