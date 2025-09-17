@description('Location for all resources')
param location string = resourceGroup().location

@description('Prefix for generated names')
param namePrefix string = 'ohipdemo'

@description('Prefix for generated names')
param nameSuffix string = 'fabio'
// Storage account (used for staging by Data Factory)
resource storageAccount 'Microsoft.Storage/storageAccounts@2022-09-01' = {
  name: toLower('${namePrefix}st${uniqueString(resourceGroup().id)}')
  location: location
  sku: {
    name: 'Standard_LRS'
  }
  kind: 'StorageV2'
  properties: {
    accessTier: 'Hot'
  }
}

// Service Bus namespace (Standard - cheapest sku that supports topics)
resource serviceBusNamespace 'Microsoft.ServiceBus/namespaces@2021-11-01' = {
  name: toLower('${namePrefix}-sb-${nameSuffix}')
  location: location
  sku: {
    name: 'Standard'
    tier: 'Standard'
  }
  properties: {}
}

// Topic
resource bookingTopic 'Microsoft.ServiceBus/namespaces/topics@2021-11-01' = {
  parent: serviceBusNamespace
  name: 'bookings'
  properties: {
    defaultMessageTimeToLive: 'P7D'
  }
}

// Subscription
resource bookingSubscription 'Microsoft.ServiceBus/namespaces/topics/subscriptions@2021-11-01' = {
  parent: bookingTopic
  name: 'processing-sub'
  properties: {
    lockDuration: 'PT1M'
    maxDeliveryCount: 5
  }
}

// Data Factory (basic factory)
resource dataFactory 'Microsoft.DataFactory/factories@2018-06-01' = {
  name: toLower('${namePrefix}-df')
  location: location
  properties: {}
}

// Logic App (Consumption workflow)
resource logicApp 'Microsoft.Logic/workflows@2019-05-01' = {
  name: toLower('${namePrefix}-logic')
  location: location
  properties: {
    definition: {}
    // the runtimeModel and other properties are typically supplied during deployment of the workflow definition
  }
}

output storageAccountName string = storageAccount.name
output serviceBusNamespaceName string = serviceBusNamespace.name
output dataFactoryName string = dataFactory.name
output logicAppName string = logicApp.name
