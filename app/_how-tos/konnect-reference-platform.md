---
title: Konnect Reference Platform - How To
content_type: how_to
permalink: /konnect-reference-platform/how-to/

breadcrumbs:
  - /konnect-reference-platform/

products:
  - reference-platform

works_on:
  - konnect

tldr: 
  q: How do I use the {{site.konnect_short_name}} Reference Platform? 
  a: |
    The following is a step by step guide to deploying a 
    [Konnect Reference Platform](/konnect-reference-platform/) to 
    your own {{site.konnect_saas}} Organization and GitHub repositories.

tags:
    - get-started
    - konnect
    - reference-platform

prereqs:
  show_works_on: false
  expand_accordion: false
  inline:
    - title: "{{site.konnect_saas}} Account"
      content: |
        A [{{site.konnect_saas}}](https://konghq.com/products/kong-konnect) account is required to create and 
        manage {{site.konnect_short_name}} Organizations and resources. 
        If you do not have a {{site.konnect_short_name}} account, you can sign up for a free trial 
        at [https://konghq.com/products/kong-konnect/register](https://konghq.com/products/kong-konnect/register).
    - title: GitHub Account
      content: |
        A GitHub account is required with the authorization to create and administer repositories. For now, 
        GitHub is the only supported Version Control System and these instructions are specific to it.
    - title: "{{site.konnect_short_name}} Orchestrator"
      content: |
        The [{{site.konnect_short_name}} Orchestrator](/konnect-reference-platform/orchestrator) (or `koctl`) is the 
        command line tool included in the {{site.konnect_short_name}} Reference Platform.
        
        * On MacOS, install `koctl` using Homebrew

          ```shell
          brew install kong/konnect-orchestrator/koctl
          ```
        
        * On Linux or Windows, install directly from the release page
            
          [Releases · Kong/konnect-orchestrator](https://github.com/Kong/konnect-orchestrator/releases)
    - title: Reference Platform Background
      content: |
        Before proceeding with deploying your own {{site.konnect_short_name}} Reference Platform,
        review the [landing page](/konnect-reference-platform) to ensure you have an 
        understanding of the platform and its purpose.
    - title: Operating System Compatibility
      content: |
        These instructions are specific to *nix style operating systems. For MS Windows, the user will need to 
        make adjustments to commands and instructions.

automated_tests: false
---

## {{site.konnect_short_name}} Organization Setup

For most use cases, a single {{site.konnect_short_name}} organization is sufficient. 
However, you may determine that your requirements include multiple {{site.konnect_short_name}} organizations which 
the reference platform can support.

The [FAQ page](/konnect-reference-platform/faq/#what-konnect-organization-design-should-i-follow) provides guidance on 
{{site.konnect_short_name}} Organization design. If you choose to use multiple {{site.konnect_short_name}} Organizations, 
the instructions pertaining to organizations in this guide will need to be 
repeated for each one you wish to add to the reference platform.

Create (if necessary) a new {{site.konnect_short_name}} Organization and [sign in](https://cloud.konghq.com/)

## Authorize the {{site.konnect_short_name}} Orchestrator to {{site.konnect_short_name}}

The {{site.konnect_short_name}} Orchestrator (aka "orchestrator" or `koctl`) provides commands you can use to 
setup the reference platform in your own engineering environment. `koctl` is also ran within the [APIOps workflows](/konnect-reference-platform/apiops)
and creates and manages resource configurations within your {{site.konnect_short_name}} Organization via APIs. 
In order to authorize the tool, use the following steps to create a system account with 
[Organization Admin](/konnect-platform/teams-and-roles/#predefined-teams) permissions:

1. From the {{site.konnect_short_name}} web console, under `Organization->System Accounts`, create a new _System Account_ 
   named `konnect-orchestrator`
1. Add the `konnect-orchestrator` system account to the `Organization Admin` team
1. Use the _Manage Tokens_ feature to generate a new access token for the `konnect-orchestrator` system 
   account and securely save the token secret 

## Platform Git Repository Setup

Regardless of the number of {{site.konnect_short_name}} Organizations used, the reference platform [operates around a **single** _Platform Team_
git repository](/konnect-reference-platform/#design-overview). This repository will contain copies of the development teams API specifications, 
APIOps workflows, and other configurations that the orchestrator will manage.

From the GitHub web console, create (if necessary) a `platform` GitHub repository in your GitHub organization. An example repository
can be found in the [KongAirlines GitHub organization](https://github.com/KongAirlines/platform).

{: .info}
> While we refer to this repository as the `platform` repository, the repository name on GitHub is arbitrary. 
The {{site.konnect_short_name}} Orchestrator will file PRs to this repository under the `.github/workflows` and `konnect` sub-directories. 
You can use an existing repository as long as PRs with changes to these locations is acceptable.

## Authorize the {{site.konnect_short_name}} Orchestrator to GitHub

The orchestrator requires specific access to the `platform` repository in order to facilitate the reference platform features.
In order to authorize the orchestrator, you need to create a GitHub access token with the proper permissions.

1. From the GitHub web console, navigate to your profile menu, then _Settings -> Developer Settings -> Personal access tokens_
1. Create a new _Fine-grained token_ and give the token a name that indicates it's relationship to the orchestrator (eg. `platform-konnect-orchestrator`)
1. Select the GitHub organization that owns the `platform` repository you created in the previous step and set appropriate token expiration
1. Under _Repository access_, choose _Only select repositories_ and choose the `platform` repository.
1. Under _Repository permissions_, select all of the following permissions:

    | - | - | - |
    | **Repository Permission** | **Access** | **Description** |
    | `Actions` | Read & Write | Required to create and manage GitHub Actions |
    | `Contents` | Read & Write | Required to write declarative configuration files to the repository |
    | `Pull requests` | Read & Write | Required to file pull requests for all proposed code file changes |
    | `Secrets` | Read & Write | Required to write secrets (the orchestrator cannot read secret values from the repository) |
    | `Workflows` | Read & Write | Required to create and manage GitHub action workflows for APIOps |

1. Once the token is generated, securely save the token secret

## Initialize the Platform repository

The orchestrator provides an `init` command to initialize the platform GitHub repository for you.
The command will prompt you for the `platform` team GitHub repository URL and the GitHub token created previously.

1. Run the `init` command from your shell:

    ```shell
    koctl init
    ```

    Use the `Tab` key to navigate through the prompts and enter the required information

1. Enter the GitHub URL for the `platform` repository you created previously (the URL should be in the format `https://github.com/<org>/<repo>`)

1. Enter the GitHub token secret you created in the previous step

1. Tab onto the `Go!` button and `koctl` will proceed with initializing the repository
by filing a PR containing the necessary changes to initialize the repository to participate in the platform

## Merge the Init PR

Once the `koctl init` command has completed, you will see a message indicating that a PR has been filed to the `platform` repository, including
a link directly to the PR. The PR will have the following title: `[Konnect Orchestrator] - Init Platform`.

Open the PR in the GitHub web console and review the changes. Once satisfied with the changes, 
merge the PR into the `main` branch of the repository. You now have a `platform` repository that is ready to be used with the 
reference platform including GitHub actions that can facilitate the APIOps workflows and other configurations to support API delivery and governance.

## Add an Organization to the Platform repository

As described earlier, the reference platform can support one or more {{site.konnect_short_name}} Organizations. Generally a single
organization design is sufficient, and you will only need to run the following instructions once. But if you wish to add multiple
organizations, run these steps for each one you wish to support.

`koctl` provides a command to add a new {{site.konnect_short_name}} Organization to the platform repository. Run the following and 
follow the prompts to provide the necessary information.

1. Run the `add organization` command from your shell:

    ```shell
    koctl add organization
    ```

1. Enter the URL of the platform repository you created in the previous steps
1. Enter the GitHub token secret you created in the previous steps
1. Enter the name of the {{site.konnect_short_name}} Organization. This can be any name you choose
   but you should choose one that clearly relates to the name of the organization within {{site.konnect_short_name}}
1. Enter the {{site.konnect_short_name}} token you created earlier for the `konnect-orchestrator` system account
1. Once you have entered the necessary information, select the `Go!` button and the `koctl` tool will proceed
   with adding a PR that sets up the organization within the `platform` repository

## Merge the Organization PR

Once the `koctl add organization` command has completed, you will see a message indicating that a PR has been filed to the `platform` repository, 
including a link directly to the PR. The PR will have the following title: `[Konnect Orchestrator] - Add <org-name> Organization`.

Open the PR in the GitHub web console and review the changes. Once satisfied with the changes, merge the PR into the `main` branch of the repository.

You have now added your {{site.konnect_short_name}} to the `platform` repository and the AIOps workflows will initiate
the necessary steps to prepare your {{site.konnect_short_name}} Organization for use with the reference platform.

## Create a {{site.konnect_short_name}} Orchestrator GitHub OAuth application 

The reference platform includes a web-based self service tool that can be used to onboard your development teams and their services.
Once this tool is configured and ran, you (or your development teams) can use it to add teams and service applications
to the platform.

The self service tool requires additional GitHub security configuration because it uses OAuth to allow users to sign in with their GitHub accounts
to browse and select their service repositories.

1. From the GitHub web console, navigate to your profile menu, then _Settings -> Developer Settings -> OAuth Apps_
1. Create a new _OAuth application_ and name it `Konnect Orchestrator`
1. Set the _Homepage URL_ to your `platform` team repository (or any other URL you choose)
1. Set the _Authorization callback URL_ to the localhost URL of the self service application:
   `http://localhost:8080/auth/github/callback`
1. Register the new application and securely save the `Client ID` and `Client Secret` values

## Run the Self Service UI 

`koctl` provides a command to run the self service UI locally using Docker. For more advanced users, the self service UI components
will need to be ran independently and configured with network access between them and for users. For now, we will run the simple local
Docker setup.

1. Run the `run` command from your shell:

    ```shell
    koctl run
    ```

1. Use the `Tab` and `Enter` keys to navigate through the prompts and enter the necessary information.
1. Enter the `Client ID` and `Client Secret` values you created in the previous step
1. Enter the URL of the `platform` repository you created in the previous steps
1. Enter the GitHub token secret you created for the `platform` repository in previous steps
1. The command will run two Docker containers which host the platform repository API server and a web UI that allows
   users to sign in with their GitHub accounts and select their service repositories

## Add a team and service to the platform

Open the URL `http://localhost:8080` in your browser and sign in with your GitHub account.

Select a github organization and service repository to add to the platform

There must be an OpenAPI specification found in the service repository. 
The orchestrator will look for a file named `openapi.yaml` or `openapi.json` in the root of the repository.

## Merge the PR to add the team and service

Once you have added the team and service, a new PR is written that adds the necessary declarative configuration to
the `platform` repository. 

Review and Merge the PR and review the initial GitHub action workflow that is executed.

## Execute the APIOps Workflow

* Login to GitHub and review the PRs created by the orchestrator in your platform repository. There should be initial PRs created to merge 
in an API specification for each service added to the configuration. 

* Approve and merge the initial PRs and verify the API delivery process is properly configured by validating resulting PRs that
stage {{site.base_gateway}} configuration for deployment.

## View your populated {{site.konnect_short_name}} Organization 

Your platform is now setup! The orchestrator has created resources for you within the {{site.konnect_short_name}} Organization and staged
API specifications for delivery to the {{site.base_gateway}} in the platform repository.

* Login to your [{{site.konnect_short_name}} account](https://cloud.konghq.com/) and review the resources created by the orchestrator.


## What's next?

* Review the [APIOps page](/konnect-reference-platform/apiops) for more information on how the API delivery process works within the 
  platform git repository. 

* If you have questions or feedback about the reference platform, 
please reach out on the [Kong Community Forums](https://discuss.konghq.com/).
