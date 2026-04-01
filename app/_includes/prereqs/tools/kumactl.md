1. Go to the [{{site.mesh_product_name}} packages](https://cloudsmith.io/~kong/repos/kong-mesh-binaries-release/packages/) page to download and extract the installation archive for your OS, or download and extract the latest release automatically (Linux or macOS):

   ```sh
   curl -L https://developer.konghq.com/mesh/installer.sh | VERSION={{site.data.mesh_latest.version}} sh -
   ```

1. Add the {{site.mesh_product_name}} binaries directory to your path. By default, the directory is `/{{site.mesh_product_name_path}}-{{site.data.mesh_latest.version}}/bin`. You can use the following command to set the directory in your path for the **current** terminal window:

   ```sh
   export PATH=$PATH:$(pwd)/{{site.mesh_product_name_path}}-{{site.data.mesh_latest.version}}/bin
   ```