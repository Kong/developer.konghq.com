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
---

Administrators use platform installers to install kong-harnesses for every user of a computer or to deploy it across managed computers with a mobile device management (MDM) tool.
Developers installing kong-harnesses for their own account use the single-user steps on the [kong-harnesses page](/kong-harnesses/#install-kong-harnesses).

Download packages from `https://cloudsmith.io/~kong/repos/kong-harnesses/packages/`.
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
  - platform: Ubuntu (amd64 / arm64)
    packages: "`_linux_amd64.deb`, `_linux_arm64.deb`"
    path: "`/usr/bin/kong-harnesses`"
  - platform: Red Hat Enterprise Linux (amd64 / arm64)
    packages: "`_linux_amd64.rpm`, `_linux_arm64.rpm`"
    path: "`/usr/bin/kong-harnesses`"
{% endtable %}

## Check a downloaded file

Verify every downloaded package before installing it or adding it to an MDM tool.
The SHA-256 checksum confirms the file is complete.
The build provenance confirms the kong-harnesses release workflow built it from the release tag.

{:.warning}
> Do not install a file or add it to an MDM tool until all checks pass.
> A file that fails a check might not be the file built by the release workflow.

Download `SHA256SUMS.txt` and `kong-harnesses_TAG.sigstore.json` from the same release into the folder containing the package.
Replace `TAG` with the release version including its leading `v`, for example `v1.2.3`.
Run the following checks from that folder, replacing `FILE` with the full filename including its extension.

**1. Verify the SHA-256 checksum**

{% navtabs "verify-checksum" %}
{% navtab "macOS" %}

Verify `FILE` against `SHA256SUMS.txt`:

```sh
awk -v file='FILE' '$2 == file' SHA256SUMS.txt | shasum -a 256 --check
```

The command must print `FILE: OK`.

{% endnavtab %}
{% navtab "Linux" %}

Verify `FILE` against `SHA256SUMS.txt`:

```sh
awk -v file='FILE' '$2 == file' SHA256SUMS.txt | sha256sum --check
```

The command must print `FILE: OK`.

{% endnavtab %}
{% navtab "Windows" %}

Verify `FILE` against `SHA256SUMS.txt` in PowerShell:

```powershell
"$((Get-FileHash 'FILE' -Algorithm SHA256).Hash.ToLowerInvariant())  FILE" -cin (Get-Content SHA256SUMS.txt)
```

The command must print `True`.
The check is case-sensitive, so enter `FILE` exactly as it appears in `SHA256SUMS.txt`.

{% endnavtab %}
{% endnavtabs %}

**2. Verify the build provenance**

Install the [GitHub CLI](https://cli.github.com/) and verify `FILE` against `kong-harnesses_TAG.sigstore.json`:

{% navtabs "verify-provenance" %}
{% navtab "macOS and Linux" %}

```sh
gh attestation verify FILE \
  --bundle kong-harnesses_TAG.sigstore.json \
  --repo Kong/kong-harnesses \
  --signer-workflow Kong/kong-harnesses/.github/workflows/release.yml \
  --source-ref refs/tags/TAG
```

{% endnavtab %}
{% navtab "Windows" %}

```powershell
gh attestation verify FILE `
  --bundle kong-harnesses_TAG.sigstore.json `
  --repo Kong/kong-harnesses `
  --signer-workflow Kong/kong-harnesses/.github/workflows/release.yml `
  --source-ref refs/tags/TAG
```

{% endnavtab %}
{% endnavtabs %}

The command must exit with code `0`.

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
Verify that only administrators can modify `/usr/local` and `/usr/local/bin` before installing.
If either folder doesn't exist, the package creates it writable only by administrators.

1. Check ownership and permissions on `/usr/local` and `/usr/local/bin`:

   ```sh
   /bin/ls -lde /usr/local /usr/local/bin
   ```

   Each folder must be owned by `root`.
   Only `root` and the `admin` or `wheel` group can have write permission, and no access control entry can grant write permission to another account.
1. Download `_darwin_arm64.pkg` (Apple silicon) or `_darwin_amd64.pkg` (Intel) and verify it using [Check a downloaded file](#check-a-downloaded-file).
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

Upload the verified `.pkg` to your MDM tool, for example Jamf Pro, without modification.
The package doesn't contain installer scripts.

1. Assign `_darwin_arm64.pkg` to Apple silicon Macs and `_darwin_amd64.pkg` to Intel Macs.
1. Deploy to one test Mac first.
   For a new release, use a test Mac running the previous release, because an earlier receipt also passes a receipt-existence check.
1. Inspect the package receipt on the test Mac:

   ```sh
   pkgutil --pkg-info com.konghq.kong-harnesses
   ```

   The `version` line must match the release version without its leading `v`, for example `1.2.3`.
1. Assign the package to remaining Macs only after the MDM tool reports success on the test Mac and `version` matches.

{:.info}
> **Microsoft Intune macOS PKG detection:** Intune's macOS app (PKG) type detects installs by an app bundle ID or a matching package receipt.
> Because this package doesn't install an app bundle and writes only the receipt `com.konghq.kong-harnesses`, test it on one Mac first.
> If Intune doesn't report success or `version` doesn't match, use an MDM tool that checks the receipt's `version` field or the output of `/usr/local/bin/kong-harnesses version`, which includes the leading `v`, for example `v1.2.3`.

### Remove from macOS

Follow these steps to remove only the files installed by the macOS package:

1. If an MDM tool deploys the package to the Mac, remove the Mac from that deployment so the tool doesn't reinstall it.
1. Ask each developer on the Mac to [remove their settings](#remove-developer-settings).
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
   If any line starts with another character or prints `No such file or directory`, skip the next three steps (verifying and deleting the executable) so `rm` doesn't delete a file in another folder through a link.
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
   If any line starts with another character or prints `No such file or directory`, skip the next two steps (deleting the license files and folder) so `rm` doesn't delete files through a link.
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

When kong-harnesses runs from `C:\Program Files\Kong\kong-harnesses`, running [`kong-harnesses doctor`](/kong-harnesses/doctor/) (`kong-harnesses doctor --profile PROFILE`) also checks these permissions and reports the fix if another account can modify them.

### Install on Windows

1. Download `_windows_amd64.msi` (x64) or `_windows_arm64.msi` (Arm) and verify it using [Check a downloaded file](#check-a-downloaded-file).
1. Open PowerShell as an administrator.
1. Run the silent Windows installer, replacing `MSI_PATH` with the full path to the `.msi` file:

   ```powershell
   (Start-Process msiexec.exe -ArgumentList '/i "MSI_PATH" /qn /norestart' -Wait -PassThru).ExitCode
   ```

   The command prints `0` when the installation completes.
   It prints `3010` when the installation completes and requires a restart to finish.
   Schedule a restart when you see `3010`.
   Because `/qn` suppresses error dialogs, any other exit code means the installation failed.

Installing a newer `.msi` replaces the installed version in place, and Windows Installer refuses an older installer.

### Deploy on Windows with Intune

Releases don't include an `.intunewin` file, so wrap the verified `.msi` installer and add one Windows app (Win32) for each processor type and each release.
See [Deploy the kong-harnesses Windows installer with Intune](/kong-harnesses/deploy-with-intune/) for step-by-step instructions.

### Remove from Windows

1. Ask each developer on the computer to [remove their settings](#remove-developer-settings).
1. If Microsoft Intune manages the app, remove the **Required** assignment for the target users or devices before uninstalling so Intune doesn't reinstall it.
1. Open PowerShell as an administrator and uninstall kong-harnesses with the `.msi` file that installed it, replacing `MSI_PATH` with its full path:

   ```powershell
   (Start-Process msiexec.exe -ArgumentList '/x "MSI_PATH" /qn /norestart' -Wait -PassThru).ExitCode
   ```

   If you don't have that `.msi` file, remove **Kong Harnesses** in **Settings** > **Apps** > **Installed apps**.

## Linux packages

On the Ubuntu and Red Hat Enterprise Linux releases that kong-harnesses supports, the `.deb` and `.rpm` packages install `kong-harnesses` in `/usr/bin` for every user.
The package manager handles upgrades and removal.

### Install on Linux

Download `_linux_amd64.deb` or `_linux_arm64.deb` (Ubuntu), or `_linux_amd64.rpm` or `_linux_arm64.rpm` (Red Hat Enterprise Linux), and verify it using [Check a downloaded file](#check-a-downloaded-file).
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

Ask each developer on the computer to [remove their settings](#remove-developer-settings) before uninstalling.
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
{% navtab "macOS and Linux" %}

```sh
command -v kong-harnesses
```

The command must print `/usr/local/bin/kong-harnesses` on macOS or `/usr/bin/kong-harnesses` on Linux.

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

## Remove developer settings

Removing kong-harnesses doesn't remove a developer's saved sign-ins, profiles, or coding agent settings.
Before removing kong-harnesses from a computer, ask each developer to run these steps in their own account:

1. Sign out of each profile with [`kong-harnesses logout`](/kong-harnesses/logout/):

   ```sh
   kong-harnesses logout --profile PROFILE
   ```

1. Remove credentials from coding agents that store their own sign-in:
   * **OpenCode:** Run `opencode auth logout`, then select the provider named after the profile.
   * **Hermes:** Run `hermes auth list kong-ai-gateway` to find each credential's entry ID, then remove each entry with `hermes auth remove kong-ai-gateway ENTRY_ID`.
     Do not pass an index, which changes when an earlier entry is removed, or a label, which Hermes refuses when more than one entry shares it.
1. Remove the coding agent settings added by kong-harnesses with [`kong-harnesses profile cleanup`](/kong-harnesses/profile/cleanup/):

   ```sh
   kong-harnesses profile cleanup
   ```

1. Delete each profile with [`kong-harnesses profile delete`](/kong-harnesses/profile/delete/):

   ```sh
   kong-harnesses profile delete PROFILE
   ```
