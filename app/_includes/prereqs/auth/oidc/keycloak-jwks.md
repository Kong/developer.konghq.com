This tutorial requires an identity provider (IdP). If you don't have one, you can use [Keycloak](http://www.keycloak.org/). The steps will be similar in other standard identity providers.

#### Create a client
1. Install [Keycloak](https://www.keycloak.org/guides) (version 26 or later) on your platform.
1. Open the admin console and select a realm. 
    
    The default URL of the console is `http://{your-keycloak-host}:8080/admin/master/console/`.
1. In the sidebar, open **Clients**, then click **Create client**.
1. Configure the client:

Section | Settings
--------|----------
**General settings** | - Client type: **OpenID Connect** <br> - Client ID: any unique name, for example `kong`
**Capability config** | - Toggle **Client authentication** to **on** <br> - Make sure that **Standard flow** and **Direct access grants** are checked.
**Login settings** |  **Valid redirect URIs**: `http://localhost:8000/*`

#### Set up keys and credentials
1. In your client, open the **Keys** tab.
1. Toggle **Use JWKS URL** to **on**.
1. In the **JWKS URL** field, enter `http://localhost:8001/openid-connect/jwks`.
1. Save, then switch to the **Credentials** tab.
1. Set **Client Authenticator** to **Client ID and Secret**.
1. Copy the **Client Secret**.

#### Export to environment variables
Export your client secret, client ID, and issuer URL to environment variables. 
For example:
```
export ISSUER=http://host.docker.internal:8080/realms/master
export CLIENT_ID=kong
export CLIENT_SECRET=UNT3GPzCKI7zUbhAmFSUGbj4wmiBDGiW
```