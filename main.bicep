param location string = 'usgovvirginia'
param prodRGName string = 'Prod-RG'
param devRGName string = 'Dev-RG'
param kvName string = 'testkeyvault609'
param kvRGName string = 'test'
param deployNumber string = '2'
//param prodArtifactUploadModuleDeploy bool = false
//param devArtifactUploadModuleDeploy bool = false
param prodVNetsModuleDeploy bool = true
param devVNetsModuleDeploy bool = true
param prodVPNGWModuleDeploy bool = true
param devVPNGWModuleDeploy bool = true
param prodS2SConnectivityModuleDeploy bool = true
param devS2SConnectivityModuleDeploy bool = true
param prodVNetPeeringModuleDeploy bool = true
param devVNetPeeringModuleDeploy bool = true
param prodFirewallModuleDeploy bool = true
param devFirewallModuleDeploy bool = true
param prodRoutesModuleDeploy bool = true
param devRoutesModuleDeploy bool = true
param prodVMsModuleDeploy bool = true
param devVMsModuleDeploy bool = true

// Step-0 == Setting Scope to "Subscription" to create "Resource Groups"
targetScope = 'subscription'
resource prodRG 'Microsoft.Resources/resourceGroups@2021-04-01' = {
  name: prodRGName
  location: location
}

resource devRG 'Microsoft.Resources/resourceGroups@2021-04-01' = {
  name: devRGName
  location: location
}

// Step-0 == Retrieve existing "Key Vault" where "adminLogin" and "adminPassword" secrets are stored
resource kvRG 'Microsoft.Resources/resourceGroups@2021-04-01' existing = {
  name: kvRGName
}

resource keyvault 'Microsoft.KeyVault/vaults@2019-09-01' existing = {
  name: kvName
  scope: kvRG
}
/*
// Step-0 == Upload artifacts to Stoage account as a blob using Az Cli
module prodArtifactUploadModule './modules/0A-prodStgAccount.bicep' = if (prodArtifactUploadModuleDeploy) {
  name: 'prodArtifactUpload-${deployNumber}'
  scope: prodRG
  params: {
    location: location
  }
}

module devArtifactUploadModule './modules/0B-devStgAccount.bicep' = if (devArtifactUploadModuleDeploy) {
  name: 'devArtifactUpload-${deployNumber}'
  scope: devRG
  params: {
    location: location
  }
}
*/

// Step-1 == Deploying module to create "Virutal Networks" at specific "Resource Group" scope
module prodVNetsModule './modules/1A-prodVNets.bicep' = if (prodVNetsModuleDeploy) {
  name: 'prodVNetDeploy-${deployNumber}'
  scope: prodRG
  params: {
    location: location    
  }
}

module devVNetsModule './modules/1B-devVNets.bicep' = if (devVNetsModuleDeploy) {
  name: 'devVNetDeploy-${deployNumber}'
  scope: devRG
  params: {
    location: location
  }
}

// Step-2 == Deploying module to create "Virutal Network Gateway" at specific "Resource Group" scope
module prodVPNGWModule './modules/2A-prodVPNGW.bicep' = if (prodVPNGWModuleDeploy) {
  name: 'prodVPNGWDeploy-${deployNumber}'
  scope: prodRG
  dependsOn: [
    prodVNetsModule
  ]
  params: {
    location: location
  }
}

module devVPNGWModule './modules/2B-devVPNGW.bicep' = if (devVPNGWModuleDeploy) {
  name: 'devVPNGWDeploy-${deployNumber}'
  scope: devRG
  dependsOn: [
    devVNetsModule
  ]
  params: {
    location: location
  }
}

// Step-3 == Deploying module to create "Local Network Gateway" and "Connections" at specific "Resource Group" scope
module prodS2SConnectivityModule './modules/3A-prodS2SConnectivity.bicep' = if (prodS2SConnectivityModuleDeploy) {
  name: 'prodS2SConnectivity-${deployNumber}'
  scope: prodRG
  dependsOn: [
    devVPNGWModule
  ]
  params: {
    location: location
    devHubaddressPrefix: devVNetsModule.outputs.devHubaddressPrefix
    itSpokeaddressPrefix: devVNetsModule.outputs.itSpokeaddressPrefix
    prodHubVPNGW: prodVPNGWModule.outputs.prodHubVPNGW
    devVPNGWPIP: devVPNGWModule.outputs.devVPNGWPIP
    adminPassword: keyvault.getSecret('adminPassword')
  }
}

module devS2SConnectivityModule './modules/3B-devS2SConnectivity.bicep' = if (devS2SConnectivityModuleDeploy) {
  name: 'devS2SConnectivity-${deployNumber}'
  scope: devRG
  dependsOn: [
    prodVPNGWModule
  ]
  params: {
    location: location
    prodHubaddressPrefix: prodVNetsModule.outputs.prodHubaddressPrefix
    salesSpokeaddressPrefix: prodVNetsModule.outputs.salesSpokeaddressPrefix
    devHubVPNGW: devVPNGWModule.outputs.devHubVPNGW
    prodVPNGWPIP: prodVPNGWModule.outputs.prodVPNGWPIP
    adminPassword: keyvault.getSecret('adminPassword')
  }
}

// Step-4 == Deploying module to create "VNet Peering" at specific "Resource Group" scope
module prodVNetPeeringModule './modules/4A-prodVNetPeering.bicep' = if (prodVNetPeeringModuleDeploy) {
  name: 'prodVNetPeering-${deployNumber}'
  scope: prodRG
  dependsOn: [
    prodVPNGWModule
  ]
  params: {
    prodHubVNet: prodVNetsModule.outputs.prodHubVNet
    salesSpokeVNet: prodVNetsModule.outputs.salesSpokeVNet
    prodFirewallVNet: prodVNetsModule.outputs.prodFirewallVNet
  }
}

