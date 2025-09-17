Azure Function sample (Send to Service Bus)

Place the `function_send_servicebus_sample.js` file inside an Azure Functions project alongside `function.json` (in this sample they are under `config/function`).

Environment variables required:
- SERVICEBUS_CONNECTION: full Service Bus namespace connection string (RootManageSharedAccessKey)
- SERVICEBUS_TOPIC: topic name (default: bookings)

Local test (requires Azure Functions Core Tools):

```powershell
cd config
npm install
func start
# then POST the mock payload
Invoke-RestMethod -Uri http://localhost:7071/api/sendToServiceBus -Method POST -Body (Get-Content -Raw ..\config\mock_ohip_sample.json) -ContentType 'application/json'
```

When deploying to Azure, set the application settings in the Function App configuration.
