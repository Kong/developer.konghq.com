import test from 'node:test';
import assert from 'node:assert/strict';
import { buildCommandTree } from '../extract-help.js';

const topHelp = `agent-auth-cli obtains short-lived OIDC access tokens for Claude Code.

Usage:
  agent-auth-cli <command>

Commands:
  completion  Print shell completion setup or generate a script
  credential  Return an access token, creating the first login when absent
  doctor      Check the profile, sign-in, client, and both endpoints
  help        Show help for the CLI or one command
  profile     Manage public connection profiles and Claude integration
  version     Print the build version
`;

const doctorHelp = `Check one profile end to end and report each fix beside its finding.

Unlike status, this reaches the network: it establishes and closes one
connection to the issuer and to the gateway.

Usage:
  agent-auth-cli doctor --name <name> [--json]
`;

const profileHelp = `Manage public connection profiles and the global Claude integration.

Usage:
  agent-auth-cli profile <command>

Commands:
  create     Build and install a profile using OIDC discovery
  delete     Remove one installed profile from this computer
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
    'agent-auth-cli --help': topHelp,
    'agent-auth-cli credential --help': 'Return one short-lived access token, with lazy first login.\n\nUsage:\n  agent-auth-cli credential --name <name>\n',
    'agent-auth-cli doctor --help': doctorHelp,
    'agent-auth-cli profile --help': profileHelp,
    'agent-auth-cli profile create --help': 'Build and install a profile using OIDC discovery.\n\nUsage:\n  agent-auth-cli profile create --name <name>\n',
    'agent-auth-cli profile delete --help': 'Remove one installed profile from this computer.\n\nUsage:\n  agent-auth-cli profile delete --name <name>\n',
  };
}

test('reads commands from the Commands section, skipping help, completion, and version', async () => {
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
    'Check one profile end to end and report each fix beside its finding.\n\n' +
      'Unlike status, this reaches the network: it establishes and closes one\n' +
      'connection to the issuer and to the gateway.\n\n' +
      'Usage:\n' +
      '  agent-auth-cli doctor --name <name> [--json]',
  );
});

test('produces nothing for a command absent from the Commands list', async () => {
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
  assert.equal(profile.subcommands[0].help, 'Build and install a profile using OIDC discovery.\n\nUsage:\n  agent-auth-cli profile create --name <name>');
  assert.equal(calls.includes('agent-auth-cli profile create --help'), true);
  assert.equal(calls.includes('agent-auth-cli profile delete --help'), true);
});
