The Encrypt Fields policy appends a `kong/enc` header to each message. This header identifies the encryption key by its ID, for example when using a [static key](/event-gateway/entities/static-key/).
Only the fields matched by the policy are encrypted, while the rest of the value structure is left intact. In the following message, the `personal.ssn` field is encrypted, but the sibling `personal.name` field is left in plaintext:

```json
{
	"Partition": 0,
	"Offset": 0,
	"Headers": {
		"kong/enc": "\u0000\u0004\u0000-static://019a537d-96ca-74f7-8903-aa99905e722d"
	},
	"Value": "{\"personal\":{\"name\":\"Jane Doe\",\"ssn\":\"AHry69Jl4oJzafOlu/xOjVa37hpfYTAVXoAolj94NoBQSKz7dkEF/gg=\"}}"
}
```

When decrypting, the Decrypt Fields policy reads the key reference from the `kong/enc` header. It then retrieves the corresponding key from the configured [key sources](/event-gateway/policies/decrypt-fields/reference/#schema-event-gateway-parsed-record-decrypt-fields-policy-config-key-sources) and uses it to decrypt only the matched fields.
