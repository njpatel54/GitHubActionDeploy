param location string
param prodLNGName string = 'LNG-Development'
param prodConnectionName string = 'Production-to-Devlopment-Connection'
param devHubaddressPrefix string
param itSpokeaddressPrefix string
param devVPNGWPIP string
param prodHubVPNGW string

@secure()
param adminPassword string

//Create Local Network Gateway in Production Hub Network (This represents "Development" side of the network)
resource prodLNG 'Microsoft.Network/localNetworkGateways@2021-05-01' = {
  name: prodLNGName
  location: location
  properties: {
    localNetworkAddressSpace: {
      addressPrefixes: [
        devHubaddressPrefix
        itSpokeaddressPrefix        
      ]
      
    }
    gatewayIpAddress: devVPNGWPIP
  }
}


//Create Connection 
resource prodConnection 'Microsoft.Network/connections@2021-05-01' = {
  name: prodConnectionName
  location: location
  properties: {
    virtualNetworkGateway1: {
      id: prodHubVPNGW
      properties:{}
    }
    localNetworkGateway2: {
      id: prodLNG.id
      properties:{}
    }
    connectionType: 'IPsec'
    routingWeight: 0
    sharedKey: adminPassword
  }
}
