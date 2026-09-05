# Introduction

This sample demonstrates a sample deployment using the [Snap CD Terraform Provider](https://registry.terraform.io/providers/schrieksoft/snapcd/latest/docs).

> 📺 **Watch it explained:** [The Sample Deployment | Deep Dive](https://youtu.be/v3R538Ww_oo) — a line-by-line walk through this exact project: the hierarchy, inputs, hooks, the state store, approvals, and how outputs propagate.

[![The Sample Deployment — Deep Dive](https://img.youtube.com/vi/v3R538Ww_oo/maxresdefault.jpg)](https://youtu.be/v3R538Ww_oo)

In the root of this repo is an OpenTofu project that you can run with `tofu init`, `tofu apply` and so forth. Within `./module/main.tf` you'll find the actual `snapcd_...` resources that will be created. These are in numbered sections, meant as a guide for the order in which you should read through them, as each subsequent one introduces a new resource type. You will find extensive comments that explain the thinking behind each of the resources.

The Snap CD resources you will be creating will in turn manage four modules with mock resources (we will not actually be deploying a vpc etc.):

```
       |-----> cluster  ----- |
vpc ---|                      | ---> app
       |-----> database ----- |
```

The following concepts are addressed in this guide:
- **State Store Backend** - Configuring the built-in Snap CD State Store as an HTTP backend for all modules in a namespace via extra files, flags, and array flags
- **Namespace Inputs** - Providing default inputs to all modules in a namespace via `snapcd_namespace_input_from_literal`
- **Stack Secrets** - Using secured stored secrets with the `snapcd_module_input_from_secret` resource.
- **Output Sets** - Passing all outputs from one module to another via `snapcd_module_input_from_output_set`
- **Single Output** - Passing a specific output via `snapcd_module_input_from_output`
- **Non-String Types** - Using `type = "NotString"` for numeric values (e.g., replicas)
- **Environment Variables** - Passing env vars to module execution
- **Agents and Missions** - Attaching an AI-driven `SummarizeJob` recipe to every Job in the Namespace via `snapcd_namespace_mission`
- **Policies** - Gating what a plan may contain before it is applied, via `snapcd_module_terraform_inline_policy`


## Prerequisites

- **OpenTofu** — the sample is driven entirely with `tofu` commands, and every module sets `engine = "OpenTofu"`. The `tofu` binary must be installed both on the machine where you run this project and on the Runner (the Docker reference deployment mounts it from the host, see its `components/runner/docker-compose.yml`).
- **Snap CD 1.11.0 or later** (Policy as Code was introduced in this version; the State Store backend used throughout requires 1.7.1)
- Complete the steps from the [Self-Hosted Quickstart Guide](https://docs.snapcd.io/quickstart/self-hosted)

## Variables

Every variable has a default that works out of the box with the pre-configured `snapcd-selfhosted-deployment-docker` setup — with that deployment running you can apply this sample without setting anything. Override whichever of these differ in your environment:

| Variable | Description | Default |
|----------|-------------|---------|
| `client_id` | The Client ID for authentication | `default` |
| `client_secret` | The Client Secret for authentication (sensitive) | `default` |
| `organization_id` | Your Snap CD Organization ID | `10000000-0000-0000-0000-000000000000` (the pre-seeded Organization) |
| `snapcd_server_url` | Server URL as reachable from where you run `tofu apply` | `http://localhost:5000` |
| `snapcd_server_url_from_runner` | Server URL as reachable from inside the Runner (used in the modules' State Store backend config) | `http://snapcd-server:5000` |
| `insecure_skip_verify` | Skip TLS verification (set `false` when the server has a valid certificate) | `true` |
| `runner_name` | The name of your registered Runner | `default` |
| `agent_name` | The name of your registered Agent (see [Agents and Missions](#agents-and-missions) below) | `default` |
| `stack_name` | The name of the Stack to deploy to | `default` |
| `namespace_name` | The name of the Namespace this sample creates | `my-sample-namespace` |
| `sample_stack_secret_name` | Name of a Stack Secret with any sample value | `sample` |

To override variables, create a `terraform.tfvars` file:

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

Once you have created the `terraform.tfvars` file and are ready to start deploying, use the usual OpenTofu commands, e.g:

```bash
# Initialize OpenTofu
tofu init

# Preview changes
tofu plan

# Apply changes
tofu apply
```

This project's own state is stored in the Snap CD State Store (see the `backend "http"` block in `root.tf`), not in a local `terraform.tfstate` file. The backend defaults match the `snapcd-selfhosted-deployment-docker` setup; if your server URL or credentials differ, override them at init time with `-backend-config` flags (examples in `root.tf`). If you previously applied this sample with local state, migrate it into the State Store with:

```bash
tofu init -migrate-state
```

## See it in action

Now navigate to http://localhost:5000/Namespace/default/my-sample-namespace?action=DependencyGraph (or to https://snapcd.io/Namespace/default/my-sample-namespace?action=DependencyGraph if using Snap CD Cloud) and see the dependency graph resolve.


## Agents and Missions

Section 7 in `./module/main.tf` attaches an Agent and a Mission to the sample Namespace. **Missions** are AI-driven recipes that run automatically against Job events, alongside the normal OpenTofu lifecycle:

| Mission | Triggers when… | What it produces |
|---------|----------------|------------------|
| `SummarizeJob` | A Module's Apply or Destroy Job succeeds | An audit-quality summary of what changed, who approved, and what was anomalous |
| `AutoDiagnose` | A Job fails, gets cancelled, or has its approval declined | A root-cause classification (`ModuleCode` / `ProviderTransient` / `Configuration` / …) with the relevant log excerpt |
| `ApprovalRecommend` | A Job enters the `WaitingForApproval` state | A recommendation (Approve / Decline + reasoning) shown to the human approver |

Each Mission runs inside an **Agent** that you host yourself (the AI control plane), with one or more provider-specific **Sidecars** doing the actual inference. The default sidecar is Claude.

### Prerequisites

Before `tofu apply` can succeed, you must:

1. **Register the Agent** in the Dashboard (Self-Hosted: `<your-server>/Agents`; Cloud: <https://snapcd.io/Agents>). Name it, attach a Service Principal, and note the name — that's the value of `agent_name` in your `tfvars`.
   - Self-Hosted defaults: the seed includes an Agent named `default` with a matching `defaultAgent` Service Principal; the sample's variable defaults already point at it, so you don't need to do anything extra.
2. **Deploy at least one Agent Instance** that connects back to your Server. Use one of the reference deployments:
   - Docker Compose: <https://github.com/schrieksoft/snapcd-deployment-docker>
   - Kubernetes (Kustomize): <https://github.com/schrieksoft/snapcd-deployment-kubernetes>
   - Local binary: <https://github.com/schrieksoft/snapcd-deployment-local>

   Each repo's `components/agent/` directory is a self-contained deployment for the Agent + its Sidecar pair. Bring it up and confirm the Agent appears as "Online" in the Dashboard before applying this sample.

### Watching the missions execute

After `tofu apply` finishes, navigate to your Namespace and watch the modules go through their lifecycles. On every Module's Job, a **Missions** tab appears next to the **Logs** and **Approvals** tabs — that's where each Mission's output lands.

A guided tour using the modules already declared above:

- The **`database`** Module has `apply_approval_threshold = 1`, so its first Job plans and then waits in `WaitingForApproval` until you approve it in the Dashboard. (Its `destroy_approval_threshold = 2` means a destroy would need approvals from two separate principals.)
- All four modules apply cleanly, and the namespace attaches a **`SummarizeJob`** Mission (section 7 in `./module/main.tf`), so every successful Apply produces a human-readable summary on the Job's **Missions** tab.
- To see the other two Mission types, add `snapcd_namespace_mission` resources with `mission_type = "ApprovalRecommend"` and `"AutoDiagnose"` alongside `summarize_job`: `ApprovalRecommend` writes a recommendation while `database` waits for approval, and `AutoDiagnose` runs whenever a Job fails, is cancelled, or has its approval declined.


## A word on backends (state file storage)

Snap CD orchestrates your deployments but does not prescribe where you store your Terraform / OpenTofu state. You can use any remote backend — AWS S3, Azure Storage, GCS, or anything else your engine supports. The only requirement is that you *do* use a remote backend: because Snap CD Runners are stateless and potentially ephemeral, relying on local state is not practical.

This sample uses the built-in [State Store](https://docs.snapcd.io/resources/state-store/) that ships with every Snap CD installation, in two places:

1. **The modules deployed by Snap CD** — section 2 in `./module/main.tf` configures the State Store as the HTTP backend for every module in the namespace, entirely through Snap CD resources. If you prefer a different backend, replace that section with your own backend configuration using [Extra Files](https://docs.snapcd.io/how-it-works/configuration/extra-files/) and [Array Flags](https://docs.snapcd.io/how-it-works/configuration/flags/).
2. **This OpenTofu project itself** — the `backend "http"` block in `root.tf` stores the sample deployment's own state in the State Store too (under the state file name `sample-deployment`), so nothing is kept on your local disk.