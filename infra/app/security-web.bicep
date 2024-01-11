metadata description = 'Assigns web application registry.'

param envName string
param appName string
param serviceTag string
param location string = resourceGroup().location
param tags object = {}

@description('Endpoint for Azure Cosmos DB for NoSQL account.')
param databaseAccountEndpoint string = ''

@description('Endpoint for Azure Table Storage account.')
param storageAccountEndpoint string = ''

@description('Endpoint of the Azure Container Registry to use.')
param containerRegistryEndpoint string = ''

var secrets = union(
  [],
  empty(databaseAccountEndpoint) ? [] : [
    {
      name: 'azure-cosmos-db-nosql-endpoint' // Create a uniquely-named secret
      value: databaseAccountEndpoint // NoSQL database account endpoint
    }
  ],
  empty(storageAccountEndpoint) ? [] : [
    {
      name: 'azure-table-storage-endpoint' // Create a uniquely-named secret
      value: storageAccountEndpoint // Table storage account endpoint
    }
  ]
)

var environmentVariables = union(
  [],
  empty(databaseAccountEndpoint) ? [] : [
    {
      name: 'AZURE_COSMOS_DB_NOSQL_ENDPOINT' // Name of the environment variable referenced in the application
      secretRef: 'azure-cosmos-db-nosql-endpoint' // Reference to secret
    }
  ],
  empty(storageAccountEndpoint) ? [] : [
    {
      name: 'AZURE_TABLE_STORAGE_ENDPOINT' // Name of the environment variable referenced in the application
      secretRef: 'azure-table-storage-endpoint' // Reference to secret
    }
  ]
)

resource containerAppsEnvironment 'Microsoft.App/managedEnvironments@2023-05-01' existing = {
  name: envName
}

// The registries must be assigned AFTER the web app's system-assigned managed identity is granted access to the container registry
module containerAppsApp '../core/host/container-apps/app.bicep' = {
  name: 'container-apps-app'
  params: {
    name: appName
    parentEnvironmentName: containerAppsEnvironment.name
    location: location
    tags: union(tags, {
        'azd-service-name': serviceTag
      })
    secrets: secrets
    environmentVariables: environmentVariables
    targetPort: 8080
    enableSystemAssignedManagedIdentity: true
    registries: [ {
        server: containerRegistryEndpoint
        identity: 'system'
      } ]
    containerImage: 'mcr.microsoft.com/dotnet/samples:aspnetapp'
  }
}
