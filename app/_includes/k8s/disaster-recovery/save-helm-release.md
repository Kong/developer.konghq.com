1. Save the effective Helm values of the `{{include.release}}` release:

   ```bash
   helm get values {{include.release}} -n {{include.namespace}} \
     --all -o yaml > recovery/{{include.values_file}}
   ```

1. Read the chart version of the release:

   ```bash
   export {{include.version_var}}=$(helm get metadata {{include.release}} -n {{include.namespace}} | awk '/^VERSION:/ {print $2}')
   ```

1. Save that exact chart version:

   ```bash
   helm pull {{include.chart}} --version "${{include.version_var}}" \
     --destination recovery
   ```
