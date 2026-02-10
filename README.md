# Introduction

This sample demonstrates a sample deployment using the [Snap CD Terraform Provider](https://registry.terraform.io/providers/schrieksoft/snapcd/latest/docs).

In the root of this repo is a terraform project that you can run with `terraform init`, `terraform apply` and so forth. Within the `./module` folder you'll find the actual `snapcd_...` resources that will be created. These are in files numbered `01` through to `07`. This is meant as a guide for the order in which you should read through the files, as each subsequent one will introduce one new resources. Within the .tf files themselves you will find extensive comments that explain the thinking behind each of the resources.

The Snap CD resources you will be creating will in turn manage four modules with mock resources (we will not actually be deploying a vpc etc.):

```
       |-----> cluster  ----- |
vpc ---|                      | ---> app
       |-----> database ----- |
```

The following concepts are addressed in this guide:
- **Stack Secrets** - Using secured stored secrets with the `snapcd_module_input_from_secret` data source.
- **Output Sets** - Passing all outputs from one module to another via `snapcd_module_input_from_output_set`
- **Single Output** - Passing a specific output via `snapcd_module_input_from_output`
- **Non-String Types** - Using `type = "NotString"` for numeric values (e.g., replicas)
- **Environment Variables** - Passing env vars to module execution
- **Lifecycle Hooks** - Running commands during module lifecycle (`init_before_hook`)


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


To set the varialbe, create a `terraform.tfvars` file:

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


## Usage

```bash
# Initialize Terraform
terraform init

# Preview changes
terraform plan

# Apply changes
terraform apply
```


## A word on backends (state file storage)

It is important to realise that Snap CD's goal is *orchestration* and that it therefore only stores data that supports that goal. It *does not* for example store your highly sensitive and business-critical state files; this remains fully in your control and is determined by the backend config your terrafom code uses. If no backend is configured (as is typically the case in a pure reusable module) terraform/opentofu will use a local state file. What this means in the context of Snap CD is that your Runner will store the state on its local storage. In this sample deployment, that is exactly what will happen. 

If you only have one Runner in a single place and are happy to have the state files live there, then this approach is perfectly legitimate. However, the more robust approach is of course is to use remote backends, such as Azure Storage Accounts or AWS S3. How to configure remote backends is outside of the scope of this sample, except to mention that Snap CD offers a way to initialize vanilla modules (i.e. that have no backend configuration in them) with any backend of your choosing via [Extra Files](https://docs.snapcd.io/how-it-works/configuration/extra-files/), [Backend Configs](https://docs.snapcd.io/how-it-works/configuration/backend-configs/) and [Hooks](https://docs.snapcd.io/how-it-works/configuration/hooks/). Depending on your exact requirements, using one or more of the above resource types will allow you to inject any backend configuration you need into your modules.

If you have completed this sample deployment and wish to explore [Extra Files](https://docs.snapcd.io/how-it-works/configuration/extra-files/), [Backend Configs](https://docs.snapcd.io/how-it-works/configuration/backend-configs/) and [Hooks](https://docs.snapcd.io/how-it-works/configuration/hooks/), please see the [sample-deployment-azure-backed](https://github.com/snapcd-samples/sample-deployment-azure-backend) repository.
