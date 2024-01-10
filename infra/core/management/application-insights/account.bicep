metadata description = 'Creates an Application Insights account.'

param name string
param location string = resourceGroup().location
param tags object = {}

@allowed([
  'web'
  'ios'
  'other'
  'store'
  'java'
  'phone'
])
@description('The kind of application that this Application Insights account is used with.')
param kind string = 'web'

@allowed([
  'web'
  'other'
])
@description('The type of application that this Application Insights account is used with.')
param type string = 'web'

@description('The name of the Log Analytics workspace to use.')
param logAnalyticsWorkspaceName string = ''

resource workspace 'Microsoft.OperationalInsights/workspaces@2022-10-01' existing = if (!empty(logAnalyticsWorkspaceName)) {
  name: logAnalyticsWorkspaceName
}

resource account 'Microsoft.Insights/components@2020-02-02' = {
  name: name
  location: location
  tags: tags
  kind: kind
  properties: {
    Application_Type: type
    WorkspaceResourceId: !empty(logAnalyticsWorkspaceName) ? workspace.id : null
  }
}

output name string = account.name
