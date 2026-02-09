# Sample Deployment

This sample demonstrates a complete application deployment using the [Snap CD Terraform Provider](https://registry.terraform.io/providers/schrieksoft/snapcd/latest/docs).

## Prerequisites

Before deploying this sample, complete the following steps from the [Quickstart Guide](https://docs.snapcd.io/quickstart/):

1. **Create a User Account** - Sign up at [snapcd.io](https://snapcd.io)
2. **Create an Organization** - Set up your organization on first login
3. **Generate Credentials** - Create either:
   - A personal access token for your user, OR
   - A Service Principal with `Organization.Owner` permissions
4. **Register and Deploy a Runner** - Follow the runner deployment instructions
5. **Create a Stack** - Create a Stack (e.g., "samples") via the portal or API
6. **Create Stack Secret** - Create a secret in your Stack and pass its name into the `sample_stack_secret_name` (see below) variable. (For the purposes of this sample it does not matter what value you store in the Stack Secret, it is meant only to illustrate the functionality). You can read more about Secrets [here](https://docs.snapcd.io/how-it-works/configuration/secrets/)


## Variables

This deployment requires the following variables:

| Variable | Description | How to Obtain |
|----------|-------------|---------------|
| `client_id` | The Client ID for authentication | From your Service Principal or personal access token settings |
| `client_secret` | The Client Secret for authentication (sensitive) | Generated when creating your Service Principal or personal access token |
| `organization_id` | Your Snap CD Organization ID | Found in your organization settings |
| `runner_name` | The name of your registered Runner | The name you gave your Runner when registering it |
| `stack_name` | The name of the Stack to deploy to | The name of the Stack you created (e.g., "samples") |
| `sample_stack_secret_name` | Name of a Stack Secret with any sample value | The name you gave the secret when creating it |

The following are optional and can be used if you wish to explore how Snap CD supports remote backend configuration. (In this sample we show you how to do with for Azure, but the same approach would work for any remote backend). When you first deploy this sample we recommend leaving them unset so that your Runner uses local state storage. Thereafter, see the section below on **Backend Configuration" for a discussion how you can use various Snap CD configuration resources in order make terraform/opentofu store your state files remotely.

| Variable | Description | 
|----------|-------------|
| `azure_backend_enabled` | Set to `true` to deploy the `snapcd_...` so that your sample Modules store their states remotely on Azure |
| `azure_backend_tenant_id` | Your Azure Tenant Id |
| `azure_backend_subscription_id` | Your Azure Subscription Id |
| `azure_backend_resource_group_name` | The name of the Resource Group where you Azure Storage Account is |
| `azure_backend_storage_account_name` | The name of your Azure Storage Account |
| `azure_backend_storage_container_name` | The name of the storage container within your Azure Storage Account where your state files will be saved |


### Setting Variables

Create a `terraform.tfvars` file:

```hcl
client_id                  = "your-client-id"
client_secret              = "your-client-secret"
organization_id            = "your-organization-id"
runner_name                = "your-runner-name"
stack_name                 = "samples"
sample_stack_secret        = "my-secret-name"
```

Alternatively, use environment variables:

```bash
export TF_VAR_client_id="your-client-id"
export TF_VAR_client_secret="your-client-secret"
export TF_VAR_organization_id="your-organization-id"
export TF_VAR_runner_name="your-runner-name"
export TF_VAR_stack_name="samples"
export TF_VAR_sample_stack_secret="my-secret-name"
```

## What This Sample Creates

This sample creates a sample e-commerce application stack with the following modules:

### Infrastructure Layer
- **VPC** - Virtual network with public/private subnets, environment variables, and lifecycle hooks
- **Cluster** - Kubernetes cluster depending on VPC outputs
- **Database** - Database instance in the private subnet
- **App** - Web application with dependencies on cluster, 

## Architecture

The above illustrates a dependency graph as follows

```
       |-----> cluster  ----- |
vpc ---|                      | ---> app
       |-----> database ----- |

```

## Key Concepts

- **Stack Secrets** - Using secured stored secrets with the `snapcd_module_input_from_secret` data source.
- **Output Sets** - Passing all outputs from one module to another via `snapcd_module_input_from_output_set`
- **Single Output** - Passing a specific output via `snapcd_module_input_from_output`
- **Non-String Types** - Using `type = "NotString"` for numeric values (e.g., replicas)
- **Environment Variables** - Passing env vars to module execution
- **Lifecycle Hooks** - Running commands during module lifecycle (`init_before_hook`)

## Usage

Once you have created to `terraform.tfvars` file and are ready to start deploying, us the usual terraform commands, e.g:

```bash
# Initialize Terraform
terraform init

# Preview changes
terraform plan

# Apply changes
terraform apply
```

After running `terraform apply`, navigate to [snapcd.io/Stacks/samples?action=DependencyGraph](https://snapcd.io/Stacks/samples?action=DependencyGraph) (provided that "samples" is what you called your Stack) to see the dependency graph.


## Backend Configuration

It is important to realise that Snap CD's goal is *orchestration* and that it therefore only stores data that supports that goal. It *does not* for example store your highly sensitive and business-critical state files; this remains fully in your control and is determined by the backend config your terrafom code uses. If no backend is configured (as is typically the case in a pure reusable module) terraform/opentofu will use a local state file. What this means in the context of Snap CD is that your Runner will store the state on its local storage. If you only have one Runner in a single place and are happy to have the state files live there, then this approach is perfectly legitimate. However, the more robust approach is of course is to use remote backends, such as Azure Storage Accounts or AWS S3. The way this is configured in terraform/opentofu is in the `terraform` block, e.g:


### Typical Backend Configuration

```hcl
terraform {
  backend "azurerm" {
    resource_group_name  = "rg-terraform-state"
    storage_account_name = "tfstateprod001"
    container_name       = "tfstate"
    key                  = "prod.terraform.tfstate"
  }
}
```

followed by 

```bash
terraform init
```

Alternatively with 

```hcl
terraform {
  backend "azurerm" {}
}
```

in conjuction with "backend-config" flags:

```bash
terraform init \
  -backend-config="resource_group_name=rg-terraform-state" \
  -backend-config="storage_account_name=tfstateprod001" \
  -backend-config="container_name=tfstate" \
  -backend-config="key=prod.terraform.tfstate"
```

### How Snap CD helps you inject such a configuraiton

Snap CD offers a way to initialize vanilla modules (i.e. that have no backend configuration in them) with any backend of your choosing via [Extra Files](https://docs.snapcd.io/how-it-works/configuration/extra-files/), [Backend Configs](https://docs.snapcd.io/how-it-works/configuration/backend-configs/) and [Hooks](https://docs.snapcd.io/how-it-works/configuration/hooks/). Depending on your exact requirements, you could use one or more of these resources to instantiate the backend.

(As an aside note, [Extra Files](https://docs.snapcd.io/how-it-works/configuration/extra-files/) and [Hooks](https://docs.snapcd.io/how-it-works/configuration/hooks/) are also quite useful for provider initialization).

