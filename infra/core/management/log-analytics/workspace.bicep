metadata description = 'Creates a Log Analytics workspace.'

param name string
param location string = resourceGroup().location
param tags object = {}

@allowed([
  'Free'
  'PerGB2018'
  'PerNode'
  'Standalone'
])
@description('The SKU of the workspace. Default value is "PerGB2018."')
param sku string = 'PerGB2018'

resource workspace 'Microsoft.OperationalInsights/workspaces@2022-10-01' = {
  name: name
  location: location
  tags: tags
  properties: {
    sku: {
      name: sku
    }
  }
}

output name string = workspace.name
