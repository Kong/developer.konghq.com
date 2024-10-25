---
title: Postman Migration to Insomnia
content_type: reference
layout: reference

products:
    - insomnia

breadcrumbs:
  - /insomnia

tags:
  - migrate
  - collections
  - environments

related_resources:
  - text: API specs
    url: /insomnia/api-specs

faqs:
  - q: I've got many collections and environments in Postman, how do I migrate that?
    a: You can import all your collections and environments in Insomnia by navigating to the Postman settings and doing a data dump of all your collections and environments. Once you download the data, you can upload each environment and collection to Insomnia like normal.
  - q: How does script syntax map in Insomnia?
    a: |
        Insomnia uses `insomnia` instead of `pm` in scripts. For example, a Postman script like `pm.test("Status code is 200", function () {pm.response.to.have.status(200);});` would turn into `insomnia.test("Status code is 200", function () {insomnia.response.to.have.status(200);});`. Insomnia automatically converts script syntax when you copy and paste it from Postman or import files with Postman scripts.
  - q: Is there anything that can't be pasted, migrated, or imported from Postman to Insomnia?
    a: You can't copy and paste or migrate Postman dynamic variables. Insomnia doesn't convert them to Insomnia dynamic variables automatically. 
---

## What are features called in Insomnia in comparison to Postman?

The following table describes how features in Postman map to features in Insomnia:

| Postman feature | Insomnia feature |
|-----------------|------------------|
| Workspaces | Organization |
| Collection | Collection |
| Environments | Global environments |
| API Builder | [Design documents](/insomnia/documents) |
| Mock servers | Mock Server |
| Postman CLI | [Inso CLI](/inso-cli) |
| Post-response scripts | After-response scripts |

## What can I import or migrate from Postman in Insomnia?

When you migrate the following from Postman, either by import or copy and paste, Insomnia will automatically convert them to the correct format and syntax for Insomnia:

* Pre-request scripts
* Post-response scripts
* Collections
* Environments
* Data dumps of all your collections and environments in Postman