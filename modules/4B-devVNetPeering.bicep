param devHubToITVNetPeeringName string = 'Development-To-IT-Peering'
param itToDevHubVNetPeeringName string = 'IT-To-Development-Peering'
param devFirewallToDevHubVNetPeeringName string = 'Firewall-To-Development-Peering'
param devHubToDevFirewallVNetPeeringName string = 'Development-To-Firewall-Peering'
param devFirewallToItVNetPeeringName string = 'Firewall-To-IT-Peering'
param itToDevFirewallVNetPeeringName string = 'IT-To-Firewall-Peering'

param devHubVNet string
param devFirewallVNet string
param itSpokeVNet string
//param devHubVNetId string
//param devFirewallVNetId string
//param itSpokeVNetId string

//Retrive exisitng Virtual Network info
resource devVNet 'Microsoft.Network/virtualNetworks@2021-05-01' existing = {
  name: devHubVNet
}

resource firewallVNet 'Microsoft.Network/virtualNetworks@2021-05-01' existing = {
  name: devFirewallVNet
}

resource itVNet 'Microsoft.Network/virtualNetworks@2021-05-01' existing = {
  name: itSpokeVNet
}

// VNetPeering - 1 == Create VNet Peering between "Development-VNet" and "IT-VNet"
resource devHubToITVNetPeering 'Microsoft.Network/virtualNetworks/virtualNetworkPeerings@2021-05-01' = {
  name: devHubToITVNetPeeringName
  parent: devVNet
  properties: {
    allowVirtualNetworkAccess: true
    allowForwardedTraffic: true
    allowGatewayTransit: true
    //useRemoteGateways: true
    remoteVirtualNetwork: {
      id: itVNet.id
    }
  }
}

resource itToDevHubVNetPeering 'Microsoft.Network/virtualNetworks/virtualNetworkPeerings@2021-05-01' = {
  name: itToDevHubVNetPeeringName
  parent: itVNet
  properties: {
    allowVirtualNetworkAccess: true
    allowForwardedTraffic: true
    //allowGatewayTransit: true
    useRemoteGateways: true
    remoteVirtualNetwork: {
      id: devVNet.id
    }
  }
}

// VNetPeering - 2 == Create VNet Peering between "Firewall-VNet" and "Development-VNet"
resource devFirewallToDevHubVNetPeering 'Microsoft.Network/virtualNetworks/virtualNetworkPeerings@2021-05-01' = {
  name: devFirewallToDevHubVNetPeeringName
  parent: firewallVNet
  properties: {
    allowVirtualNetworkAccess: true
    allowForwardedTraffic: true
    //allowGatewayTransit: true
    useRemoteGateways: true
    remoteVirtualNetwork: {
      id: devVNet.id
    }
  }
}

resource devHubToDevFirewallVNetPeering 'Microsoft.Network/virtualNetworks/virtualNetworkPeerings@2021-05-01' = {
  name: devHubToDevFirewallVNetPeeringName
  parent: devVNet
  properties: {
    allowVirtualNetworkAccess: true
    allowForwardedTraffic: true
    allowGatewayTransit: true
    //useRemoteGateways: true
    remoteVirtualNetwork: {
      id: firewallVNet.id
    }
  }
}

// VNetPeering - 3 == Create VNet Peering between "Firewall-VNet" and "IT-VNet"
resource devFirewallToItVNetPeering 'Microsoft.Network/virtualNetworks/virtualNetworkPeerings@2021-05-01' = {
  name: devFirewallToItVNetPeeringName
  parent: firewallVNet
  properties: {
    allowVirtualNetworkAccess: true
    allowForwardedTraffic: true
    //allowGatewayTransit: true
    //useRemoteGateways: true
    remoteVirtualNetwork: {
      id: itVNet.id
    }
  }
}

resource itToDevFirewallVNetPeering 'Microsoft.Network/virtualNetworks/virtualNetworkPeerings@2021-05-01' = {
  name: itToDevFirewallVNetPeeringName
  parent: itVNet
  properties: {
    allowVirtualNetworkAccess: true
    allowForwardedTraffic: true
    //allowGatewayTransit: true
    //useRemoteGateways: true
    remoteVirtualNetwork: {
      id: firewallVNet.id
    }
  }
}
