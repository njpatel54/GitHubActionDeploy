param prodSubnetsRTName string = 'Production-Subnets-RT'
param prodGWSubnetRTName string = 'Production-Gateway-Subnet-RT'
param allTrafficRouteName string = 'All-Traffic'
param defaultSubnetRouteName string = 'Default'
param salesSubnetRouteName string = 'Sales'
param p2sClientsRouteName string = 'P2S-Clients'
param prodFirewallPrivateIP string
param prodHubDefaultSubnetAddressPrefix string
param salesSpokeSalesSubnetAddressprefix string
param prodVPNClientAddPoolPrefix string

var prodSubnetsRoutes = [
  {
    name: allTrafficRouteName
    addressPrefix: '0.0.0.0/0'
    nextHopType: 'VirtualAppliance'
    nextHopIpAddress: prodFirewallPrivateIP
  }
]

var prodGWSubnetsRoutes = [
  {
    name: defaultSubnetRouteName
    addressPrefix: prodHubDefaultSubnetAddressPrefix
    nextHopType: 'VirtualAppliance'
    nextHopIpAddress: prodFirewallPrivateIP
  }
  {
    name: salesSubnetRouteName
    addressPrefix: salesSpokeSalesSubnetAddressprefix
    nextHopType: 'VirtualAppliance'
    nextHopIpAddress: prodFirewallPrivateIP
  }
  {
    name: p2sClientsRouteName
    addressPrefix: prodVPNClientAddPoolPrefix
    nextHopType: 'VirtualAppliance'
    nextHopIpAddress: prodFirewallPrivateIP
  }
]
resource prodSubnetsRT 'Microsoft.Network/routeTables@2021-05-01' existing = {
  name: prodSubnetsRTName
}

resource prodSubnetsRoute 'Microsoft.Network/routeTables/routes@2021-05-01' = [for route in prodSubnetsRoutes: {
  name: route.name
  parent: prodSubnetsRT
  properties: {
    addressPrefix: route.addressPrefix
    nextHopType: route.nextHopType
    nextHopIpAddress: route.nextHopIpAddress    
  }
}]

resource prodGWSubnetsRT 'Microsoft.Network/routeTables@2021-05-01' existing = {
  name: prodGWSubnetRTName
}

resource prodGWSubnetsRoute 'Microsoft.Network/routeTables/routes@2021-05-01' = [for route in prodGWSubnetsRoutes: {
  name: route.name
  parent: prodGWSubnetsRT
  properties: {
    addressPrefix: route.addressPrefix
    nextHopType: route.nextHopType
    nextHopIpAddress: route.nextHopIpAddress   
  }
}]
