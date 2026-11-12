# Auth Plugin examples

Some auth plugins (`basic-auth`, `hmac-auth`, `jwt` and `key-auth`) require a consumer and a credential attached to that consumer.

Their plugin examples now render a section showing how they are created.

## How it works

Plugins that require a consumer and credential define the necessary data in `app/_data/plugin/credentials`, e.g basic-auth

```yaml
consumer:
  username: alex

credential:
  endpoint: basic-auth
  deck_key: basicauth_credentials
  data:
    username: alex
    password: hello_world
```

And the platform will render the corresponding blocks in every supported tool.
This behaviour can be opted out of in each individual plugin example by setting `consumer_credential: false` in the example configuration.