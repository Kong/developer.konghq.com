```bash
Usage:
  deck file merge [flags] filename [...filename]

Examples:
# Merge 3 files
deck file merge -o merged.yaml file1.yaml file2.yaml file3.yaml

Flags:
      --format string        output format: yaml or json (default "yaml")
  -h, --help                 help for merge
  -o, --output-file string   Output file to write to. Use - to write to stdout. (default "-")

```