{{site.base_gateway}} Docker container images are signed using Cosign, 
which is a tool that lets you sign images and verify image signatures.

1. Install [Cosign](https://github.com/sigstore/cosign) by following the 
installation instructions for your system.

2. Set the `COSIGN_REPOSITORY` environment variable on your system:

    ```sh
    export COSIGN_REPOSITORY=kong/notary
    ```