param location string = 'usgovvirginia'
param rgName string = 'WebApp-RG2'
param deployNumber string = '2'
param vNetsModuleDeploy bool = true
param webAppModuleDeploy bool = true
param bastionHostModuleDeploy bool = true
param vmsModuleDeploy bool = true
param kvName string = 'testkeyvault609'
param kvRGName string = 'test'

targetScope = 'subscription'
resource rg 'Microsoft.Resources/resourceGroups@2021-04-01' = {
  name: rgName
  location: location
}

module vNetModule 'modules/vNets.bicep' = if (vNetsModuleDeploy) {
  name: 'vNetModule-${deployNumber}'
  scope: rg
  params: {
    location: location
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
  }
}

module bastionHostModule 'modules/bastionHost.bicep' = if (bastionHostModuleDeploy) {
  name: 'bastionHostModule-${deployNumber}'
  scope: rg
  params: {
    location: location
    vNetName: vNetModule.outputs.vNetName
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
  }
}
