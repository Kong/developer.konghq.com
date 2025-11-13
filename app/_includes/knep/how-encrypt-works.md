The Encrypt policy appends a `kong/enc` header to each message. This header identifies the encryption key by its ID for example when using a [static key](/event-gateway/entities/static-key/)
the resulting message appears as follows:

```json
{
	"Partition": 0,
	"Offset": 2,
	"Headers": {
		"kong/enc": "\u0000\u0001\u0000-static://019a537d-96ca-74f7-8903-aa99905e722d"
	},
	"Value": "deJ415liQWUEP8j33Yrb/7knuwRzHrHNRDQkkePePZ18MShhlY9A++ZFH/9uaHRb+Q=="
}
```

When decrypting, the Decrypt policy reads the key reference from the `kong/enc` header. It then retrieves the corresponding key from the configured [key sources](/event-gateway/policies/decrypt/reference/#schema-event-gateway-decrypt-policy-config-key-sources) and uses it to decrypt the message.

