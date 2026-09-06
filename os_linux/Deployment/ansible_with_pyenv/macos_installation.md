# macOS Installation Plan: Ansible 2.21 + Python 3.1x + pyenv

> Scope: planning only. This document describes the target architecture, setup sequence, validation criteria, and maintenance strategy for a reproducible macOS environment that uses `pyenv` to manage an isolated Python 3.1x runtime and install `ansible-core` 2.21 without affecting the system Python.

## 1. Pre-Requirements

1. Do not use the macOS system Python.
   - Python must be managed by `pyenv` only.
   - Package installation must happen inside a `pyenv`-managed virtual environment.
2. Target versions.
   - `pyenv`: latest stable release.
   - Python: one fixed 3.1x minor release, such as Python 3.11.x or 3.12.x.
   - `ansible-core`: 2.21.x.
3. Base dependencies.
   - Xcode Command Line Tools.
   - Homebrew as the base package manager.
4. Isolation rules.
   - Keep the Python interpreter controlled by `pyenv global` or `pyenv local`.
   - Install Ansible inside a dedicated `pyenv` virtualenv.
   - Avoid mixing packages across environments.
5. Validation targets.
   - `python --version`
   - `ansible --version`
   - `which python`
   - `which ansible`
   - Confirm that the resolved paths point to `pyenv`-managed locations.

## 2. Overall Architecture

1. Homebrew provides `pyenv` and the build-time dependencies needed to compile Python.
2. `pyenv` compiles and manages a standalone Python 3.1x interpreter.
3. A dedicated `pyenv` virtualenv is created for Ansible 2.21 to isolate Ansible packages from other Python projects.
4. `ansible-core==2.21.x` is installed with `pip` inside that virtualenv.
5. The shell startup file, typically `~/.zshrc`, initializes `pyenv` so the shim directory has priority in `PATH`.
6. Verification confirms the Python and Ansible binaries, their versions, and basic runtime behavior.

## 3. Step-by-Step Planning Outline

### 3.1 Base System Preparation

1. Install Xcode Command Line Tools.
   - This provides the compiler toolchain required by `pyenv` to build Python from source.
2. Install Homebrew.
   - Homebrew is the base package manager for `pyenv` and supporting build dependencies.
3. Install `pyenv` and Python build dependencies with Homebrew.
   - Include the libraries commonly required for Python builds.
4. Configure `pyenv` initialization in `~/.zshrc`.
   - Ensure `pyenv init` is loaded for interactive shells.
   - Ensure the shim path is prioritized ahead of system and Homebrew binaries when appropriate.
5. Restart the shell session.
   - Reload profile settings so `pyenv` becomes available immediately.

### 3.2 Build Python 3.1x with pyenv

1. Enumerate available Python versions supported by `pyenv`.
   - Choose one fixed 3.1x release and keep it pinned.
2. Compile and install the selected Python version.
   - Use `pyenv install` to create a dedicated interpreter.
3. Verify the installed Python version.
   - Confirm the runtime matches the chosen 3.1x release.
4. Create a dedicated `pyenv` virtualenv for Ansible 2.21.
   - Example naming convention: `ansible-2.21-env`.
5. Activate the virtualenv.
   - Confirm the active `python` resolves to the `pyenv` virtualenv path.

### 3.3 Install Ansible 2.21 Inside the Virtualenv

1. Pin `ansible-core` to the 2.21 release series with `pip`.
   - The `ansible-core` package controls the engine version.
   - If the broader Ansible meta-package is needed later, it should be treated separately from the core runtime pin.
2. Avoid any Homebrew-installed Ansible binary.
   - Do not allow a Homebrew Ansible installation to take precedence over the `pyenv` virtualenv.
3. Verify the `ansible` executable location.
   - The resolved binary should live under the `pyenv` virtualenv directory.
4. Validate the installed version.
   - `ansible --version` must report the 2.21.x core release.

### 3.4 Environment Persistence Configuration

1. Define two usage modes.
   - Mode A: project-level activation using `pyenv local ansible-2.21-env` inside the working directory.
   - Mode B: manual activation using `pyenv activate ansible-2.21-env` when needed.
2. Keep the global Python clean.
   - Do not set the Ansible environment as the `pyenv global` default.
   - Preserve separate control for general Python use and Ansible use.
3. Document `PATH` precedence.
   - `pyenv` shims should appear before system and Homebrew `bin` directories when the Ansible environment is active.
4. Record the main conflict risk.
   - If Homebrew Ansible exists, either remove it or ensure the `pyenv` shim path wins.

### 3.5 Post-Deployment Validation Checklist

- `python --version` returns the selected Python 3.1x release.
- `which python` points to `~/.pyenv/shims` or the active `pyenv` virtualenv path.
- `ansible --version` reports `ansible-core 2.21.x`.
- `which ansible` points to the `pyenv` virtualenv directory.
- A basic ad-hoc check such as `ansible localhost -m ping` confirms the runtime works.
- `pip list` shows `ansible-core` at the expected version.

### 3.6 Known Risks and Mitigations

| Risk Item | Mitigation |
|---|---|
| macOS system Python is used accidentally | Never run `pip` without an active `pyenv` virtualenv; verify `which python` before package operations |
| Python compilation fails under `pyenv` | Ensure Homebrew build dependencies are installed and keep `pyenv` updated |
| Ansible binary conflict from Homebrew | Uninstall Homebrew Ansible or guarantee `pyenv` shim precedence in `PATH` |
| Shell startup file misses `pyenv` initialization | Keep the `pyenv` init block in `~/.zshrc` and reload the shell after changes |
| Virtualenv activation is forgotten | Prefer `pyenv local` for the Ansible working directory so activation happens automatically |

