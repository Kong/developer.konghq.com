import test from 'node:test';
import assert from 'node:assert/strict';
import { buildCommandTree } from '../extract-help.js';

const topHelp = `Get started:
  # Set up with a profile file or URL from your admin
  kong-harnesses setup <profile-url>

kong-harnesses signs you in with your identity provider and gives agent CLIs
short-lived access tokens for the gateway.

Usage:
  kong-harnesses [flags]
  kong-harnesses [command]

Available Commands:
  credential    Print an access token, signing in first if needed
  doctor        Find problems with a profile and show how to fix them
  completion    Turn on shell completion, or print a completion script
  help          Show help for the CLI or one command
  profile       Manage connection profiles and the agent CLIs that use them
  version       Print the version

Flags:
  -h, --help   help for kong-harnesses
`;

const doctorHelp = `Check that a profile works from start to end, and show a fix for each
problem found.

Unlike status, doctor uses the network.

Usage:
  kong-harnesses doctor [flags]
`;

const profileHelp = `Manage connection profiles and the agent CLIs that use them.

Usage:
  kong-harnesses profile [flags]
  kong-harnesses profile [command]

Available Commands:
  create    Create a profile from your identity provider's details
  delete    Delete an installed profile from this computer

Flags:
  -h, --help   help for profile
`;

function fakeExec(outputs) {
  const calls = [];
  const exec = async (command) => {
    calls.push(command);
    const stdout = outputs[command];
    if (stdout === undefined) {
      throw new Error(`Unexpected command: ${command}`);
    }
    return { stdout };
  };
  return { exec, calls };
}

function outputs() {
  return {
    'kong-harnesses --help': topHelp,
    'kong-harnesses credential --help': 'Print an access token, signing in first if needed.\n\nUsage:\n  kong-harnesses credential [flags]\n',
    'kong-harnesses doctor --help': doctorHelp,
    'kong-harnesses profile --help': profileHelp,
    'kong-harnesses profile create --help': "Create a profile from your identity provider's details.\n\nUsage:\n  kong-harnesses profile create [flags]\n",
    'kong-harnesses profile delete --help': 'Delete an installed profile from this computer.\n\nUsage:\n  kong-harnesses profile delete [flags]\n',
  };
}

test('reads commands from the Available Commands section, skipping help, completion, and version', async () => {
  const { exec } = fakeExec(outputs());

  const tree = await buildCommandTree({ exec });

  assert.deepEqual(tree.map((node) => node.name), ['credential', 'doctor', 'profile']);
});

test('captures the complete help text, including prose that precedes the Usage block', async () => {
  const { exec } = fakeExec(outputs());

  const tree = await buildCommandTree({ exec });
  const doctor = tree.find((node) => node.name === 'doctor');

  assert.equal(
    doctor.help,
    'Check that a profile works from start to end, and show a fix for each\n' +
      'problem found.\n\n' +
      'Unlike status, doctor uses the network.\n\n' +
      'Usage:\n' +
      '  kong-harnesses doctor [flags]',
  );
});

test('produces nothing for a command absent from the Available Commands list', async () => {
  const { exec, calls } = fakeExec(outputs());

  const tree = await buildCommandTree({ exec });

  assert.equal(tree.some((node) => node.name === 'web-search-hook'), false);
  assert.equal(calls.some((command) => command.includes('web-search-hook')), false);
});

test('recurses one level into profile subcommands', async () => {
  const { exec, calls } = fakeExec(outputs());

  const tree = await buildCommandTree({ exec });
  const profile = tree.find((node) => node.name === 'profile');

  assert.deepEqual(profile.subcommands.map((sub) => sub.name), ['create', 'delete']);
  assert.equal(profile.subcommands[0].help, "Create a profile from your identity provider's details.\n\nUsage:\n  kong-harnesses profile create [flags]");
  assert.equal(calls.includes('kong-harnesses profile create --help'), true);
  assert.equal(calls.includes('kong-harnesses profile delete --help'), true);
});
