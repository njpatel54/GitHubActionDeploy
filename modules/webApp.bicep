param location string
param appServicePlanName string = 'myAppServicePlan'
param frontEndName string = 'fe-nileshpa-11'
param backEndName string = 'be-nileshpa-11'
param linuxFxVersion string = 'node|14-lts'
param vNetLinkName string = 'vNetLink-PrivateDNS'
param webAppPEName string = '${backEndName}-pe'
param privateDNSZoneLinkLocation string = 'global'
param privateLinkServiceConnectionName string = '${backEndName}-pe-connection'
param vNetIntegrationSubnetId string
param webAppPESubnetId string
param vNetId string

@description('SKU name, must be minimum P1v2')
@allowed([
  'P1v2'
  'P2v2'
  'P3v2'
])
param skuName string = 'P1v2'

@description('SKU size, must be minimum P1v2')
@allowed([
  'P1v2'
  'P2v2'
  'P3v2'
])
param skuSize string = 'P1v2'

@description('SKU family, must be minimum P1v2')
@allowed([
  'P1v2'
  'P2v2'
  'P3v2'
])
param skuFamily string = 'P1v2'

var skuTier = 'PremiumV2'

resource appServicePlan 'Microsoft.Web/serverfarms@2020-06-01' = {
  name: appServicePlanName
  location: location
  properties: {
    reserved: true
  }
  sku: {
    name: skuName
    tier: skuTier
    size: skuSize
    family: skuFamily
    capacity: 1
  }
  kind: 'linux'
}
resource feAppService 'Microsoft.Web/sites@2020-06-01' = {
  name: frontEndName
  location: location
  properties: {
    serverFarmId: appServicePlan.id
    siteConfig: {
      linuxFxVersion: linuxFxVersion
      appSettings: [
        {
          name: 'WEBSITE_DNS_SERVER'
          value: '168.63.129.16'
        }
        {
          name: 'WEBSITE_VNET_ROUTE_ALL'
          value: '1'
        }
      ]
    }
  }
}

resource vNetIntegration 'Microsoft.Web/sites/networkConfig@2021-02-01' = {
  name: 'virtualNetwork'
  parent: feAppService
  properties: {
    subnetResourceId: vNetIntegrationSubnetId
    swiftSupported: true
  }
}

resource beAppService 'Microsoft.Web/sites@2020-06-01' = {
  name: backEndName
  location: location
  properties: {
    serverFarmId: appServicePlan.id
    siteConfig: {
      linuxFxVersion: linuxFxVersion
    }
  }
}

resource privateDNSZone 'Microsoft.Network/privateDnsZones@2020-06-01' = {
  name: 'privatelink.azurewebsites.net'
  location: privateDNSZoneLinkLocation
}

resource vNetLink 'Microsoft.Network/privateDnsZones/virtualNetworkLinks@2020-06-01' = {
  name: '${privateDNSZone.name}/${vNetLinkName}'
  location: privateDNSZoneLinkLocation
  properties: {
    registrationEnabled: false
    virtualNetwork: {
      id: vNetId
    }
  }
}

resource webAppPE 'Microsoft.Network/privateEndpoints@2021-05-01' = {
  name: webAppPEName
  location: location
  dependsOn: [
    vNetLink
  ]
  properties: {
    subnet: {
      id: webAppPESubnetId
    }
    privateLinkServiceConnections: [
      {
        name: privateLinkServiceConnectionName
        properties: {
          privateLinkServiceId: beAppService.id
          groupIds: [
           'sites'
          ]
        }
      }
    ]
  }
}

resource privateDnsZoneGroup 'Microsoft.Network/privateEndpoints/privateDnsZoneGroups@2020-03-01' = {
  parent: webAppPE
  name: 'dnsgroupname'
  properties: {
    privateDnsZoneConfigs: [
      {
        name: 'config1'
        properties: {
          privateDnsZoneId: privateDNSZone.id
        }
      }
    ]
  }
}
