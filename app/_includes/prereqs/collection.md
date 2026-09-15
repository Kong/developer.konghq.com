1. [Create a new API Collection](/how-to/create-an-api-collection/).
1. [Import](/how-to/import-an-api-spec/) the [KongAir Flights](https://raw.githubusercontent.com/Kong/KongAir/refs/heads/main/flight-data/flights/openapi.yaml) requests.
1. Add the following content to the [base environment](/insomnia/environments/):

   ```json
   {
       "base_url": "https://api.kong-air.com"
   }
   ```