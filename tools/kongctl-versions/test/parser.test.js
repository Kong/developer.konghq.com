import test from 'node:test';
import assert from 'node:assert/strict';
import { buildCobraCommandTree, extractCobraHelp } from '../../lib/tool-versions.js';
import { buildCommandTree } from '../extract-help.js';

const topHelp = `Longer help to show usage of this application.

Usage:
  kongctl [command]

Available Commands:
  get         Display one or many Kong resources
  completion  Generate the autocompletion script for the specified shell
  help        Help about any command
  version     Print the version

Flags:
  -h, --help   help for kongctl
`;

const getHelp = `Display one or many Kong resources.

Usage:
  kongctl get [command]

Available Commands:
  ai-gateway    Interact with AI Gateways
  api           Display API resources

Flags:
  -h, --help   help for get

Global Flags:
      --config string   config file (default is $HOME/.kongctl/config.yaml)
`;

const aiGatewayHelp = `Interact with AI Gateways.

Usage:
  kongctl get ai-gateway [command]

Available Commands:
  agents    Interact with AI Gateway agents

Flags:
  -h, --help   help for ai-gateway

Global Flags:
      --config string   config file (default is $HOME/.kongctl/config.yaml)
`;

const agentsHelp = `Interact with AI Gateway agents.

Usage:
  kongctl get ai-gateway agents [command]

Available Commands:
  list    List agents

Flags:
  -h, --help   help for agents

Global Flags:
      --config string   config file (default is $HOME/.kongctl/config.yaml)
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
    'kongctl --help': topHelp,
    'kongctl get --help': getHelp,
    'kongctl get ai-gateway --help': aiGatewayHelp,
    'kongctl get ai-gateway agents --help': agentsHelp,
    'kongctl get api --help': usageScoped('Display API resources.'),
  };
}

function usageScoped(prose) {
  return `${prose}

Usage:
  kongctl get api [flags]

Flags:
  -h, --help   help for api

Global Flags:
      --config string   config file (default is $HOME/.kongctl/config.yaml)
`;
}

test('recurses into sub-subcommands at maxDepth 2 and no further', async () => {
  const { exec, calls } = fakeExec(outputs());

  const tree = await buildCobraCommandTree({ exec, command: 'kongctl', maxDepth: 2, helpFromStdout: extractCobraHelp });

  const get = tree.find((node) => node.name === 'get');
  const aiGateway = get.subcommands.find((node) => node.name === 'ai-gateway');

  // Depth 2 is populated: ai-gateway's children are nodes of the tree.
  assert.deepEqual(aiGateway.subcommands.map((node) => node.name), ['agents']);

  // Depth 3 is not: agents lists subcommands, but nothing recurses into them.
  const agents = aiGateway.subcommands[0];
  assert.equal(agents.subcommands, undefined);
  assert.equal(calls.includes('kongctl get ai-gateway agents list --help'), false);
});

test('applies helpFromStdout to every node, scoping help from Usage to Global Flags', async () => {
  const { exec } = fakeExec(outputs());

  const tree = await buildCobraCommandTree({ exec, command: 'kongctl', maxDepth: 2, helpFromStdout: extractCobraHelp });

  const get = tree[0];
  assert.equal(get.help, extractCobraHelp(getHelp));
  assert.equal(get.help.startsWith('Usage:'), true);
  assert.equal(get.help.includes('Display one or many Kong resources.'), false);
  assert.equal(get.help.includes('Global Flags:'), false);

  const aiGateway = get.subcommands.find((node) => node.name === 'ai-gateway');
  assert.equal(aiGateway.help, extractCobraHelp(aiGatewayHelp));

  const api = get.subcommands.find((node) => node.name === 'api');
  assert.equal(api.help, extractCobraHelp(usageScoped('Display API resources.')));
});

test('skips help, completion, version, and deprecated commands at every level', async () => {
  const deprecatedTop = topHelp.replace(
    '  version     Print the version\n',
    '  version     Print the version\n  old-thing   Do something [deprecated]\n',
  );
  const { exec, calls } = fakeExec({
    ...outputs(),
    'kongctl --help': deprecatedTop,
    'kongctl old-thing --help': usageScoped('Deprecated command.'),
    'kongctl get ai-gateway agents --help': agentsHelp,
    'kongctl get ai-gateway --help': aiGatewayHelp.replace(
      '  agents    Interact with AI Gateway agents\n',
      '  agents    Interact with AI Gateway agents\n  completion  Generate the autocompletion script\n  help        Help about any command\n',
    ),
  });

  const tree = await buildCobraCommandTree({ exec, command: 'kongctl', maxDepth: 2, helpFromStdout: extractCobraHelp });

  assert.deepEqual(tree.map((node) => node.name), ['get']);

  const aiGateway = tree[0].subcommands.find((node) => node.name === 'ai-gateway');
  assert.deepEqual(aiGateway.subcommands.map((node) => node.name), ['agents']);

  assert.equal(calls.some((command) => command.includes('old-thing')), false);
  assert.equal(calls.some((command) => command.includes('completion')), false);
  assert.equal(calls.some((command) => / help /.test(command) || command.endsWith(' help --help')), false);
  assert.equal(calls.some((command) => command.includes('version')), false);
});

test('the entry point wires the builder to usage-scoped help and depth-2 recursion', async () => {
  const { exec } = fakeExec(outputs());

  const tree = await buildCommandTree({ exec });

  // helpFromStdout is extractCobraHelp: the usage-scoped section only.
  assert.deepEqual(tree.map((node) => node.name), ['get']);
  assert.equal(tree[0].help.startsWith('Usage:'), true);
  assert.equal(tree[0].help.includes('Display one or many Kong resources.'), false);

  // maxDepth is 2: sub-subcommands are populated, and recursion stops there.
  const aiGateway = tree[0].subcommands.find((node) => node.name === 'ai-gateway');
  assert.deepEqual(aiGateway.subcommands.map((node) => node.name), ['agents']);
  assert.equal(aiGateway.subcommands[0].subcommands, undefined);
});
