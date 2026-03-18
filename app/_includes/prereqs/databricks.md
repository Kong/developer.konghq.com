This tutorial requires a Databricks instance. You can create one with the [express setup](https://docs.databricks.com/aws/en/getting-started/express-setup) or through [AWS](https://docs.databricks.com/aws/en/getting-started/cloud-setup).

1. Log in to [Databricks](https://login.databricks.com/).
1. Copy your instance ID, starting with `dbc-`, from the URL, and export it to your environment:
   ```sh
   export DECK_DATABRICKS_WORKSPACE_INSTANCE_ID='YOUR INSTANCE ID'
   ```
1. In Databricks, click your profile icon and click **Settings**.
1. Click **Developer**.
1. Click **Manage**.
1. Click **Generate new token**.
1. In the **Comment** field, enter `Kong`.
1. In the **API scope(s)** dropdown list, select `TODO`.
1. Click **Generate**.
1. Copy the token and export it to your environment:
   ```sh
   export DECK_DATABRICKS_TOKEN='YOUR DATABRICKS TOKEN'
   ```

