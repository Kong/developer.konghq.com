<details class="mb-2" markdown="1">
  <summary class="rounded mb-0.5 bg-gray-200 p-2">Pre-configured Entities</summary>
For this tutorial, you'll need Kong Gateway entities, like services and routes, pre-configured. These entities are essential for Kong Gateway to function but installing them isn't the focus of this guide. Follow these steps to pre-configure them:
1. Create a `deck_files` directory and add the `kong.yaml` file to it.
1. Create a `prereqs.yaml` file within the same folder, and add the following content to it:

{% capture entities %}
```yaml
{{ include.data }}
```
{: data-file="prereqs.yaml" }
{% endcapture %}
{{ entities | indent: 3 }}

1. Sync your changes:

   ```sh
   deck gateway sync prereqs.yaml
   ```
To learn more about entities, you can read our [entities documentation](/entities/). 

</details>
