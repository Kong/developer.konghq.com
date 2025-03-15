## 1. Configure PostgreSQL 

1. Switch to the default PostgreSQL user: 

    ```sh
    sudo -i -u postgres
    ```
1. Start the PostgreSQL shell:

    ```
    psql 
    ```
1. Create a `kong` user and password:

    ```
    CREATE USER kong WITH PASSWORD 'super_secret';
    ```
1. Create a database titled `kong` and assign the user as an owner:

    ```
    CREATE DATABASE kong OWNER kong;
    ```
1. Exit PostgreSQL, and exit the PostgreSQL shell:
    
    ```
    exit
    ```

## 2. Run a {{site.base_gateway}} database migration

`kong migrations` is used to configure the database for the first time. 
Running `bootstrap` forces {{site.base_gateway}} to bootstrap the database set up in the previous step and run all of the migrations: 

```sh
kong migrations bootstrap
```

This command must be run as the `root` user. 

## 3. Validate

You can validate that the datastore was configured correctly by starting {{site.base_gateway}}. 

1. Start {{site.base_gateway}}:

    ```sh
    kong start
    ```
2. Verify the installation:

    ```sh
    curl -i http://localhost:8001
    ```
If you receive a `200` status code, {{site.base_gateway}} was configured correctly. 