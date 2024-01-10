metadata description = 'Create Azure Table Storage RBAC assignments.'

@description('Id of the service principals to assign database and application roles.')
param appPrincipalId string = ''

@description('Id of the user principals to assign database and application roles.')
param userPrincipalId string = ''

module storageAppAssignment '../core/security/role/assignment.bicep' = if (!empty(appPrincipalId)) {
  name: 'storage-role-assignment-app'
  params: {
    roleDefinitionId: subscriptionResourceId('Microsoft.Authorization/roleDefinitions', '0a9a7e1f-b9d0-4cc4-a60d-0319b160aaa3') // Storage Table Data Contributor built-in role
    principalId: appPrincipalId // Principal to assign role
    principalType: 'ServicePrincipal' // 
  }
}

module storageUserAssignment '../core/security/role/assignment.bicep' = if (!empty(userPrincipalId)) {
  name: 'storage-role-assignment-user'
  params: {
    roleDefinitionId: subscriptionResourceId('Microsoft.Authorization/roleDefinitions', '0a9a7e1f-b9d0-4cc4-a60d-0319b160aaa3') // Storage Table Data Contributor built-in role
    principalId: userPrincipalId // Principal to assign role
    principalType: 'User' // Current deployment user
  }
}

output roleDefinitions array = (!empty(appPrincipalId) || !empty(userPrincipalId)) ? [] : [
  subscriptionResourceId('Microsoft.Authorization/roleDefinitions', '0a9a7e1f-b9d0-4cc4-a60d-0319b160aaa3')
]

output roleAssignments array = union(
  (!empty(appPrincipalId)) ? [ storageAppAssignment.outputs.id ] : [],
  (!empty(userPrincipalId)) ? [ storageUserAssignment.outputs.id ] : []
)
