---
title: Install kong-harnesses for every user of a computer
description: Install kong-harnesses system-wide on macOS, Windows, and Linux using platform installers, verify downloads, and deploy packages with an MDM tool.
content_type: reference
layout: reference

products:
  - ai-gateway

works_on:
  - konnect

tools:
  - kong-harnesses

tags:
  - cli
  - install

breadcrumbs:
  - /kong-harnesses/

related_resources:
  - text: kong-harnesses
    url: /kong-harnesses/
  - text: Set up {{ site.claude_code }} with kong-harnesses
    url: /ai-gateway/set-up-claude-code-with-kong-harnesses/
  - text: kong-harnesses doctor
    url: /kong-harnesses/doctor/
  - text: Deploy the kong-harnesses Windows installer with Intune
    url: /kong-harnesses/deploy-with-intune/
  - text: Remove kong-harnesses
    url: /kong-harnesses/remove-kong-harnesses/
---

Administrators use platform installers to install kong-harnesses for every user of a computer or to deploy it across managed computers with a mobile device management (MDM) tool.
Developers installing kong-harnesses for their own account use the single-user steps on the [kong-harnesses page](/kong-harnesses/#install-kong-harnesses).

## Platform packages

Download packages from the kong-harnesses Cloudsmith repository at `https://cloudsmith.io/~kong/repos/kong-harnesses/packages/`.
Choose `_amd64` for Intel and AMD (x64) processors, or `_arm64` for Arm processors such as Apple silicon.
A prerelease doesn't include the Windows installer (`.msi`).

{% table %}
columns:
  - title: Platform
    key: platform
  - title: Package filenames
    key: packages
  - title: Install path
    key: path
rows:
  - platform: macOS (Apple silicon / Intel)
    packages: "`_darwin_arm64.pkg`, `_darwin_amd64.pkg`"
    path: "`/usr/local/bin/kong-harnesses`"
  - platform: Windows 11 (x64 / Arm)
    packages: "`_windows_amd64.msi`, `_windows_arm64.msi`"
    path: "`C:\\Program Files\\Kong\\kong-harnesses\\kong-harnesses.exe`"
  - platform: Ubuntu 26.04, 24.04, 22.04 (amd64 / arm64)
    packages: "`_linux_amd64.deb`, `_linux_arm64.deb`"
    path: "`/usr/bin/kong-harnesses`"
  - platform: Red Hat Enterprise Linux 9 (amd64 / arm64)
    packages: "`_linux_amd64.rpm`, `_linux_arm64.rpm`"
    path: "`/usr/bin/kong-harnesses`"
{% endtable %}

## Check a downloaded file

Verify every downloaded package before installing it or adding it to an MDM tool.
The SHA-256 checksum confirms the file is complete.
The build provenance confirms that a Kong GitHub Actions workflow built it from the release tag on a GitHub-hosted runner.

{:.warning}
> Do not install a file or add it to an MDM tool until all checks pass.
> A file that fails a check might not be the file that Kong built.

Download `SHA256SUMS.txt` and `kong-harnesses_TAG.sigstore.json` of the same release from the kong-harnesses Cloudsmith repository into the folder containing the package.
Replace `TAG` with the release version including its leading `v`, for example `v1.2.3`.
Run the following checks from that folder, replacing `FILE` with the full filename including its extension.
The build provenance check needs the [GitHub CLI](https://cli.github.com/).

{% navtabs "check-downloaded-file" %}
{% navtab "macOS" %}

1. Verify `FILE` against `SHA256SUMS.txt`:

   ```sh
   awk -v file='FILE' '$2 == file' SHA256SUMS.txt | shasum -a 256 --check
   ```

   The command must print `FILE: OK`.
1. Verify the build provenance of `FILE` against `kong-harnesses_TAG.sigstore.json`:

   ```sh
   gh attestation verify FILE \
     --bundle kong-harnesses_TAG.sigstore.json \
     --owner Kong \
     --source-ref refs/tags/TAG \
     --deny-self-hosted-runners
   ```

   The command must exit with code `0`.

{% endnavtab %}
{% navtab "Linux" %}

1. Verify `FILE` against `SHA256SUMS.txt`:

   ```sh
   awk -v file='FILE' '$2 == file' SHA256SUMS.txt | sha256sum --check
   ```

   The command must print `FILE: OK`.
1. Verify the build provenance of `FILE` against `kong-harnesses_TAG.sigstore.json`:

   ```sh
   gh attestation verify FILE \
     --bundle kong-harnesses_TAG.sigstore.json \
     --owner Kong \
     --source-ref refs/tags/TAG \
     --deny-self-hosted-runners
   ```

   The command must exit with code `0`.

{% endnavtab %}
{% navtab "Windows" %}

1. In PowerShell, verify `FILE` against `SHA256SUMS.txt`:

   ```powershell
   "$((Get-FileHash 'FILE' -Algorithm SHA256).Hash.ToLowerInvariant())  FILE" -cin (Get-Content SHA256SUMS.txt)
   ```

   The command must print `True`.
   The check is case-sensitive, so enter `FILE` exactly as it appears in `SHA256SUMS.txt`.
1. Verify the build provenance of `FILE` against `kong-harnesses_TAG.sigstore.json`:

   ```powershell
   gh attestation verify FILE `
     --bundle kong-harnesses_TAG.sigstore.json `
     --owner Kong `
     --source-ref refs/tags/TAG `
     --deny-self-hosted-runners
   ```

   The command must exit with code `0`.

{% endnavtab %}
{% endnavtabs %}

## macOS installer package

The macOS installer package (`.pkg`) installs `kong-harnesses` in `/usr/local/bin` for every user and writes `LICENSE` and third-party notices (`COPYRIGHT`) to `/usr/local/share/doc/kong-harnesses`.
Kong signs the package with its Developer ID Installer certificate and Apple notarizes it.
The notarization ticket is stapled to the package, so it installs without network access.

{:.warning}
> Do not install kong-harnesses by another method on a Mac that uses the installer package.
> On an Intel Mac, Homebrew installs `kong-harnesses` at `/usr/local/bin/kong-harnesses`, and a release archive can also go to that path.
> Package removal cannot distinguish a release archive copy from the package copy.

### Install on macOS

The macOS package preserves permissions on existing folders.
If `/usr/local` or `/usr/local/bin` doesn't exist, the package creates it writable only by administrators.

1. Check ownership and permissions on `/usr/local` and `/usr/local/bin`:

   ```sh
   /bin/ls -lde /usr/local /usr/local/bin
   ```

   Each existing path must start with `d` (a directory, not a symbolic link) and be owned by `root`.
   Only `root` and the `admin` or `wheel` group can have write permission, and no access control entry can grant write permission to another account.
1. Download the macOS package for your processor from [Platform packages](#platform-packages) and verify it using [Check a downloaded file](#check-a-downloaded-file).
1. Verify Kong's Developer ID Installer signature:

   ```sh
   pkgutil --check-signature FILE | grep -F 'Developer ID Installer: Kong Inc. (FX44YY62GV)'
   ```

   The command must print the certificate line.
   If it prints nothing, do not install the package.
1. Verify Apple notarization:

   ```sh
   spctl --assess --type install -vv FILE
   ```

   The command must print `accepted` and `source=Notarized Developer ID`.
   If it prints anything else, do not install the package.
1. Install the package:

   ```sh
   sudo installer -pkg FILE -target /
   ```

Installing a newer macOS package replaces the installed version.

### Deploy on macOS with an MDM tool

The macOS package preserves permissions on existing folders and doesn't contain installer scripts.
Upload the verified `.pkg` (with passing checksum, provenance, Developer ID Installer signature, and Apple notarization checks) to your MDM tool, for example Jamf Pro, without modification.

1. Confirm that on every target Mac where `/usr/local` or `/usr/local/bin` exists, each path is a directory owned by `root` and writable only by administrators, using step 1 of [Install on macOS](#install-on-macos).
1. Assign the Arm package from [Platform packages](#platform-packages) to Apple silicon Macs and the Intel package to Intel Macs.
1. Deploy to one test Mac first.
   For a new release, use a test Mac running the previous release, because an earlier receipt also passes a receipt-existence check.
1. Inspect the package receipt on the test Mac:

   ```sh
   pkgutil --pkg-info com.konghq.kong-harnesses
   ```

   The `version` line must match the release version without its leading `v`, for example `1.2.3`.
1. Assign the package to remaining Macs only after the MDM tool reports success on the test Mac and `version` matches.

{:.info}
> **Microsoft Intune macOS PKG detection:** Microsoft Intune's **macOS app (PKG)** type cannot report installation success for this package.
> Intune's [unmanaged macOS PKG detection rules](https://learn.microsoft.com/en-us/intune/app-management/deployment/add-unmanaged-pkg-macos#step-4--detection-rules) detect and monitor installations using the bundle IDs and build numbers of included `.app` applications, and **Included apps** must contain only applications.
> The kong-harnesses `.pkg` installs only `/usr/local/bin/kong-harnesses` and documentation files without a `.app` bundle.
> Check deployment on the Mac with `pkgutil --pkg-info com.konghq.kong-harnesses` (receipt `version` field) or `/usr/local/bin/kong-harnesses version`, or deploy with an MDM tool that checks the receipt version.
> The `version` command output includes the leading `v`, for example `v1.2.3`.

### Remove from macOS

Follow these steps to remove only the files installed by the macOS package:

1. Ask each developer on the Mac to [remove their sign-ins, settings, and profiles](/kong-harnesses/remove-kong-harnesses/).
1. If an MDM tool deploys the package to the Mac, remove the Mac from that deployment so the tool doesn't reinstall it.
1. Confirm the installer package created the installation:

   ```sh
   pkgutil --pkg-info com.konghq.kong-harnesses
   ```

   If the command fails with `No receipt for 'com.konghq.kong-harnesses' found at '/'.`, the installer package didn't install kong-harnesses.
   Skip the remaining steps.
1. Check `/usr/local/bin/kong-harnesses` and its parent folders for symbolic links:

   ```sh
   /bin/ls -ld /usr/local /usr/local/bin /usr/local/bin/kong-harnesses
   ```

   The `/usr/local` and `/usr/local/bin` lines must start with `d`, and the `/usr/local/bin/kong-harnesses` line must start with `-`.
   If any line starts with another character or prints `No such file or directory`, skip the next three steps (verifying and deleting the executable).
   Skipping them prevents `rm` from deleting a file in another folder through a symbolic link.
   If `/usr/local/bin/kong-harnesses` links to a path containing `Cellar`, Homebrew installed it.
   Remove that copy with Homebrew instead.
1. Print the executable checksum stored in the package receipt:

   ```sh
   lsbom -f -p fc /var/db/receipts/com.konghq.kong-harnesses.bom
   ```

1. Print the checksum of the installed executable:

   ```sh
   cksum /usr/local/bin/kong-harnesses
   ```

   The first number must match the number on the `./bin/kong-harnesses` line of the receipt.
   If they don't match or the receipt doesn't contain `./bin/kong-harnesses`, another install replaced the package binary.
   Skip the next step (deleting the executable).
1. Delete the package executable:

   ```sh
   sudo rm /usr/local/bin/kong-harnesses
   ```

1. Check the documentation path for symbolic links:

   ```sh
   /bin/ls -ld /usr/local /usr/local/share /usr/local/share/doc /usr/local/share/doc/kong-harnesses
   ```

   All four lines must start with `d`.
   If any line starts with another character or prints `No such file or directory`, skip the next two steps (deleting the license files and folder).
   Skipping them prevents `rm` from deleting files in another folder through a symbolic link.
1. Delete the license and third-party notices:

   ```sh
   sudo rm -f /usr/local/share/doc/kong-harnesses/LICENSE /usr/local/share/doc/kong-harnesses/COPYRIGHT
   ```

1. Remove the documentation folder:

   ```sh
   sudo rmdir /usr/local/share/doc/kong-harnesses
   ```

   If the folder contains other files, `rmdir` fails and keeps them.
1. Delete the package receipt:

   ```sh
   sudo pkgutil --forget com.konghq.kong-harnesses
   ```

## Windows installer

The Windows installer (`.msi`) installs `kong-harnesses.exe` in `C:\Program Files\Kong\kong-harnesses` for every user on Windows 11 and adds that folder to the system `PATH`.
kong-harnesses doesn't support Windows 10.

{:.warning}
> Make sure that only administrators can modify `C:\Program Files\Kong\kong-harnesses\kong-harnesses.exe` and its parent folders.
> Any other account with write permission can replace kong-harnesses with a program that captures developer sign-ins.

When kong-harnesses runs from `C:\Program Files\Kong\kong-harnesses`, [`kong-harnesses doctor`](/kong-harnesses/doctor/) also checks these permissions and shows the fix.

### Install on Windows

1. Download the Windows installer for your processor from [Platform packages](#platform-packages) and verify it using [Check a downloaded file](#check-a-downloaded-file).
1. Open PowerShell as an administrator.
1. Run the silent Windows installer, replacing `MSI_PATH` with the full path to the `.msi` file:

   ```powershell
   (Start-Process msiexec.exe -ArgumentList '/i "MSI_PATH" /qn /norestart' -Wait -PassThru).ExitCode
   ```

   The command prints `0` when installation completes, or `3010` when installation completes and requires you to schedule a restart.
   Because `/qn` suppresses error dialogs, any other exit code means the installation failed.

Installing a newer `.msi` replaces the installed version in place, and Windows Installer refuses an older installer.

### Deploy on Windows with Intune

Releases don't include an `.intunewin` file, so wrap the verified `.msi` installer and add one Windows app (Win32) for each processor type and each release.
See [Deploy the kong-harnesses Windows installer with Intune](/kong-harnesses/deploy-with-intune/) for step-by-step instructions.

### Remove from Windows

1. Ask each developer on the computer to [remove their sign-ins, settings, and profiles](/kong-harnesses/remove-kong-harnesses/).
1. If Microsoft Intune manages the app, remove the **Required** assignment for the target users or devices before uninstalling so Intune doesn't reinstall it.
1. Open PowerShell as an administrator and uninstall kong-harnesses with the `.msi` file that installed it, replacing `MSI_PATH` with its full path:

   ```powershell
   (Start-Process msiexec.exe -ArgumentList '/x "MSI_PATH" /qn /norestart' -Wait -PassThru).ExitCode
   ```

   If you don't have that `.msi` file, remove **Kong Harnesses** in **Settings** > **Apps** > **Installed apps**.

## Linux packages

On Ubuntu 26.04, 24.04, and 22.04 and Red Hat Enterprise Linux 9, the `.deb` and `.rpm` packages install `kong-harnesses` in `/usr/bin` for every user.
The package manager handles upgrades and removal.

### Install on Linux

Download the Linux package for your distribution and processor from [Platform packages](#platform-packages), then verify it using [Check a downloaded file](#check-a-downloaded-file).
Install the verified package, replacing `FILE` with the downloaded filename:

{% navtabs "install-linux-package" %}
{% navtab "Ubuntu" %}

```sh
sudo apt install ./FILE
```

{% endnavtab %}
{% navtab "Red Hat Enterprise Linux" %}

```sh
sudo dnf install ./FILE
```

{% endnavtab %}
{% endnavtabs %}

### Remove from Linux

Ask each developer on the computer to [remove their sign-ins, settings, and profiles](/kong-harnesses/remove-kong-harnesses/) before uninstalling.
Remove the kong-harnesses package with your distribution's package manager:

{% navtabs "remove-linux-package" %}
{% navtab "Ubuntu" %}

```sh
sudo apt remove kong-harnesses
```

{% endnavtab %}
{% navtab "Red Hat Enterprise Linux" %}

```sh
sudo dnf remove kong-harnesses
```

{% endnavtab %}
{% endnavtabs %}

## Check the installation

Open a new terminal so `PATH` changes take effect, then verify both the executable path and the installed version.

Confirm the terminal resolves the system-wide executable:

{% navtabs "check-install-path" %}
{% navtab "macOS" %}

```sh
command -v kong-harnesses
```

The command must print `/usr/local/bin/kong-harnesses`.

{% endnavtab %}
{% navtab "Linux" %}

```sh
command -v kong-harnesses
```

The command must print `/usr/bin/kong-harnesses`.

{% endnavtab %}
{% navtab "Windows" %}

```powershell
(Get-Command kong-harnesses).Source
```

The command must print `C:\Program Files\Kong\kong-harnesses\kong-harnesses.exe`.

{% endnavtab %}
{% endnavtabs %}

Verify the installed release version:

```sh
kong-harnesses version
```

The command prints the release version with its leading `v`, for example `v1.2.3`.
