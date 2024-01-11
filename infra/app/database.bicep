metadata description = 'Create Azure Cosmos DB for NoSQL accounts and resources.'

param accountName string
param location string = resourceGroup().location
param tags object = {}

var database = {
  name: 'Orleans' // Default database
}

var containers = [
  {
    name: 'OrleansCluster' // Default clustering container
    partitionKeyPaths: [
      '/ClusterId' // Partition key
    ]
    autoscale: true // Scale at the database level
    throughput: 1000 // Enable autoscale with a minimum of 100 RUs and a maximum of 1,000 RUs

  }
  {
    name: 'OrleansStorage' // Default storage container
    partitionKeyPaths: [
      '/PartitionKey' // Partition key
    ]
    autoscale: true // Scale at the database level
    throughput: 1000 // Enable autoscale with a minimum of 100 RUs and a maximum of 1,000 RUs

  }
]

module cosmosDbAccount '../core/database/cosmos-db/nosql/account.bicep' = {
  name: 'cosmos-db-account'
  params: {
    name: accountName
    location: location
    tags: tags
    disableKeyBasedAuth: true
  }
}

module cosmosDbDatabase '../core/database/cosmos-db/nosql/database.bicep' = {
  name: 'cosmos-db-database-${database.name}'
  params: {
    name: database.name
    parentAccountName: cosmosDbAccount.outputs.name
    tags: tags
  }
}

module cosmosDbContainers '../core/database/cosmos-db/nosql/container.bicep' = [for (container, _) in containers: {
  name: 'cosmos-db-container-${container.name}'
  params: {
    name: container.name
    parentAccountName: cosmosDbAccount.outputs.name
    parentDatabaseName: cosmosDbDatabase.outputs.name
    tags: tags
    setThroughput: true
    autoscale: container.autoscale
    throughput: container.throughput
    partitionKeyPaths: container.partitionKeyPaths
  }
}]

output endpoint string = cosmosDbAccount.outputs.endpoint
output accountName string = cosmosDbAccount.outputs.name
