In the parent directory of `kong-quickstart-cert`, delete the directory with the certificate and key.
On macOS and Linux:

```sh
rm -rf kong-quickstart-cert
```

On Windows, in PowerShell:

```powershell
Remove-Item -Recurse -Force kong-quickstart-cert
```

The {{site.ai_gateway}} cleanup deletes the copies of the certificate and key that the quickstart keeps.

If mkcert created its CA for this guide and you don't use it for other projects, remove it from the system trust store and delete its files.
mkcert can ask for your password, or on Windows, ask you to confirm the removal.
On macOS and Linux:

```sh
ca_root="$(mkcert -CAROOT)"
mkcert -uninstall && rm -f "$ca_root/rootCA.pem" "$ca_root/rootCA-key.pem"
```

On Windows, in PowerShell:

```powershell
$caRoot = mkcert -CAROOT
mkcert -uninstall
if ($LASTEXITCODE -eq 0) { Remove-Item -Force "$caRoot\rootCA.pem", "$caRoot\rootCA-key.pem" }
```
