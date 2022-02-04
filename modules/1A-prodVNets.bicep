param location string
param prodHubVNetName string = 'Production-VNet'
param prodHubaddressPrefix string = '10.7.0.0/16'
param prodHubDefaultSubnetAddressPrefix string = '10.7.0.0/24'
param prodHubGateWaySubnetAddressPrefix string = '10.7.1.0/27'
param prodHubBastionSubnetAddressPrefix string = '10.7.2.0/26'
param prodFirewallVNetName string = 'Production-Firewall-VNet'
param prodFirewalladdressPrefix string = '10.8.0.0/16'
param prodFirewallSubnetAddressPrefix string = '10.8.0.0/26'
param salesSpokeVNetName string = 'Sales-VNet'
param salesSpokeaddressPrefix string = '10.9.0.0/16'
param salesSpokeSalesSubnetAddressprefix string = '10.9.0.0/24'
param prodSubnetsRTName string = 'Production-Subnets-RT'
param prodGWSubnetRTName string = 'Production-Gateway-Subnet-RT'

//Create Route Tables
resource prodSubnetsRT 'Microsoft.Network/routeTables@2021-05-01' = {
  name: prodSubnetsRTName
  location: location
  properties: {
    routes: []
    disableBgpRoutePropagation: true
  }
}

resource prodGWSubnetRT 'Microsoft.Network/routeTables@2021-05-01' = {
  name: prodGWSubnetRTName
  location: location
  properties: {
    routes: []
    disableBgpRoutePropagation: false
  }
}

// Creating Virtual Networks
resource prodHubVNet 'Microsoft.Network/virtualNetworks@2021-05-01' = {
  name: prodHubVNetName
  location: location
  properties: {
    addressSpace: {
      addressPrefixes: [
        prodHubaddressPrefix
      ]
    }
    subnets: [
      {
        name: 'default'
        properties: {
          addressPrefix: prodHubDefaultSubnetAddressPrefix
          routeTable: {
            id: prodSubnetsRT.id
          }
        }
      }
      {
        name: 'GatewaySubnet'
        properties: {
          addressPrefix: prodHubGateWaySubnetAddressPrefix
          routeTable: {
            id: prodGWSubnetRT.id
          }
        }
      }
      {
        name: 'AzureBastionSubnet'
        properties: {
          addressPrefix: prodHubBastionSubnetAddressPrefix
        }
      }
    ]
  }
}

resource prodFirewallVNet 'Microsoft.Network/virtualNetworks@2021-05-01' = {
  name: prodFirewallVNetName
  location: location
  properties: {
    addressSpace: {
      addressPrefixes: [
        prodFirewalladdressPrefix
      ]
    }
    subnets: [
      {
        name: 'AzureFirewallSubnet'
        properties: {
          addressPrefix: prodFirewallSubnetAddressPrefix
      }
    }
  ]
  }
}

resource salesSpokeVNet 'Microsoft.Network/virtualNetworks@2021-05-01' = {
  name: salesSpokeVNetName
  location: location
  properties: {
    addressSpace: {
      addressPrefixes: [
        salesSpokeaddressPrefix
      ]
    }
    subnets: [
      {
        name: 'sales-subnet'
        properties: {
          addressPrefix: salesSpokeSalesSubnetAddressprefix
          routeTable: {
           id: prodSubnetsRT.id
        }
      }
    }
  ]
  }
}

// Output - Production Hub VNet Name
// Output - Production Hub VNet resourceId
// Output - Production Hub VNet Address Prefix
// Output - Default Subnet Address Prefix (Production-VNet)
output prodHubVNet string = prodHubVNet.name
output prodHubVNetId string = prodHubVNet.id
output prodHubaddressPrefix string = prodHubaddressPrefix
output prodHubDefaultSubnetAddressPrefix string = prodHubDefaultSubnetAddressPrefix

// Output - Production Firewall VNet Name
// Output - Production Firewall VNet resourceId
// Output - Production Firewall VNet Address Prefix
output prodFirewallVNet string = prodFirewallVNet.name
output prodFirewallVNetId string = prodFirewallVNet.id
output prodFirewalladdressPrefix string = prodFirewalladdressPrefix

// Output - Sales Spoke VNet Name
// Output - Sales Spoke VNet resourceId
// Output - Sales Spoke VNet Address Prefix
// Output - Sales Subnet Address Prefix (Sales-VNet)
output salesSpokeVNet string = salesSpokeVNet.name
output salesSpokeVNetId string = salesSpokeVNet.id
output salesSpokeaddressPrefix string = salesSpokeaddressPrefix
output salesSpokeSalesSubnetAddressprefix string = salesSpokeSalesSubnetAddressprefix

// Output - Production-Subnets-RT resourceID
// Output - Production-Gateway-Subnet-RT resourceID
output prodSubnetsRTId string = prodSubnetsRT.id
output prodGWSubnetRTId string = prodGWSubnetRT.id

