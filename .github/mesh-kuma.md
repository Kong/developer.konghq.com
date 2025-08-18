

## Mesh in Kong Developer


For the time being we generate a portion of the Mesh docs from the [Kuma docs](https://kuma.io/docs/2.11.x/), this is done through the use of a submodule and a configuration file:  

### `app/_data/kuma_to_mesh/config.yaml`

This file manages the files pulled from the submodule, an entry looks like this: 

```
  -
    path: app/_src/guides/consumer-producer-policies.md
    title: 'Producer and Consumer policies'
    description: 'Understand how producer and consumer policies work in {{site.base_product}} to control traffic at the namespace level. This guide walks through setup, roles, and overrides using real examples with MeshService and MeshTimeout.'
    url: /mesh/consumer-producer-policies/
    related_resources:
      - text: Mesh Policies
        url: '/mesh/policies-introduction/'
    min_version:
      mesh: '2.9'
  -

```
Here is a description of each parameter

| Value             | Description |
|------------------|-------------|
| `path`           | File path of the markdown in the Kuma repository |
| `title`          | Title of the guide or page as it will appear in the Developer site|
| `description`    | Short summary of the guide’s content and purpose. |
| `url`            | URL path where the page will be available on the Developer site. |
| `related_resources` | A list of related pages to link to from the guide. Each entry includes `text` and `url`. |
| `min_version` | Minimum required version of Mesh |


Removing an entry removes a file from generation. This should be done as we start to replace files. 

## Mesh Policies

Mesh Policies are rendered in the [Mesh Policy hub](https://developer.konghq.com/mesh/policies/)

The process to add a new Mesh Policy is this: 

1. Create a new directory under `_mesh_policies` with the name of the mesh policy for example `meshaccesslog`
2. Create a new `index.md` file. This is where the documentation for the policy will go. 
3. Create a new subdirectory titled `examples` that contains the configuration. 


### Front matter for Mesh Policies


An `index.md` file must contain the following front matter: 


| Value            | Description |
|------------------|-------------|
| `title`          | The display name of the policy or feature. |
| `name`           | Internal or programmatic name used for identification. |
| `products`       | List of products this feature applies to. Must always be `mesh` |
| `description`    | Summary of what the feature does, shown in documentation listings. |
| `content_type`   | Type of content **must always be `plugin`** |
| `icon`           | Filename of the icon representing the policy, thes are stored in `app/assets/icons/mesh_policies/meshaccesslog.png` |


### Example configuration

| Value                      | Description |
|----------------------------|-------------|
| `title`                   | Title of the example or configuration. |
| `description`             | Short explanation of what the example does. |
| `weight`                  | Ordering weight for sorting in lists |
| `namespace`               | Namespace in which the policy or resource is applied. |
| `config`             | Where you paste the configuration |




## Submodule Management

The submodule is `app/.repos/kuma`, this is a copy of the kuma documentation. Editing files in here will not edit the file on the Developer Site. 

We can update the submodule to include changes from the Kuma documentation if the changes interface with generated files. 