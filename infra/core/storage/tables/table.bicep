metadata description = 'Creates an Azure Table Storage table.'

param name string

@description('Name of the parent Azure Storage account.')
param parentAccountName string

@description('Name of the parent Azure Table Storage service.')
param parentServiceName string

resource account 'Microsoft.Storage/storageAccounts@2022-09-01' existing = {
  name: parentAccountName
}
resource service 'Microsoft.Storage/storageAccounts/tableServices@2022-09-01' existing = {
  name: parentServiceName
  parent: account
}

resource table 'Microsoft.Storage/storageAccounts/tableServices/tables@2022-09-01' = {
  name: name
  parent: service
}

output name string = table.name
