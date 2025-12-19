Let's define a context we can use to create Kafka topics:

```bash
cat <<EOF > kafkactl.yaml
contexts:
    direct:
      brokers:
        - localhost:9095
        - localhost:9096
        - localhost:9094
EOF
```
{: data-test-prereqs="block" }