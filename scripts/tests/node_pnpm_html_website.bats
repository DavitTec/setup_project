#!/usr/bin/env bats
# Version:0.5
setup() {
  TEST_DIR="./tests/node_pnpm_html_website_v0.1.0"
  RECIPE="./recipes/node_pnpm_html_website.yaml"
  SCRIPT="./scripts/setup_project.sh"

  # Clean up any existing test directory
  rm -rf "$TEST_DIR"

  # Create test directory structure
  mkdir -p "$TEST_DIR/scripts" "$TEST_DIR/logs" "$TEST_DIR/archives"

  # Verify and copy script
  if [[ ! -f "$SCRIPT" ]]; then
    echo "Error: $SCRIPT not found" >&2
    return 1
  fi
  cp "$SCRIPT" "$TEST_DIR/scripts/"
  chmod +x "$TEST_DIR/scripts/setup_project.sh"

  # Verify and copy recipe
  if [[ ! -f "$RECIPE" ]]; then
    echo "Error: $RECIPE not found" >&2
    return 1
  fi
  cp "$RECIPE" "$TEST_DIR/config.yaml"

  # Verify dependencies
  for cmd in yq git pnpm; do
    if ! command -v "$cmd" &>/dev/null; then
      echo "Error: $cmd not found" >&2
      return 1
    fi
  done
}

teardown() {
  # Keep test directory for debugging
  echo "Test directory preserved at $TEST_DIR for debugging"
}

@test "node_pnpm_html_website: setup creates expected files" {
  cd "$TEST_DIR" || {
    echo "Failed to cd to $TEST_DIR" >&2
    return 1
  }
  run bash "./scripts/setup_project.sh" --config-path "./config.yaml" --recipe "./config.yaml" --verbose debug
  echo "Status: $status" >&2
  echo "Output: $output" >&2
  [ "$status" -eq 0 ]
  [ -f "./index.html" ]
  [ -f "./package.json" ]
  [ -f "./.vscode/settings.json" ]
  [ -f "./.vscode/launch.json" ]
  [ -f "./.gitignore" ]
  [ -f "./README.md" ]
  [ -f "./main.sh" ]
}

@test "node_pnpm_html_website: log contains success message" {
  cd "$TEST_DIR" || {
    echo "Failed to cd to $TEST_DIR" >&2
    return 1
  }
  run bash "./scripts/setup_project.sh" --config-path "./config.yaml" --recipe "./config.yaml" --verbose debug
  echo "Status: $status" >&2
  echo "Output: $output" >&2
  [ "$status" -eq 0 ]
  log_file=$(ls "./logs/" | tail -n 1 || true)
  [ -n "$log_file" ] # Ensure log file exists
  grep -q "Project setup complete" "./logs/$log_file"
}

@test "node_pnpm_html_website: package.json has correct name" {
  cd "$TEST_DIR" || {
    echo "Failed to cd to $TEST_DIR" >&2
    return 1
  }
  run bash "./scripts/setup_project.sh" --config-path "./config.yaml" --recipe "./config.yaml" --verbose debug
  echo "Status: $status" >&2
  echo "Output: $output" >&2
  [ "$status" -eq 0 ]
  grep -q '"name": "html_website"' "./package.json"
}
