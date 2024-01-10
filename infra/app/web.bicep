metadata description = 'Create web application resources.'

param envName string
param appName string
param serviceTag string
param location string = resourceGroup().location
param tags object = {}

@description('Name of the Log Analytics workspace to use.')
param logAnalyticsWorkspaceName string

@description('Endpoint for Azure Cosmos DB for NoSQL account.')
param databaseAccountEndpoint string = ''

@description('Endpoint for Azure Table Storage account.')
param storageAccountEndpoint string = ''

@description('Endpoint of the Azure Container Registry to use.')
param containerRegistryEndpoint string = ''

type managedIdentity = {
  resourceId: string
  clientId: string
}

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

module containerAppsEnvironment '../core/host/container-apps/environments/managed.bicep' = {
  name: 'container-apps-env'
  params: {
    name: envName
    location: location
    tags: tags
    logAnalyticsWorkspaceName: logAnalyticsWorkspaceName
  }
}

module containerAppsApp '../core/host/container-apps/app.bicep' = {
  name: 'container-apps-app'
  params: {
    name: appName
    parentEnvironmentName: containerAppsEnvironment.outputs.name
    location: location
    tags: union(tags, {
        'azd-service-name': serviceTag
      })
    secrets: secrets
    environmentVariables: environmentVariables
    targetPort: 8080
    enableSystemAssignedManagedIdentity: true
    registries: empty(containerRegistryEndpoint) ? [] : [
      containerRegistryEndpoint
    ]
    containerImage: 'mcr.microsoft.com/dotnet/samples:aspnetapp'
  }
}

output endpoint string = containerAppsApp.outputs.endpoint
output envName string = containerAppsApp.outputs.name
output managedIdentityPrincipalId string = containerAppsApp.outputs.systemAssignedManagedIdentityPrincipalId
