# Installing Terraform on macOS

This guide installs the Terraform CLI on macOS using Homebrew. It works on both
Apple silicon Macs and Intel Macs.

## Prerequisites

Open **Terminal** and check the Mac architecture:

```bash
uname -m
```

- `arm64` means Apple silicon.
- `x86_64` means Intel.

## Option 1: Install with Homebrew (recommended)

### 1. Install Homebrew

Skip this step if Homebrew is already installed. Otherwise, run the official
installer:

```bash
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
```

Follow the installer instructions. At the end, run the suggested commands to
add Homebrew to your shell environment.

Confirm that Homebrew is available:

```bash
brew --version
```

### 2. Install Terraform

```bash
brew tap hashicorp/tap
brew install hashicorp/tap/terraform
```

### 3. Verify the installation

```bash
terraform version
which terraform
```

The output should show the installed Terraform version and the executable path.

## Option 2: Install the official binary manually

Use this option when Homebrew is not suitable for your environment.

1. Open the [Terraform downloads page](https://developer.hashicorp.com/terraform/install).
2. Download the macOS package matching the Mac architecture:
   - Apple silicon: `arm64`
   - Intel: `amd64`
3. Unzip the downloaded archive.
4. Move the `terraform` executable into a directory on your `PATH`, for example:

   ```bash
   sudo install -m 0755 terraform /usr/local/bin/terraform
   ```

5. Verify the installation:

   ```bash
   terraform version
   ```

If `/usr/local/bin` is not on your `PATH`, add it to `~/.zshrc` and reload the
shell:

```bash
export PATH="/usr/local/bin:$PATH"
source ~/.zshrc
```

## Test Terraform in a new project

Create a working directory and initialize Terraform:

```bash
mkdir -p ~/terraform-demo
cd ~/terraform-demo
terraform init
```

`terraform init` should complete successfully. It is safe to run in an empty
directory; it prepares the directory for Terraform configuration.

## Upgrade Terraform

When Terraform was installed with Homebrew:

```bash
brew update
brew upgrade hashicorp/tap/terraform
terraform version
```

When Terraform was installed manually, download and replace the binary with a
new version from the [official downloads page](https://developer.hashicorp.com/terraform/install).

## Uninstall Terraform

For a Homebrew installation:

```bash
brew uninstall hashicorp/tap/terraform
```

For a manual installation, remove only the Terraform executable from the
directory where it was installed, for example:

```bash
sudo rm /usr/local/bin/terraform
```

## Troubleshooting

### `terraform: command not found`

Check whether the executable is on the `PATH`:

```bash
command -v terraform
echo "$PATH"
```

If Homebrew is installed but not available in the current shell, run the
`brew shellenv` command printed by the Homebrew installer, then open a new
Terminal window.

### macOS blocks the executable

Download Terraform only from the official HashiCorp website or install it with
the official Homebrew tap. If macOS asks for permission to run the executable,
review the prompt and allow it only when the downloaded package came from a
trusted source.
