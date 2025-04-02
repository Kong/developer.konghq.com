The plugin allows navigating complex JSON objects (arrays and nested objects)
when `config.dots_in_keys` is set to `false` (the default is `true`).

- `array[*]`: Loops through all elements of the array.
- `array[N]`: Navigates to the nth element of the array (the index of the first element is `1`).
- `top.sub`: Navigates to the `sub` property of the `top` object.

These can be combined. For example, `config.remove.json: customers[*].info.phone` removes
all `phone` properties from inside the `info` object of all entries in the `customers` array.