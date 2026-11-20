Download the Windows installer (`.msi`) for your computer from the kong-harnesses repository at `https://cloudsmith.io/~kong/repos/kong-harnesses/packages/`.
Check the installer as in [Check a downloaded file](/kong-harnesses/install/#check-a-downloaded-file).
Then install it in PowerShell opened as an administrator. Replace `<msi-path>` with the full path of the installer:

```powershell
msiexec /i "<msi-path>"
```

Verify the installation in a new PowerShell window:

```powershell
kong-harnesses version
```
