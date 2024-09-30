1. Import the KongAir Flights spec in Insomnia: 
    <a href="https://insomnia.rest/run/?label=&uri=https%3A%2F%2Fraw.githubusercontent.com%2FKong%2FKongAir%2Frefs%2Fheads%2Fmain%2Fflight-data%2Fflights%2Fopenapi.yaml" target="_blank"><img src="https://insomnia.rest/images/run.svg" alt="Run in Insomnia"></a>
1. Click the **Settings** icon for **SPEC** in the sidebar, and then click **Generate collection**. 
1. Click **Base environment** and then click the **Edit** icon.
1. Add the following content to the base environment:
```json
{
	"base_url": "https://api.kong-air.com",
	"flightNumber": "KA0284"
}
```