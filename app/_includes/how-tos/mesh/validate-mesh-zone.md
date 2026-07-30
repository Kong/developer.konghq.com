Confirm the zone and demo services are connected to your global control plane.

1. In the {{site.konnect_short_name}} sidebar, click [**Service Mesh**](https://cloud.konghq.com/mesh-manager).
1. Click **example-cp**, then click **Meshes**.
1. Click **default**, then click the **Services** tab.

   You should see the `demo-app` and `kv` services.
   {:.info}
   > It may take a few minutes for the services to reach the `Online` status.
1. Port-forward the `demo-app` service to your local machine:

   ```sh
   kubectl port-forward svc/demo-app -n kong-mesh-demo 5050:5050
   ```

1. In a browser, go to [`http://127.0.0.1:5050`](http://127.0.0.1:5050) and increment the counter.

   The counter is stored in the `kv` service through the mesh, so a successful increment confirms that traffic is flowing between your services.
