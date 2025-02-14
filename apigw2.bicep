// Parameters
param containerAppName string
param location string
param existingContainerAppEnvironmentName string
param storageAccountName string
param dockerImage string
param fileShareName string

// Reference existing storage account
resource storageAccount 'Microsoft.Storage/storageAccounts@2023-01-01' existing = {
  name: storageAccountName
}

// Reference existing Managed Environment
resource managedEnvironment 'Microsoft.App/managedEnvironments@2023-04-01-preview' existing = {
  name: existingContainerAppEnvironmentName
}

// Create a storage link for Azure Files in the Managed Environment
resource storageLink 'Microsoft.App/managedEnvironments/storages@2023-04-01-preview' = {
  parent: managedEnvironment
  name: 'fileshare-storage' 
  properties: {
    azureFile: {
      accountName: storageAccountName
      shareName: fileShareName
      accessMode: 'ReadWrite'
    }
  }
}

// Deploy the Container App
resource containerApp 'Microsoft.App/containerApps@2023-04-01-preview' = {
  name: containerAppName
  location: location
  properties: {
    managedEnvironmentId: managedEnvironment.id

    configuration: {
      secrets: [
        {
          name: 'storageaccountkey'
          value: storageAccount.listKeys().keys[0].value
        }
      ]
    }

    template: {
      containers: [
        {
          name: containerAppName
          image: dockerImage
          env: [{ name: 'ACCEPT_GENERAL_CONDITIONS', value: 'yes' },{ name: 'EMT_ANM_HOSTS', value: 'anm:8090' },{ name: 'CASS_HOST', value: 'casshost1' },{ name: 'EMT_TRACE_LEVEL', value: 'DEBUG' }
          ]
          volumeMounts: [
            {
              volumeName: 'fileshare-volume'
              mountPath: '/opt/Axway/apigateway/conf/licenses'
            }
          ]
        }
      ]
      volumes: [
        {
          name: 'fileshare-volume'
          storageType: 'AzureFile'
          storageName: 'fileshare-storage' // Must match the storage link name
        }
      ]
    }
  }
}
