Now that DCR is configured, you can create an application with Dynamic Client Registration by using a developer account.

1. Navigate to your Dev Portal URL and log in with your developer account.

1. Select an API and click **Use this API**.

1. Complete the Create New Application modal with your application name, authentication strategy, and description.

1. After the application is created, the Client ID and Client Secret will be displayed.  
   Make sure to store these values, as they will only be shown once.

1. After the application is created, it will appear your IdP. From your IdP organization, select **Applications** from the sidebar. You will see the application created in the Dev Portal, along with its corresponding Client ID.

For developers to authorize requests, they must attach the client ID and secret pair obtained previously in the header. They can do this by using any API product, such as [Insomnia](https://insomnia.rest/), or directly using the command line:

{% validation request-check %}
url: '/$ROUTE_PATH'
headers:
  - 'Authorization: Basic $CLIENT_ID:$CLIENT_SECRET'
  - 'Content-Type: application/json'
status_code: 200
{% endvalidation %}