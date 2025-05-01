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
    The following is a guide for the step by step process of onboarding an engineering group to 
    [{{site.konnect_product_name}}](https://konghq.com/products/kong-konnect) using the 
    [Konnect Reference Platform](/konnect-reference-platform/). These instructions include all the steps required to add a new platform team and 
    relevant service repositories to the reference platform. Alternatively, example engineering groups are provided in order to expedite the evaluation of the 
    platform, see [Kong Airlines](/konnect-reference-platform/kong-air/) for more information. 


tags:
    - get-started
    - konnect
    - reference-platform

prereqs:
  skip_product: true
  expand_accordion: false
  inline:
    - title: Reference Platform Background
      content: |
        Before proceeding with applying the [{{site.konnect_short_name}} Reference Platform](/konnect-reference-platform/) to your own organization
        review the [FAQ page](/konnect-reference-platform/faq/) for an understanding of the platform its purpose and components. 
    - title: GitHub Account
      content: |
        A GitHub account is required with the ability to create and administer repositories. For now, GitHub is the only supported 
        Version Control System (VCS) and these instructions are specific to it.
    - title: "{{site.konnect_product_name}} Account"
      content: |
        A {{site.konnect_product_name}} account is required to create and manage {{site.konnect_short_name}} Organizations and resources. 
        If you do not have a {{site.konnect_short_name}} account, you can sign up for a free trial 
        at [https://konghq.com/products/kong-konnect/register](https://konghq.com/products/kong-konnect/register).
    - title: Operating System Compatibility
      content: |
        These instructions are specific to *nix style operating systems. For MS Windows, the user will need to make adjustments to commands and instructions.

automated_tests: false
---

## 1. {{site.konnect_short_name}} Organization Setup

Typically the reference platform will be used as an initial onboarding of {{site.konnect_product_name}} to evaluate best practices and 
{{site.konnect_short_name}} capabilities. In these cases a single {{site.konnect_short_name}} organization is sufficient. However, you may determine 
that your requirements include multiple {{site.konnect_short_name}} organizations, in which case
the [Konnect Orchestrator](/konnect-reference-platform/orchestrator/) can support managing multiple organizations. 

The [FAQ page](/konnect-reference-platform/faq/#what-konnect-organization-design-should-i-follow) provides guidance on {{site.konnect_short_name}}
organization design. If you choose to use multiple {{site.konnect_short_name}} organizations, the instructions pertaining to organizations in this guide will need to be 
repeated for each one you wish to add to the reference platform.

## 2. Authorize the {{site.konnect_short_name}} Orchestrator

* Create (if necessary) a new {{site.konnect_short_name}} organization and [sign in](https://cloud.konghq.com/)
* From the {{site.konnect_short_name}} web console, under `Organization->System Accounts`, create a new _System Account_ named `konnect-orchestrator`
* Add `konnect-orchestrator` to the `Organization Admin` team
* Generate a new Access Token for the `konnect-orchestrator` system account
* Save the token secret to a file locally (e.g. `$HOME/.konnect/konnect-orchestrator.spat`)

## 3. Setup the Platform repository

Regardless of the number of {{site.konnect_short_name}} Organizations used, the reference platform operates around a **single** _Platform Team_
git repository. This repository will contain copies of the development teams API specifications, APIOps workflows, and other configurations 
that the orchestrator will manage.

* From the GitHub web console, create (if necessary) a `platform` GitHub repository in your GitHub organization. 
* Open a command terminal on your development machine, clone the repository locally, and change your working directory
to the repository folder for future steps in this guide.

{: .info}
> While the reference platform refers to this repository as the “platform” repository, the repository name on GitHub is arbitrary. 
The orchestrator will file PRs to this repository under the `.github/workflows` and `konnect` sub-directories. 
You can use an existing repository as long as PRs to these locations is acceptable.

## 4. Prepare the Konnect Orchestrator

`koctl` is the command line tool for the Konnect Orchestrator. For now, the orchestrator is ran directly on a development machine using the `koctl` program.

* On MacOS, install `koctl` using Homebrew

    ```shell
    brew install kong/konnect-orchestrator/koctl
    ```

* On Linux or Windows, install directly from the release page

    [Releases · Kong/konnect-orchestrator](https://github.com/Kong/konnect-orchestrator/releases)

`koctl` accepts configuration files which drive its behavior. The configuration is broken into three parts 
which can be specified in a single or individual files:

| Config | Description |
|:---|:---|
| `platform` | The configuration that sets up the orchestrator to manage files and APIOps workflows within the platform repository |
| `teams` | Configures developer teams and the service applications they support, that are available to the orchestrator |
| `organizations` | Configures {{site.konnect_short_name}} Organizations and the resources contained within them |

While not required, you can store the configuration within the platform repository. 

* Create a new folder which will be used to store the configuration as well as other working files managed by the operator.

    ```shell
    mkdir konnect
    ```

## 5. Create the Platform Configuration

The `platform` configuration sets up `koctl` to access the platform `git` repository. 

* Using the GitHub web console, navigate to your profile, then _Settings -> Developer Settings -> Personal access tokens_
* Create a new _Fine-grained token_ and select the repositories `koctl` will need access to. The specific repositories required 
will largely depend on your specific GitHub setup and the public / private visibility of your team repositories. 

{:.info}
> `koctl` must be authorized with read & write access to the platform repository _and_ read access to all  
service application repositories you wish to include in your {{site.konnect_short_name}} API management solution. 
The token you create for `koctl` will require read & write access for content, pull requests, and workflows 
on the platform repository and read access to content on all service application repositories.

* Once you create the new token, store the secret in a file on the local development machine where `koctl` will have
read access to it.

* Create the following yaml configuration and save it to a file located at `konnect/ko-config.yaml`, substitute in your specific values.

    ```yaml
    platform:
      git:
        remote: <Platform git repo remote URL (https)> 
        author:
          name: "Konnect Orchestrator"
          email: <email address for commits>
        github:
          token:
            type: file
            value: <Path to GitHub token file>
    ```

A sample platform configuration can be found in the 
[KongAirlines example platform repository](https://github.com/KongAirlines/platform/blob/main/konnect/platform-config.yaml).

## 6. Apply the Platform Configuration

* After saving the configuration, run the `koctl apply` command passing in the path to the file:

    ```shell
    koctl apply --file konnect/ko-config.yaml
    ```
    
* A successful application of the configuration will show you the following message:

    ```text
    Changes detected in platform repository
    Configuration Applied
    ```

Open your platform repository in GitHub and you will have an open PR containing the addition of APIOps workflow files and other configurations.
Merge this PR and the platform repository now has an APIOps workflow capability which will be utilized to deliver APIs to {{site.base_gateway}}.

{:.info}
> Before these GitHub Actions will run successfully, it is required to create a GitHub Repository Secret that authorizes the 
actions to invoke {{site.konnect_short_name}} APIs. The process for authorizing the workflows is dependent on the remaining configuration and 
will be explained later on this page.

## 7. Create the Teams Configuration

The `teams` configuration defines your engineering organization teams and their service applications. 
The orchestrator reads this information and uses it to manage {{site.konnect_short_name}} resources. For each
team in the configuration, the orchestrator will create a team in the {{site.konnect_short_name}} Organization,
and create resources and policies for the team and their applications. For every service, the API specification is 
copied from the service repository and staged for delivery in the platform repository.

* Add the following configuration to the `konnect/ko-config.yaml` file. 

    ```yaml
    teams:
      <team-name>:
        description: <team description>
        users:
          - <team member email address>
        services:
          <service-key>:                               # Service key can be a ("parent/child") hierarchy
            name: <service-name>
            description: <service-description>
            spec-path: <path/to/oas-file>              # default = openapi.yaml
            prod-branch-name: <production-code-branch> # default = main
            dev-branch-name: <dev-code-branch>         # default = dev
            git:
              remote: <git-remote-url>
    ```

* Populate this section with your own teams and services configurations. For every team you wish to add,
create a new section under the `teams` key. The `team-name` value is arbitrary, but should be unique across the
configuration. 

* For each team, add `users` you wish to invite by email address. The orchestrator will send {{site.konnect_short_name}} 
invitations to these users if they do not already exist.

* For each team, add the services they own under the `services` key. The `service-key` is arbitrary, and can be made up
of a hierarchy of values. This allows for a logical grouping of services and will determine a folder structure on the
platform repository for the service API specifications.

{:.warning}
> **Important**: by default, the service repositories are accessed using the GitHub credentials specified in the platform configuration. 
If the repositories are public they are always readable, but if they are private and require different authentication then what is available 
in the platform configuration, individual service auth settings must be specified.

For each service configuration, it is paramount to understand the `spec-path`, `prod-branch-name` and `dev-branch-name` fields.

`spec-path`: This defines where in the service git repository the orchestrator will find the OpenAPI specification for the service. 
The specification files are critical to the entire reference platform process. They are copied into the platform repository and staged for 
conversion to {{site.base_gateway}} configuration. Additionally, the specifications are the foundation for representing the 
API in [Developer Portals](https://konghq.com/products/kong-konnect/features/developer-portal).

`prod-branch-name`: It is assumed that the service application repositories follow a multi-branch strategy for tracking the specification 
file for promoting from “dev to prod”. This field represents the name of the branch that the service uses for its production deployment. 
The default value is `main`.

`dev-branch-name`: Similar to prod-branch-name, this field defines development branches for the services. 
The default value is `dev`.

{:.info}
> Dev vs Prod environments will be explained next, but for the orchestrator to work properly, specifications must be found in the 
repository at the `spec-path` location on the proper branch specified here.

These blocks of configuration are repeated for all your teams, users, and services. A full sample can be found in the 
[KongAirlines example platform repository](https://github.com/KongAirlines/platform/blob/main/konnect/teams-config.yaml).

## 8. Create the Organizations Configuration

The `organizations` configuration defines your {{site.konnect_short_name}} organization layout and the environments within them. 
Environments are used to create relationships between {{site.konnect_short_name}} resources within the organization. 
Environments are not a native {{site.konnect_short_name}} concept, instead resources are named and given 
metadata that designates them as part of an environment. While you can have many environments, 
they are specified to have one of two types, either `PROD` or `DEV`. Certain resource configurations are different depending on the 
type of the Environment. See the FAQ page for more information on [Environment Types](/konnect-reference-platform/faq/#what-are-environments).

* Add the following configuration to the `konnect/ko-config.yaml` file. 

```yaml
organizations:
  <organization-name>:
    access-token:
      type: file
      value: <Path to konnect-orchestrator system account token file>
    environments:
      <environment-name>:
        type: <DEV or PROD>
        region: <Konnect region string us|eu...>
```

As mentioned at the top of this page, a single organization is sufficient for most use cases. However, if you have multiple organizations,
you will need to repeat this configuration for each organization you wish to manage with the orchestrator.

* Give the organization a name in the `organization-name` key. This value is arbitrary, but should be unique across the configuration.

* In [a previous step](#2-authorize-the-konnect-orchestrator), you created a system account named `konnect-orchestrator` and generated an access token.
This token is used to authorize the orchestrator to manage resources in the {{site.konnect_short_name}} organization. Specify the path to this
token in the `access-token` section of this configuration.

{:.info}
> API access to organization resources is determined by the access token presented in API calls. This is why the `access-token` is specified in these 
organization configurations. 

* The `environments` section specifies the environments you want within the organization. The `environment-name` value is arbitrary, but should be
unique across the organization. The environment `type` determines some aspects for the managed {{site.konnect_short_name}} resources. See
the [FAQ page](/konnect-reference-platform/faq/) for more information on [environments](/konnect-reference-platform/faq/#what-are-environments) 
and [managed resources](/konnect-reference-platform/faq/#what-specific-konnect-resource-are-managed-by-the-konnect-orchestrator).

A full sample organization configuration can be found in the 
[KongAirlines example platform repository](https://github.com/KongAirlines/platform/blob/main/konnect/orgs-config.yaml).

## 9. Apply the configuration

* Once you have completed the full configuration, apply it with the `koctl apply` command:

    ```shell
    koctl apply --file konnect/ko-config.yaml
    ```

* Assuming you have created a valid configuration, you will see positive confirmation that the configuration was applied to your Konnect Organizations 
and the platform GitHub repository.

    ```text
    Configuration Applied
    ```

* The first time you apply the configuration you will see warnings that looks like the following:

    ```text
    !!!Found 0 serivces for API api-name. Cannot create API implementation relation...
    ```
  This is expected and the reason is further explained in the 
  [FAQ page](/konnect-reference-platform/faq/#why-do-i-see-the-warning-message-found-0-serivces-for-api-cannot-create-api-implementation-relation).

## 10. Authorize the GitHub Actions

Once you have setup your organization configuration and applied it to your {{site.konnect_short_name}} account, you need to authorize 
the platform GitHub repository actions to use the {{site.konnect_short_name}} APIs. 
This is accomplished by creating an GitHub Actions Secret on the platform repository. 

Because multiple organizations are supported, and the {{site.konnect_short_name}} APIs scope their requests to the proper Organization by the token 
used, there is a naming convention for the GitHub Actions Secret that must be followed.

* In the GitHub web console, go to the platform repository and access the repository Settings. Under Secrets and variables, add a new 
Actions Repository Secret. The name of the secret must conform to the following pattern:

    `<ORGANIZATION-KEY>_KONNECT_TOKEN`

    For example, if your organization name in the configuration above is `MYORG`, your secret must be named `MYORG_KONNECT_TOKEN`.

* The token used for the GitHub actions needs to be token with broad access to manage resources in the {{site.konnect_short_name}} organization. 
You can use the same token created earlier for the `konnect-orchestrator` system account. Paste that token value into the Secret value and 
save the secret. 

{:.warning}
> **Important**: In addition to this secret configuration, your platform repository must enable GitHub Actions the ability to read/write to the repository 
as well as manage PRs within it. This is configured in the repository settings, see the 
[GitHub Actions documentation](https://docs.github.com/en/repositories/managing-your-repositorys-settings-and-features/enabling-features-for-your-repository/managing-github-actions-settings-for-a-repository) 
for details.

## 11. What's next?

Your platform is now setup! The orchestrator has created resources for you within the {{site.konnect_short_name}} Organization and staged
API specifications for delivery to the {{site.base_gateway}} in the platform repository.

* Login to your [{{site.konnect_short_name}} account](https://cloud.konghq.com/) and review the resources created by the orchestrator.

* Login to GitHub and review the PRs created by the orchestrator in your platform repository. There should be initial PRs created to merge 
in an API specification for each service added to the configuration. 

* Every user added to your configuration should have received a {{site.konnect_short_name}} invitation to register and 
login to {{site.konnect_short_name}}. 

* Review the FAQ page for more information on how the API delivery process works within the platform git repository. 

* Approve and merge the initial PRs and verify the API delivery process is properly configured by validating resulting PRs that
stage {{site.base_gateway}} configuration for deployment.

* If you have questions or feedback about the reference platform, 
please reach out on the [Kong Community Forums](https://discuss.konghq.com/).
