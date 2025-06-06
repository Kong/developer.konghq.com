---
title: Migrate from Postman
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
  - q: I've got many collections and environments in Postman, how do I migrate them?
    a: You can import all your collections and environments in Insomnia by navigating to the Postman settings and doing a data dump of all your collections and environments. Once you download the data, you can upload each environment and collection to Insomnia like normal.
  - q: How does script syntax map in Insomnia?
    a: |
      Insomnia automatically converts script syntax when you copy and paste it from Postman or import files with Postman scripts.
  - q: Is there anything that can't be pasted, migrated, or imported from Postman to Insomnia?
    a: You can't copy and paste or migrate Postman dynamic variables. Insomnia doesn't convert them to Insomnia dynamic variables automatically.
  - q: What can I import from Postman to Insomnia?
    a: |
        * Pre-request scripts
        * Post-request scripts
        * Collections
        * Environments
  - q: What Postman features map to Insomnia features?
    a: | 
      |Postman feature|Insomnia feature|
      |--|--|
      |Workspaces|Organization|
      |Collection| Collection|
      |Environments| Global environments |
      |API Builder| [Design documents](/insomnia/documents)|
      |Postman CLI | [Inso CLI](/insomnia/inso-cli)|
      |Post-response scripts| After-response scripts|
      |pre-resonse scripts |Pre-response scripts|

---


## Migrate Collections

To migrate a collection from Postman, select the collection in Postman click the `...` icon and select **Export**. Select **Collection v2.1**. This will create a JSON file of your entire Postman collection. 

![Postman Export](/assets/images/insomnia/postman-export.png)

From Insomnia select **Import** and select the JSON file you exported from Postman. This will import the collection into Insomnia, including any scripts, collections, and specs.

## Migrate Environments

Postman environments are stored seperatly from collections. To import an environment file from Postman to Insomnia. 
Click the `...` icon and select **Export** and save the environment file.

From Insomnia select **Import** and select the JSON file you exported from Postman. This will import the environment file into Insomnia which you can view from the **Environments** tab. 


## Postman scripts

Postman supports Pre-response and Post-response scripts. These scripts map directly 1:1 to Insomnia Post-response scripts and After-response scripts. Scripts can be copied directly from Postman and used in Insomnia automatically. Insomnia will convert the script for you. 

<div style="display: flex;">
    <div>
        <img src="/assets/images/insomnia/postman-scripts.png" alt="Postman script" />
    </div>
    <div>
        <img src="/assets/images/insomnia/insomnia-scripts.png" alt="Insomnia script" />
    </div>
</div>

