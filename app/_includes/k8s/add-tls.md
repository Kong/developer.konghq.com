
{% include_cached /k8s/create-certificate.md hostname=include.hostname namespace=include.namespace %}

1. Update your routing configuration to use this certificate.
 {% capture the_code %}
{% navtabs codeblock %}
{% navtab "Gateway API" %}
```bash
kubectl patch -n kong --type=json gateway kong -p='[{
    "op":"add",
    "path":"/spec/listeners/-",
    "value":{
        "name":"proxy-ssl",
        "port":443,
        "protocol":"HTTPS",
        "tls":{
            "certificateRefs":[{
                "group":"",
                "kind":"Secret",
                "name":"{{include.hostname}}"
            }]
        }
    }
}]'

```
{% endnavtab %}
{% navtab "Ingress" %}
```bash
kubectl patch -n kong --type json ingress echo -p='[{
    "op":"add",
	"path":"/spec/tls",
	"value":[{
        "hosts":["{{ include.hostname }}"],
		"secretName":"{{include.hostname}}"
    }]
}]'
```
{% endnavtab %}
{% endnavtabs %}
{% endcapture %}
{{ the_code | indent:4 }}

1. Send requests to verify if the configured certificate is served.

    ```bash
    curl -ksv https://{{ include.hostname }}/echo --resolve {{ include.hostname }}:443:$PROXY_IP 2>&1 | grep -A1 "certificate:"
    ```
    The results should look like this:
    ```text
    * Server certificate:
    *  subject: CN={{ include.hostname }}
    ```