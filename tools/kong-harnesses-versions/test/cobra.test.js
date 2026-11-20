import test from 'node:test';
import assert from 'node:assert/strict';
import { extractCobraCommands, extractCobraHelp } from '../../lib/tool-versions.js';

const kongctlHelp = `kongctl is a CLI to manage your Kong Konnect resources

Usage:
  kongctl [command]

Examples:
kongctl get api

Available Commands:
  apply       Apply a configuration file
  get         Display one or many resources
  help        Help about any command
  completion  Generate the autocompletion script for the specified shell
  version     Print the version
  old-thing   An old command [deprecated]

Flags:
  -h, --help   help for kongctl

Global Flags:
  --verbose   log verbose output

Use "kongctl [command] --help" for more information about a command.`;

test('extractCobraCommands reads the Available Commands section, skipping help, completion, version, and deprecated entries', () => {
  assert.deepEqual(extractCobraCommands(kongctlHelp), ['apply', 'get']);
});

test('extractCobraHelp captures from Usage up to Global Flags', () => {
  const help = extractCobraHelp(kongctlHelp);

  assert.equal(
    help,
    'Usage:\n  kongctl [command]\n\nExamples:\nkongctl get api\n\nAvailable Commands:\n  apply       Apply a configuration file\n  get         Display one or many resources\n  help        Help about any command\n  completion  Generate the autocompletion script for the specified shell\n  version     Print the version\n  old-thing   An old command [deprecated]\n\nFlags:\n  -h, --help   help for kongctl\n',
  );
  assert.ok(!help.includes('Global Flags'), 'the captured help must stop before Global Flags');
});

test('extractCobraHelp returns an empty string when there is no Usage block', () => {
  assert.equal(extractCobraHelp('No usage here at all'), '');
});
