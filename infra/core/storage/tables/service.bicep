metadata description = 'Creates an Azure Table Storage service.'

@description('Name of the parent Azure Storage account.')
param parentAccountName string

resource account 'Microsoft.Storage/storageAccounts@2022-09-01' existing = {
  name: parentAccountName
}

resource service 'Microsoft.Storage/storageAccounts/tableServices@2022-09-01' = {
  name: 'default'
  parent: account
}

output name string = service.name
