param location string
param devFirewallPolicyName string = 'Development-FW-Policy'
param devFirewallName string = 'Firewall-Development'
param devNetworkRuleCollectionName string = 'Production-To-Development'
param devInternetRuleCollectionName string = 'Internet'
param devP2SClientsRuleCollectionName string = 'P2S-Client-To-Development'
param allowAllFromProdToItRuleName string = 'AllowAll-From-Production-To-IT'
param allowAllFromProdToDefaultRuleName string = 'AllowAll-From-Production-To-Default'
param allowInternetFromITDefaultVMsRuleName string = 'AllowInternet-From-IT-and-Default-VMs'
param allowAllFromP2SClientsToITRuleName string = 'AllowAll-From-P2S-Clients-To-IT'
param allowAllFromP2SClientsToDefaultRuleName string = 'AllowAll-From-P2S-Clients-To-Default'
param devHubVNetName string
param devFirewallVNet string
param devVMPrivateIP string
param itVMPrivateIP string
param prodHubDefaultSubnetAddressPrefix string
param salesSpokeSalesSubnetAddressprefix string
param devHubDefaultSubnetAddressPrefix string
param itSpokeItSubnetAddressprefix string
param devVPNClientAddPoolPrefix string

//Retrive exisitng Virtual Network info
resource devHubVNet 'Microsoft.Network/virtualNetworks@2019-11-01' existing = {
  name: devHubVNetName
}

//Retrieve existing GatewaySubnet info
resource devHubFirewallSubnet 'Microsoft.Network/virtualNetworks/subnets@2021-05-01' existing = {
  //parent: devHubVNet
  name: '${devFirewallVNet}/AzureFirewallSubnet'
}

//Create Public IP Address
resource devFirewallPIP 'Microsoft.Network/publicIPAddresses@2021-05-01' = {
  name: 'devFirewallPIP'
  location: location
  properties: {
    publicIPAllocationMethod: 'Static'
  }
  sku: {
    name: 'Standard'
    tier: 'Regional'
  }
}

//Create Firewall Policy
resource devFirewallPolicy 'Microsoft.Network/firewallPolicies@2020-11-01' = {
  name: devFirewallPolicyName
  location: location
  properties: {
    sku: {
      tier: 'Standard'
    }
  }
}

//Create Firewall Rule Collection Groups & Rules.
resource devRuleCollectionGroups 'Microsoft.Network/firewallPolicies/ruleCollectionGroups@2020-11-01' = {
  parent: devFirewallPolicy
  name: 'DefaultNetworkRuleCollectionGroup'
  properties: {
    priority: 200
    ruleCollections: [
      {
        name: devNetworkRuleCollectionName
        priority: 200
        action: {
          type: 'Allow'
        }
        ruleCollectionType: 'FirewallPolicyFilterRuleCollection'
        rules: [
          {
            name: allowAllFromProdToItRuleName
            description: 'Allow all access from Production/Sales subnets to Development IT subnet'
            ruleType: 'NetworkRule'
            sourceAddresses: [
              prodHubDefaultSubnetAddressPrefix
              salesSpokeSalesSubnetAddressprefix
            ]
            destinationAddresses: [
              itSpokeItSubnetAddressprefix
            ]
            destinationPorts: [
              '*'
            ]
            ipProtocols: [
              'Any'
            ]
            sourceIpGroups: []            
            destinationIpGroups: []            
            destinationFqdns: []
          }
          {
            name: allowAllFromProdToDefaultRuleName
            description: 'Allow all access from Production/Sales subnets to Development Default subnet'
            ruleType: 'NetworkRule'
            sourceAddresses: [
              prodHubDefaultSubnetAddressPrefix
              salesSpokeSalesSubnetAddressprefix
            ]
            destinationAddresses: [
              devHubDefaultSubnetAddressPrefix
            ]
            destinationPorts: [
              '*'
            ]
            ipProtocols: [
              'Any'
            ]
            sourceIpGroups: []            
            destinationIpGroups: []            
            destinationFqdns: []
          }
        ]
      }
      {
        name: devInternetRuleCollectionName
        priority: 500
        action: {
         type: 'Allow'
        }
        ruleCollectionType: 'FirewallPolicyFilterRuleCollection'
        rules: [
          {
            name: allowInternetFromITDefaultVMsRuleName
            description: 'Allow all Internet access from "Dev-VM-01" and "IT-VM-01"'
            ruleType: 'NetworkRule'
            sourceAddresses: [
              devVMPrivateIP
              itVMPrivateIP
            ]
            destinationAddresses: [
              '*'
            ]
            destinationPorts: [
              '*'
            ]
            ipProtocols: [
              'Any'
            ]
            sourceIpGroups: []            
            destinationIpGroups: []            
            destinationFqdns: []
          }
        ]
      }
      {
        name: devP2SClientsRuleCollectionName
        priority: 300
        action: {
         type: 'Allow'
        }
        ruleCollectionType: 'FirewallPolicyFilterRuleCollection'
        rules: [
          {
            name: allowAllFromP2SClientsToDefaultRuleName
            description: 'Allow all access from P2S Clients subnet to Development Default subnet"'
            ruleType: 'NetworkRule'
            sourceAddresses: [
              devVPNClientAddPoolPrefix
            ]
            destinationAddresses: [
              devHubDefaultSubnetAddressPrefix
            ]
            destinationPorts: [
              '*'
            ]
            ipProtocols: [
              'Any'
            ]
            sourceIpGroups: []            
            destinationIpGroups: []            
            destinationFqdns: []
          }
          {
            name: allowAllFromP2SClientsToITRuleName
            description: 'Allow all access from P2S Clients subnet to Development IT subnet"'
            ruleType: 'NetworkRule'
            sourceAddresses: [
              devVPNClientAddPoolPrefix
            ]
            destinationAddresses: [
              itSpokeItSubnetAddressprefix
            ]
            destinationPorts: [
              '*'
            ]
            ipProtocols: [
              'Any'
            ]
            sourceIpGroups: []            
            destinationIpGroups: []            
            destinationFqdns: []
          }
        ]
      }
    ]
  }
}

//Create Firewall
resource devFirewall 'Microsoft.Network/azureFirewalls@2020-05-01' = {
  name: devFirewallName
  location: location
  dependsOn: [
    devRuleCollectionGroups
  ]
  properties: {
    sku: {
      name: 'AZFW_VNet' 
      tier: 'Standard'
    }
    firewallPolicy: {
      id: devFirewallPolicy.id
    }
    ipConfigurations: [
      {
        name: 'name'
        properties: {
          subnet: {
            id: devHubFirewallSubnet.id
          }
          publicIPAddress: {
            id: devFirewallPIP.id
          }
        }
      }
    ]
  }
 }

 //Output - Development Firewall's Private IP Address
 output devFirewallPrivateIP string = devFirewall.properties.ipConfigurations[0].properties.privateIPAddress
