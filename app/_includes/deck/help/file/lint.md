```bash
Usage:
  deck file lint [flags] ruleset-file

Flags:
  -D, --display-only-failures   only output results equal to or greater than --fail-severity
  -F, --fail-severity string    results of this level or above will trigger a failure exit code
                                [choices: "error", "warn", "info", "hint"] (default "error")
      --format string           output format [choices: "plain", "json", "yaml"] (default "plain")
  -h, --help                    help for lint
  -o, --output-file string      Output file to write to. Use - to write to stdout. (default "-")
  -s, --state string            decK file to process. Use - to read from stdin. (default "-")

```