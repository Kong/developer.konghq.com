```ansi
Usage:
  deck file render [flags]

Flags:
  -W, --errors-as-warnings string   Treat the given comma-separated diagnostic codes as warnings.
      --format string               output file format: json or yaml. (default "yaml")
  -h, --help                        help for render
  -o, --output-file -               file to which to write Kong's configuration.Use - to write to stdout. (default "-")
      --populate-env-vars           Populate 'DECK_' environment variables in the output file. The default behavior
                                    is to mock environment variable values.
  -E, --warnings-as-errors string   Treat the given comma-separated diagnostic codes as errors.

```