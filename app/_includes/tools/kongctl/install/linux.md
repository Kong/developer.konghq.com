Download the latest kongctl binary for Linux from the [GitHub releases page](https://github.com/Kong/kongctl/releases).

For example, to download and install version `x.y.z`:

```bash
# Download the binary (replace x.y.z with the desired version)
curl -sL https://github.com/Kong/kongctl/releases/download/vx.y.z/kongctl_x.y.z_linux_amd64.tar.gz -o kongctl.tar.gz

# Extract the archive
tar -xzf kongctl.tar.gz

# Move the binary to your PATH
sudo mv kongctl /usr/local/bin/

# Verify the installation
kongctl version --full
```

For other architectures (arm64, etc.), check the [releases page](https://github.com/Kong/kongctl/releases) for available downloads.
