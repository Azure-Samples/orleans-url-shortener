metadata description = 'Creates an Azure Storage account.'

param name string
param location string = resourceGroup().location
param tags object = {}

@allowed([
  'Premium_LRS'
  'Premium_ZRS'
  'Standard_GRS'
  'Standard_GZRS'
  'Standard_LRS'
  'Standard_RAGRS'
  'Standard_RAGZRS'
  'Standard_ZRS'
])
@description('Name of the SKU. Defaults to "Standard_LRS".')
param skuName string = 'Standard_LRS'

@allowed([
  'BlobStorage'
  'BlockBlobStorage'
  'FileStorage'
  'Storage'
  'StorageV2'
])
@description('Sets the kind of account. Defaults to "StorageV2".')
param kind string = 'StorageV2'

@allowed([
  'Hot'
  'Cool'
  'Premium'
])
@description('Sets the access tier of the storage account. Defaults to "Hot".')
param accessTier string = 'Hot'

@description('Configures the storage account to only allow requests via HTTPS. Defaults to true.')
param httpsOnly bool = true

@description('Configures the storage account to allow public access to blobs. Defaults to false.')
param publicBlobAccess bool = false

resource account 'Microsoft.Storage/storageAccounts@2022-09-01' = {
  name: name
  location: location
  tags: tags
  sku: {
    name: skuName
  }
  kind: kind
  properties: {
    accessTier: accessTier
    allowBlobPublicAccess: publicBlobAccess
    supportsHttpsTrafficOnly: httpsOnly
  }
}

output blobEndpoint string = account.properties.primaryEndpoints.blob
output fileEndpoint string = account.properties.primaryEndpoints.file
output tableEndpoint string = account.properties.primaryEndpoints.table
output name string = account.name
