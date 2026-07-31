export async function processSetup(setup) {
  let runtime;
  let version;
  let rbac;
  let wasm;
  let standaloneGateway;
  let env_variables = {};
  if (typeof setup === "object") {
    // It should be one key/value pair, e.g. { gateway: 'x.y' }
    runtime = Object.keys(setup)[0];
    version = setup[runtime];
    rbac = setup.rbac;
    wasm = setup.wasm;
    standaloneGateway = setup.standalone_gateway;

    const knownKeys = new Set([runtime, "rbac", "wasm", "standalone_gateway"]);
    env_variables = Object.fromEntries(
      Object.entries(setup).filter(([key]) => !knownKeys.has(key)),
    );
  } else {
    // Not an object, for products/platforms that don't have versions.
    runtime = setup;
  }
  return { runtime, version, rbac, wasm, standaloneGateway, env_variables };
}

export async function getSetupConfig(setup) {
  const config = await processSetup(setup[0]);

  return config;
}
