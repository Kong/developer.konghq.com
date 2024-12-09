# scaffold-plugin

Automates the process of scaffolding a new plugin. It takes a plugin-name as an argument and generates the corresponding folder structure and files in the appropriate location.

## How it works

The script will copy the necessary templates from the `tools/scaffold-plugin/templates` directory into the `app/_plugins/plugin-name` directory.

## How to run it

Running the script with the plugin name `my-plugin`:

```bash
node tools/scaffold-plugin/index.js my-plugin
```

will generate the folder `app/_kong_plugins/my-plugin`, with all the necessary files copied from `tools/scaffold-plugin/templates`.
