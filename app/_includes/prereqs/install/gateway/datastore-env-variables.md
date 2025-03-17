Set the following variables so that `kong.conf` can interact with the datastore:

```sh
    export KONG_DATABASE=postgres
    export KONG_PG_HOST=127.0.0.1
    export KONG_PG_PORT=5432
    export KONG_PG_USER=kong
    export KONG_PG_PASSWORD=super_secret
    export KONG_PG_DATABASE=kong
```