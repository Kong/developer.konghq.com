<div markdown="1">
The following creates a new service called **{{ include.presenter.data['name'] }}** with basic configuration:

1. In Kong Manager or Gateway Manager, go to **Gateway Services**.
2. Click **New Gateway Service**.
3. Enter a unique name for the service. In this example, it's `{{ include.presenter.data['name'] }}`.
4. Define the endpoint for this service by specifying the full URL or by its separate elements. In this example, the full upstream URL is `{{ include.presenter.data['url'] }}`.
5. Click **Save**.
</div>
    