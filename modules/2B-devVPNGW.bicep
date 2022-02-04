param location string
param devHubVNetName string = 'Development-VNet'
param devHubVPNGWPIP string = 'Development-VPN-GW-PIP'
param devHubVPNGWName string = 'Development-VPN-GW'
param devVPNClientAddPoolPrefix string = '172.16.201.0/24'
param devVPNAuthenticationTypes string = 'Certificate'
param devVPNClientRootCertName string = 'myRootCA'
param devRootCACert string = 'MIIC5zCCAc+gAwIBAgIQLc69/HIm46hGfHJNb0+GPzANBgkqhkiG9w0BAQsFADAW MRQwEgYDVQQDDAtQMlNSb290Q2VydDAeFw0yMjAxMTYwMzU3MDZaFw0yMzAxMTYw NDE3MDZaMBYxFDASBgNVBAMMC1AyU1Jvb3RDZXJ0MIIBIjANBgkqhkiG9w0BAQEF AAOCAQ8AMIIBCgKCAQEA4u2NejWooKRGrNkuB2iW2jUpZp3NN8DhZAFIn5++o3es kR6h/XOmU++Seqy7rld4DIE0AzyX7rzfhFZJOngMniKMezAJmIsQR3OZi5ley2Dq beSpBmR3dGVZqlYfPudbHuMBrlj6xEmIDnrgRUl5ax7FhzCvxiAFm6cSU8s2btXW aozhAl2i5UhIuPrzyPNKq4YIXV1+Rk3K4ItjFmkPP1JR+nGnWCyQ3hGqBkO+a8t3 y/qfhQuoRK39yOuplrgRk1ra9Uox0UnUbGyiNJRrsfpkw+Yajn3l9nweIFsmnCPF w+3pkqS9gv8tCEBZSFEO668nQhPujuJQMwuz95XE6QIDAQABozEwLzAOBgNVHQ8B Af8EBAMCAgQwHQYDVR0OBBYEFNpMKbepK5ZxJZ7IWKhRswSVClDEMA0GCSqGSIb3 DQEBCwUAA4IBAQDMDbpS6vtsilmzfInbznpmRjloixoSewiu2rPLCVuxV4Zm4NG/ aAQk3cR5bNpx8tvfCGi+WchchhaaCXeGA7GfzCXJM6mcMhFU0+fG9t58KkQkX7sK dlaVzhQZ+RJ8Xp0YHF07JoqAcpQ2Eshj7hL2JSAXk52TXKh4u4HQsYxDXa2RGYGd yL0uQBeML1TWtVAHCJiUMKT5wXryGl4e+8iy/EmZbqhfMJK/NZH7iUXaWblkdLyX 9vcUDLBH0dLfh4CaNLnlTCcn1twMEbyjWdaHCqEBaxsIsvE7lYd2TxkXaG5X8Vh0 4PNK4qjjMnQilt7mhpok7rKrm7GtvZy6i2ek'


//Retrive exisitng Virtual Network info
resource devHubVNet 'Microsoft.Network/virtualNetworks@2019-11-01' existing = {
name: devHubVNetName
}

//Retrieve existing GatewaySubnet info
resource devHubGWSubnet 'Microsoft.Network/virtualNetworks/subnets@2021-05-01' existing = {
  parent: devHubVNet
  name: 'GatewaySubnet'
}

//Create Public IP Address
resource devVPNGWPIP 'Microsoft.Network/publicIPAddresses@2021-05-01' = {
  name: devHubVPNGWPIP
  location: location
}

//Create VPN Gateway
resource devHubVPNGW 'Microsoft.Network/virtualNetworkGateways@2020-11-01' = {
  name: devHubVPNGWName
  location: location
  properties: {
    ipConfigurations: [
      {
        name: 'name'
        properties: {
          privateIPAllocationMethod: 'Dynamic'
          subnet: {
            id: devHubGWSubnet.id
          }
          publicIPAddress: {
            id: devVPNGWPIP.id
          }
        }
      }
    ]
    sku: {
      name: 'VpnGw3'
      tier: 'VpnGw3'
    }
    gatewayType: 'Vpn'
    vpnType: 'RouteBased'
    enableBgp: false
    vpnGatewayGeneration:'Generation2'
    vpnClientConfiguration: {
      vpnClientAddressPool: {
        addressPrefixes: [
          devVPNClientAddPoolPrefix
        ]
      }
      vpnClientProtocols: [
        'SSTP'
        'IkeV2'
      ]
      vpnAuthenticationTypes: [
        devVPNAuthenticationTypes
      ]
      vpnClientRootCertificates: [
        {
          name: devVPNClientRootCertName
          properties: {
            publicCertData: devRootCACert
          }
        }
      ]
      vpnClientIpsecPolicies: []      
      vpnClientRevokedCertificates: []
      radiusServers: []      
    }
  }
}

//Output - VPN Gateway resoruceID (Development HUB)
//Output - VPN Gateway publicIPAddress address (Development Hub)
output devHubVPNGW string = devHubVPNGW.id
output devVPNGWPIP string = devVPNGWPIP.properties.ipAddress

//Output - P2S VPN Client Address Pool Prefix
output devVPNClientAddPoolPrefix string = devVPNClientAddPoolPrefix
