metadata description = 'Create Azure Table Storage accounts and resources.'

param accountName string
param location string = resourceGroup().location
param tags object = {}

var tables = [
  {
    name: 'OrleansSiloInstances'
  }
  {
    name: 'OrleansGrainState'
  }
]

module storageAccount '../core/storage/account.bicep' = {
  name: 'storage-account'
  params: {
    name: accountName
    location: location
    tags: tags
  }
}

module storageTableService '../core/storage/tables/service.bicep' = {
  name: 'storage-table-service'
  params: {
    parentAccountName: storageAccount.outputs.name
  }
}

module storageTables '../core/storage/tables/table.bicep' = [for (table, _) in tables: {
  name: 'cosmos-db-container-${table.name}'
  params: {
    name: table.name
    parentAccountName: storageAccount.outputs.name
    parentServiceName: storageTableService.outputs.name
  }
}]

output endpoint string = storageAccount.outputs.tableEndpoint
output accountName string = storageAccount.outputs.name
