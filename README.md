# Introduction

This sample demonstrates a sample deployment using the [Snap CD Terraform Provider](https://registry.terraform.io/providers/schrieksoft/snapcd/latest/docs).

In the root of this repo is a terraform project that you can run with `terraform init`, `terraform apply` and so forth. Within `./module/main.tf` you'll find the actual `snapcd_...` resources that will be created. These are in numbered sections, meant as a guide for the order in which you should read through them, as each subsequent one introduces a new resource type. You will find extensive comments that explain the thinking behind each of the resources.

The Snap CD resources you will be creating will in turn manage four modules with mock resources (we will not actually be deploying a vpc etc.):

```
       |-----> cluster  ----- |
vpc ---|                      | ---> app
       |-----> database ----- |
```

The following concepts are addressed in this guide:
- **Namespace Inputs** - Providing default inputs to all modules in a namespace via `snapcd_namespace_input_from_literal`
- **Stack Secrets** - Using secured stored secrets with the `snapcd_module_input_from_secret` resource.
- **Output Sets** - Passing all outputs from one module to another via `snapcd_module_input_from_output_set`
- **Single Output** - Passing a specific output via `snapcd_module_input_from_output`
- **Non-String Types** - Using `type = "NotString"` for numeric values (e.g., replicas)
- **Environment Variables** - Passing env vars to module execution
- **Agents and Missions** - Attaching AI-driven `SummarizeJob` / `AutoDiagnose` / `ApprovalRecommend` recipes to every Job in the Namespace via `snapcd_namespace_mission`


## Prerequisites

Before deploying this sample, complete the steps from the [Self-Hosted Quickstart Guide](https://docs.snapcd.io/quickstart/self-hosted).

## Variables

This deployment requires the following variables:

| Variable | Description | How to Obtain |
|----------|-------------|---------------|
| `client_id` | The Client ID for authentication | From your Service Principal or personal access token settings |
| `client_secret` | The Client Secret for authentication (sensitive) | Generated when creating your Service Principal or personal access token |
| `organization_id` | Your Snap CD Organization ID | Found in your organization settings |
| `runner_name` | The name of your registered Runner | The name you gave your Runner when registering it |
| `agent_name` | The name of your registered Agent | The name you gave your Agent when registering it (see [Agents and Missions](#agents-and-missions) below) |
| `stack_name` | The name of the Stack to deploy to | The name of the Stack you created (e.g., "samples") |
| `sample_stack_secret_name` | Name of a Stack Secret with any sample value | The name you gave the secret when creating it |


To set the variables, create a `terraform.tfvars` file:

```hcl
client_id                  = "your-client-id"
client_secret              = "your-client-secret"
organization_id            = "your-organization-id"
runner_name                = "your-runner-name"
agent_name                 = "your-agent-name"
stack_name                 = "samples"
sample_stack_secret_name   = "my-secret-name"
```

Alternatively, use environment variables:

```bash
export TF_VAR_client_id="your-client-id"
export TF_VAR_client_secret="your-client-secret"
export TF_VAR_organization_id="your-organization-id"
export TF_VAR_runner_name="your-runner-name"
export TF_VAR_agent_name="your-agent-name"
export TF_VAR_stack_name="samples"
export TF_VAR_sample_stack_secret_name="my-secret-name"
```


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

## See it in action

Now navigate to http://localhost:8080/Stacks/default/my-sample-namespace?action=DependencyGraph (or to https://snapcd.io/Stacks/default/my-sample-namespace?action=DependencyGraph if using Snap CD Cloud) and see the dependency graph resolve.


## Agents and Missions

Section 6 (`./module/missions.tf`) attaches an Agent and three Missions to the sample Namespace. **Missions** are AI-driven recipes that run automatically against Job events, alongside the normal Terraform lifecycle:

| Mission | Triggers when… | What it produces |
|---------|----------------|------------------|
| `SummarizeJob` | A Module's Apply or Destroy Job succeeds | An audit-quality summary of what changed, who approved, and what was anomalous |
| `AutoDiagnose` | A Job fails, gets cancelled, or has its approval declined | A root-cause classification (`ModuleCode` / `ProviderTransient` / `Configuration` / …) with the relevant log excerpt |
| `ApprovalRecommend` | A Job enters the `WaitingForApproval` state | A recommendation (Approve / Decline + reasoning) shown to the human approver |

Each Mission runs inside an **Agent** that you host yourself (the AI control plane), with one or more provider-specific **Sidecars** doing the actual inference. The default sidecar is Claude.

### Prerequisites

Before `terraform apply` can succeed, you must:

1. **Register the Agent** in the Dashboard (Self-Hosted: `<your-server>/Agents`; Cloud: <https://snapcd.io/Agents>). Name it, attach a Service Principal, and note the name — that's the value of `agent_name` in your `tfvars`.
   - Self-Hosted defaults: the seed includes an Agent named `default` with a matching `defaultAgent` Service Principal; the sample's variable defaults already point at it, so you don't need to do anything extra.
2. **Deploy at least one Agent Instance** that connects back to your Server. Use one of the reference deployments:
   - Docker Compose: <https://github.com/schrieksoft/snapcd-deployment-docker>
   - Kubernetes (Kustomize): <https://github.com/schrieksoft/snapcd-deployment-kubernetes>
   - Local binary: <https://github.com/schrieksoft/snapcd-deployment-local>

   Each repo's `components/agent/` directory is a self-contained deployment for the Agent + its Sidecar pair. Bring it up and confirm the Agent appears as "Online" in the Dashboard before applying this sample.

### Watching the missions execute

After `terraform apply` finishes, navigate to your Namespace and watch the modules go through their lifecycles. On every Module's Job, a **Missions** tab appears next to the **Logs** and **Approvals** tabs — that's where each Mission's output lands.

A guided tour using the modules already declared above:

- The **`vpc`** Module points at the `fails` git branch and has `apply_approval_threshold = 1`. So its first Job will:
  1. Plan successfully → enter `WaitingForApproval` → **`ApprovalRecommend`** runs and writes a recommendation.
  2. Whether you approve or decline:
     - **Approve** → Apply runs → fails (the branch is broken on purpose) → **`AutoDiagnose`** runs against the failure.
     - **Decline** → Job ends as `NotApproved` → **`AutoDiagnose`** also runs (a declined approval is treated as a non-success terminal state).
- The **`database`**, **`cluster`**, and **`app`** Modules apply cleanly, so each one's Apply Job produces a **`SummarizeJob`** Mission with the human-readable summary.

This gives you a first-run, end-to-end exercise of all three Mission types without any extra setup.


## A word on backends (state file storage)

It is important to realise that Snap CD's goal is *orchestration* and that it therefore only stores data that supports that goal. It *does not* for example store your highly sensitive and business-critical state files; this remains fully in your control and is determined by the backend config your terrafom code uses. If no backend is configured (as is typically the case in a pure reusable module) terraform/opentofu will use a local state file. What this means in the context of Snap CD is that your Runner will store the state on its local storage. In this sample deployment, that is exactly what will happen. 

If you only have one Runner in a single place and are happy to have the state files live there, then this approach is perfectly legitimate. However, the more robust approach is of course is to use remote backends, such as Azure Storage Accounts or AWS S3. How to configure remote backends is outside of the scope of this sample, except to mention that Snap CD offers a way to initialize vanilla modules (i.e. that have no backend configuration in them) with any backend of your choosing via [Extra Files](https://docs.snapcd.io/how-it-works/configuration/extra-files/), [Array Flags](https://docs.snapcd.io/how-it-works/configuration/flags/). Depending on your exact requirements, using one or more of the above resource types will allow you to inject any backend configuration you need into your modules.

(As an aside note, [Extra Files](https://docs.snapcd.io/how-it-works/configuration/extra-files/) and [Hooks](https://docs.snapcd.io/how-it-works/configuration/hooks/) are also quite useful for provider initialization).

If you have completed this sample deployment and wish to explore [Extra Files](https://docs.snapcd.io/how-it-works/configuration/extra-files/), [Array Flags](https://docs.snapcd.io/how-it-works/configuration/flags/), please see the [sample-deployment-azure-backed](https://github.com/snapcd-samples/sample-deployment-azure-backend) repository.
