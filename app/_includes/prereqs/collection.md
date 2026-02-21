1. [Create a new collection](/insomnia/collections/).
1. [Import]() the [KongAir Flights](https://raw.githubusercontent.com/Kong/KongAir/refs/heads/main/flight-data/flights/openapi.yaml) requests.
1. Add the following content to the [base environment](/insomnia/environments/):

   ```json
   {
       "base_url": "https://api.kong-air.com"
   }
   ```