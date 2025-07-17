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
  #TODO: use find instead of ls
  log_file=$(ls "$TEST_DIR/logs/" | tail -n 1)
  grep -q "Setup completed successfully" "$TEST_DIR/logs/$log_file"
}

@test "node_pnpm_html_website: package.json has correct name" {
  run bash "$TEST_DIR/scripts/setup_project.sh" --config-path "$TEST_DIR/config.yaml" --verbose debug
  [ "$status" -eq 0 ]
  grep -q '"name": "html_website"' "$TEST_DIR/package.json"
}
