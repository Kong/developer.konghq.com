You can use any of the current request headers, query parameters, and captured URI
groups as templates to populate supported configuration fields.

{% table %}
columns:
  - title: Type
    key: type
  - title: Template
    key: template
rows:
  - type: Header
    template: |
      * `$(headers.<header-name>)`
      * `$(headers["<header-name>"])`
  - type: Query parameter
    template: |
      * `$(query_params.<query-param-name>)`
      * `$(query_params["<query-param-name>"])`
  - type: Captured URIs
    template: |
      * `$(uri_captures.<group-name>)`
      * `$(uri_captures["<group-name>"])`
  - type: Shared variables
    template: |
      * `$(shared.<variable-name>)`
      * `$(shared["<variable-name>"])`
    
{% endtable %}

To escape a template, wrap it inside quotes and pass inside another template.
For example:

```
$('$(something_that_needs_to_escaped)')
```

{:.info}
> **Note:** The plugin creates a non-mutable table of request headers, query strings, and captured URIs before transformation. Therefore, any update or removal of parameters used in a template does not affect the rendered value of a template.

### Arrays and nested objects

The plugin allows navigating complex JSON objects (arrays and nested objects)
when `config.dots_in_keys` is set to `false` (the default is `true`).

- `array[*]`: Loops through all elements of the array.
- `array[N]`: Navigates to the nth element of the array (the index of the first element is `1`).
- `top.sub`: Navigates to the `sub` property of the `top` object.

These can be combined. For example, `config.remove.json: customers[*].info.phone` removes
all `phone` properties from inside the `info` object of all entries in the `customers` array.

### Advanced templates

The content of the placeholder `$(...)` is evaluated as a Lua expression, so
logical operators may be used. For example:

```
$(uri_captures["user-id"] or query_params["user"] or "unknown")
```

This will first look for the path parameter named `user-id` (in `uri_captures`). If not found, it will
return the query parameter named `user`. If that also doesn't exist, it returns the default
value '"unknown"'.

Constant parts can be specified as part of the template outside the dynamic
placeholders. For example, creating a basic-auth header from a query parameter
called `auth` that only contains the base64-encoded part:

```
Basic $(query_params["auth"])
```

Lambdas are also supported if wrapped as an expression like this:

```
$((function() ... implementation here ... end)())
```

A complete Lambda example for prefixing a header value with `Basic` if it's not
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

{:.info}
> **Note:** Especially in multi-line templates like the example above, make sure not
to add any trailing white space or new lines. Because these would be outside the
placeholders, they would be considered part of the template, and hence would be
appended to the generated value.
The environment is sandboxed, meaning that Lambdas will not have access to any
library functions, except for the string methods (like `sub()` in the example
above).