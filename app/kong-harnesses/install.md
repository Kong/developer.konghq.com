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
---

A developer who installs kong-harnesses for themselves follows the steps on the [kong-harnesses page](/kong-harnesses/#install-kong-harnesses). An administrator who installs it for every user of a computer, or deploys it to many computers with a mobile device management (MDM) tool, uses the installer for the platform: the installer package (`.pkg`) on macOS, the Windows installer (`.msi`), or the `.deb` or `.rpm` package on Linux.

Download the files from the kong-harnesses repository at `https://cloudsmith.io/~kong/repos/kong-harnesses/packages/`. Each release has one file of each package type for each processor type. The filename contains `_amd64` for Intel and AMD processors, or `_arm64` for Arm processors such as Apple silicon. A prerelease doesn't include the Windows installer.

## Check a downloaded file

Check each file before you install it or add it to an MDM tool. The checksum shows that the file is complete. The build provenance shows that the release workflow of kong-harnesses built the file from the release tag.

1. Download `SHA256SUMS.txt` and `kong-harnesses_<tag>.sigstore.json` from the same release, into the folder of the file. `<tag>` is the release version with its initial `v`, for example `v1.2.3`.
1. Check the checksum of the file. On macOS, run:

   ```sh
   grep -F '<file>' SHA256SUMS.txt | shasum -a 256 --check
   ```

   On Linux, run the same command with `sha256sum --check` in place of `shasum -a 256 --check`. The command must print `<file>: OK`.

   On Windows, run in PowerShell:

   ```powershell
   (Get-FileHash <file> -Algorithm SHA256).Hash -eq (Select-String -Path SHA256SUMS.txt -SimpleMatch '<file>').Line.Split(' ')[0]
   ```

   The command must print `True`.
1. Install the [GitHub CLI](https://cli.github.com/), and check the build provenance of the file:

   ```sh
   gh attestation verify <file> --bundle kong-harnesses_<tag>.sigstore.json --repo Kong/kong-harnesses --signer-workflow Kong/kong-harnesses/.github/workflows/release.yml --source-ref refs/tags/<tag>
   ```

{:.warning}
> Do not install a file or add it to an MDM tool if a check fails. A file that fails a check is not the file that the release workflow built.

## macOS installer package

The installer package installs `kong-harnesses` in `/usr/local/bin` for every user of the Mac, and the license and third-party notices in `/usr/local/share/doc/kong-harnesses`. Kong signs the package with its Developer ID Installer certificate, and Apple notarizes it. The notarization ticket is stapled to the package, so the package installs without network access.

{:.warning}
> Do not use both Homebrew and the installer package on one Mac. On an Intel Mac, Homebrew installs its own `kong-harnesses` at the same path, `/usr/local/bin/kong-harnesses`. The package keeps the permissions of `/usr/local/bin`, so before you install the package, make sure that only administrators can change this folder.

1. Download the file that ends in `_darwin_arm64.pkg` for Apple silicon, or in `_darwin_amd64.pkg` for an Intel Mac.
1. Check the package as in [Check a downloaded file](#check-a-downloaded-file).
1. Check that Kong signed the package:

   ```sh
   pkgutil --check-signature <file>.pkg | grep -F 'Developer ID Installer: Kong Inc. (FX44YY62GV)'
   ```

   The command must print the certificate line. If it prints nothing, do not install the package.
1. Check that Apple notarized the package:

   ```sh
   spctl --assess --type install -vv <file>.pkg
   ```

   The command must print `accepted` and `source=Notarized Developer ID`. If it prints something else, do not install the package.
1. Install the package:

   ```sh
   sudo installer -pkg <file>.pkg -target /
   ```

A newer package replaces the installed version. To remove kong-harnesses, delete its files:

```sh
sudo rm -r /usr/local/bin/kong-harnesses /usr/local/share/doc/kong-harnesses
```

Then delete the package receipt:

```sh
sudo pkgutil --forget com.konghq.kong-harnesses
```

To deploy kong-harnesses with an MDM tool, such as Jamf Pro or Intune, add the installer package to the tool without changes. The package is signed and notarized, and it doesn't contain installer scripts.

## Windows installer

The Windows installer installs kong-harnesses in `C:\Program Files\Kong\kong-harnesses` for every user of the computer, and adds that folder to the system `PATH`.

1. Download the file that ends in `_windows_amd64.msi` for an x64 computer, or in `_windows_arm64.msi` for an Arm computer.
1. Check the installer as in [Check a downloaded file](#check-a-downloaded-file).
1. Open PowerShell as an administrator, and run the installer:

   ```powershell
   (Start-Process msiexec.exe -ArgumentList '/i', '<file>.msi', '/qn' -Wait -PassThru).ExitCode
   ```

   The command prints `0` when the install is complete. With `/qn`, the installer doesn't show errors, so any other number means that the install failed.

A newer installer replaces the installed version, and Windows Installer refuses an older installer. To remove kong-harnesses, run the same command as an administrator with `'/x'` in place of `'/i'`, with the installer that installed it.

When kong-harnesses runs from `C:\Program Files\Kong\kong-harnesses`, `kong-harnesses doctor --profile <profile>` checks that only administrators can change that folder and the folders that contain it. An account that can change these folders can replace kong-harnesses with a program that takes the sign-in of each developer. In that case, the check fails and names the fix.

### Deploy the Windows installer with Intune

Releases don't include an `.intunewin` file, so you wrap the installer yourself. Add one Windows app (Win32) for each processor type:

1. Check the installer as in [Check a downloaded file](#check-a-downloaded-file), and put the installer alone in an empty folder.
1. Wrap the installer with the [Microsoft Win32 Content Prep Tool](https://github.com/microsoft/Microsoft-Win32-Content-Prep-Tool):

   ```powershell
   IntuneWinAppUtil.exe -c <folder> -s <file>.msi -o <output-folder>
   ```

1. In the Microsoft Intune admin center, add a Windows app (Win32), and upload the `.intunewin` file. Intune reads the installer and fills in the install and uninstall commands. Keep these commands, and keep the install behavior **System**.
1. Under **Requirements**, select **x64** for the `_windows_amd64.msi` installer, or **ARM64** for the `_windows_arm64.msi` installer, and select the minimum operating system for your computers.
1. Under **Detection rules**, select **Manually configure detection rules**, and add a rule of type **MSI**. Intune fills in the product code of the installer. Keep it.
1. Under **Assignments**, assign the app as **Required** to the devices or users that need kong-harnesses.

For each new release, add a new app in the same way, with the same assignments, because a new app doesn't copy the assignments of the previous app. Under **Supersedence**, select the app of the previous release, and set **Uninstall previous version** to **No**. The new installer upgrades the installed version, so each developer keeps their sign-in and settings.

## Linux packages

On Ubuntu and Red Hat Enterprise Linux, the `.deb` and `.rpm` packages install `kong-harnesses` in `/usr/bin` for every user, and the package manager upgrades and removes it.

1. Download the file that ends in `_linux_amd64.deb` or `_linux_arm64.deb` for Ubuntu, or in `_linux_amd64.rpm` or `_linux_arm64.rpm` for Red Hat Enterprise Linux.
1. Check the package as in [Check a downloaded file](#check-a-downloaded-file).
1. Install the package:

   * Ubuntu: `sudo apt install ./<file>.deb`
   * Red Hat Enterprise Linux: `sudo dnf install ./<file>.rpm`

To remove kong-harnesses, run `sudo apt remove kong-harnesses` on Ubuntu, or `sudo dnf remove kong-harnesses` on Red Hat Enterprise Linux.

## Check the installation

Check the installed version in a new terminal:

```sh
kong-harnesses version
```

## Remove the settings of a developer

Removing kong-harnesses doesn't remove the sign-in, the profiles or the coding agent settings of each developer. Before you remove kong-harnesses from a computer, ask each developer to run these commands in their own account:

1. Remove the saved sign-in of each profile:

   ```sh
   kong-harnesses logout --profile <profile>
   ```

1. Remove the settings that kong-harnesses added to the coding agents:

   ```sh
   kong-harnesses profile cleanup
   ```

1. Delete each profile:

   ```sh
   kong-harnesses profile delete <profile>
   ```
