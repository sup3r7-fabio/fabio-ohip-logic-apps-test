# OHIP -> Azure Integration Demo

This small project demonstrates integrating Oracle Hospitality APIs (OHIP) with Azure using Data Factory, Service Bus, and Logic Apps. It is designed for interview or demo purposes and uses minimal/low-cost Azure resources provisioned via Bicep.

Architecture (simplified):

- Data Factory pipeline polls OHIP mock endpoint (or GitHub-hosted sample) using a Web activity.
- The pipeline calls an Azure Function (or similar) to publish the payload to an Azure Service Bus Topic (`bookings`).
- A Logic App is configured with a Service Bus trigger for the `bookings` topic subscription and processes incoming messages (parses JSON and forwards/logs to an HTTP endpoint).

Files added:

- `infrastructure/main.bicep` - Bicep file to create Storage, Service Bus, Data Factory, and Logic App.
- `infrastructure/parameters.json` - Bicep parameter values.
- `data-factory/pipeline.json` - Data Factory pipeline definition (fetch + handoff).
- `data-factory/linked-services.json` - Example linked services for Storage and Azure Functions.
- `logic-app/workflow-definition.json` - Logic App workflow (Service Bus trigger + parse + HTTP call).
- `logic-app/connections.json` - Example connections file for the Service Bus connector.
- `service-bus/topic-subscription-config.json` - Topic/subscription settings and Azure CLI examples.
- `config/appsettings.json` & `config/mock_ohip_sample.json` - Mock config and sample OHIP payload.
- `.vscode/extensions.json` - Recommended VS Code extensions.

Quick start (deploy to a resource group):

1. Install the recommended VS Code extensions (see `.vscode/extensions.json`).
2. Login with Azure CLI and select your subscription:

```powershell
az login
az account set --subscription "<your-subscription-id-or-name>"
```

3. Create a resource group (replace names/locations as you prefer):

```powershell
az group create -n ohipdemo-rg -l eastus
```

4. Deploy the Bicep template to the resource group:

```powershell
az deployment group create -g ohipdemo-rg -f infrastructure/main.bicep -p infrastructure/parameters.json
```

After deployment (manual wiring steps):

- Configure Azure Data Factory: import `data-factory/pipeline.json` and `data-factory/linked-services.json` using the Data Factory UI or ARM APIs. Update linked service placeholders (storage account name/key, Function URL) to match deployed resources.
- Create an Azure Function App and deploy the sample function `config/function_send_servicebus_sample.js` (Node.js). Set application settings `SERVICEBUS_CONNECTION` (namespace connection string) and `SERVICEBUS_TOPIC=bookings`.
- Import the Logic App: create a Consumption Logic App and paste `logic-app/workflow-definition.json` as the workflow definition. Create an API connection for Service Bus via the portal and update `logic-app/connections.json` placeholders.

End-to-end test (quick):

1. Start the Function App locally (Azure Functions Core Tools) or deploy it to a Function App.
2. Use the REST Client extension or curl to POST the sample payload to the function endpoint:

```powershell
# If running locally with Functions Core Tools
func start
# POST with PowerShell (replace url)
Invoke-RestMethod -Uri http://localhost:7071/api/sendToServiceBus -Method POST -Body (Get-Content -Raw config/mock_ohip_sample.json) -ContentType 'application/json'
```

3. Verify messages arrive in the Service Bus topic (Azure portal -> Service Bus -> Topic -> Metrics / Messages). The Logic App should trigger and forward the parsed payload to the HTTP sink defined in the workflow.

Requirements coverage (mapping):

- Bicep infra: `infrastructure/main.bicep` and `infrastructure/parameters.json` (cheapest SKUs used where possible) — Provided.
- Data Factory: `data-factory/pipeline.json` and `data-factory/linked-services.json` — Provided.
- Logic App: `logic-app/workflow-definition.json` and `logic-app/connections.json` — Provided.
- Service Bus: `service-bus/topic-subscription-config.json` — Provided CLI guidance and settings.
- Mock OHIP payloads: `config/mock_ohip_sample.json` and `config/README_MOCKS.md` — Provided.

Notes and assumptions:
- To keep this project interview-friendly the sample wires the pieces manually after deployment (Data Factory and Logic App connectors typically require portal steps or service principal credentials). This keeps the Bicep template compact while demonstrating the full architecture.
- Replace placeholders like `<subId>`, `<rg>`, `<location>`, `<storageAccount>`, `<accountKey>`, and Function/connection details before deploying.

References and documentation:
- Logic Apps: https://learn.microsoft.com/en-us/azure/logic-apps/logic-apps-overview
- Service Bus connector: https://learn.microsoft.com/en-us/azure/connectors/connectors-create-api-servicebus?tabs=consumption
- Bicep: https://learn.microsoft.com/en-us/azure/azure-resource-manager/bicep/overview?tabs=bicep
- Data Factory: https://learn.microsoft.com/en-us/azure/data-factory/introduction

References:
- Logic Apps: https://learn.microsoft.com/en-us/azure/logic-apps/logic-apps-overview
- Service Bus connector: https://learn.microsoft.com/en-us/azure/connectors/connectors-create-api-servicebus?tabs=consumption
- Bicep: https://learn.microsoft.com/en-us/azure/azure-resource-manager/bicep/overview?tabs=bicep
- Data Factory: https://learn.microsoft.com/en-us/azure/data-factory/introduction

Testing locally (mock):
- Use the provided `config/mock_ohip_sample.json` and the REST Client extension to POST it to a small Azure Function endpoint that publishes to Service Bus. Alternatively, use `az servicebus topic send` (Azure CLI) with the topic connection string to publish a message.

Notes and assumptions:
- The demo uses minimal SKUs but not every detail (like Managed Identity wiring for Data Factory or Logic App connections) is fully automated here to keep the sample small and reviewable.
- Replace placeholders like `<subId>`, `<rg>`, `<location>`, `<storageAccount>`, `<accountKey>`, and Function/connection details before deploying.
