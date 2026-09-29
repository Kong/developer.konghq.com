You can use any of the current request headers and query parameters as templates to populate supported configuration fields.

{% table %}
columns:
  - title: Type
    key: type
  - title: Template
    key: template
rows:
  - type: Header
    template: |
      * `$(headers.{HEADER-NAME})`
      * `$(headers["{HEADER-NAME}"])`
  - type: Query parameter
    template: |
      * `$(query_params.{QUERY-PARAM-NAME})`
      * `$(query_params["{QUERY-PARAM-NAME}"])`
  - type: Shared variables
    template: |
      * `$(shared.{VARIABLE-NAME})`
      * `$(shared["{VARIABLE-NAME}"])`

{% endtable %}

To escape a template, wrap it inside quotes and pass inside another template.
For example:

```
$('$(something_that_needs_to_escaped)')
```

{:.info}
> **Note:** The Policy creates a non-mutable table of request headers and query strings before transformation. Therefore, removing or updating any parameters used in a template doesn't affect the rendered value of a template.

### Advanced templates

The content of the placeholder `$(...)` is evaluated as a Lua expression, so you can use logical operators. For example:

```
$(query_params["user"] or "unknown")
```

This example looks for a query parameter named `user`. If it doesn't exist, it returns the default value `"unknown"`.

Constant parts can be specified as part of the template outside the dynamic
placeholders. For example, this creates a basic-auth header from a query parameter
called `auth` that only contains the base64-encoded part:

```
Basic $(query_params["auth"])
```

Lambdas are also supported if wrapped as an expression like this:

```
$((function() ... implementation here ... end)())
```

Here's a complete Lambda example for prefixing a header value with `Basic` if it's not
already included:

```
$((function()
    local value = headers.Authorization
    if not value then
      return
    end
    if value:sub(1, 6) == "Basic " then
      return value            -- was already properly formed
    end
    return "Basic " .. value  -- added proper prefix
  end)())
```

The environment is sandboxed, meaning that Lambdas won't have access to any
library functions, except for the string methods (like `sub()` in this example).

{:.info}
> **Note:** Make sure not to add any trailing whitespace or newlines, especially in multi-line templates.
These would be outside the placeholders and would be considered part of the template, and hence would be appended to the generated value.
