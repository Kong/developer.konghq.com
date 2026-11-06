// Owns the $PROXY_IP export injection for block-extracted steps.
//
// KIC how-tos reference $PROXY_IP in curl steps without documenting the export
// themselves, so the KIC product prereq's service lookup is injected here.
// Operator pages document their own export step (kubectl get gateway ...),
// which executeDocCommand persists to /env-vars.sh; injecting the KIC service
// lookup for them would overwrite that value with an empty one, because
// operator deployments never expose a kong-gateway-proxy service.

const KIC_PROXY_IP_EXPORT =
  "export PROXY_IP=$(kubectl get svc --namespace kong kong-gateway-proxy -o jsonpath='{range .status.loadBalancer.ingress[0]}{@.ip}{@.hostname}{end}')";

export function prependProxyIpExport(copiedText, product) {
  if (product !== "kic") {
    return copiedText;
  }
  if (!copiedText.includes("curl") || !copiedText.includes("$PROXY_IP")) {
    return copiedText;
  }
  return `${KIC_PROXY_IP_EXPORT}\n${copiedText}`;
}
