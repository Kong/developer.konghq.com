Download the latest kongctl binary for Linux from the [GitHub releases page](https://github.com/Kong/kongctl/releases).

1. Download the binary:
   ```sh
   curl -sL https://github.com/Kong/kongctl/releases/download/v{{site.data.kongctl_latest.version}}/kongctl_linux_amd64.zip -o kongctl.zip
   ```

1. Extract the archive: 
   ```sh
   unzip kongctl.zip
   ```

1. Move the binary to your PATH:
   ```sh
   sudo mv kongctl /usr/local/bin/
   ```

1. Verify the installation:
   ```sh
   kongctl version --full
   ```


For other architectures (arm64, etc.), check the [releases page](https://github.com/Kong/kongctl/releases) for available downloads.
