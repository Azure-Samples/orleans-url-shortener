metadata description = 'Create Azure Monitor accounts and resources.'

param logAnalyticsWorkspaceName string
param location string = resourceGroup().location
param tags object = {}

module logAnalyicsWorkspace '../core/management/log-analytics/workspace.bicep' = {
  name: 'log-analytics-workspace'
  params: {
    name: logAnalyticsWorkspaceName
    location: location
    tags: tags
  }
}

output logAnalyticsWorkspaceName string = logAnalyicsWorkspace.outputs.name
