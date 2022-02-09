param location string
param vNetName string = 'WebApp-VNet'
param vNetAaddressPrefix string = '10.7.0.0/16'
param vNetIntegrationSubnetName string = 'vnet-integration-subnet'
param vNETIntegrationSubnetAddressPrefix string = '10.7.0.0/24'
param webappPeSubnetName string = 'webapp-pe-subnet'
param webappPeSubnetAddressPrefix string = '10.7.1.0/24'
param bastionSubnetName string = 'AzureBastionSubnet'
param bastionSubnetAddressPrefix string = '10.7.2.0/26'
param salesSubnetName string = 'sales-subnet'
param psalesSubnetAddressPrefix string = '10.7.3.0/24'

// Creating Virtual Networks

resource vNet 'Microsoft.Network/virtualNetworks@2021-05-01' = {
  name: vNetName
  location: location
  properties: {
    addressSpace: {
      addressPrefixes: [
        vNetAaddressPrefix
      ]
    }
    subnets: [
      {
        name: vNetIntegrationSubnetName
        properties: {
          addressPrefix: vNETIntegrationSubnetAddressPrefix
          delegations: [
            {
              name: 'delegation'
              properties: {
                  serviceName: 'Microsoft.Web/serverFarms'
              }
            }
          ]
        }
      }
      {
        name: webappPeSubnetName
        properties: {
          addressPrefix: webappPeSubnetAddressPrefix
          privateEndpointNetworkPolicies: 'Disabled'
        }
      }
      {
        name: bastionSubnetName
        properties: {
          addressPrefix: bastionSubnetAddressPrefix
        }
      }
      {
        name: salesSubnetName
        properties: {
          addressPrefix: psalesSubnetAddressPrefix  
        }
      }
    ]
  }
}

// Output - Production Hub VNet Name
// Output - Production Hub VNet resourceId
// Output - vnet-integration Subnet resourceId
// Output - webapp-pe Subnet resourceId
output vNetName string = vNetName
output vNetId string = vNet.id
output vNetIntegrationSubnetId string = vNet.properties.subnets[0].id
output webAppPESubnetId string = vNet.properties.subnets[1].id

