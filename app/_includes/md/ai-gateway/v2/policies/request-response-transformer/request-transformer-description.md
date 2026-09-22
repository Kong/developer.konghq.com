This Policy lets you configure transformations of requests before {{site.ai_gateway}} forwards them to the upstream provider. 
These transformations can be simple substitutions or complex ones.
For example, complex transformations can match portions of incoming requests using regular expressions, save those matched strings into variables, and substitute those strings into transformed requests using flexible templates.

This Policy operates on the raw HTTP request only: headers, query string, and body fields. To transform a request based on its meaning using an LLM (for example, rewriting a prompt), use the [AI Request Transformer Policy](/ai-gateway/policies/ai-request-transformer/) instead.

{:.info}
> **Note**: The `X-Forwarded-*` fields are non-standard header fields written by Nginx to inform the upstream about
client details and can't be overwritten by this Policy. If you need to overwrite these header fields, see the
[Post-Function Policy](/ai-gateway/policies/post-function/).
