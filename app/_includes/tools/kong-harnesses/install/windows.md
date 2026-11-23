Download the Windows installer (`.msi`) for your computer from the kong-harnesses Cloudsmith repository at `https://cloudsmith.io/~kong/repos/kong-harnesses/packages/`.
Check the installer using [Check a downloaded file](/kong-harnesses/install/#check-a-downloaded-file).
Run the installer in PowerShell opened as an administrator.
Replace `MSI_PATH` with the full path to the installer:

```powershell
msiexec /i "MSI_PATH"
```

Verify the installation in a new PowerShell window:

```powershell
kong-harnesses version
```
