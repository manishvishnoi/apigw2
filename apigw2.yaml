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

// Retrieve storage account keys
var storageKeys = listKeys(storageAccount.id, '2023-01-01')
var storageKey = storageKeys.keys[0].value

// Create a storage link for Azure Files in the Managed Environment
resource storageLink 'Microsoft.App/managedEnvironments/storages@2023-04-01-preview' = {
  parent: managedEnvironment
  name: '${storageAccountName}-link' // Make sure the name matches the link reference
  properties: {
    azureFile: {
      accountName: storageAccountName
      accountKey: storageKey
      shareName: fileShareName
      accessMode: 'ReadWrite' // Or 'ReadOnly' based on your needs
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
          value: storageKey
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
              volumeName: '${storageAccountName}-volume' // Volume name
              mountPath: '/opt/Axway/apigateway/conf/licenses'
            }
          ]
        }
      ]
      volumes: [
        {
          name: '${storageAccountName}-volume' // Ensure this matches the volume reference in container
          storageType: 'AzureFile'
          storageName: '${storageAccountName}-link' // Ensure the storage link name matches
        }
      ]
    }
  }
}
