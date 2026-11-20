---
title: Install kong-harnesses for every user of a computer
description: Install kong-harnesses for every user of a computer with the macOS installer package, the Windows installer or a Linux package, and deploy it to many computers with an MDM tool such as Intune.
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

A developer who installs kong-harnesses for themselves follows the steps on the [kong-harnesses page](/kong-harnesses/#install-kong-harnesses). An administrator who installs it for every user of a computer, or deploys it to many computers with a mobile device management (MDM) tool, uses the installer for the platform: the installer package (`.pkg`) on macOS, the Windows installer (`.msi`), or the `.deb` or `.rpm` package on Linux.

Download the files from the kong-harnesses repository at `https://cloudsmith.io/~kong/repos/kong-harnesses/packages/`. Each release has one file of each package type for each processor type. The filename contains `_amd64` for Intel and AMD processors, or `_arm64` for Arm processors such as Apple silicon. A prerelease doesn't include the Windows installer.

## Check a downloaded file

Check each file before you install it or add it to an MDM tool. The checksum shows that the file is complete. The build provenance shows that the release workflow of kong-harnesses built the file from the release tag.

1. Download `SHA256SUMS.txt` and `kong-harnesses_<tag>.sigstore.json` from the same release, into the folder of the file. `<tag>` is the release version with its initial `v`, for example `v1.2.3`. In the commands on this page, `<file>` is the full filename of the downloaded file, with its extension. Run the commands in this section in that folder.
1. Check the checksum of the file. On macOS, run:

   ```sh
   awk -v file='<file>' '$2 == file' SHA256SUMS.txt | shasum -a 256 --check
   ```

   On Linux, run the same command with `sha256sum --check` in place of `shasum -a 256 --check`. The command must print `<file>: OK`.

   On Windows, run in PowerShell:

   ```powershell
   "$((Get-FileHash '<file>' -Algorithm SHA256).Hash.ToLowerInvariant())  <file>" -cin (Get-Content SHA256SUMS.txt)
   ```

   The command must print `True`. The check is case-sensitive, so enter the filename exactly as it is in `SHA256SUMS.txt`.
1. Install the [GitHub CLI](https://cli.github.com/), and check the build provenance of the file. The command is the same in a macOS or Linux terminal and in PowerShell:

   ```sh
   gh attestation verify <file> --bundle kong-harnesses_<tag>.sigstore.json --repo Kong/kong-harnesses --signer-workflow Kong/kong-harnesses/.github/workflows/release.yml --source-ref refs/tags/<tag>
   ```

   The command must exit with code `0`.

{:.warning}
> Do not install a file or add it to an MDM tool until all checks pass. A file that fails a check might not be the file that the release workflow built.

## macOS installer package

The installer package installs `kong-harnesses` in `/usr/local/bin` for every user of the Mac, and the license and third-party notices in `/usr/local/share/doc/kong-harnesses`. Kong signs the package with its Developer ID Installer certificate, and Apple notarizes it. The notarization ticket is stapled to the package, so the package installs without network access.

{:.warning}
> Do not install kong-harnesses in another way on a Mac that has the installer package. On an Intel Mac, Homebrew installs its own `kong-harnesses` at the same path, `/usr/local/bin/kong-harnesses`, and a release archive can also go to that path. The removal steps for the package cannot tell a copy from a release archive from the copy of the package. The package keeps the permissions of folders that exist, so before you install the package, make sure that only administrators can change `/usr/local` and `/usr/local/bin`.

To check the permissions, run:

```sh
/bin/ls -lde /usr/local /usr/local/bin
```

The owner of each folder must be `root`. Only the owner and the `admin` or `wheel` group can have write permission, and no access control entry that the command shows can give another account write permission. If a folder doesn't exist, the package creates it, and only administrators can change it.

1. Download the file that ends in `_darwin_arm64.pkg` for Apple silicon, or in `_darwin_amd64.pkg` for an Intel Mac.
1. Check the package as in [Check a downloaded file](#check-a-downloaded-file).
1. Check that Kong signed the package:

   ```sh
   pkgutil --check-signature <file> | grep -F 'Developer ID Installer: Kong Inc. (FX44YY62GV)'
   ```

   The command must print the certificate line. If it prints nothing, do not install the package.
1. Check that Apple notarized the package:

   ```sh
   spctl --assess --type install -vv <file>
   ```

   The command must print `accepted` and `source=Notarized Developer ID`. If it prints something else, do not install the package.
1. Install the package:

   ```sh
   sudo installer -pkg <file> -target /
   ```

A newer package replaces the installed version. To remove kong-harnesses:

1. If an MDM tool deploys the package to the Mac, remove the Mac from that deployment, so that the tool doesn't install the package again.
1. Ask each developer to [remove their settings](#remove-the-settings-of-a-developer).
1. Check that the installer package installed kong-harnesses:

   ```sh
   pkgutil --pkg-info com.konghq.kong-harnesses
   ```

   If the command fails and prints `No receipt for 'com.konghq.kong-harnesses' found at '/'.`, the installer package didn't install kong-harnesses. Skip the next steps.
1. Check that the path of the executable doesn't contain a link:

   ```sh
   /bin/ls -ld /usr/local /usr/local/bin /usr/local/bin/kong-harnesses
   ```

   The lines of `/usr/local` and `/usr/local/bin` must start with `d`, and the line of `/usr/local/bin/kong-harnesses` must start with `-`. If a line starts with something else, or the command prints `No such file or directory`, skip the next three steps, because `rm` can delete a file in another folder through a link. If `/usr/local/bin/kong-harnesses` is a link to a path that contains `Cellar`, Homebrew installed this copy, so remove it with Homebrew.
1. Show the checksum that the package receipt has for the executable:

   ```sh
   lsbom -f -p fc /var/db/receipts/com.konghq.kong-harnesses.bom
   ```

1. Show the checksum of the installed executable:

   ```sh
   cksum /usr/local/bin/kong-harnesses
   ```

   The first number must match the number in the `./bin/kong-harnesses` line of the receipt. If the numbers don't match, or the receipt doesn't have a `./bin/kong-harnesses` line, another install replaced the copy of the package, so skip the next step.
1. Delete the executable of the package:

   ```sh
   sudo rm /usr/local/bin/kong-harnesses
   ```

1. Check that the path of the license and notices doesn't contain a link:

   ```sh
   /bin/ls -ld /usr/local /usr/local/share /usr/local/share/doc /usr/local/share/doc/kong-harnesses
   ```

   Each of the four lines must start with `d`. If a line starts with something else, or the command prints `No such file or directory`, skip the next two steps, because `rm` can delete files in another folder through a link.
1. Delete the license and notices of the package:

   ```sh
   sudo rm -f /usr/local/share/doc/kong-harnesses/LICENSE /usr/local/share/doc/kong-harnesses/COPYRIGHT
   ```

1. Delete the folder of the license and notices:

   ```sh
   sudo rmdir /usr/local/share/doc/kong-harnesses
   ```

   If the folder has other files, the command fails and keeps the folder and its files.
1. Delete the package receipt:

   ```sh
   sudo pkgutil --forget com.konghq.kong-harnesses
   ```

### Deploy the installer package with an MDM tool

Add the installer package to the MDM tool, such as Jamf Pro, without changes. The package is signed and notarized, and it doesn't contain installer scripts.

1. Assign the `_darwin_arm64.pkg` package to Apple silicon Macs, and the `_darwin_amd64.pkg` package to Intel Macs.
1. Assign the package to one test Mac first. For a new release, use a test Mac that has the previous release, because a receipt of the previous release also passes a receipt check.
1. On the test Mac, check the receipt:

   ```sh
   pkgutil --pkg-info com.konghq.kong-harnesses
   ```

   The `version` line must show the release version without its initial `v`, for example `1.2.3`.
1. Assign the package to other Macs only if the MDM tool reports the install on the test Mac as successful, and the `version` matches.

The macOS app (PKG) type of Intune detects an install by the bundle ID of an app bundle, or by a package receipt with that ID. This package doesn't install an app bundle, and its package receipt is `com.konghq.kong-harnesses`. If Intune doesn't report the install on the test Mac as successful, or the `version` doesn't match, deploy the package with an MDM tool that can check the release version. That tool can check the `version` in the receipt, or the output of `/usr/local/bin/kong-harnesses version`, which is the release version with its initial `v`, for example `v1.2.3`.

## Windows installer

The Windows installer installs kong-harnesses in `C:\Program Files\Kong\kong-harnesses` for every user of the computer, and adds that folder to the system `PATH`.

1. Download the file that ends in `_windows_amd64.msi` for an x64 computer, or in `_windows_arm64.msi` for an Arm computer.
1. Check the installer as in [Check a downloaded file](#check-a-downloaded-file).
1. Open PowerShell as an administrator.
1. Run the installer. Replace `<msi-path>` with the full path of the installer:

   ```powershell
   (Start-Process msiexec.exe -ArgumentList '/i "<msi-path>" /qn /norestart' -Wait -PassThru).ExitCode
   ```

   The command prints `0` when the install is complete. It prints `3010` when the install is complete and the computer must restart to finish it, so schedule a restart. With `/qn`, the installer doesn't show errors, so any other number means that the install failed.

A newer installer replaces the installed version, and Windows Installer refuses an older installer. Before you remove kong-harnesses, ask each developer to [remove their settings](#remove-the-settings-of-a-developer). If Intune manages the app, remove the **Required** assignment for the users or devices before you uninstall it, because Intune installs the app again while a **Required** assignment applies. To remove kong-harnesses, run the same command as an administrator with `/x` in place of `/i`, with the installer that installed it. If you don't have that installer, remove **Kong Harnesses** in **Settings** > **Apps** > **Installed apps**.

Make sure that only administrators can change `C:\Program Files\Kong\kong-harnesses\kong-harnesses.exe` and the folders that contain it. An account that can change the file or these folders can replace kong-harnesses with a program that takes the sign-in of each developer. When kong-harnesses runs from this folder, a developer who runs `kong-harnesses doctor --profile <profile>` also checks these permissions. If another account can change them, the check fails and names the fix.

### Deploy the Windows installer with Intune

Releases don't include an `.intunewin` file, so you wrap the installer and add one Windows app (Win32) for each processor type and each release. For the steps, see [Deploy the kong-harnesses Windows installer with Intune](/kong-harnesses/deploy-with-intune/).

## Linux packages

On the Ubuntu and Red Hat Enterprise Linux releases that kong-harnesses supports, the `.deb` and `.rpm` packages install `kong-harnesses` in `/usr/bin` for every user, and the package manager upgrades and removes it.

1. Download the file that ends in `_linux_amd64.deb` or `_linux_arm64.deb` for Ubuntu, or in `_linux_amd64.rpm` or `_linux_arm64.rpm` for Red Hat Enterprise Linux.
1. Check the package as in [Check a downloaded file](#check-a-downloaded-file).
1. Install the package:

   * Ubuntu: `sudo apt install ./<file>`
   * Red Hat Enterprise Linux: `sudo dnf install ./<file>`

Before you remove kong-harnesses, ask each developer to [remove their settings](#remove-the-settings-of-a-developer). To remove kong-harnesses, run `sudo apt remove kong-harnesses` on Ubuntu, or `sudo dnf remove kong-harnesses` on Red Hat Enterprise Linux.

## Check the installation

Open a new terminal, and check that the command runs the installed copy. On macOS or Linux, run:

```sh
command -v kong-harnesses
```

In PowerShell, run:

```powershell
(Get-Command kong-harnesses).Source
```

The command must print the path of the installed copy: `/usr/local/bin/kong-harnesses` on macOS, `/usr/bin/kong-harnesses` on Linux, or `C:\Program Files\Kong\kong-harnesses\kong-harnesses.exe` on Windows. Then check the installed version:

```sh
kong-harnesses version
```

## Remove the settings of a developer

Removing kong-harnesses doesn't remove the sign-in, the profiles or the coding agent settings of each developer. Before you remove kong-harnesses from a computer, ask each developer to run these commands in their own account:

1. Remove the saved sign-in of each profile:

   ```sh
   kong-harnesses logout --profile <profile>
   ```

   OpenCode and Hermes keep their own sign-in. For OpenCode, also run `opencode auth logout`, and select the provider that has the name of the profile. For Hermes, run `hermes auth list kong-ai-gateway` to find the index of each credential. Remove the credentials with `hermes auth remove kong-ai-gateway <index>`, from the highest index to the lowest, because a removal renumbers the credentials after it.

1. Remove the settings that kong-harnesses added to the coding agents:

   ```sh
   kong-harnesses profile cleanup
   ```

1. Delete each profile:

   ```sh
   kong-harnesses profile delete <profile>
   ```
