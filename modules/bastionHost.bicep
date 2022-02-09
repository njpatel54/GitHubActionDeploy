param location string
param bastionHostName string = 'myHost-01'
param vNetName string

resource prodBastionHostPIP 'Microsoft.Network/publicIpAddresses@2020-08-01' = {
  name: '${bastionHostName}-PIP'
  location: location
  sku: {
    name: 'Standard'
  }
  properties: {
    publicIPAllocationMethod: 'Static'
  }
}

resource prodBastionHost 'Microsoft.Network/bastionHosts@2021-03-01' = {
  name: bastionHostName
  location: location
  properties: {
    ipConfigurations: [
      {
        name: 'IpConf'
        properties: {
          subnet: {
            id: resourceId('Microsoft.Network/virtualNetworks/subnets', vNetName, 'AzureBastionSubnet')
          }
          publicIPAddress: {
            id: prodBastionHostPIP.id
          }
        }
      }
    ]
  }
}
