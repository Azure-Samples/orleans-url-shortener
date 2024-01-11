targetScope = 'subscription'

@minLength(1)
@maxLength(64)
@description('Name of the environment that can be used as part of naming resource convention.')
param environmentName string

@minLength(1)
@description('Primary location for all resources.')
param location string

@description('Id of the principal to assign database and application roles.')
param principalId string = ''

// Deployment parameters
param deployAzureCosmosDBNoSQL bool = false
param deployAzureTableStorage bool = false

// Optional parameters
param containerAppsAppName string = ''
param containerAppsEnvName string = ''
param containerRegistryName string = ''
param cosmosDbAccountName string = ''
param logAnalyticsWorkspaceName string = ''
param storageAccountName string = ''

// serviceName is used as value for the tag (azd-service-name) azd uses to identify deployment host
param serviceName string = 'web'

var abbreviations = loadJsonContent('abbreviations.json')
var resourceToken = toLower(uniqueString(subscription().id, environmentName, location))
var tags = {
  'azd-env-name': environmentName
  repo: 'https://github.com/azure-samples/orleans-url-shortener'
}

// Define resource group
resource resourceGroup 'Microsoft.Resources/resourceGroups@2022-09-01' = {
  name: environmentName
  location: location
  tags: tags
}

// Optionally create Azure Cosmos DB for NoSQL account and resources
module database 'app/database.bicep' = if (deployAzureCosmosDBNoSQL) {
  name: 'database'
  scope: resourceGroup
  params: {
    accountName: !empty(cosmosDbAccountName) ? cosmosDbAccountName : '${abbreviations.cosmosDbAccount}-${resourceToken}'
    location: location
    tags: tags
  }
}

// Optionally create Azure Table Storage account and resources
module storage 'app/storage.bicep' = if (deployAzureTableStorage) {
  name: 'storage'
  scope: resourceGroup
  params: {
    accountName: !empty(storageAccountName) ? storageAccountName : '${abbreviations.storageAccount}${resourceToken}'
    location: location
    tags: tags
  }
}

// Create Azure Container Registry resource
module registry 'app/registry.bicep' = {
  name: 'registry'
  scope: resourceGroup
  params: {
    registryName: !empty(containerRegistryName) ? containerRegistryName : '${abbreviations.containerRegistry}${resourceToken}'
    location: location
    tags: tags
  }
}

// Create Azure Log Analytics workspace
module monitoring 'app/monitoring.bicep' = {
  name: 'monitoring'
  scope: resourceGroup
  params: {
    logAnalyticsWorkspaceName: !empty(logAnalyticsWorkspaceName) ? logAnalyticsWorkspaceName : '${abbreviations.logAnalyticsWorkspace}-${resourceToken}'
    location: location
    tags: tags
  }
}

// Create Azure Container App and environment
module web 'app/web.bicep' = {
  name: serviceName
  scope: resourceGroup
  params: {
    envName: !empty(containerAppsEnvName) ? containerAppsEnvName : '${abbreviations.containerAppsEnv}-${resourceToken}'
    appName: !empty(containerAppsAppName) ? containerAppsAppName : '${abbreviations.containerAppsApp}-${resourceToken}'
    location: location
    tags: tags
    databaseAccountEndpoint: deployAzureCosmosDBNoSQL ? database.outputs.endpoint : null
    storageAccountEndpoint: deployAzureTableStorage ? storage.outputs.endpoint : null
    logAnalyticsWorkspaceName: monitoring.outputs.logAnalyticsWorkspaceName
    serviceTag: serviceName
  }
}

// Optinally create RBAC definitions and assign roles for Azure Cosmos DB for NoSQL
module databaseSecurity 'app/security-database.bicep' = if (deployAzureCosmosDBNoSQL) {
  name: 'database-security'
  scope: resourceGroup
  params: {
    databaseAccountName: deployAzureCosmosDBNoSQL ? database.outputs.accountName : ''
    appPrincipalId: web.outputs.managedIdentityPrincipalId
    userPrincipalId: !empty(principalId) ? principalId : null
  }
}

// Optionally assign RBAC roles for Azure Table Storage
module storageSecurity 'app/security-storage.bicep' = if (deployAzureTableStorage) {
  name: 'storage-security'
  scope: resourceGroup
  params: {
    appPrincipalId: web.outputs.managedIdentityPrincipalId
    userPrincipalId: !empty(principalId) ? principalId : null
  }
}

// Assign RBAC roles for Azure Container Registry
module registrySecurity 'app/security-registry.bicep' = {
  name: 'registry-security'
  scope: resourceGroup
  params: {
    appPrincipalId: web.outputs.managedIdentityPrincipalId
    userPrincipalId: !empty(principalId) ? principalId : null
  }
}

// Assign Azure Container Registry to Azure Container App
module webSecurity 'app/security-web.bicep' = {
  name: 'web-security'
  scope: resourceGroup
  dependsOn: [
    registrySecurity
  ]
  params: {
    envName: !empty(containerAppsEnvName) ? containerAppsEnvName : '${abbreviations.containerAppsEnv}-${resourceToken}'
    appName: !empty(containerAppsAppName) ? containerAppsAppName : '${abbreviations.containerAppsApp}-${resourceToken}'
    location: location
    tags: tags
    databaseAccountEndpoint: deployAzureCosmosDBNoSQL ? database.outputs.endpoint : null
    storageAccountEndpoint: deployAzureTableStorage ? storage.outputs.endpoint : null
    containerRegistryEndpoint: registry.outputs.endpoint
    serviceTag: serviceName
  }
}

// Database outputs
output AZURE_COSMOS_DB_NOSQL_ENDPOINT string = deployAzureCosmosDBNoSQL ? database.outputs.endpoint : ''

// Storage outputs
output AZURE_TABLE_STORAGE_ENDPOINT string = deployAzureTableStorage ? storage.outputs.endpoint : ''

// Container outputs
output AZURE_CONTAINER_REGISTRY_ENDPOINT string = registry.outputs.endpoint
output AZURE_CONTAINER_REGISTRY_NAME string = registry.outputs.name

// Application outputs
output AZURE_CONTAINER_APP_ENDPOINT string = web.outputs.endpoint
output AZURE_CONTAINER_ENVIRONMENT_NAME string = web.outputs.envName

// Management outputs
output LOG_ANALYTICS_WORKSPACE_NAME string = monitoring.outputs.logAnalyticsWorkspaceName

// Security outputs
output AZURE_ROLE_DEFINITION_IDS array = union(
  deployAzureCosmosDBNoSQL ? [ databaseSecurity.outputs.roleDefinitions ] : [],
  deployAzureTableStorage ? [ storageSecurity.outputs.roleDefinitions ] : [],
  registrySecurity.outputs.roleDefinitions
)
output AZURE_ROLE_ASSIGNMENT_IDS array = union(
  deployAzureCosmosDBNoSQL ? [ databaseSecurity.outputs.roleAssignments ] : [],
  deployAzureTableStorage ? [ storageSecurity.outputs.roleAssignments ] : [],
  registrySecurity.outputs.roleAssignments
)