module devVNetPeeringModule './modules/4B-devVNetPeering.bicep' = if (devVNetPeeringModuleDeploy) {
  name: 'devVNetPeering-${deployNumber}'
  scope: devRG
  dependsOn: [
    devVPNGWModule
  ]
  params: {
    devHubVNet: devVNetsModule.outputs.devHubVNet
    itSpokeVNet: devVNetsModule.outputs.itSpokeVNet
    devFirewallVNet: devVNetsModule.outputs.devFirewallVNet
  }
}

// Step-5 == Deploying module to create "Azure Firewall" at specific "Resource Group" scope
module prodFirewallModule './modules/5A-prodFirewall.bicep' = if (prodFirewallModuleDeploy) {
  name: 'prodFirewall-${deployNumber}'
  scope: prodRG
  dependsOn: [
    prodVNetsModule
  ]
  params: {
    location: location
    prodVMPrivateIP: prodVMsModule.outputs.prodVMPrivateIP
    salesVMPrivateIP: prodVMsModule.outputs.salesVMPrivateIP
    prodHubVNetName: prodVNetsModule.outputs.prodHubVNet
    prodFirewallVNet: prodVNetsModule.outputs.prodFirewallVNet
    prodHubDefaultSubnetAddressPrefix: prodVNetsModule.outputs.prodHubDefaultSubnetAddressPrefix
    salesSpokeSalesSubnetAddressprefix: prodVNetsModule.outputs.salesSpokeSalesSubnetAddressprefix
    devHubDefaultSubnetAddressPrefix: devVNetsModule.outputs.devHubDefaultSubnetAddressPrefix
    itSpokeItSubnetAddressprefix: devVNetsModule.outputs.itSpokeItSubnetAddressprefix
    prodVPNClientAddPoolPrefix: prodVPNGWModule.outputs.prodVPNClientAddPoolPrefix
  }
}

module devFirewallModule './modules/5B-devFirewall.bicep' = if (devFirewallModuleDeploy) {
  name: 'devFirewall-${deployNumber}'
  scope: devRG
  dependsOn: [
    devVNetsModule
  ]
  params: {
    location: location
    devVMPrivateIP: devVMsModule.outputs.devVMPrivateIP
    itVMPrivateIP: devVMsModule.outputs.itVMPrivateIP
    devHubVNetName: devVNetsModule.outputs.devHubVNet
    devFirewallVNet: devVNetsModule.outputs.devFirewallVNet
    prodHubDefaultSubnetAddressPrefix: prodVNetsModule.outputs.prodHubDefaultSubnetAddressPrefix
    salesSpokeSalesSubnetAddressprefix: prodVNetsModule.outputs.salesSpokeSalesSubnetAddressprefix
    devHubDefaultSubnetAddressPrefix: devVNetsModule.outputs.devHubDefaultSubnetAddressPrefix
    itSpokeItSubnetAddressprefix: devVNetsModule.outputs.itSpokeItSubnetAddressprefix
    devVPNClientAddPoolPrefix: devVPNGWModule.outputs.devVPNClientAddPoolPrefix
  }
}

// Step-6 == Deploying module to create "Routes" at specific "Resource Group" scope
module prodRoutesModule './modules/6A-prodRoutes.bicep' = if(prodRoutesModuleDeploy) {
  name: 'prodRoutes-${deployNumber}'
  scope: prodRG
  dependsOn: [
  prodFirewallModule
  ]
  params: {
    prodFirewallPrivateIP: prodFirewallModule.outputs.prodFirewallPrivateIP
    prodHubDefaultSubnetAddressPrefix: prodVNetsModule.outputs.prodHubDefaultSubnetAddressPrefix
    salesSpokeSalesSubnetAddressprefix: prodVNetsModule.outputs.salesSpokeSalesSubnetAddressprefix
    prodVPNClientAddPoolPrefix: prodVPNGWModule.outputs.prodVPNClientAddPoolPrefix
  }
}

module devRoutesModule './modules/6B-devRoutes.bicep' = if(devRoutesModuleDeploy) {
  name: 'devRoutes-${deployNumber}'
  scope: devRG
  dependsOn: [
    devFirewallModule
  ]
  params: {
    devFirewallPrivateIP: devFirewallModule.outputs.devFirewallPrivateIP
    devHubDefaultSubnetAddressPrefix: devVNetsModule.outputs.devHubDefaultSubnetAddressPrefix
    itSpokeItSubnetAddressprefix: devVNetsModule.outputs.itSpokeItSubnetAddressprefix
    devVPNClientAddPoolPrefix: devVPNGWModule.outputs.devVPNClientAddPoolPrefix
  }
}

// Step-7 == Deploying module to create "Virtual Machines" at specific "Resource Group" scope
module prodVMsModule './modules/7A-prodVMs.bicep' = if (prodVMsModuleDeploy) {
  name: 'prodVMs-${deployNumber}'
  scope: prodRG
  dependsOn: [
    prodVNetsModule
  ]
  params: {
    location: location
    adminLogin: keyvault.getSecret('adminLogin')
    adminPassword: keyvault.getSecret('adminPassword')
    //prodFileUris: prodArtifactUploadModule.outputs.prodBloburi
  }
}

module devVMsModule './modules/7B-devVMs.bicep' = if (devVMsModuleDeploy) {
  name: 'devVMs-${deployNumber}'
  scope: devRG
  dependsOn: [
    devVNetsModule
  ]
  params: {
    location: location
    adminLogin: keyvault.getSecret('adminLogin')
    adminPassword: keyvault.getSecret('adminPassword')
    //devFileUris: devArtifactUploadModule.outputs.devBloburi
  }
}
