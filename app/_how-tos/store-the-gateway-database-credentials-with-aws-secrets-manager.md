---
title: Store the {{site.base_gateway}} database credentials with AWS Secrets Manager
content_type: how_to
related_resources:
  - text: Secrets management
    url: /gateway/secrets-management

products:
  - gateway

tier: enterprise

works_on:
  - on-prem

min_version:
  gateway: '3.4'

tags:
  - security
  - secrets-management

tldr:
    q: How can I connect {{site.base_gateway}} to the database using credentials stored in AWS Secrets Manager?
    a: |
      Create a secret in AWS Secrets Manager with your PostgreSQL credentials, and start {{site.base_gateway}} with the required environment variables:
        - `AWS_ACCESS_KEY_ID`, `AWS_SECRET_ACCESS_KEY`, `AWS_SESSION_TOKEN`, and `AWS_REGION` to connect to AWS
        - `KONG_PG_USER` and `KONG_PG_PASSWORD`, where the values are references to your AWS secret
      
prereqs:
  skip_product: true
  inline:
    - title: AWS configuration
      content: |
        This tutorial requires: 
        - An AWS subscription with access to [AWS Secrets Manager](https://docs.aws.amazon.com/secretsmanager/latest/userguide/intro.html) and the following permissions:
          - `secretsmanager:CreateSecret`
          - `secretsmanager:PutSecretValue`
          - `secretsmanager:GetSecretValue`
        - [AWS CLI](https://docs.aws.amazon.com/cli/latest/userguide/cli-chap-getting-started.html) installed
        
        You will also need the following authentication information to connect your AWS Secrets Manager with {{site.base_gateway}}:
        - Your access key ID
        - Your secret access key
        - Your session token
        - Your AWS region, `us-east-1` in this example

        Create environment variables to store these credentials:
        ```sh
        export AWS_ACCESS_KEY_ID=your-aws-access-key-id
        export AWS_SECRET_ACCESS_KEY=your-aws-secret-access-key
        export AWS_SESSION_TOKEN=your-aws-session-token
        export AWS_REGION="us-east-1"
        ```
      icon_url: /assets/icons/aws.svg

cleanup:
  inline:
    - title: Clean up AWS resources
      include_content: cleanup/third-party/aws
      icon_url: /assets/icons/aws.svg
    - title: Clean up Konnect environment
      include_content: cleanup/platform/konnect
      icon_url: /assets/icons/gateway.svg
    - title: Destroy the {{site.base_gateway}} container
      include_content: cleanup/products/gateway
      icon_url: /assets/icons/gateway.svg 
---

## 1. Create a Docker network
```sh
docker network create kong-net
```
The Docker network will be used for communication between {{site.base_gateway}} and the database.

## 2. Run the database
Create the `kong-database` container for the PostgreSQL database: 
```sh
docker run -d --name kong-database \
 --network=kong-net \
 -p 5432:5432 \
 -e "POSTGRES_USER=admin" \
 -e "POSTGRES_PASSWORD=password" \
 postgres:9.6
```
The username and password specified in this command are the PostgreSQL master credentials.

## 3. Create environment variables
Define the username and password to use to connect {{site.base_gateway}} to the database and store them in environment variables.
```sh
export KONG_PG_USER=kong
export KONG_PG_PASSWORD=KongFTW
```

## 4. Create a database user
Create a user in the PostgreSQL container, using the credentials defined in the previous step:
```sh
docker exec -it kong-database psql -U admin -c \
 "CREATE USER ${KONG_PG_USER} WITH PASSWORD '${KONG_PG_PASSWORD}'"
```

## 5. Create a database
Create a database named `kong`, with the user you created as the owner:
```sh
docker exec -it kong-database psql -U admin -c "CREATE DATABASE kong OWNER ${KONG_PG_USER};"
```

## 6. Create a secret in AWS Secrets Manager
Use AWS CLI to create a new secret named `kong-gateway-database` containing the username and password you defined:
```sh
aws secretsmanager create-secret --name kong-gateway-database \
 --description "Kong GW Database credentials" \
 --secret-string '{"pg_user":"'${KONG_PG_USER}'","pg_password":"'${KONG_PG_PASSWORD}'"}'
```

## 7. Run the Kong migrations
```sh
docker run --rm \
 --network=kong-net \
 -e "KONG_DATABASE=postgres" \
 -e "KONG_PG_HOST=kong-database" \
 -e KONG_PG_USER \
 -e KONG_PG_PASSWORD \
 kong/kong-gateway:latest kong migrations bootstrap
```
{:.note}
> Note: `kong migrations` does not support secrets managements, so this step passes the database credentials with environment variables.

## 8. Start {{site.base_gateway}}
Create the {{site.base_gateway}} container with your AWS credentials and the vault references in the environment:
```sh
docker run -d --name kong-gateway \
 --network=kong-net \
 -e "KONG_DATABASE=postgres" \
 -e "KONG_PG_HOST=kong-database" \
 -e AWS_ACCESS_KEY_ID \
 -e AWS_SECRET_ACCESS_KEY \
 -e AWS_REGION \
 -e AWS_SESSION_TOKEN \
 -e "KONG_PG_USER={vault://aws/kong-gateway-database/pg_user}" \
 -e "KONG_PG_PASSWORD={vault://aws/kong-gateway-database/pg_password}" \
 -e KONG_LICENSE_DATA \
 kong/kong-gateway:latest
```