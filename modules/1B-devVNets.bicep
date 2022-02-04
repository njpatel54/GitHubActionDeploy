param location string
param devHubVNetName string = 'Development-VNet'
param devHubaddressPrefix string = '10.10.0.0/16'
param devHubDefaultSubnetAddressPrefix string = '10.10.0.0/24'
param devHubGateWaySubnetAddressPrefix string = '10.10.1.0/27'
param devHubBastionSubnetAddressPrefix string = '10.10.2.0/26'
param devFirewallVNetName string = 'Development-Firewall-VNet'
param devFirewalladdressPrefix string = '10.11.0.0/16'
param devFirewallSubnetAddressPrefix string = '10.11.0.0/26'
param itSpokeVNetName string = 'IT-VNet'
param itSpokeaddressPrefix string = '10.12.0.0/16'
param itSpokeItSubnetAddressprefix string = '10.12.0.0/24'
param devSubnetsRTName string = 'Development-Subnets-RT'
param devGWSubnetRTName string = 'Development-Gateway-Subnet-RT'

//Create Route Tables
resource devSubnetsRT 'Microsoft.Network/routeTables@2021-05-01' = {
  name: devSubnetsRTName
  location: location
  properties: {
    routes: []
    disableBgpRoutePropagation: true
  }
}

resource devGWSubnetRT 'Microsoft.Network/routeTables@2021-05-01' = {
  name: devGWSubnetRTName
  location: location
  properties: {
    routes: []
    disableBgpRoutePropagation: false
  }
}


// Creating Virtual Networks
resource devHubVNet 'Microsoft.Network/virtualNetworks@2021-05-01' = {
  name: devHubVNetName
  location: location
  properties: {
    addressSpace: {
      addressPrefixes: [
        devHubaddressPrefix
      ]
    }
    subnets: [
      {
        name: 'default'
        properties: {
          addressPrefix: devHubDefaultSubnetAddressPrefix
          routeTable: {
            id: devSubnetsRT.id
          }
        }
      }
      {
        name: 'GatewaySubnet'
        properties: {
          addressPrefix: devHubGateWaySubnetAddressPrefix
          routeTable: {
            id: devGWSubnetRT.id
          }
        }
      }
      {
        name: 'AzureBastionSubnet'
        properties: {
          addressPrefix: devHubBastionSubnetAddressPrefix
        }
      }
    ]
  }
}

resource devFirewallVNet 'Microsoft.Network/virtualNetworks@2021-05-01' = {
  name: devFirewallVNetName
  location: location
  properties: {
    addressSpace: {
      addressPrefixes: [
        devFirewalladdressPrefix
      ]
    }
    subnets: [
      {
        name: 'AzureFirewallSubnet'
        properties: {
          addressPrefix: devFirewallSubnetAddressPrefix
        }
      }
    ]
  }
}

resource itSpokeVNet 'Microsoft.Network/virtualNetworks@2021-05-01' = {
  name: itSpokeVNetName
  location: location
  properties: {
    addressSpace: {
      addressPrefixes: [
        itSpokeaddressPrefix
      ]
    }
    subnets: [
      {
        name: 'it-subnet'
        properties: {
          addressPrefix: itSpokeItSubnetAddressprefix
          routeTable: {
           id: devSubnetsRT.id
          }
        }
      }
    ]
  }
}

// Output - Development Hub VNet Name
// Output - Development Hub VNet resourceId
// Output - Development Hub VNet Address Prefix
// Output - Default Subnet Address Prefix (Development-VNet)
output devHubVNet string = devHubVNet.name
output devHubVNetId string = devHubVNet.id
output devHubaddressPrefix string = devHubaddressPrefix
output devHubDefaultSubnetAddressPrefix string = devHubDefaultSubnetAddressPrefix

// Output - Development Firewall VNet Name
// Output - Development Firewall VNet resourceId
// Output - Development Firewall VNet Address Prefix
output devFirewallVNet string = devFirewallVNet.name
output devFirewallVNetId string = devFirewallVNet.id
output devFirewalladdressPrefix string = devFirewalladdressPrefix

// Output - IT Spoke VNet Name
// Output - IT Spoke VNet resourceId
// Output - IT Spoke VNet Address Prefix
// Output - IT Subnet Address Prefix (IT-VNet)
output itSpokeVNet string = itSpokeVNet.name
output itSpokeVNetId string = itSpokeVNet.id
output itSpokeaddressPrefix string = itSpokeaddressPrefix
output itSpokeItSubnetAddressprefix string = itSpokeItSubnetAddressprefix

// Output - Development-Subnets-RT resourceID
// Output - Development-Gateway-Subnet-RT resourceID
output devdSubnetsRTId string = devSubnetsRT.id
output devGWSubnetRTId string = devGWSubnetRT.id
