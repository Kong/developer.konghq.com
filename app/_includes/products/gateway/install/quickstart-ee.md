Export your license to an environment variable:

```
export KONG_LICENSE_DATA='<license-contents-go-here>'
```

Run the quickstart script:

```bash
curl -Ls https://get.konghq.com/quickstart | bash -s -- -e KONG_LICENSE_DATA
```
    