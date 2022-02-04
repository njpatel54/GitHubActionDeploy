param location string
param prodFirewallPolicyName string = 'Production-FW-Policy'
param prodFirewallName string = 'Firewall-Production'
param prodNetworkRuleCollectionName string = 'Development-to-Production'
param prodInternetRuleCollectionName string = 'Internet'
param prodP2SClientsRuleCollectionName string = 'P2S-Client-To-Production'
param allowAllFromDevToSalesRuleName string = 'AllowAll-From-Development-To-Sales'
param allowAllFromDevToDefaultRuleName string = 'AllowAll-From-Development-To-Default'
param allowInternetFromSalesDefaultVMsRuleName string = 'AllowInternet-From-Sales-and-Default-VMs'
param allowAllFromP2SClientsToSalesRuleName string = 'AllowAll-From-P2S-Clients-To-Sales'
param allowAllFromP2SClientsToDefaultRuleName string = 'AllowAll-From-P2S-Clients-To-Default'
param prodHubVNetName string
param prodFirewallVNet string
param prodVMPrivateIP string
param salesVMPrivateIP string
param prodHubDefaultSubnetAddressPrefix string
param salesSpokeSalesSubnetAddressprefix string
param devHubDefaultSubnetAddressPrefix string
param itSpokeItSubnetAddressprefix string
param prodVPNClientAddPoolPrefix string

//Retrive exisitng Production-VNet info
resource prodHubVNet 'Microsoft.Network/virtualNetworks@2019-11-01' existing = {
  name: prodHubVNetName
}

//Retrieve existing AzureFirewallSubnet info
resource prodHubFirewallSubnet 'Microsoft.Network/virtualNetworks/subnets@2021-05-01' existing = {
  //parent: prodFirewallVNet
  name: '${prodFirewallVNet}/AzureFirewallSubnet'
}

//Create Public IP Address
resource prodFirewallPIP 'Microsoft.Network/publicIPAddresses@2021-05-01' = {
  name: 'prodFirewallPIP'
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
resource prodFirewallPolicy 'Microsoft.Network/firewallPolicies@2020-11-01' = {
  name: prodFirewallPolicyName
  location: location
  properties: {
    sku: {
      tier: 'Standard'
    }
  }
}

//Create Firwall Rule Collection Group & Rules.
resource prodRuleCollectionGroups 'Microsoft.Network/firewallPolicies/ruleCollectionGroups@2020-11-01' = {
  parent: prodFirewallPolicy
  name: 'DefaultNetworkRuleCollectionGroup'
  properties: {
    priority: 200
    ruleCollections: [
      {
        name: prodNetworkRuleCollectionName
        priority: 200
        action: {
          type: 'Allow'
        }
        ruleCollectionType: 'FirewallPolicyFilterRuleCollection'
        rules: [
          {
            name: allowAllFromDevToSalesRuleName
            description: 'Allow all access from Development/IT subnets to Production Sales subnet'
            ruleType: 'NetworkRule'
            sourceAddresses: [
              devHubDefaultSubnetAddressPrefix
              itSpokeItSubnetAddressprefix
            ]
            destinationAddresses: [
              salesSpokeSalesSubnetAddressprefix
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
            name: allowAllFromDevToDefaultRuleName
            description: 'Allow all access from Development/IT subnets to Production Default subnet'
            ruleType: 'NetworkRule'
            sourceAddresses: [
              devHubDefaultSubnetAddressPrefix
              itSpokeItSubnetAddressprefix
            ]
            destinationAddresses: [
              prodHubDefaultSubnetAddressPrefix
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
        name: prodInternetRuleCollectionName
        priority: 500
        action: {
         type: 'Allow'
        }
        ruleCollectionType: 'FirewallPolicyFilterRuleCollection'
        rules: [
          {
            name: allowInternetFromSalesDefaultVMsRuleName
            description: 'Allow Internet access from "Prod-VM-01" and "Sales-VM-01"'
            ruleType: 'NetworkRule'
            sourceAddresses: [
              prodVMPrivateIP
              salesVMPrivateIP
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
        name: prodP2SClientsRuleCollectionName
        priority: 300
        action: {
         type: 'Allow'
        }
        ruleCollectionType: 'FirewallPolicyFilterRuleCollection'
        rules: [
          {
            name: allowAllFromP2SClientsToSalesRuleName
            description: 'Allow all access from P2S Clients subnet to Production Default subnet"'
            ruleType: 'NetworkRule'
            sourceAddresses: [
              prodVPNClientAddPoolPrefix
            ]
            destinationAddresses: [
              prodHubDefaultSubnetAddressPrefix
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
            name: allowAllFromP2SClientsToDefaultRuleName
            description: 'Allow all access from P2S Clients subnet to Production Sales subnet"'
            ruleType: 'NetworkRule'
            sourceAddresses: [
              prodVPNClientAddPoolPrefix
            ]
            destinationAddresses: [
              salesSpokeSalesSubnetAddressprefix
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
resource prodFirewall 'Microsoft.Network/azureFirewalls@2020-05-01' = {
  name: prodFirewallName
  location: location
  dependsOn: [
    prodRuleCollectionGroups
  ]
  properties: {
    sku: {
      name: 'AZFW_VNet' 
      tier: 'Standard'
    }
    firewallPolicy: {
      id: prodFirewallPolicy.id
    }
    ipConfigurations: [
      {
        name: 'name'
        properties: {
          subnet: {
            id: prodHubFirewallSubnet.id
          }
          publicIPAddress: {
            id: prodFirewallPIP.id
          }
        }
      }
    ]
  }
 }

//Output - Production Firewall's Private IP Address
 output prodFirewallPrivateIP string = prodFirewall.properties.ipConfigurations[0].properties.privateIPAddress
