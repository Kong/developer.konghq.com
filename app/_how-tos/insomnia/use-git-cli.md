---
title: Use Git CLI in an Insomnia project 
permalink: /how-to/use-git-cli/
content_type: how_to

description: Use the native Git CLI at the root of an Insomnia project.

products:
- insomnia

tags:
- insomnia-documents
- collections
- mock-servers
- git

search_aliases:
  - git cli

prereqs:
    inline:
    - title: Git repository
      content: |
        When you create an Insomnia project with Git Sync, you can either add the repository now or later (if you're using Insomnia 11.5 or later). If you want to add the repository when you create the project, you can either use an existing repository with Insomnia content or an empty repository.
      icon_url: /assets/icons/git.svg

tldr:
    q: How can I use Git natively in an Insomnia project?
    a: Navigate to the local folder to use Git natively in your Insomnia Git Sync project.

faqs:
  - q: macOS:Why do I get the error string not in pwd?
    a: |
      That error is because the path has a space in it (Application Support), and your shell is splitting it into two arguments. `cd` only sees the first part (/Users/<your-user>/Library/Application), can't find it, and complains.
      
      Fix it by quoting the path that Insomnia provides from the UI:

      ```bash
      cd "<path-from-Insomnia>"
      ```

related_resources:
  - text: Storage options in Insomnia
    url: /insomnia/storage/
  - text: Git Sync
    url: /insomnia/git-sync/

---

## Find your project's URI

1. Select your project options and click **Settings**.
1. Check the section **Path to local files**: depending on your OS, Insomnia displays the exact local path where it stores the project.
1. Copy the path.
1. Paste the path in your terminal to navigate at the root of the repository. The command should look like that:

{% navtabs "repo" %}

{% navtab "Windows" %}

- `<your-user>`: your Windows user.
- `git_xxx`: Git project folder with `xxx` being a generated number by Insomnia to index your project.

```shell
cd C:\Users\<your-user>\AppData\Roaming\Insomnia\version-control\git\git_xxx
```

{% endnavtab %}

{% navtab "macOS" %}

{:.info}
> Quote the path provided by Insomnia to avoid path errors.

- `<your-user>`: your macOS user.
- `git_xxx`: Git project folder with `xxx` being a generated number by Insomnia to index your project.

```bash
cd "/Users/<your-user>/Library/Application Support/Insomnia/version-control/git/git_xxx"
```

{% endnavtab %}

{% navtab "Linux" %}

- `git_xxx`: Git project folder with `xxx` being a generated number by Insomnia to index your project.

```bash
cd ~/.config/Insomnia/version-control/git/git_xxx
```

{% endnavtab %}

{% endnavtabs %}

## Use Git CLI in your Insomnia project

You can now run any native Git command, even actions not supported for the Insomnia GUI, like adding multiple remotes, cherry-picking, etc.

