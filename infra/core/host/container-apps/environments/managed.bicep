metadata description = 'Creates an Azure Container Apps managed environment.'

param name string
param location string = resourceGroup().location
param tags object = {}

@description('The name of the Log Analytics workspace to use for monitoring the managed environment.')
param logAnalyticsWorkspaceName string

resource workspace 'Microsoft.OperationalInsights/workspaces@2022-10-01' existing = if (!empty(logAnalyticsWorkspaceName)) {
  name: logAnalyticsWorkspaceName
}

resource environment 'Microsoft.App/managedEnvironments@2023-05-01' = {
  name: name
  location: location
  tags: tags
  properties: {
    appLogsConfiguration: {
      destination: 'log-analytics'
      logAnalyticsConfiguration: {
        customerId: workspace.properties.customerId
        sharedKey: workspace.listKeys().primarySharedKey
      }
    }
  }
}

output name string = environment.name
output domain string = environment.properties.defaultDomain
