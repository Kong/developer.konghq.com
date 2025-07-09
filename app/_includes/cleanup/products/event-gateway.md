When you're done experimenting with this example, clean up the resources:

1. Stop and remove the containers:

   ```sh
   docker-compose down
   ```
1. Verify that all containers have been removed:

   ```sh
   docker ps -a | grep -E 'kafka|knep'
   ```

This will stop all services and remove the containers, but preserve your configuration files for future use.