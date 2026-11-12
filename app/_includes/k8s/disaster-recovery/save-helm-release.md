{% assign chart_name = include.chart | split: "/" | last %}
Create a protected directory outside the cluster for the recovery files:

```bash
mkdir -p recovery/{{include.dir}}
```

Save the effective Helm values of the `{{include.release}}` release:

```bash
helm get values {{include.release}} -n {{include.namespace}} --kube-context "$PRIMARY_CONTEXT" \
  --all -o yaml > recovery/{{include.dir}}/{{include.values_file}}
```

Read the installed chart version:

```bash
helm list -n {{include.namespace}} --kube-context "$PRIMARY_CONTEXT"
```

Set `{{include.version_var}}` to the version that follows `{{chart_name}}-` in the `CHART` column, then save that chart:

```bash
helm pull {{include.chart}} --version "${{include.version_var}}" \
  --destination recovery/{{include.dir}}
```
