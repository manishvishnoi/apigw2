param containerAppName string
param location string
param managedEnvironmentName string
param acrName string
param imageName string
@secure param acrPassword string
param storageAccountName string
@secure param storageAccountKey string
param fileShareName string
param targetPorts array = [8080, 8065, 8075] // The ports you want to expose

// Reference to the existing Managed Environment
resource managedEnvironment 'Microsoft.App/managedEnvironments@2023-05-01' existing = {
  name: managedEnvironmentName
}

// Creating a storage link for Azure Files
resource storageLink 'Microsoft.App/managedEnvironments/storages@2023-05-01' = {
  parent: managedEnvironment
  name: '${storageAccountName}-link'
  properties: {
    azureFile: {
      accountName: storageAccountName
      accountKey: storageAccountKey
      shareName: fileShareName
      accessMode: 'ReadWrite'  // Modify as needed
    }
  }
}

// Deploy the Container App
resource containerApp 'Microsoft.App/containerApps@2023-05-01' = {
  name: containerAppName
  location: location
  properties: {
    managedEnvironmentId: managedEnvironment.id
    configuration: {
      registries: [
        {
          server: '${acrName}.azurecr.io'
          username: acrName
          passwordSecretRef: 'acr-password'
        }
      ]
      ingress: {
        external: true
        targetPort: 8080  // First port
        transport: 'tcp'
      }
      secrets: [
        {
          name: 'acr-password'
          value: acrPassword
        }
      ]
    }
    template: {
      containers: [
        {
          name: containerAppName
          image: '${acrName}.azurecr.io/${imageName}:latest'
          resources: {
            cpu: 2
            memory: '4Gi'
          }
          env: [{ name: 'ACCEPT_GENERAL_CONDITIONS', value: 'yes' },{ name: 'EMT_ANM_HOSTS', value: 'anm:8090' },{ name: 'CASS_HOST', value: 'casshost1' },{ name: 'EMT_TRACE_LEVEL', value: 'DEBUG' }       
      ]
      volumes: [
        {
          name: '${storageAccountName}-volume'
          storageType: 'AzureFile'
          storageName: '${storageAccountName}-link'
        }
      ]
    }
    scale: {
      minReplicas: 1
      maxReplicas: 3
    }
  }
}
