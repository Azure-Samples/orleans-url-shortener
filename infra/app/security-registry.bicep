metadata description = 'Create Azure Container Registry RBAC assignments.'

@description('Id of the service principals to assign database and application roles.')
param appPrincipalId string = ''

@description('Id of the user principals to assign database and application roles.')
param userPrincipalId string = ''

module registryAppAssignment '../core/security/role/assignment.bicep' = if (!empty(appPrincipalId)) {
  name: 'container-registry-role-assignment-push-app'
  params: {
    roleDefinitionId: subscriptionResourceId('Microsoft.Authorization/roleDefinitions', '7f951dda-4ed3-4680-a7ca-43fe172d538d') // AcrPull built-in role
    principalId: appPrincipalId // Principal to assign role
    principalType: 'ServicePrincipal' // Current deployment user
  }
}

module registryUserAssignment '../core/security/role/assignment.bicep' = if (!empty(userPrincipalId)) {
  name: 'container-registry-role-assignment-push-user'
  params: {
    roleDefinitionId: subscriptionResourceId('Microsoft.Authorization/roleDefinitions', '8311e382-0749-4cb8-b61a-304f252e45ec') // AcrPush built-in role
    principalId: userPrincipalId // Principal to assign role
    principalType: 'User' // Current deployment user
  }
}

output roleDefinitions array = union(
  empty(userPrincipalId) ? [] : [
    subscriptionResourceId('Microsoft.Authorization/roleDefinitions', '8311e382-0749-4cb8-b61a-304f252e45ec')
  ],
  empty(appPrincipalId) ? [] : [
    subscriptionResourceId('Microsoft.Authorization/roleDefinitions', '7f951dda-4ed3-4680-a7ca-43fe172d538d')
  ]
)

output roleAssignments array = !empty(userPrincipalId) ? [] : [
  registryUserAssignment.outputs.id
]
