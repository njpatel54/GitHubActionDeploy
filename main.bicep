param location string = 'usgovvirginia'
param prodRGName string = 'Prod-RG'
param devRGName string = 'Dev-RG'

// Step-0 == Setting Scope to "Subscription" to create "Resource Groups"
targetScope = 'subscription'
resource prodRG 'Microsoft.Resources/resourceGroups@2021-04-01' = {
  name: prodRGName
  location: location
}

resource devRG 'Microsoft.Resources/resourceGroups@2021-04-01' = {
  name: devRGName
  location: location
}
