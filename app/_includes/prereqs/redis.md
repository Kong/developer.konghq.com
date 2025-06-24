To complete this tutorial, make sure you have the following:

* A [Redis Stack](https://redis.io/docs/latest/) running and accessible from the environment where Kong is deployed.
* Port `6379`, or your custom Redis port is open and reachable from Kong.
* Redis host set as an environment variable so the plugin can connect:

  ```sh
  export DECK_REDIS_HOST='YOUR-REDIS-HOST'
  ```

{:.info}
>If you're testing locally with Docker, use `host.docker.internal` as the host value.

