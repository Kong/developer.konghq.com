Use the following recommendations for each key location:

* **Recommended:** Use `config.key_in_header` (enabled by default) as the most common and
  secure way to do service-to-service calls.
* If you need to share links to browser clients, use `config.key_in_query` (enabled by default).
  Be aware that query parameter requests can appear within application logs and URL browser bars, which expose the API key.
* If you are sending a form with a browser, such as a login form, use `config.key_in_body`. 
This option is set to `false` by default because it's a less common use case, and is a more expensive and less performant request.

For better security, only enable the key locations that you need to use.