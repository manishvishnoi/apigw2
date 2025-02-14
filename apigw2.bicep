// Parameters
param containerAppName string
param location string
param existingContainerAppEnvironmentName string
param storageAccountName string
param dockerImage string
param fileShareName string
param storageAccountKey string // Passed from the pipeline as a parameter

// Reference the existing Managed Environment
resource managedEnvironment 'Microsoft.App/managedEnvironments@2023-04-01-preview' existing = {
  name: existingContainerAppEnvironmentName
}

// Create a storage link for Azure Files in the Managed Environment
resource storageLink 'Microsoft.App/managedEnvironments/storages@2023-04-01-preview' = {
  parent: managedEnvironment
  name: '${storageAccountName}-link' // Ensure the name is unique
  properties: {
    azureFile: {
      accountName: storageAccountName
      accountKey: storageAccountKey
      shareName: fileShareName
      accessMode: 'ReadWrite' // Or 'ReadOnly' based on your needs
    }
  }
}

// Deploy the Container App with ingress configuration
resource containerApp 'Microsoft.App/containerApps@2023-04-01-preview' = {
  name: containerAppName
  location: location
  properties: {
    managedEnvironmentId: managedEnvironment.id
    configuration: {
      secrets: [
        {
          name: 'storageaccountkey'
          value: storageAccountKey
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
              volumeName: '${storageAccountName}-volume' // Ensure this is correct
              mountPath: '/opt/Axway/apigateway/conf/licenses'
            }
          ]
        }
      ]
      volumes: [
        {
          name: '${storageAccountName}-volume' // Ensure the volume name matches
          storageType: 'AzureFile'
          storageName: '${storageAccountName}-link' // Correctly use the storage link
        }
      ]
    }

    ingress: {
      external: false // Limit ingress traffic to Container Apps Environment only
      targetPort: 8080 // This is the target port for your application
      transports: ['TCP'] // Define transport type
      rules: [
        {
          port: 8075
          protocol: 'TCP'
        }
        {
          port: 8065
          protocol: 'TCP'
        }
        {
          port: 8080
          protocol: 'TCP'
        }
      ]
    }
  }
}
