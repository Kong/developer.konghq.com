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

1. Download `SHA256SUMS.txt` and `kong-harnesses_<tag>.sigstore.json` from the same release, into the folder of the file. `<tag>` is the release version with its initial `v`, for example `v1.2.3`. In the commands on this page, `<file>` is the full filename of the downloaded file, with its extension.
1. Check the checksum of the file. On macOS, run:

   ```sh
   awk -v file='<file>' '$2 == file' SHA256SUMS.txt | shasum -a 256 --check
   ```

   On Linux, run the same command with `sha256sum --check` in place of `shasum -a 256 --check`. The command must print `<file>: OK`.

   On Windows, run in PowerShell:

   ```powershell
   (Get-FileHash '<file>' -Algorithm SHA256).Hash -eq ((Select-String -Path SHA256SUMS.txt -Pattern ('^[0-9a-f]{64}  ' + [regex]::Escape('<file>') + '$')).Line.Split(' ')[0])
   ```

   The command must print `True`.
1. Install the [GitHub CLI](https://cli.github.com/), and check the build provenance of the file. The command is the same in a macOS or Linux terminal and in PowerShell:

   ```sh
   gh attestation verify <file> --bundle kong-harnesses_<tag>.sigstore.json --repo Kong/kong-harnesses --signer-workflow Kong/kong-harnesses/.github/workflows/release.yml --source-ref refs/tags/<tag>
   ```

   The command must print that the verification succeeded, and exit with code `0`.

{:.warning}
> Do not install a file or add it to an MDM tool until all checks pass. A file that fails a check might not be the file that the release workflow built.

## macOS installer package

The installer package installs `kong-harnesses` in `/usr/local/bin` for every user of the Mac, and the license and third-party notices in `/usr/local/share/doc/kong-harnesses`. Kong signs the package with its Developer ID Installer certificate, and Apple notarizes it. The notarization ticket is stapled to the package, so the package installs without network access.

{:.warning}
> Do not use both Homebrew and the installer package on one Mac. On an Intel Mac, Homebrew installs its own `kong-harnesses` at the same path, `/usr/local/bin/kong-harnesses`. The package keeps the permissions of folders that exist, so before you install the package, make sure that only administrators can change `/usr/local` and `/usr/local/bin`.

To check the permissions, run:

```sh
ls -lde /usr/local /usr/local/bin
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

1. Ask each developer to [remove their settings](#remove-the-settings-of-a-developer).
1. Check that the installer package installed kong-harnesses:

   ```sh
   pkgutil --pkg-info com.konghq.kong-harnesses
   ```

   If the command prints `No receipt for 'com.konghq.kong-harnesses' found`, the installer package didn't install kong-harnesses. Skip the next steps.
1. Check that the file at the install path is the copy of the package:

   ```sh
   ls -l /usr/local/bin/kong-harnesses
   ```

   If the output shows a link (`->`) to a Homebrew folder, Homebrew installed this copy. Remove it with Homebrew, and skip the next steps.
1. Delete the files of the package:

   ```sh
   sudo rm -r /usr/local/bin/kong-harnesses /usr/local/share/doc/kong-harnesses
   ```

1. Delete the package receipt:

   ```sh
   sudo pkgutil --forget com.konghq.kong-harnesses
   ```

To deploy kong-harnesses with an MDM tool, such as Jamf Pro, add the installer package to the tool without changes. The package is signed and notarized, and it doesn't contain installer scripts. The macOS app (PKG) type of Intune detects an install by the app bundles in the package, and this package installs a command-line tool without an app bundle. Assign the package to one test Mac first. Assign it to other Macs only if Intune reports the install on the test Mac as successful. If it doesn't, deploy the package with an MDM tool that detects the install by the package receipt `com.konghq.kong-harnesses` or by the file `/usr/local/bin/kong-harnesses`.

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

A newer installer replaces the installed version, and Windows Installer refuses an older installer. Before you remove kong-harnesses, ask each developer to [remove their settings](#remove-the-settings-of-a-developer). To remove kong-harnesses, run the same command as an administrator with `/x` in place of `/i`, with the installer that installed it. If you don't have that installer, remove **Kong Harnesses** in **Settings** > **Apps** > **Installed apps**.

Make sure that only administrators can change `C:\Program Files\Kong\kong-harnesses` and the folders that contain it. An account that can change these folders can replace kong-harnesses with a program that takes the sign-in of each developer. When kong-harnesses runs from this folder, a developer who runs `kong-harnesses doctor --profile <profile>` also checks these permissions. If another account can change them, the check fails and names the fix.

### Deploy the Windows installer with Intune

Releases don't include an `.intunewin` file, so you wrap the installer yourself. Add one Windows app (Win32) for each processor type.

Wrap the installer:

1. Check the installer as in [Check a downloaded file](#check-a-downloaded-file), and put the installer alone in an empty folder.
1. Download the [Microsoft Win32 Content Prep Tool](https://github.com/microsoft/Microsoft-Win32-Content-Prep-Tool), and open PowerShell in the folder that contains `IntuneWinAppUtil.exe`.
1. Wrap the installer:

   ```powershell
   .\IntuneWinAppUtil.exe -c '<folder>' -s '<folder>\<file>' -o '<output-folder>'
   ```

   Use full paths. `<output-folder>` must be a folder other than `<folder>`.

Add the app in the Microsoft Intune admin center:

1. Navigate to **Apps** > **All Apps**.
1. Click **Create**.
1. In the **Select app type** pane, select **Windows app (Win32)**.
1. Click **Select**.
1. On the **App information** page, click **Select app package file**.
1. Select the `.intunewin` file.
1. Click **OK**.
1. In the **Name** field, enter a name that contains the release and the processor type, for example `kong-harnesses v1.2.3 x64`.
1. In the **Publisher** field, enter `Kong Inc.` if the field is empty.
1. Click **Next**.
1. On the **Program** page, keep the install and uninstall commands that Intune reads from the installer.
1. In the **Install behavior** field, select **System**.
1. Click **Next**.
1. On the **Requirements** page, in the **Operating system architecture** field, select **x64** for the `_windows_amd64.msi` installer, or **ARM64** for the `_windows_arm64.msi` installer.
1. In the **Minimum operating system** field, select the oldest Windows 11 release in the list. kong-harnesses doesn't support Windows 10.
1. Click **Next**.
1. On the **Detection rules** page, in the **Rules format** field, select **Manually configure detection rules**.
1. Click **Add**.
1. In the **Rule type** field, select **MSI**. Keep the product code that Intune reads from the installer.
1. Click **OK**.
1. Click **Next**.
1. On the **Dependencies** page, click **Next**.
1. On the **Supersedence** page, for a new release, click **Add**. For the first release, skip to the **Assignments** page.
1. In the **Add Apps** pane, select the app of the previous release for the same processor type.
1. Click **Select**.
1. In the **Uninstall previous version** field, select **No**. The new installer upgrades the installed version in place, so Intune doesn't need to remove the previous version first.
1. Click **Next**.
1. On the **Assignments** page, under **Required**, click **Add group**.
1. Select the groups of devices or users that need kong-harnesses. A new app doesn't copy the assignments of the previous app, so select the same groups for each release.
1. Click **Select**.
1. Click **Next**.
1. On the **Review + create** page, click **Create**.

Add a new app in the same way for each new release. Intune allows at most 10 apps in a supersedence chain, and each release adds one. When all assigned devices run the new release, remove the supersedence of the previous app from the new app, and delete the previous app.

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

   OpenCode and Hermes Agent keep their own sign-in. For OpenCode, also run `opencode auth logout`, and select the provider that has the name of the profile. For Hermes Agent, run `hermes auth list kong-ai-gateway` to find the index of each credential, and remove each one with `hermes auth remove kong-ai-gateway <index>`.

1. Remove the settings that kong-harnesses added to the coding agents:

   ```sh
   kong-harnesses profile cleanup
   ```

1. Delete each profile:

   ```sh
   kong-harnesses profile delete <profile>
   ```
