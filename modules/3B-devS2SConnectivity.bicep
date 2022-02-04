param location string
param devLNGName string = 'LNG-Production'
param devConnectionName string = 'Devlopment-To-Production-Connection'
param prodHubaddressPrefix string
param salesSpokeaddressPrefix string
param devHubVPNGW string
param prodVPNGWPIP string

@secure()
param adminPassword string

//Create Local Network Gateway in Development Hub Network (This represents "Production" side of the network)
resource devLNG 'Microsoft.Network/localNetworkGateways@2021-05-01' = {
  name: devLNGName
  location: location
  properties: {
    localNetworkAddressSpace: {
      addressPrefixes: [
        prodHubaddressPrefix
        salesSpokeaddressPrefix        
      ]
      
    }
    gatewayIpAddress: prodVPNGWPIP
  }
}

//Create Connection 
resource devConnection 'Microsoft.Network/connections@2021-05-01' = {
  name: devConnectionName
  location: location
  properties: {
    virtualNetworkGateway1: {
      id: devHubVPNGW
      properties:{}
    }
    localNetworkGateway2: {
      id: devLNG.id
      properties:{}
    }
    connectionType: 'IPsec'
    routingWeight: 0
    sharedKey: adminPassword
  }
}
