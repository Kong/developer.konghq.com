The Encrypt policy adds the `kong/enc` header to the message, referencing the key used to encrypt it by id, e.g., when using a [static key](/event-gateway/entities/static-key/)
the resulting message should look like:

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

When decrypting a message, the Decrypt policy uses the referenced key in the `kong/enc` header and looks for it in [key_sources](/event-gateway/policies/decrypt/reference/#schema-event-gateway-decrypt-policy-config-key-sources) to obtain the key’s value and uses it to decrypt the message.
