---
services: resources
platforms: ruby
author: vishrutshah
---

# Manage resources using Managed Service Identity using Ruby

This sample demonstrates how to manage Azure resources via Managed Service Identity using the Ruby SDK.

**On this page**

- [Create an Azure VM with MSI extension](#pre-requisite)
- [Run this sample](#run)
- [What does example.rb do?](#example)
    - [Create a System Assigned MSI Token Provider](#msi-sa)
    - [Create a User Assigned MSI Token Provider](#msi-ua)
    - [Create a resource client](#resource-client)
    - [Create an Azure Vault](#create-vault)
    - [Delete an Azure vault](#delete-vault)

<a id="pre-requisite"></a>
## Create an Azure VM with MSI extension

[Azure Compute VM with MSI](https://github.com/Azure-Samples/compute-ruby-msi-vm)

<a id="run"></a>
## Run this sample

1. log in to the above Azure virtual machine which has MSI service running and then follow the steps on that VM.

2. If you don't already have it, [install Ruby and the Ruby DevKit](https://www.ruby-lang.org/en/documentation/installation/).

3. If you don't have bundler, install it.

    ```
    gem install bundler
    ```

4. Clone the repository.

    ```
    git clone https://github.com/Azure-Samples/resources-ruby-manage-resources-with-msi.git
    ```

5. Install the dependencies using bundler.

    ```
    cd resources-ruby-manage-resources-with-msi
    bundle install
    ```

6. Set the following environment variables.

    ```
    export AZURE_TENANT_ID={your tenant id}
    export AZURE_SUBSCRIPTION_ID={your subscription id}
    export RESOURCE_GROUP_NAME={name of the resource group}    
    ```

    > [AZURE.NOTE] On Windows, use `set` instead of `export`.

7. Run the sample.

    ```
    bundle exec ruby example.rb
    ```

<a id="example"></a>
## What does example.rb do?

Initialize `subscription_id`, `tenant_id`, `resource_group_name` and `port` from environment variables.

```ruby
subscription_id = ENV['AZURE_SUBSCRIPTION_ID'] || '11111111-1111-1111-1111-111111111111'
tenant_id = ENV['AZURE_TENANT_ID']
resource_group_name = ENV['RESOURCE_GROUP_NAME']
port = ENV['MSI_PORT'] || 50342 # If not provided then we assume the default port
```

<a id="msi-sa"></a>
### Create a System Assigned MSI Token Provider

We can create token credential using `MSITokenProvider` with System Assigned Identity:

```ruby
# Create System Assigned MSI token provider
provider = MsRestAzure::MSITokenProvider.new
```

<a id="msi-ua"></a>
### Create a User Assigned MSI Token Provider
To create a User Assigned Identity, you would need to provide a reference to your User Assigned object in order to create an instance. You can provide a
`client_id`, an `object_id` (Active Directory IDs) or the MSI resource id that must conform to:
 `/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg/providers/Microsoft.ManagedIdentity/userAssignedIdentities/msiname`

The fastest way to get a `client_id` is to use the CLI 2.0: `az identity show -g myR -n myMSi`

You can get the `object_id` using the `az ad sp show --id <client_id>` command, or througth the Azure Portal in the Active Directory section.

You can also use the `azure_mgmt_msi` package.

```ruby
    # Create User Assigned MSI token provider using client_id
    provider = MsRestAzure::MSITokenProvider.new(port, settings,  {:client_id => '00000000-0000-0000-0000-000000000000' })
```
or `object_id`:
```ruby
    # Create User Assigned MSI token provider using object_id
    provider = MsRestAzure::MSITokenProvider.new(port, settings,  {:object_id => '00000000-0000-0000-0000-000000000000' })
 ```
or `msi_res_id`:
 ```ruby
     # Create User Assigned MSI token provider using msi_res_id
     provider = MsRestAzure::MSITokenProvider.new(port, settings,  {:msi_res_id => '/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg/providers/Microsoft.ManagedIdentity/userAssignedIdentities/msiname'})
 ```

Then, obtain credentials with the obtained provider:
```ruby
credentials = MsRest::TokenCredentials.new(provider)
```

<a id="resource-client"></a>
### Create a resource client
Now, we will create a resource management client using Managed Service Identity token provider.

```ruby
client = Azure::ARM::Resources::ResourceManagementClient.new(credentials)
client.subscription_id = subscription_id
```

<a id="create-vault"></a>
### Create an Azure Vault
Now, we will create an Azure key vault account using MSI authenticated resource client. This Azure Key Vault
account resource is identical to normal account but it is just created under the resource group where MSI enabled 
Azure VM has the permission to create resources. 

```ruby
puts 'Creating key vault account with MSI Identity...'
key_vault_params = Azure::ARM::Resources::Models::GenericResource.new.tap do |rg|
  rg.location = WEST_US
  rg.properties = {
      sku: { family: 'A', name: 'standard' },
      tenantId: tenant_id,
      accessPolicies: [],
      enabledForDeployment: true,
      enabledForTemplateDeployment: true,
      enabledForDiskEncryption: true
  }
end
```

<a id="delete-vault"></a>
### Delete an Azure vault
Now, we will delete key vault account created using this example. Please comment this out to keep the resources alive in you Azure subscription.

```ruby
client.resources.delete(resource_group_name,
                          'Microsoft.KeyVault',
                          '',
                          'vaults',
                          KEY_VAULT_NAME,
                          '2015-06-01')
```
