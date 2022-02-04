param devSubnetsRTName string = 'Development-Subnets-RT'
param devGWSubnetRTName string = 'Development-Gateway-Subnet-RT'
param allTrafficRouteName string = 'All-Traffic'
param defaultSubnetRouteName string = 'default'
param itSubnetRouteName string = 'IT'
param p2sClientsRouteName string = 'P2S-Clients'
param devFirewallPrivateIP string
param devHubDefaultSubnetAddressPrefix string
param itSpokeItSubnetAddressprefix string
param devVPNClientAddPoolPrefix string

var devSubnetsRoutes = [
  {
    name: allTrafficRouteName
    addressPrefix: '0.0.0.0/0'
    nextHopType: 'VirtualAppliance'
    nextHopIpAddress: devFirewallPrivateIP
  }
]

var devGWSubnetsRoutes = [
  {
    name: defaultSubnetRouteName
    addressPrefix: devHubDefaultSubnetAddressPrefix
    nextHopType: 'VirtualAppliance'
    nextHopIpAddress: devFirewallPrivateIP
  }
  {
    name: itSubnetRouteName
    addressPrefix: itSpokeItSubnetAddressprefix
    nextHopType: 'VirtualAppliance'
    nextHopIpAddress: devFirewallPrivateIP
  }
  {
    name: p2sClientsRouteName
    addressPrefix: devVPNClientAddPoolPrefix
    nextHopType: 'VirtualAppliance'
    nextHopIpAddress: devFirewallPrivateIP
  }
]

resource devSubnetsRT 'Microsoft.Network/routeTables@2021-05-01' existing = {
  name: devSubnetsRTName
}

resource prodSubnetsRoute 'Microsoft.Network/routeTables/routes@2021-05-01' = [for route in devSubnetsRoutes: {
  name: route.name
  parent: devSubnetsRT
  properties: {
    addressPrefix: route.addressPrefix
    nextHopType: route.nextHopType
    nextHopIpAddress: route.nextHopIpAddress    
  }
}]

resource devGWSubnetsRT 'Microsoft.Network/routeTables@2021-05-01' existing = {
  name: devGWSubnetRTName
}

resource prodGWSubnetsRoute 'Microsoft.Network/routeTables/routes@2021-05-01' = [for route in devGWSubnetsRoutes: {
  name: route.name
  parent: devGWSubnetsRT
  properties: {
    addressPrefix: route.addressPrefix
    nextHopType: route.nextHopType
    nextHopIpAddress: route.nextHopIpAddress   
  }
}]
