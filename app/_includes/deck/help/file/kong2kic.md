```bash
Usage:
  deck file kong2kic [flags]

Flags:
      --class-name string    Value to use for "kubernetes.io/ingress.class" ObjectMeta.Annotations and for
                             		"parentRefs.name" in the case of HTTPRoute. (default "kong")
  -f, --format string        Output file format: json or yaml. (default "yaml")
  -h, --help                 help for kong2kic
      --ingress              Use Kubernetes Ingress API manifests instead of Gateway API manifests.
      --kic-version string   Generate manifests for KIC v3 or v2. Possible values are 2 or 3. (default "3")
  -o, --output-file string   Output file to write. Use - to write to stdout. (default "-")
  -s, --state string         decK file to process. Use - to read from stdin. (default "-")

```