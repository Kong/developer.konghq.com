Download the Windows installer (`.msi`) for your computer from the kong-harnesses repository at `https://cloudsmith.io/~kong/repos/kong-harnesses/packages/`.
Then install it in PowerShell opened as an administrator:

```powershell
msiexec /i <file>.msi
```

Verify the installation in a new PowerShell window:

```powershell
kong-harnesses version
```
