// Parameters
param containerAppName string
param location string
param existingContainerAppEnvironmentName string
param storageAccountName string
param dockerImage string
param fileShareName string

// Reference an existing storage account (ensure it exists)
resource storageAccount 'Microsoft.Storage/storageAccounts@2023-01-01' existing = {
  name: storageAccountName
}

// Deploy the Container App
resource containerApp 'Microsoft.App/containerApps@2023-04-01-preview' = {
  name: containerAppName
  location: location
  properties: {
    managedEnvironmentId: resourceId('Microsoft.App/managedEnvironments', existingContainerAppEnvironmentName)

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
          env: [
            { name: 'ACCEPT_GENERAL_CONDITIONS', value: 'yes' },
            { name: 'EMT_ANM_HOSTS', value: 'anm:8090' },
            { name: 'CASS_HOST', value: 'casshost1' },
            { name: 'EMT_TRACE_LEVEL', value: 'DEBUG' }
          ]
          volumeMounts: [ // Mount the file share volume
            {
              volumeName: 'fileshare-volume'
              mountPath: '/opt/Axway/apigateway/conf/licenses' // Mount path inside the container
            }
          ]
        }
      ]
      volumes: [ // Define the file share volume
        {
          name: 'fileshare-volume'
          storageType: 'AzureFile'
          storageName: storageAccountName
          mountOptions: 'shareName=${fileShareName}'
        }
      ]
    }
  }
}
