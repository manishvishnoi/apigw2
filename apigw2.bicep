// Parameters
param containerAppName string
param location string
param existingContainerAppEnvironmentName string
param storageAccountName string
param dockerImage string
param fileShareName string

// Define the storage account (if it does not exist)
resource storageAccount 'Microsoft.Storage/storageAccounts@2023-01-01' existing = {
  name: storageAccountName
}

// Define the Managed Environment
resource managedEnvironment 'Microsoft.App/managedEnvironments@2023-04-01-preview' existing = {
  name: existingContainerAppEnvironmentName
}

// Link the storage account to the Managed Environment
resource storageLink 'Microsoft.App/managedEnvironments/storages@2023-04-01-preview' = {
  parent: managedEnvironment
  name: 'stacc337-link' // Unique name for the storage link
  properties: {
    azureFile: {
      accountName: storageAccountName
      accountKey: storageAccount.listKeys().keys[0].value
      shareName: fileShareName
      accessMode: 'ReadWrite' // or 'ReadOnly' depending on your needs
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
          env: [ { name: 'ACCEPT_GENERAL_CONDITIONS', value: 'yes' },{ name: 'EMT_ANM_HOSTS', value: 'anm:8090' },{ name: 'CASS_HOST', value: 'casshost1' },{ name: 'EMT_TRACE_LEVEL', value: 'DEBUG' }
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
          storageName: storageAccountName
          azureFile: {
            shareName: fileShareName
          }
        }
      ]
    }
  }
}
