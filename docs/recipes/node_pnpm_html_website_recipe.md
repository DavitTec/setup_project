# Node.js Static HTML Website Recipe

This recipe sets up a Node.js-based static HTML website using `pnpm`.

## Overview

- **Purpose**: Initialize a static website with `index.html`, `pnpm` dependencies, and VSCode support.
- **File**: `./recipes/node_pnpm_html_website.yaml`
- **Use Case**: Simple static websites with HTML/CSS/JS.

## Structure

- **Project Metadata**: Name, version, author, `node` language, `pnpm` package manager.
- **Git**: Initializes with a Node.js-specific `.gitignore`.
- **VSCode**: Configures `settings.json` with Prettier and ESLint extensions.
- **Dependencies**:
  - Global: `git`, `yq`, `pnpm`.
  - Project: `prettier`, `eslint`, `serve`.
- **Files**: Generates `index.html` and `package.json`.
- **Logging**: Debug verbosity, stored in `logs/`.
- **Backup**: Archives to `archives/`.

## Usage

```bash
./scripts/setup_project.sh --recipe ./recipes/node_pnpm_html_website.yaml

```

## Customization

- Edit `project.name` and `project.version` in the YAML.
- Add more dependencies under `dependencies.project`.
- Modify `files` to include additional HTML/CSS/JS files.

## Testing

Tests are located in `./tests/node_pnpm_html_website_v0.1.0/`.
Run with:

```bash
bats scripts/tests/node_pnpm_html_website.bats
```

**Development Steps**:

1. Create `./recipes/node_pnpm_html_website.yaml` with the content above.
2. Create `./scripts/tests/node_pnpm_html_website.bats` with the test script.
3. Create `./docs/recipes/node_pnpm_html_website_recipe.md` with the documentation.
4. Update `setup_project.sh` to support the `--recipe` flag:

   ```bash
   main() {
     local recipe="./recipes/generic_bash.yaml"
     while [[ $# -gt 0 ]]; do
       case $1 in
         --recipe) recipe="$2"; shift ;;
         # ... other options ...
       esac
       shift
     done
     if [[ -f "$recipe" ]]; then
       log "Using recipe: $recipe"
       # Merge recipe with initial_config.yaml (if present)
       # Example: yq ea '. as $item ireduce ({}; . * $item )' initial_config.yaml "$recipe" > merged_config.yaml
     else
       log "Recipe not found, using default settings"
     fi
     # ... rest of main ...
   }
   ```

5. Test locally:

   ```bash
   sudo apt install bats
   bats scripts/tests/node_pnpm_html_website.bats
   ```

6. Push changes to a `feature/testing` branch and update `.github/workflows/test.yml`.
