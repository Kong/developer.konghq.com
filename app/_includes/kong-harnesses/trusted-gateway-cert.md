kong-harnesses sends your access token only to an HTTPS gateway whose certificate your computer trusts.
The quickstart data plane serves HTTPS on port 8443.
Create a certificate for `localhost` with [mkcert](https://github.com/FiloSottile/mkcert), a tool that adds a local certificate authority (CA) to the system trust store.

1. Install mkcert.
   On macOS, run:

   ```sh
   brew install mkcert
   ```

   For other systems, see the [mkcert installation guide](https://github.com/FiloSottile/mkcert#installation).
   On Windows, install mkcert and run the next two steps in PowerShell.
   kong-harnesses on Windows checks the certificate against the Windows trust store, not the one in WSL.
1. Add the mkcert CA to the system trust store:

   ```sh
   mkcert -install
   ```

   On macOS and Linux, mkcert can ask for your password.
   On Windows, it asks you to confirm the new CA.
1. Create a directory, and create a certificate and key for `localhost` in it:

   ```sh
   mkdir kong-quickstart-cert
   cd kong-quickstart-cert
   mkcert -cert-file localhost.pem -key-file localhost-key.pem localhost 127.0.0.1 '::1'
   ```

1. In the `kong-quickstart-cert` directory, export the two files as base64 text for the quickstart.
   Run the quickstart in the same shell, because the variables exist only in that shell.
   On Windows, run `wsl` in PowerShell in that directory, and run this step and the quickstart in the WSL shell that opens.

   ```sh
   export KONG_SSL_CERT="$(base64 < localhost.pem | tr -d '\n')"
   export KONG_SSL_CERT_KEY="$(base64 < localhost-key.pem | tr -d '\n')"
   ```

The quickstart passes these variables to the data plane, which then serves your certificate at `https://localhost:8443`.
