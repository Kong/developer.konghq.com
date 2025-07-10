export async function processSetup(setup) {
  let runtime;
  let version;
  let rbac;
  let wasm;
  if (typeof setup === "object") {
    // It should be one key/value pair, e.g. { gateway: 'x.y' }
    runtime = Object.keys(setup)[0];
    version = setup[runtime];
    rbac = setup.rbac;
    wasm = setup.wasm;
  } else {
    // Not an object, for products/platforms that don't have versions.
    runtime = setup;
  }
  return { runtime, version, rbac, wasm };
}

export async function getSetupConfig(setup) {
  const config = await processSetup(setup[0]);

  return config;
}
