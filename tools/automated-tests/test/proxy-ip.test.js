import { test } from "node:test";
import assert from "node:assert/strict";

import { prependProxyIpExport } from "../instructions/proxy-ip.js";

test("injects the KIC service lookup for a kic curl step using $PROXY_IP", () => {
  const result = prependProxyIpExport('curl "$PROXY_IP/echo"\n     --no-progress-meter --fail-with-body', "kic");
  assert.equal(
    result,
    "export PROXY_IP=$(kubectl get svc --namespace kong kong-gateway-proxy -o jsonpath='{range .status.loadBalancer.ingress[0]}{@.ip}{@.hostname}{end}')\n" +
      'curl "$PROXY_IP/echo"\n     --no-progress-meter --fail-with-body',
  );
});

test("does not inject for the operator product", () => {
  const step = 'curl "$PROXY_IP/echo" --no-progress-meter --fail-with-body';
  assert.equal(prependProxyIpExport(step, "operator"), step);
});

test("does not inject when the step has no $PROXY_IP reference", () => {
  const step = "curl http://localhost:8000/anything";
  assert.equal(prependProxyIpExport(step, "kic"), step);
});

test("does not inject when the step is not a curl command", () => {
  const step = 'export PROXY_IP=$(kubectl get gateway kong -n kong -o jsonpath=\'{.status.addresses[0].value}\')';
  assert.equal(prependProxyIpExport(step, "kic"), step);
});