### 3.7 Maintenance and Upgrade Strategy

1. Do not upgrade the Ansible runtime beyond 2.21 in this environment.
   - Create a separate `pyenv` virtualenv for any future major Ansible version.
2. Handle Python patch updates deliberately.
   - Install the new Python 3.1x patch release and rebuild the virtualenv if needed.
3. Document the cleanup path.
   - Remove the environment with `pyenv virtualenv-delete ansible-2.21-env` when a fresh rebuild is required.

## 4. Recommended Operating Rules

1. Use one pinned Python version per Ansible environment.
2. Keep Ansible and general Python projects in separate `pyenv` virtualenvs.
3. Validate the active interpreter before every `pip` or `ansible` operation.
4. Treat Homebrew as the dependency source, not the runtime source, for Python-based tooling.
5. Prefer reproducibility over convenience when changing versions.

## 5. Acceptance Criteria

The plan is considered complete when all of the following are true:

1. The selected Python 3.1x version is installed through `pyenv`.
2. A dedicated Ansible 2.21 virtualenv exists and is isolated from other projects.
3. `ansible-core 2.21.x` is the active Ansible engine in that virtualenv.
4. `python` and `ansible` resolve to `pyenv`-managed paths.
5. The environment can be re-created from the documented procedure without modifying the macOS system Python.

## 6. Notes

1. This document intentionally avoids execution commands.
2. It is designed as an implementation plan that can be followed later in a controlled setup session.
3. If desired, this plan can be expanded into a full operational runbook with exact install commands and verification snippets.

## 7. Annotated Installation Commands

The following command set is provided for implementation reference. It is written for the target macOS environment and uses `pyenv` to isolate Python and Ansible from the system Python.

### 7.1 Install Base System Dependencies

```bash
# Install Xcode Command Line Tools required for compiling Python from source.
xcode-select --install

# Install Homebrew if it is not already present.
# Use the official Homebrew installer from the project documentation.

# Update Homebrew package metadata before installing anything else.
brew update

# Install pyenv and pyenv-virtualenv for Python version and environment isolation.
brew install pyenv pyenv-virtualenv

# Install common Python build dependencies needed by pyenv on macOS.
brew install openssl@3 readline sqlite3 xz zlib tcl-tk
```

### 7.2 Configure Shell Initialization for pyenv

```bash
# Add the following lines to ~/.zprofile if you want login shells to know where pyenv lives.
export PYENV_ROOT="$HOME/.pyenv"
export PATH="$PYENV_ROOT/bin:$PATH"

# Add the following lines to ~/.zshrc for interactive shell initialization.
eval "$(pyenv init --path)"
eval "$(pyenv init -)"
eval "$(pyenv virtualenv-init -)"
```

### 7.3 Load the Shell Configuration

```bash
# Reload the current shell so the new PATH and pyenv hooks become active.
source ~/.zprofile
source ~/.zshrc
```

### 7.4 Install a Fixed Python 3.1x Version

```bash
# List available Python versions and choose one fixed 3.1x release.
pyenv install --list

# Install the chosen Python version, for example Python 3.12.4.
pyenv install 3.12.4

# Confirm the interpreter is now available through pyenv.
pyenv versions
```

### 7.5 Create a Dedicated Ansible Virtualenv

```bash
# Create a dedicated virtual environment based on the pinned Python version.
pyenv virtualenv 3.12.4 ansible-2.21-env

# Activate the environment for the current shell session.
pyenv activate ansible-2.21-env

# Verify that python now resolves to the pyenv-managed virtualenv.
which python
python --version
```

### 7.6 Install Ansible 2.21 Inside the Virtualenv

```bash
# Upgrade packaging tools inside the isolated environment.
python -m pip install --upgrade pip setuptools wheel

# Install the pinned Ansible core release series.
python -m pip install "ansible-core==2.21.*"

# Confirm the Ansible executable is the one from the active virtualenv.
which ansible
ansible --version
```

### 7.7 Project-Level Environment Binding

```bash
# Inside the target project directory, bind the environment locally.
pyenv local ansible-2.21-env

# Confirm the local version file has been created and the environment is selected.
pyenv version
python --version
which ansible
```

### 7.8 Functional Verification

```bash
# Show the current Ansible runtime details.
ansible --version

# Confirm Python resolves to the pyenv shim path.
which python

# Confirm Ansible resolves to the pyenv virtualenv path.
which ansible

# Run a basic local connectivity check.
ansible localhost -m ping

# Confirm the package list contains the expected ansible-core release.
python -m pip list | grep ansible-core
```

### 7.9 Environment Cleanup and Rebuild

```bash
# Deactivate the current virtualenv if it is active.
pyenv deactivate

# Remove the dedicated environment when a clean rebuild is needed.
pyenv virtualenv-delete ansible-2.21-env
```

### 7.10 Notes on Command Usage

1. Do not run these commands with the macOS system Python.
2. Prefer `python -m pip` over bare `pip` so the active interpreter is explicit.
3. Keep the `ansible-2.21-env` virtualenv dedicated to Ansible and do not reuse it for unrelated Python projects.
4. If a Homebrew-provided `ansible` binary exists, remove it or ensure the `pyenv` shims directory has higher precedence in `PATH`.