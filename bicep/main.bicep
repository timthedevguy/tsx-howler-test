param location string = resourceGroup().location
param linuxAdminUsername string = 'timthedevguy'
param sshPublicKey string

resource aksCluster 'Microsoft.ContainerService/managedClusters@2021-03-01' = {
  name: 'tsx-cluster-01'
  location: location
  identity: {
    type: 'SystemAssigned'
  }
  properties: {
    dnsPrefix: 'tsx-cluster-01'
    enableRBAC: true
    agentPoolProfiles: [
      {
        name: 'agentpool'
        count: 1
        vmSize: 'Standard_DS2_v2'
        osType: 'Linux'
        mode: 'System'
      }
    ]
    linuxProfile: {
      adminUsername: linuxAdminUsername
      ssh: {
        publicKeys: [
          {
            keyData: sshPublicKey
          }
        ]
      }
    }
  }
}

resource fluxExtension 'Microsoft.KubernetesConfiguration/extensions@2022-03-01' = {
  name: 'flux'
  properties: {
    extensionType: 'microsoft.flux'
  }
  scope: aksCluster
}

resource fluxConfig 'Microsoft.KubernetesConfiguration/fluxConfigurations@2022-03-01' = {
  name: 'tsx-fluxconfig'
  properties: {
    scope: 'cluster'
    namespace: 'cluster-config'
    sourceKind: 'GitRepository'
    gitRepository: {
      url: 'https://github.com/timthedevguy/tsx-howler-test'
      repositoryRef: {
        branch: 'main'
      }
      syncIntervalInSeconds: 120
    }
    kustomizations: {
      'infra': {
        path: './infrastructure'
        syncIntervalInSeconds: 120
      }
      'apps': {
        path: './apps/production'
        syncIntervalInSeconds: 120
        dependsOn: [
          'infra'
        ]
      }
    }
  }
  dependsOn: [
    fluxExtension
  ]
  scope: aksCluster
}
