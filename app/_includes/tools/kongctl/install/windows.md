Download the latest kongctl binary for Windows from the [GitHub releases page](https://github.com/Kong/kongctl/releases).

1. Navigate to the [kongctl releases page](https://github.com/Kong/kongctl/releases).
2. Download the Windows binary (for example, `kongctl_{{site.data.kongctl_latest.version}}_windows_amd64.zip`)
3. Extract the ZIP archive.
4. Move `kongctl.exe` to a directory in your PATH, or add the extracted directory to your PATH.
5. Verify the installation:
   ```powershell
   kongctl version --full
   ```
