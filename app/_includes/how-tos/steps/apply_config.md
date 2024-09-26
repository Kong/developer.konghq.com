{% assign konnect_token = site.data.entity_examples.config.konnect_variables.pat.placeholder %}

Synchronize your [decK](/deck/) configuration files.
Make sure you created the `deck_files` directory in the [prerequisites](#prerequisites).

First, compare the decK file or files to the state of the Kong Gateway:
```bash
deck gateway diff deck_files
```
{: data-deployment-topology="on-prem" }

```bash
deck gateway diff deck_files \
  --konnect-token ${{konnect_token}} \
  --konnect-control-plane-name $KONNECT_CP_NAME
```
{: data-deployment-topology="konnect" }

The output shows you which entities will change if you sync the state files.

If everything looks right, synchronize them to update your Gateway configuration:

```bash
deck gateway sync deck_files
```
{: data-deployment-topology="on-prem" }
```bash
deck gateway sync deck_files \
  --konnect-token ${{konnect_token}} \
  --konnect-control-plane-name $KONNECT_CP_NAME
```
{: data-deployment-topology="konnect" }
