param location string
param deployBlob bool = true
param deployQueue bool = false
param deployTable bool = false
param deployFile bool = false
param entityName string = 'data'
param devStgAcctPrefix string = 'devstg'
param random string = take(newGuid(), 4)
param filename string = 'start.ps1'
param utcValue string = utcNow()

//SAS to download blobs in account
// signedServices - https://docs.microsoft.com/en-us/rest/api/storagerp/storage-accounts/list-account-sas#services
// signedPermission - https://docs.microsoft.com/en-us/rest/api/storagerp/storage-accounts/list-account-sas#permissions
// signedResourceTypes - https://docs.microsoft.com/en-us/rest/api/storagerp/storage-accounts/list-account-sas#signedresourcetypes

var accountSasProperties = {
  signedServices: 'b'
  signedPermission: 'rwdlacup'
  signedResourceTypes: 'cos'
  signedProtocol: 'https'
  signedExpiry: '2022-01-31T17:00:00Z'
  }

// SAS Toekn created using "accountSasProperties" and stored into variable "sasToken"
var sasToken = devStgaAcct.listAccountSas(devStgaAcct.apiVersion, accountSasProperties).accountSasToken

// create storage account
resource devStgaAcct 'Microsoft.Storage/storageAccounts@2021-04-01' = {
  name: '${devStgAcctPrefix}${random}'
  location: resourceGroup().location
  sku: {
    name: 'Standard_LRS'
  }
  kind: 'StorageV2'
  properties: {
      minimumTlsVersion: 'TLS1_2'
      supportsHttpsTrafficOnly: true
  }

  resource blobService 'blobServices' = if (deployBlob) {
    name: 'default'
    resource container 'containers' = {
      name: entityName
    }
  }

  resource queueService 'queueServices' = if (deployQueue) {
    name: 'default'
    resource queue 'queues' = {
      name: entityName
    }
  }

  resource tableService 'tableServices' = if (deployTable) {
    name: 'default'
    resource table 'tables' = {
      name: entityName
    }
  }

  resource fileService 'fileServices' = if (deployFile) {
    name: 'default'
    resource share 'shares' = {
      name: entityName
    }
  }
}

// Upload artifacts to storage account as a blob using Az Cli
resource deploymentScript 'Microsoft.Resources/deploymentScripts@2020-10-01' = {
  name: 'deployscript-upload-blob-${utcValue}'
  location: location
  kind: 'AzureCLI'
  properties: {
    azCliVersion: '2.26.1'
    timeout: 'PT5M'
    retentionInterval: 'PT1H'
    //https://docs.microsoft.com/en-us/azure/storage/blobs/authorize-data-operations-cli#set-environment-variables-for-authorization-parameters
    environmentVariables: [
      {
        name: 'AZURE_STORAGE_ACCOUNT'
        value: devStgaAcct.name
      }
      {
        name: 'AZURE_STORAGE_SAS_TOKEN'
        secureValue: sasToken
      }
      //{
      //  name: 'CONTENT'
      //  value: loadTextContent('../start.ps1')
      //}
    ]
    scriptContent: 'az storage blob upload -f C:\\start.ps1 -c ${entityName} -n ${filename}'
  }
}

output devStgaAcctName string = devStgaAcct.name
output devStgaAcctEndpoints object = devStgaAcct.properties.primaryEndpoints
output devBloburi string = '${devStgaAcct.properties.primaryEndpoints['blob']}${entityName}/${filename}'
