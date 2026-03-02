1. If you have not connected Insomnia to your GitHub account yet, click **Authenticate with GitHub**.
1. In the page that opens in your browser, click **Continue**, then click **Authorize Kong**.
1. Click **Open Insomnia**.
1. Ensure that the Insomnia GitHub App is installed and has access to the repository that you want to use, navigate to [Github insomnia-desktop](https://app.insomnia.rest/oauth/github-app).
1. From your chosen repository, click **Configure**.
1. Select your GitHub account or organization.
1. Click **Use passkey**.
1. Under **Repository access**, ensure that the specific repository that you want to use allows access to the Insomnia GitHub App.
1. Click **Update access**.
   
    {:.info}
    > If you use a managed GitHub account, you might not be able to install GitHub Apps. In this case, use the Git tab to configure the repository with the [generic Git workflow](./?tab=git). For more details, see the [GitHub docs](https://docs.github.com/en/enterprise-cloud@latest/admin/managing-iam/understanding-iam-for-enterprises/abilities-and-restrictions-of-managed-user-accounts#github-apps).

1. If needed, select a branch.