# Install terraform‑provider‑proxmox v0.111.1 on macOS (Apple Silicon darwin_arm64)
> README for offline manual install, to bypass GitHub release‑assets network timeout issue on mainland China networks.
> Target platform: **macOS darwin_arm64 (Apple Silicon M‑series)**
> Provider: `registry.terraform.io/bpg/proxmox ~> 0.111.1`

## Problem background
When running `terraform init`, Terraform tries to fetch checksum files from `release‑assets.githubusercontent.com`.
This domain often times‑out in restricted networks, causing errors like:
```
context deadline exceeded (Client.Timeout exceeded while awaiting headers)
```
`terraform providers mirror` cannot run on this machine because it still requires GitHub network access.
We build a local filesystem mirror manually with pre‑downloaded release artifacts.

## Release Assets Required (v0.111.1)
Download these files from GitHub Releases page:
https://github.com/bpg/terraform-provider-proxmox/releases/tag/v0.111.1

Required files for **darwin_arm64**:
1. `terraform-provider-proxmox_0.111.1_darwin_arm64.zip`
2. `terraform-provider-proxmox_0.111.1_SHA256SUMS`
3. `terraform-provider-proxmox_0.111.1_SHA256SUMS.sig`
4. `terraform-provider-proxmox_0.111.1_manifest.json`

> SHA256 reference:
> - `terraform-provider-proxmox_0.111.1_darwin_arm64.zip`: `58e0789923103a77d502a0a9fc3eb920625e8eb935ec2d4ac0d006aebd1d186c`

## Step 1: Create mirror directory structure
Open zsh terminal on macOS, run:
```zsh
mkdir -p /Users/ekin/tf-proxmox-mirror/registry.terraform.io/bpg/proxmox/0.111.1/darwin_arm64
```

## Step 2: Copy downloaded assets
Place the 4 downloaded files into this directory:
```
/Users/ekin/tf-proxmox-mirror/registry.terraform.io/bpg/proxmox/0.111.1/
```

Verify files exist:
```zsh
ls -la /Users/ekin/tf-proxmox-mirror/registry.terraform.io/bpg/proxmox/0.111.1
```

## Step 3: Unzip provider binary
```zsh
cd /Users/ekin/tf-proxmox-mirror/registry.terraform.io/bpg/proxmox/0.111.1
unzip terraform-provider-proxmox_0.111.1_darwin_arm64.zip -d darwin_arm64/
chmod +x darwin_arm64/terraform-provider-proxmox_v0.111.1
```

Check final folder tree:
```
/Users/ekin/tf-proxmox-mirror
└── registry.terraform.io
    └── bpg
        └── proxmox
            └── 0.111.1
                ├── terraform-provider-proxmox_0.111.1_darwin_arm64.zip
                ├── terraform-provider-proxmox_0.111.1_SHA256SUMS
                ├── terraform-provider-proxmox_0.111.1_SHA256SUMS.sig
                ├── terraform-provider-proxmox_0.111.1_manifest.json
                └── darwin_arm64
                    └── terraform-provider-proxmox_v0.111.1
```

## Step 4: Configure Terraform CLI config (`~/.terraformrc`)
> Important: **Do NOT use $HOME variable inside .terraformrc**, HCL does not expand shell environment variables. Use absolute full path.

Create or edit `~/.terraformrc`:
```hcl
provider_installation {
  filesystem_mirror {
    path    = "/Users/ekin/tf-proxmox-mirror"
    include = ["registry.terraform.io/bpg/proxmox"]
  }
  direct {
    exclude = ["registry.terraform.io/bpg/proxmox"]
  }
}
```

## Step 5: Initialize your Terraform project
```zsh
cd your-terraform-project-folder

# clean old cache and lock file
rm -rf .terraform .terraform.lock.hcl

terraform init
```

## Disable mirror (fall back to network install)
If you later have a working network/proxy and want to use normal registry download:
```zsh
mv ~/.terraformrc ~/.terraformrc.bak
rm -rf .terraform .terraform.lock.hcl
terraform init
```

## Troubleshooting common errors
1. `lstat /Users/ekin/tf-proxmox-mirror: no such file or directory`
   - Mirror folder missing. Re‑create directory and confirm absolute path matches `.terraformrc`.
2. Signature / checksum validation failure
   - Ensure `terraform-provider-proxmox_0.111.1_SHA256SUMS.sig` file is present in version folder.
3. Wrong platform directory name
   - Apple Silicon macOS must use `darwin_arm64`, **not darwin_amd64 / linux_amd64**.
4. `terraform providers mirror` still times‑out
   - This command requires GitHub connectivity. Do not run it on restricted‑network Mac, build mirror manually.

## Quick proxy alternative (if you have a local proxy)
Skip manual mirror entirely. Backup `.terraformrc`, set proxy env variables:
```zsh
mv ~/.terraformrc ~/.terraformrc.bak
export HTTP_PROXY=http://127.0.0.1:7890
export HTTPS_PROXY=http://127.0.0.1:7890
export NO_PROXY=localhost,127.0.0.1

rm -rf .terraform .terraform.lock.hcl
terraform init
```

> Note: Adjust proxy host/port value to match your local proxy service.

---

You can save this content as `README‑proxmox‑macos‑offline.md`.
If you need me to output raw markdown text without formatting blocks for direct file copy, I can do that.