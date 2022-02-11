param location string = 'usgovvirginia'
param rgName string = 'WebApp-RG2'
param deployNumber string = '2'
param vNetsModuleDeploy bool = true
param webAppModuleDeploy bool = true
param bastionHostModuleDeploy bool = true
param vmsModuleDeploy bool = true
param kvName string = 'testkeyvault609'
param kvRGName string = 'test'

param baseTime string = utcNow('u')

// '-PTH5H' subtracks 5 Hours from UTC time to reflect Eastern Time Zone
param now string = dateTimeAdd(baseTime, '-PT5H')

param tagValues object = {
  createdOn: now
  Environment: 'Production'
}

targetScope = 'subscription'
resource rg 'Microsoft.Resources/resourceGroups@2021-04-01' = {
  name: rgName
  location: location
  tags: tagValues
}

module vNetModule 'modules/vNets.bicep' = if (vNetsModuleDeploy) {
  name: 'vNetModule-${deployNumber}'
  scope: rg
  params: {
    location: location
    tagValues: tagValues
  }
}

resource kvRG 'Microsoft.Resources/resourceGroups@2021-04-01' existing = {
  name: kvRGName
}

resource keyvault 'Microsoft.KeyVault/vaults@2019-09-01' existing = {
  name: kvName
  scope: kvRG
}

module webAppModule 'modules/webApp.bicep' = if (webAppModuleDeploy) {
  name: 'webAppModule-${deployNumber}'
  scope: rg
  params: {
    location: location
    vNetIntegrationSubnetId: vNetModule.outputs.vNetIntegrationSubnetId
    webAppPESubnetId: vNetModule.outputs.webAppPESubnetId
    vNetId: vNetModule.outputs.vNetId
    tagValues: tagValues
  }
}

module bastionHostModule 'modules/bastionHost.bicep' = if (bastionHostModuleDeploy) {
  name: 'bastionHostModule-${deployNumber}'
  scope: rg
  params: {
    location: location
    vNetName: vNetModule.outputs.vNetName
    tagValues: tagValues
  }
}

module vmsModule 'modules/vms.bicep' = if (vmsModuleDeploy) {
  name: 'vmsModule-${deployNumber}'
  scope: rg
  params: {
    location: location
    vNetName: vNetModule.outputs.vNetName
    adminLogin: keyvault.getSecret('adminLogin')
    adminPassword: keyvault.getSecret('adminPassword')
    tagValues: tagValues
  }
}
