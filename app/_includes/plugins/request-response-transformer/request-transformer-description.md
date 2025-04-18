This plugin allows you to configure simple transformations of requests before they reach the upstream server. These transformations can be simple substitutions or complex ones matching portions of incoming requests using regular expressions, saving those matched strings into variables, and substituting those strings into transformed requests using flexible templates.

{:.info}
> **Notes**:
* If a value contains a `,` (comma), you can't use the comma-separated format for lists. You must use the array notation instead.
* The `X-Forwarded-*` fields are non-standard header fields written by Nginx to inform the upstream about
client details and can't be overwritten by this plugin. If you need to overwrite these header fields, see the
[Post-Function plugin](/plugins/post-function/).