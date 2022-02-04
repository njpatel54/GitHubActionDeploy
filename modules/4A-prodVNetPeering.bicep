param prodHubToSalesVNetPeeringName string = 'Production-To-Sales-Peering'
param salesToProdHubVNetPeeringName string = 'Sales-To-Production-Peering'
param prodFirewallToProdHubVNetPeeringName string = 'Firewall-To-Production-Peering'
param prodHubToProdFirewallVNetPeeringName string = 'Production-To-Firewall-Peering'
param prodFirewallToSalesVNetPeeringName string = 'Firewall-To-Sales-Peering'
param salesToProdFirewallVNetPeeringName string = 'Sales-To-Firewall-Peering'

param prodHubVNet string
param prodFirewallVNet string
param salesSpokeVNet string
//param prodHubVNetId string
//param prodFirewallVNetId string
//param salesSpokeVNetId string

//Retrive exisitng Virtual Network info
resource prodVNet 'Microsoft.Network/virtualNetworks@2021-05-01' existing = {
  name: prodHubVNet
}

resource firewallVNet 'Microsoft.Network/virtualNetworks@2021-05-01' existing = {
  name: prodFirewallVNet
}

resource salesVNet 'Microsoft.Network/virtualNetworks@2021-05-01' existing = {
  name: salesSpokeVNet
}

// VNetPeering - 1 == Create VNet Peering between "Production-VNet" and "Sales-VNet"
resource prodHubToSalesVNetPeering 'Microsoft.Network/virtualNetworks/virtualNetworkPeerings@2021-05-01' = {
  name: prodHubToSalesVNetPeeringName
  parent: prodVNet
  properties: {
    allowVirtualNetworkAccess: true
    allowForwardedTraffic: true
    allowGatewayTransit: true
    //useRemoteGateways: true
    remoteVirtualNetwork: {
      id: salesVNet.id
    }
  }
}

resource salesToProdHubVNetPeering 'Microsoft.Network/virtualNetworks/virtualNetworkPeerings@2021-05-01' = {
  name: salesToProdHubVNetPeeringName
  parent: salesVNet
  properties: {
    allowVirtualNetworkAccess: true
    allowForwardedTraffic: true
    //allowGatewayTransit: true
    useRemoteGateways: true
    remoteVirtualNetwork: {
      id: prodVNet.id

    }
  }
}

// VNetPeering - 2 == Create VNet Peering between "Production-Firewall-VNet" VNet and "Production-VNet"
resource prodFirewallToProdHubVNetPeering 'Microsoft.Network/virtualNetworks/virtualNetworkPeerings@2021-05-01' = {
  name: prodFirewallToProdHubVNetPeeringName
  parent: firewallVNet
  properties: {
    allowVirtualNetworkAccess: true
    allowForwardedTraffic: true
    //allowGatewayTransit: true
    useRemoteGateways: true
    remoteVirtualNetwork: {
      id: prodVNet.id
    }
  }
}


resource prodHubToProdFirewallVNetPeering 'Microsoft.Network/virtualNetworks/virtualNetworkPeerings@2021-05-01' = {
  name: prodHubToProdFirewallVNetPeeringName
  parent: prodVNet
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

// VNetPeering - 3 == Create VNet Peering between "Production-Firewall-VNet" VNet and "Sales-VNet"
resource prodFirewallToSalesVNetPeering 'Microsoft.Network/virtualNetworks/virtualNetworkPeerings@2021-05-01' = {
  name: prodFirewallToSalesVNetPeeringName
  parent: firewallVNet
  properties: {
    allowVirtualNetworkAccess: true
    allowForwardedTraffic: true
    //allowGatewayTransit: true
    //useRemoteGateways: true
    remoteVirtualNetwork: {
      id: salesVNet.id
    }
  }
}


resource salesToProdFirewallVNetPeering 'Microsoft.Network/virtualNetworks/virtualNetworkPeerings@2021-05-01' = {
  name: salesToProdFirewallVNetPeeringName
  parent: salesVNet
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


