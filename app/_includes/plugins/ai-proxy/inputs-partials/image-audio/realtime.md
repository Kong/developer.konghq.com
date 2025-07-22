Supported in: {% new_in 3.11 %}

{:.warning}
> To use the realtime route, you must configure the protocols `ws` and/or `wss` on both the Service and on the Route where the plugin is associated.

```json
{
  "messages": [
    { "role": "system", "content": "You are a helpful assistant." },
    { "role": "user", "content": "Explain the concept of quantum superposition." }
  ]
}
```