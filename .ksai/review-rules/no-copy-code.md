# Output blocks

- A fenced code block that shows only command output, a response body or sample logs (not something the reader runs or pastes) ends with `{:.no-copy-code}` on the line directly after the closing fence. Flag a changed output-only block that lacks it.
- The marker may carry other classes, such as `{:.no-copy-code .collapsible}`. That is valid as long as `.no-copy-code` is one of the classes. Do not flag it.
- Not a violation: blocks the reader is meant to run or copy (commands, config, request bodies, YAML to apply).
