1. Get a list of control planes:
   ```sh
   kumactl config control-planes list
   ```

1. Remove the control planes that are no longer needed:
   ```sh
   kumactl config control-planes remove --name my-cp
   ```