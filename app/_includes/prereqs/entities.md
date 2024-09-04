{% capture entities %}
```yaml
{{ include.data }}
```
{: data-file="prereqs.yaml" }
{% endcapture %}
<details class="py-4 px-5 flex flex-col gap-1 bg-secondary shadow-primary rounded-md" markdown="1">
  <summary class="text-sm text-primary list-none">Pre-configured Entities<span class="fa fa-chevron-down float-right text-terciary"></span></summary>

For this tutorial, you'll need Kong Gateway entities, like services and routes, pre-configured. These entities are essential for Kong Gateway to function but installing them isn't the focus of this guide. Follow these steps to pre-configure them:
1. Create a `deck_files` directory and add the `kong.yaml` file to it.
2. Create a `prereqs.yaml` file within the same folder, and add the following content to it:
{{ entities | indent: 3 }}
3. Sync your changes:
   ```sh
   deck gateway sync prereqs.yaml
   ```

To learn more about entities, you can read our [entities documentation](/entities/). 

</details>
