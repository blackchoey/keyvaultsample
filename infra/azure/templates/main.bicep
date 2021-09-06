param resourceBaseName string
param frontendHosting_storageName string = 'frontendstg${uniqueString(resourceBaseName)}'
param m365ClientId string
@secure()
param m365ClientSecret string
param m365TenantId string
param m365OauthAuthorityHost string
param function_serverfarmsName string = '${resourceBaseName}-function-serverfarms'
param function_webappName string = '${resourceBaseName}-function-webapp'
param function_storageName string = 'functionstg${uniqueString(resourceBaseName)}'
param simpleAuth_sku string = 'B1'
param simpleAuth_serverFarmsName string = '${resourceBaseName}-simpleAuth-serverfarms'
param simpleAuth_webAppName string = '${resourceBaseName}-simpleAuth-webapp'
param simpleAuth_packageUri string = 'https://github.com/OfficeDev/TeamsFx/releases/download/simpleauth@0.1.0/Microsoft.TeamsFx.SimpleAuth_0.1.0.zip'
param managedIdentityName string = '${resourceBaseName}-msi'
param keyvaultName string = '${resourceBaseName}keyvault'

var m365ApplicationIdUri = 'api://${frontendHostingProvision.outputs.domain}/${m365ClientId}'

resource managedIdentity 'Microsoft.ManagedIdentity/userAssignedIdentities@2018-11-30' = {
  name: managedIdentityName
  location: resourceGroup().location
}

module keyVaultProvision './keyVaultProvision.bicep' = {
  name: 'keyVaultProvision'
  params: {
    keyvaultName: keyvaultName
    msiTenantId: managedIdentity.properties.tenantId
    msiObjectId: managedIdentity.properties.principalId
    m365ClientSecret: m365ClientSecret
  }
}

module frontendHostingProvision './frontendHostingProvision.bicep' = {
  name: 'frontendHostingProvision'
  params: {
    frontendHostingStorageName: frontendHosting_storageName
  }
}

module functionProvision './functionProvision.bicep' = {
  name: 'functionProvision'
  params: {
    functionAppName: function_webappName
    functionServerfarmsName: function_serverfarmsName
    functionStorageName: function_storageName
    identityId: managedIdentity.id
  }
}
module functionConfiguration './functionConfiguration.bicep' = {
  name: 'functionConfiguration'
  dependsOn: [
    functionProvision
  ]
  params: {
    functionAppName: function_webappName
    functionStorageName: function_storageName
    m365ClientId: m365ClientId
    m365ClientSecret: keyVaultProvision.outputs.m365ClientSecretReference
    m365TenantId: m365TenantId
    m365ApplicationIdUri: m365ApplicationIdUri
    m365OauthAuthorityHost: m365OauthAuthorityHost
    frontendHostingStorageEndpoint: frontendHostingProvision.outputs.endpoint
  }
}
module simpleAuthProvision './simpleAuthProvision.bicep' = {
  name: 'simpleAuthProvision'
  params: {
    simpleAuthServerFarmsName: simpleAuth_serverFarmsName
    simpleAuthWebAppName: simpleAuth_webAppName
    sku: simpleAuth_sku
    identityId: managedIdentity.id
  }
}
module simpleAuthConfiguration './simpleAuthConfiguration.bicep' = {
  name: 'simpleAuthConfiguration'
  dependsOn: [
    simpleAuthProvision
  ]
  params: {
    simpleAuthWebAppName: simpleAuth_webAppName
    m365ClientId: m365ClientId
    m365ClientSecret: keyVaultProvision.outputs.m365ClientSecretReference
    m365ApplicationIdUri: m365ApplicationIdUri
    frontendHostingStorageEndpoint: frontendHostingProvision.outputs.endpoint
    m365TenantId: m365TenantId
    oauthAuthorityHost: m365OauthAuthorityHost
    simpelAuthPackageUri: simpleAuth_packageUri
  }
}

output frontendHosting_storageName string = frontendHostingProvision.outputs.storageName
output frontendHosting_endpoint string = frontendHostingProvision.outputs.endpoint
output frontendHosting_domain string = frontendHostingProvision.outputs.domain
output function_storageAccountName string = functionProvision.outputs.storageAccountName
output function_appServicePlanName string = functionProvision.outputs.appServicePlanName
output function_functionEndpoint string = functionProvision.outputs.functionEndpoint
output function_appName string = functionProvision.outputs.appName
output simpleAuth_skuName string = simpleAuthProvision.outputs.skuName
output simpleAuth_endpoint string = simpleAuthProvision.outputs.endpoint
output simpleAuth_webAppName string = simpleAuthProvision.outputs.webAppName
output simpleAuth_appServicePlanName string = simpleAuthProvision.outputs.appServicePlanName
