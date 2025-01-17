param location string
param clusterName string
param tags object
param domain string
param pullSecret string
param podCidr string
param serviceCidr string
param aadClientId string
param aadClientSecret string
param aadObjectId string
param rpObjectId string
param controlPlaneVmSize string
param computeVmSize string
param computeVmDiskSize int
param computeNodeCount int
param apiServerVisibility string
param ingressVisibility string
param spokeVnetName string
param controlPlaneVnetName string
param computeVnetName string
param fipsValidatedModules string
param encryptionAtHost string

var contribRole = 'b24988ac-6180-42a0-ab88-20f7382dd24c'

resource clusterVnet 'Microsoft.Network/virtualNetworks@2021-08-01' existing = { name: spokeVnetName }

resource role_for_aadObjectId 'Microsoft.Authorization/roleAssignments@2020-10-01-preview' = {
  name: guid( resourceGroup().id, aadObjectId, contribRole)
  properties: {
    principalId: aadObjectId
    principalType: 'ServicePrincipal'
    roleDefinitionId: resourceId('Microsoft.Authorization/roleDefinitions', contribRole)
  }
  dependsOn: [
    clusterVnet
  ]
}

resource role_for_rpObjectId 'Microsoft.Authorization/roleAssignments@2020-10-01-preview' = {
  name: guid( resourceGroup().id, rpObjectId, contribRole)
  properties: {
    principalId: rpObjectId
    principalType: 'ServicePrincipal'
    roleDefinitionId: resourceId('Microsoft.Authorization/roleDefinitions', contribRole)
  }
  dependsOn: [
    clusterVnet
  ]
}

resource aro 'Microsoft.RedHatOpenShift/openShiftClusters@2022-04-01' = {
  name: clusterName
  location: location
  tags: tags
  properties: {
    clusterProfile: {
      domain: domain
      resourceGroupId: '/subscriptions/${subscription().subscriptionId}/resourceGroups/aro-${domain}'
      pullSecret: pullSecret
      fipsValidatedModules: fipsValidatedModules
    }
    networkProfile: {
      podCidr: podCidr
      serviceCidr: serviceCidr
    }
    servicePrincipalProfile: {
      clientId: aadClientId
      clientSecret: aadClientSecret
    }
    masterProfile: {
      vmSize: controlPlaneVmSize
      subnetId: resourceId('Microsoft.Network/virtualNetworks/subnets', spokeVnetName, controlPlaneVnetName)
      encryptionAtHost: encryptionAtHost
    }
    workerProfiles: [
      {
        name: 'worker'
        vmSize: computeVmSize
        diskSizeGB: computeVmDiskSize
        subnetId: resourceId('Microsoft.Network/virtualNetworks/subnets', spokeVnetName, computeVnetName)
        count: computeNodeCount
        encryptionAtHost: encryptionAtHost
      }
    ]
    apiserverProfile: {
      visibility: apiServerVisibility
    }
    ingressProfiles: [
      {
        name: 'default'
        visibility: ingressVisibility
      }
    ]
  }
  dependsOn: [
    clusterVnet
    role_for_aadObjectId
    role_for_rpObjectId
  ]
}
