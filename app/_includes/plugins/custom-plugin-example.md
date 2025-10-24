<!-- Shared between KIC and KGO plugin installation -->
## Create a custom plugin{% if include.is_optional %} (Optional){% endif %}

{:.info}
> If you already have a real plugin, you can skip this step.

```bash
mkdir myheader
echo 'local MyHeader = {}

MyHeader.PRIORITY = 1000
MyHeader.VERSION = "1.0.0"

function MyHeader:header_filter(conf)
  -- do custom logic here
  kong.response.set_header("myheader", conf.header_value)
end

return MyHeader
' > myheader/handler.lua

echo 'return {
  name = "myheader",
  fields = {
    { config = {
        type = "record",
        fields = {
          { header_value = { type = "string", default = "roar", }, },
        },
    }, },
  }
}
' > myheader/schema.lua
```

The directory should now look like this:

```bash
myheader
├── handler.lua
└── schema.lua

1 directory, 2 files
```
