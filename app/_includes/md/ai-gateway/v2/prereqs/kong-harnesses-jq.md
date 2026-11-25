The request that creates the key uses [jq](https://jqlang.org/) to save the key in a variable.
Install jq in the shell where you run the API requests:

{% navtabs "install-jq" %}
{% navtab "macOS" %}
```sh
brew install jq
```
{% endnavtab %}
{% navtab "Linux" %}
On Debian and Ubuntu:

```sh
sudo apt-get install jq
```
{% endnavtab %}
{% navtab "Windows" %}
In WSL, on Debian and Ubuntu:

```sh
sudo apt-get install jq
```
{% endnavtab %}
{% endnavtabs %}

For other installation methods, see the [jq download page](https://jqlang.org/download/).
