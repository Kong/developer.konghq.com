<details class="mb-2" markdown="1">
  <summary class="rounded mb-0.5 bg-gray-200 p-2">Entities needed for this tutorial</summary>

1. Create a `deck_files` folder and add your `kong.yaml` file in it.
1. Create a `prereqs.yaml` file in the same folder, and add the following content to it:

{: data-file="prereqs.yaml" }
{% highlight yaml %}
{{ include.data }}
{% endhighlight %}

1. Sync your changes:

  ```sh
  deck gateway sync prereqs.yaml
  ```

</details>
