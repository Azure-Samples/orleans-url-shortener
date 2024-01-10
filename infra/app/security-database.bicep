metadata description = 'Create Azure Cosmos DB for NoSQL RBAC definitions and assignments.'

param databaseAccountName string

@description('Id of the service principals to assign database and application roles.')
param appPrincipalId string = ''

@description('Id of the user principals to assign database and application roles.')
param userPrincipalId string = ''

resource account 'Microsoft.DocumentDB/databaseAccounts@2023-04-15' existing = {
  name: databaseAccountName
}

module nosqlDataPlaneDefinition '../core/database/cosmos-db/nosql/role/definition.bicep' = {
  name: 'nosql-role-definition'
  params: {
    targetAccountName: account.name // Existing account
    definitionName: 'Write to Azure Cosmos DB for NoSQL data plane' // Custom role name
    permissionsDataActions: [
      'Microsoft.DocumentDB/databaseAccounts/readMetadata' // Read account metadata
      'Microsoft.DocumentDB/databaseAccounts/sqlDatabases/containers/items/*' // Create items
      'Microsoft.DocumentDB/databaseAccounts/sqlDatabases/containers/*' // Manage items
    ]
  }
}

module nosqlDataPlaneAppAssignment '../core/database/cosmos-db/nosql/role/assignment.bicep' = if (!empty(appPrincipalId)) {
  name: 'nosql-role-data-plane-assignment-app'
  params: {
    targetAccountName: account.name // Existing account
    roleDefinitionId: nosqlDataPlaneDefinition.outputs.id // New role definition
    principalId: appPrincipalId // Principal to assign role
  }
}

module nosqlDataPlaneUserAssignment '../core/database/cosmos-db/nosql/role/assignment.bicep' = if (!empty(userPrincipalId)) {
  name: 'nosql-role-data-plane-assignment-user'
  params: {
    targetAccountName: account.name // Existing account
    roleDefinitionId: nosqlDataPlaneDefinition.outputs.id // New role definition
    principalId: userPrincipalId ?? '' // Principal to assign role
  }
}

output roleDefinitions array = [
  nosqlDataPlaneDefinition.outputs.id
]

output roleAssignments array = union(
  (empty(appPrincipalId)) ? [] : [
    nosqlDataPlaneAppAssignment.outputs.id
  ],
  (empty(userPrincipalId)) ? [] : [
    nosqlDataPlaneUserAssignment.outputs.id
  ]
)
