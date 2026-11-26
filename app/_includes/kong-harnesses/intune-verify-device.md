Under **Monitor** > **Device install status** for {{ include.app }}, the test device reports `Installed` when the {{ include.process }} completes.
If you assigned a user group, check **User install status** instead.
For more about install status, see [Monitor apps](https://learn.microsoft.com/en-us/intune/intune-service/apps/apps-monitor).

Then check the executable on the device from a new PowerShell window.
The installer updates the system `PATH`, which a PowerShell window that was open during the installation doesn't see.

```powershell
(Get-Command kong-harnesses).Source
kong-harnesses version
```

The first command prints `C:\Program Files\Kong\kong-harnesses\kong-harnesses.exe`.
The second prints {{ include.release }} with its leading `v`, for example `v1.2.3`.
