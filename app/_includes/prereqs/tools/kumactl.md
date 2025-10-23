1. Go to the [Kuma packages](https://cloudsmith.io/~kong/repos/kuma-binaries-release/packages/) page to download and extract the installation archive for your OS, or download and extract the latest release automatically (Linux or macOS):

   ```sh
   curl -L https://developer.konghq.com/mesh/installer.sh | VERSION={{site.data.mesh_latest.version}} sh -
   ```

   On macOS, you can also install kumactl with Homebrew:
   ```sh
   brew install kumactl
   ```

1. Add the Kuma binaries directory to your path. By default, the directory is `/kuma-{{site.data.mesh_latest.version}}/bin`.
