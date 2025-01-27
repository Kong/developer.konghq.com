---
title: Local vault storage in Insomnia

description: Local vault is a storage option that allows all project data to be stored locally on your device.

content_type: concept
layout: concept

products:
    - insomnia

related_resources:
  - text: Storage options
    url: /insomnia/storage-options
  - text: Git sync
    url: /insomnia/git-sync/
  - text: Cloud sync
    url: /insomnia/cloud-sync/
  - text: Scratch pad
    url: /insomnia/scratch-pad/
  - text: API specs
    url: /insomnia/api-specs/
  - text: Write tests for HTTP status codes
    url: /how-to/write-http-status-tests/
  - text: Security at Insomnia
    url: /insomnia/security

faqs:
  - q: What is the difference between local vault and scratch pad?
    a: In both local vault and scratch pad, project data is stored locally. With local vault, you can also use git sync. In scratch pad, all data is stored locally, so it is best suited for individual developers who aren't working as part of a team.

---

{{ page.description | liquify }}
This option is ideal for users who prefer or require their data to remain off the cloud for privacy or security reasons.

Key features:
* **Local storage:** All project files are stored on your local machine.
* **No cloud interaction:** No data is sent to or stored in the cloud.
* **Security:** Enhanced security as data remains within your local environment.
* **Work offline:** Access and work on your projects without needing an internet connection.
* **Collaborate:** With local vault, you still have the option to use [Git sync](/insomnia/git-sync/).

You can create a local vault project when you create a new project in Insomnia and select the **Local vault** option.