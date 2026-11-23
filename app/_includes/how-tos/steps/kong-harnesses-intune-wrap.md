Package the verified `.msi` file into an `.intunewin` archive before uploading it to Intune.

1. Place the verified `.msi` installer alone in an empty folder.
1. Download the [Microsoft Win32 Content Prep Tool](https://github.com/microsoft/Microsoft-Win32-Content-Prep-Tool).
1. Open PowerShell in the folder that contains `IntuneWinAppUtil.exe`.
1. Wrap the installer into an `.intunewin` package, replacing `SOURCE_FOLDER` and `OUTPUT_FOLDER` with full paths (`OUTPUT_FOLDER` must be a different folder than `SOURCE_FOLDER`) and `FILE` with the `.msi` filename:

   ```powershell
   .\IntuneWinAppUtil.exe -c 'SOURCE_FOLDER' -s 'SOURCE_FOLDER\FILE' -o 'OUTPUT_FOLDER'
   ```

   The tool writes a `.intunewin` package file into `OUTPUT_FOLDER`.
