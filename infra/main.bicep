targetScope = 'resourceGroup'

@description('Azure region for the demo runtime.')
param location string = resourceGroup().location

@description('Container App name.')
param appName string = 'skill-library-demo'

@description('Container image built from src/SkillLibrary.Api/Dockerfile.')
param containerImage string

@description('Microsoft Entra tenant ID.')
param tenantId string

@description('Client ID of the Entra app registration used by Container Apps authentication.')
param clientId string

@secure()
@description('Client secret generated for the Entra app registration.')
param clientSecret string

resource environment 'Microsoft.App/managedEnvironments@2024-10-02-preview' = {
  name: '${appName}-env'
  location: location
  properties: {
    appLogsConfiguration: {
      destination: 'azure-monitor'
    }
  }
}

resource app 'Microsoft.App/containerApps@2025-01-01' = {
  name: appName
  location: location
  identity: {
    type: 'SystemAssigned'
  }
  properties: {
    environmentId: environment.id
    configuration: {
      activeRevisionsMode: 'Single'
      ingress: {
        external: true
        targetPort: 8080
        transport: 'auto'
        allowInsecure: false
      }
      secrets: [
        {
          name: 'entra-client-secret'
          value: clientSecret
        }
      ]
    }
    template: {
      containers: [
        {
          name: 'skill-library'
          image: containerImage
          resources: {
            cpu: json('0.5')
            memory: '1Gi'
          }
          probes: [
            {
              type: 'Liveness'
              httpGet: {
                path: '/health'
                port: 8080
                scheme: 'HTTP'
              }
              initialDelaySeconds: 5
              periodSeconds: 20
            }
          ]
        }
      ]
      scale: {
        minReplicas: 1
        maxReplicas: 3
      }
    }
  }
}

resource auth 'Microsoft.App/containerApps/authConfigs@2024-03-01' = {
  parent: app
  name: 'current'
  properties: {
    platform: {
      enabled: true
    }
    globalValidation: {
      unauthenticatedClientAction: 'RedirectToLoginPage'
      redirectToProvider: 'azureactivedirectory'
    }
    identityProviders: {
      azureActiveDirectory: {
        enabled: true
        registration: {
          clientId: clientId
          clientSecretSettingName: 'entra-client-secret'
          openIdIssuer: '${az.environment().authentication.loginEndpoint}${tenantId}/v2.0'
        }
        validation: {
          allowedAudiences: [
            'api://${clientId}'
          ]
        }
      }
    }
  }
}

output app object = {
  name: app.name
  url: 'https://${app.properties.configuration.ingress.fqdn}'
  principalId: app.identity.principalId
}