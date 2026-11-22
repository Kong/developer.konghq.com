Install {{ site.claude_code }} 2.1.284 or later:

{% navtabs "install-claude-code" %}
{% navtab "macOS and Linux" %}
```sh
curl -fsSL https://claude.ai/install.sh | bash
```

Run `claude --version` to check the install.
If the terminal can't find `claude`, do the `PATH` step that the installer prints.
If you open a new terminal for it, export the variables from the other prerequisites again.
{% endnavtab %}
{% navtab "Windows" %}
In PowerShell:

```powershell
irm https://claude.ai/install.ps1 | iex
```

Run `claude --version` to check the install.
If the terminal can't find `claude`, do the `PATH` step that the installer prints.
{% endnavtab %}
{% endnavtabs %}
