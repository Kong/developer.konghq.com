---
title: Set a value from a response as an environment variable in Insomnia

products:
- insomnia

tags:
- after-response-scripts
- collections

tldr:
  q: How do I set a value from a response as an environment variable
  a: Send the request, then create an after-response script to get the value you want to use and set it as an environment variable.

prereqs:
  inline:
  - title: Create a collection
    content: |
      This tutorial requires a collection with at least one request. 
      
      In this example, we'll use the [Konnect Identity Management API](https://docs.konghq.com/konnect/api/identity-management/latest/). For this, you'll need personal access token and a system account ID.
    icon_url: /assets/icons/menu.svg
cleanup:
  inline:
  - title: Clean up Insomnia
    include_content: cleanup/products/insomnia
    icon_url: /assets/icons/insomnia/insomnia.svg
---

## 1. Configure the request

In this example, we want to generate a token for a {{site.konnect_short_name}} system account and set it as an environment variable. We first need to configure the [Create System Account Access Token](https://docs.konghq.com/konnect/api/identity-management/latest/#/System%20Accounts%20-%20Access%20Tokens/post-system-accounts-id-access-tokens) request to generate the token.

If you imported the [Konnect Identity Management API](https://docs.konghq.com/konnect/api/identity-management/latest/) specification into a new collection, most of the parameters are already set.

1. Click **Base Environment**, then click the **OpenAPI env global.api.konghq.com** sub environment to use its variables.
1. Click the pencil icon to update the environment if needed. For this example, you need to:
  * Update the `bearerToken` variable to your personal access token.
  * Create an `accountId` variable with the system account ID.
1. Open the **Create System Account Access Token** request, go to the **Body** tab, and update the token's name and expiration date and time.

## 2. Create the after-response script

1. Open the **Scripts** tab and click **After-response**.
1. Add the following script. It will check that the request returns the expected 201 status code, get the token value, and set it as the value of a new `systemToken` environment variable.

    ```js
    insomnia.test('Check if status is 201', () => {
        insomnia.expect(insomnia.response.code).to.eql(201);
      
        if (insomnia.response.code){
          const jsonBody = insomnia.response.json();
          insomnia.environment.set("systemToken", jsonBody.token);
        }
    });
    ```
1. Click **Send** to send the request. The after-response script will automatically run once the response is returned.

## 3. Validate

To verify that everything ran as expected, you can open the **Tests** tab to see if the test passed and open the environment to check that the new variable was added.
