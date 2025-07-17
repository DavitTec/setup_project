# Understanding BATS

> [!CAUTION]
>
> This document needs update

About the use and structure of BATS files, how BATS tests work and how they interact with the script. Below, I’ll address the test [design](#design), failures, [analysis](#analysis), the structure and use of BATS files, and provide an basic BATS test script to fix the issues.

---

## BATS Files in Depth

To address your confusion about BATS files, here’s a detailed explanation of their use and structure, tailored to your project:

1. **Purpose of BATS**:
   - BATS is designed to test Bash scripts by running commands and verifying their outcomes (e.g., exit status, output, file creation).
   - In your case, it tests whether `setup_project.sh` correctly sets up a Node.js static website project by checking:
     - File creation (`index.html`, `package.json`, etc.).
     - Log messages (e.g., “Project setup complete”).
     - Specific file contents (e.g., `package.json` name).

2. **Structure of a BATS File**:
   - **Shebang**: `#!/usr/bin/env bats` specifies that this is a BATS script.
   - **Setup Function**:

     ```bash
     setup() {
       # Prepare the test environment before each test
     }
     ```

     - Runs before each `@test` block.
     - Used to create directories, copy files, or set up prerequisites.
     - In your case, it creates `./tests/node_pnpm_html_website_v0.1.0/` and copies `setup_project.sh` and `config.yaml`.

   - **Teardown Function**:

     ```bash
     teardown() {
       # Clean up after each test
     }
     ```

     - Runs after each `@test` block.
     - Used to remove temporary files or directories to ensure a clean state.

   - **Test Cases**:

     ```bash
     @test "description" {
       # Test logic
       run some_command
       [ "$status" -eq 0 ]
       # Assertions
     }
     ```

     - Each test case is a block starting with `@test`.
     - The `run` command executes a command and captures its exit status (`$status`), output (`$output`), and lines (`$lines`).
     - Assertions use Bash commands like `[ -f "file" ]` (file exists) or `grep -q` (check file contents).

3. **Why No Pause is Needed**:
   - BATS executes the `run` command synchronously, meaning it waits for `setup_project.sh` to complete before checking files or logs. There’s no race condition or need for a pause.
   - The issue in your case was the missing test directory, not a timing problem.

4. **Common Assertions**:
   - Check exit status: `[ "$status" -eq 0 ]` (command succeeded).
   - Check file existence: `[ -f "file" ]`.
   - Check file contents: `grep -q "text" file`.
   - Check command output: `[[ "$output" =~ "expected text" ]]`.

5. **Best Practices**:
   - Keep tests independent: Each `@test` should not rely on previous tests (achieved via `setup()` and `teardown()`).
   - Use clear descriptions: e.g., “node_pnpm_html_website: setup creates expected files”.
   - Log errors clearly: Use `echo` in `setup()` or tests to diagnose failures.
   - Clean up: Use `teardown()` to remove temporary files unless debugging.

---

## Design

**TODO**:

- Add default bats script

**Updated BATS Script:** `./scripts/tests/node_pnpm_html_website.bats`

```bat
#!/usr/bin/env bats
# Version:0.1
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

  # Verify and copy recipe

  if [[ ! -f "$RECIPE" ]]; then
    echo "Error: $RECIPE not found" >&2
    return 1
  fi
  cp "$RECIPE" "$TEST_DIR/config.yaml"
}

teardown() {

  # Optionally keep test directory for debugging; comment out to preserve

  rm -rf "$TEST_DIR"
}

@test "node_pnpm_html_website: setup creates expected files" {
  run bash "$TEST_DIR/scripts/setup_project.sh" --config-path "$TEST_DIR/config.yaml" --recipe "$TEST_DIR/config.yaml" --verbose debug
  [ "$status" -eq 0 ]
  [ -f "$TEST_DIR/index.html" ]
  [ -f "$TEST_DIR/package.json" ]
  [ -f "$TEST_DIR/.vscode/settings.json" ]
  [ -f "$TEST_DIR/.vscode/launch.json" ]
  [ -f "$TEST_DIR/.gitignore" ]
  [ -f "$TEST_DIR/README.md" ]
  [ -f "$TEST_DIR/main.sh" ]
}

@test "node_pnpm_html_website: log contains success message" {
  run bash "$TEST_DIR/scripts/setup_project.sh" --config-path "$TEST_DIR/config.yaml" --recipe "$TEST_DIR/config.yaml" --verbose debug
  [ "$status" -eq 0 ]
  log_file=$(ls "$TEST_DIR/logs/" | tail -n 1)
  [ -n "$log_file" ] # Ensure log file exists
  grep -q "Project setup complete" "$TEST_DIR/logs/$log_file"
}

@test "node_pnpm_html_website: package.json has correct name" {
  run bash "$TEST_DIR/scripts/setup_project.sh" --config-path "$TEST_DIR/config.yaml" --recipe "$TEST_DIR/config.yaml" --verbose debug
  [ "$status" -eq 0 ]
  grep -q '"name": "html_website"' "$TEST_DIR/package.json"
}
```

---

## Analysis

### Analysis of the Issue

1. **Why the BATS Tests Failed**:
   - The BATS test script (`./scripts/tests/node_pnpm_html_website.bats`) assumes the test directory `./tests/node_pnpm_html_website_v0.1.0/` exists and contains the necessary files (`index.html`, `package.json`, etc.).
   - You moved the test directory to `./tests/node_pnpm_html_website_v0.1.0.bac/` before running the tests, so the `setup()` function in the BATS script tried to create and populate a new, empty `./tests/node_pnpm_html_website_v0.1.0/` directory, which didn’t have the expected files.
   - This caused all three tests to fail:
     - `node_pnpm_html_website: setup creates expected files`: Failed because `index.html`, `package.json`, etc., were not found in the new, empty test directory.
     - `node_pnpm_html_website: log contains success message`: Failed because the `logs/` directory was empty (no log file was created).
     - `node_pnpm_html_website: package.json has correct name`: Failed because `package.json` was missing.

2. **Is a PAUSE Needed?**:
   - No, a pause is not needed to allow files to be created. The `setup_project.sh` script creates files synchronously during execution, and the BATS `run` command waits for the script to complete before checking the results. The issue is not about timing but about the test directory being moved, causing the BATS script to operate on an empty directory.
   - The `setup()` function in the BATS script creates the test directory and copies `setup_project.sh` and `config.yaml`, but it doesn’t account for the directory being missing or moved.

3. **Understanding BATS Files**:
   - **Purpose**: BATS (Bash Automated Testing System) is a testing framework for Bash scripts. It allows you to write unit tests to verify the behavior of your scripts, such as checking file creation, command outputs, or exit statuses.
   - **Structure**:
     - **Test File**: A `.bats` file contains multiple test cases, each starting with `@test "description" { ... }`.
     - **Setup/Teardown**: The `setup()` function runs before each test, and `teardown()` runs after each test. These are used to prepare and clean up the test environment (e.g., creating directories, copying files).
     - **Run Command**: The `run` command executes a command (e.g., `bash setup_project.sh`) and captures its exit status, output, and errors. You can then assert conditions like `[ "$status" -eq 0 ]` (command succeeded) or check for files with `[ -f "file" ]`.
     - **Assertions**: Use standard Bash commands like `test`, `grep`, or `[ ... ]` to verify conditions. If any assertion fails, the test fails.
   - **Use in Your Case**: The BATS script tests whether `setup_project.sh` creates the expected files (`index.html`, `package.json`, etc.), produces the correct log messages, and configures `package.json` with the expected name.

4. **Directory Structure**:
   - The `tree` output confirms that `setup_project.sh` worked correctly when run manually, creating:
     - `index.html`, `package.json`, `pnpm-lock.yaml` (from `pnpm init` and `pnpm add`).
     - `.vscode/settings.json`, `.vscode/launch.json`.
     - `.gitignore`, `README.md`, `main.sh`.
     - Logs in `logs/setup_project_20250715.log` and archives in `archives/`.
   - The issue is that the BATS script needs to operate on the correct directory.

---

### Fixing the BATS Test

To fix the test failures, we need to:

1. Ensure the BATS script uses the correct test directory (restore or recreate `./tests/node_pnpm_html_website_v0.1.0/`).
2. Update the BATS script to handle the test environment robustly, including checking for the recipe file and logging setup.
3. Clarify the test setup to avoid confusion about directory management.

#### Changes in the BATS Script

1. **Robust Setup**:
   - Added explicit cleanup of the test directory (`rm -rf "$TEST_DIR"`) in `setup()` to ensure a fresh environment.
   - Added checks for the existence of `setup_project.sh` and the recipe file, with error messages if they’re missing.
   - Ensured directories (`scripts/`, `logs/`, `archives/`) are created before copying files.

2. **Teardown**:
   - Kept `teardown()` to clean up the test directory, but commented it out optionally for debugging (you can preserve the directory to inspect files after a test run).

3. **Test Cases**:
   - Added checks for all expected files (`README.md`, `main.sh`, etc.) to match the `tree` output.
   - Added a check in the log test to ensure the log file exists before `grep`.

4. **Error Handling**:
   - Improved error messages in `setup()` to help diagnose issues (e.g., missing script or recipe).

---

### Steps to Resolve the Test Failures

1. **Restore or Recreate the Test Directory**:
   - Since you moved `./tests/node_pnpm_html_website_v0.1.0/` to `./tests/node_pnpm_html_website_v0.1.0.bac/`, you can either:
     - **Restore it**:

       ```bash
       mv ./tests/node_pnpm_html_website_v0.1.0.bac/ ./tests/node_pnpm_html_website_v0.1.0/
       ```

     - **Recreate it**:

       ```bash
       mkdir -p ./tests/node_pnpm_html_website_v0.1.0/{scripts,logs,archives}
       cp ./scripts/setup_project.sh ./tests/node_pnpm_html_website_v0.1.0/scripts/
       cp ./recipes/node_pnpm_html_website.yaml ./tests/node_pnpm_html_website_v0.1.0/config.yaml
       ```

   - For testing, I recommend recreating it to ensure a clean state, as the BATS script will handle populating it.

2. **Verify Prerequisites**:
   - Ensure `bats`, `git`, `yq`, and `pnpm` are installed:

     ```bash
     sudo apt update && sudo apt install -y bats git yq
     sudo npm install -g pnpm
     ```

   - Verify the recipe file exists at `./recipes/node_pnpm_html_website.yaml` (use the YAML from the previous response if needed).

3. **Run the BATS Test**:
   - Use the updated BATS script above:

     ```bash
     bats scripts/tests/node_pnpm_html_website.bats
     ```

   - Expected output:

     ```shell
     ✓ node_pnpm_html_website: setup creates expected files
     ✓ node_pnpm_html_website: log contains success message
     ✓ node_pnpm_html_website: package.json has correct name

     3 tests, 0 failures
     ```

4. **Inspect Results**:
   - If tests fail, check the test directory (`./tests/node_pnpm_html_website_v0.1.0/`) and logs (`./tests/node_pnpm_html_website_v0.1.0/logs/setup_project_20250715.log`) for errors.
   - Uncomment the `teardown()` line in the BATS script to preserve the test directory for debugging.

---

### Additional Recommendations

1. **Prevent Directory Issues**:
   - Add a check in the BATS script to ensure the parent `tests/` directory exists:

     ```bash
     setup() {
       mkdir -p ./tests
       TEST_DIR="./tests/node_pnpm_html_website_v0.1.0"
       # ... rest of setup ...
     }
     ```

   - Consider locking the test directory during execution to prevent accidental moves or deletions.

2. **Debugging Tips**:
   - Run BATS with `-x` to see command output:

     ```bash
     bats -x scripts/tests/node_pnpm_html_website.bats
     ```

   - Preserve the test directory by commenting out `rm -rf "$TEST_DIR"` in `teardown()`.

3. **Update GitHub Actions**:
   - Ensure the GitHub Actions workflow uses the updated BATS script and includes the `--recipe` flag:

     ```yaml
     - name: Run tests
       run: bats scripts/tests/node_pnpm_html_website.bats
     ```

4. **Next Steps**:
   - Test the `generic_bash.yaml` recipe with a similar BATS script.
   - Implement `--dry-run` mode (TODO #010) to simulate setups without file writes, which can help with testing.
   - Add more tests to verify `pnpm-lock.yaml`, `.gitignore` contents, or VSCode settings.

---

### Summary

- **Test Failures**: Caused by moving the test directory, which broke the BATS script’s assumptions.
- **No Pause Needed**: File creation is synchronous; the issue was directory management.
- **BATS Structure**: Consists of `setup()`, `teardown()`, and `@test` blocks, with `run` to execute commands and assertions to verify results.
- **Fix**: Use the updated BATS script, restore or recreate the test directory, and run the tests.
- **Next Steps**: Debug with `-x`, update GitHub Actions, and expand tests for other recipes.

Let me know if you need help with additional BATS tests, debugging specific failures, or implementing other TODOs from the script!

---

## References
