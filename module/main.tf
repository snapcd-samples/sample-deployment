
///////////////////////////////////////////////////////////////////////////////
//
// 1. namespace
//
// Learn about:
// - snapcd_stack
// - snapcd_namespace
//
///////////////////////////////////////////////////////////////////////////////


data "snapcd_stack" "sample" {
  name = var.stack_name
}

resource "snapcd_namespace" "sample" {
  // <NOTES>
  //
  // This is a namespace. Use this to organize your modules
  //
  // For more detail, see:
  // - https://docs.snapcd.io/how-it-works/configuration/stack-namespace-module/#namespace
  // - https://registry.terraform.io/providers/schrieksoft/snapcd/latest/docs/resources/namespace
  //
  // </NOTES>


  name     = var.namespace_name
  stack_id = data.snapcd_stack.sample.id
  trigger_behaviour_on_modified = "TriggerAllImmediately"
}

resource "snapcd_namespace_input_from_literal" "sample" {

  // <NOTES>
  //
  // This is a namespace input. Every module within the namespace will receive the input variable "resource_group_name" by default every time
  // the module is deployed. This behaviour can be toggled with the "usage_mode" flag.
  //
  // This namespace input is from a literal value. Namespace inputs can also be from "Definition" or "Secret".
  //
  // For more detail, see:
  // - https://docs.snapcd.io/how-it-works/configuration/namespace-inputs/
  // - https://registry.terraform.io/providers/schrieksoft/snapcd/latest/docs/resources/namespace_input_from_literal
  //
  // </NOTES>


  input_kind    = "Param"
  name          = "resource_group_name"
  literal_value = "This will be the value of 'var.myvar'!"
  namespace_id  = snapcd_namespace.sample.id
  usage_mode    = "UseByDefault"
}

resource "snapcd_namespace_hook" "default_plan_before" {

  // <NOTES>
  //
  // This is a namespace-level hook. Every module within the namespace will run this script
  // before the "plan" task runs, unless the module overrides it with its own snapcd_module_hook
  // for the same (task, phase). Valid task values: Plan, PlanDestroy, Apply, Destroy, Output, Validate.
  // Valid phase values: Before, After.
  //
  // For more detail, see:
  // - https://registry.terraform.io/providers/schrieksoft/snapcd/latest/docs/resources/namespace_hook
  //
  // </NOTES>

  namespace_id = snapcd_namespace.sample.id
  task         = "Plan"
  phase        = "Before"
  script       = "echo 'about to plan a module in the sample namespace'"
}


///////////////////////////////////////////////////////////////////////////////
//
// 2. State Store Backend
//
// Learn about:
// - snapcd_state_store (as a data source)
// - snapcd_namespace_extra_file
// - snapcd_namespace_terraform_flag
// - snapcd_namespace_terraform_array_flag
// - snapcd_namespace_input_from_definition
//
// These resources configure the Snap CD State Store as the Terraform HTTP
// backend for all modules in the namespace. This replaces the default local
// state with encrypted, centrally managed state stored in Snap CD.
//
///////////////////////////////////////////////////////////////////////////////


data "snapcd_state_store" "default" {
  // <NOTES>
  //
  // Looks up the built-in "default" State Store by name. Every Snap CD
  // organization is pre-seeded with a default State Store that provides
  // encrypted, centrally managed Terraform state via an HTTP backend.
  //
  // We reference its ID below when constructing the backend URLs.
  //
  // For more detail, see:
  // - https://registry.terraform.io/providers/schrieksoft/snapcd/latest/docs/data-sources/state_store
  //
  // </NOTES>

  name = "default"
}

resource "snapcd_namespace_extra_file" "http_backend" {
  // <NOTES>
  //
  // Injects an extra .tf file into every module in this namespace. Here we use
  // it to declare the HTTP backend block. The Runner writes this file into the
  // working directory before `terraform init` runs.
  //
  // For more detail, see:
  // - https://registry.terraform.io/providers/schrieksoft/snapcd/latest/docs/resources/namespace_extra_file
  //
  // </NOTES>

  file_name    = "extra_root.tf"
  contents     = <<EOT
terraform {
  backend "http" {}
}
  EOT
  namespace_id = snapcd_namespace.sample.id
  overwrite    = false
}

resource "snapcd_namespace_terraform_flag" "upgrade" {
  // <NOTES>
  //
  // Adds the `-upgrade` flag to `terraform init` for every module in this
  // namespace. This automatically updates providers and modules to the latest
  // versions allowed by version constraints on every init.
  //
  // For more detail, see:
  // - https://registry.terraform.io/providers/schrieksoft/snapcd/latest/docs/resources/namespace_terraform_flag
  //
  // </NOTES>

  namespace_id = snapcd_namespace.sample.id
  task         = "Init"
  flag         = "Upgrade"
}

resource "snapcd_namespace_input_from_definition" "module_name" {
  // <NOTES>
  //
  // Injects the module's own name as the environment variable SNAPCD_MODULE_NAME.
  // "Definition" inputs resolve built-in metadata at deploy time (here,
  // "ModuleName" resolves to the name of whichever module is currently running).
  //
  // We use this env var in the backend URLs below so that each module's state is
  // stored under its own path in the State Store.
  //
  // For more detail, see:
  // - https://registry.terraform.io/providers/schrieksoft/snapcd/latest/docs/resources/namespace_input_from_definition
  //
  // </NOTES>

  name            = "SNAPCD_MODULE_NAME"
  definition_name = "ModuleName"
  usage_mode      = "UseByDefault"
  namespace_id    = snapcd_namespace.sample.id
  input_kind      = "EnvVar"
}

resource "snapcd_namespace_terraform_array_flag" "http_backend" {
  // <NOTES>
  //
  // Passes `-backend-config=key=value` arguments to `terraform init` for every
  // module in this namespace. Together these configure the HTTP backend to point
  // at the Snap CD State Store API.
  //
  // Note: these URLs use var.snapcd_server_url_from_runner (not
  // var.snapcd_server_url) because Terraform runs inside the Runner container,
  // which may reach the Server via a different hostname (e.g. a Docker network
  // name) than the machine where you run `terraform apply`.
  //
  // $${SNAPCD_MODULE_NAME} comes from the namespace_input_from_definition above,
  // which injects the current module's name as an environment variable at deploy
  // time. $${SNAPCD_CLIENT_ID} and $${SNAPCD_CLIENT_SECRET} are configured in
  // the Runner's appsettings.json under "RunnerEnvVars" — the example
  // deployments (Docker, Kubernetes, local) set these to "default".
  //
  // The double-dollar escapes Terraform interpolation so the literal ${…} is
  // preserved in the output.
  //
  // For more detail, see:
  // - https://registry.terraform.io/providers/schrieksoft/snapcd/latest/docs/resources/namespace_terraform_array_flag
  //
  // </NOTES>

  for_each = {
    address        = "${var.snapcd_server_url_from_runner}/api/state/${data.snapcd_state_store.default.id}/$${SNAPCD_MODULE_NAME}"
    lock_address   = "${var.snapcd_server_url_from_runner}/api/state/${data.snapcd_state_store.default.id}/$${SNAPCD_MODULE_NAME}/lock"
    unlock_address = "${var.snapcd_server_url_from_runner}/api/state/${data.snapcd_state_store.default.id}/$${SNAPCD_MODULE_NAME}/unlock"
    lock_method    = "POST"
    unlock_method  = "POST"
    username       = "${var.organization_id}:$${SNAPCD_CLIENT_ID}"
    password       = "$${SNAPCD_CLIENT_SECRET}"
  }
  namespace_id = snapcd_namespace.sample.id
  task         = "Init"
  flag         = "BackendConfig"
  value        = "${each.key}=${each.value}"
}


///////////////////////////////////////////////////////////////////////////////
//
// 3. module "vpc"
//
// Learn about:
// - snapcd_module
// - snapcd_module_input_from_literal (Params and EnvVars)
//
///////////////////////////////////////////////////////////////////////////////


data "snapcd_runner" "sample" {
  // <NOTES>
  // This is a "Runner". We are fetching it by name so that we can get its ID. We need to pass it into the module definitions
  // so that Snap CD knows which runner to pass the deployment jobs to.
  //
  // For more detail, see:
  // - https://docs.snapcd.io/how-it-works/configuration/runner/
  // - https://registry.terraform.io/providers/schrieksoft/snapcd/latest/docs/resources/runner
  //
  // </NOTES>

  name = var.runner_name
}

resource "snapcd_module" "vpc" {
  // <NOTES>
  //
  // This is a "module". It tells Snap CD to keep an eye on the code at the location you've specified, and keep your deployed 
  // infrastructure in line with it.
  //
  // For more detail, see:
  // - https://docs.snapcd.io/how-it-works/configuration/stack-namespace-module/#module
  // - https://registry.terraform.io/providers/schrieksoft/snapcd/latest/docs/resources/module
  //
  // </NOTES>

  name                     = "vpc"
  namespace_id             = snapcd_namespace.sample.id
  source_revision          = "main"
  source_url               = "https://github.com/snapcd-samples/mock-module-vpc.git"
  source_subdirectory      = ""
  runner_id                = data.snapcd_runner.sample.id
}

resource "snapcd_module_hook" "vpc_init_before" {
  // <NOTES>
  //
  // Init hook for the "vpc" module. Runs the given shell script before the "init" task.
  // Init is the first task in the lifecycle (it sets up the working directory, downloads
  // providers, configures the backend) and runs as part of every other task that follows.
  //
  // </NOTES>

  module_id = snapcd_module.vpc.id
  task      = "Init"
  phase     = "Before"
  script    = "echo $SOME_ENV_VAR"
}

resource "snapcd_module_input_from_literal" "vpc_params" {

  // <NOTES>
  // This is an "input" into the above "module". More specifically, it is a "literal" input to be used as a variable. Here we are
  // telling Snap CD to always pass these exact values in as inputs into the variables "vpc_name", "vpc_cidr_block" etc.
  //
  // For more detail, see https://registry.terraform.io/providers/schrieksoft/snapcd/latest/docs/resources/module_input_from_literal
  // 
  // </NOTES>

  for_each = {
    vpc_name            = "demo-vpc"
    vpc_cidr_block      = "10.0.0.0/16"
    public_subnet_cidr  = "10.0.1.0/24"
    private_subnet_cidr = "10.0.2.0/24"
  }
  input_kind    = "Param"
  module_id     = snapcd_module.vpc.id
  name          = each.key
  literal_value = each.value
  type          = "String"
}

resource "snapcd_module_input_from_literal" "env_vars" {

  // <NOTES>
  // This also an "input" into the above "module", but by setting input_kind equal to "EnvVar" (as opposed to "Param") we are 
  // instructing Snap CD to use the literal value below to populate the "SOME_ENV_VAR" environment variable with the value "Hello World!"
  // </NOTES>

  for_each = {
    SOME_ENV_VAR = "Hello World!"
  }
  input_kind    = "EnvVar"
  module_id     = snapcd_module.vpc.id
  name          = each.key
  literal_value = each.value
  type          = "String"
}


////////////////////////////////////////////////////////////////////////////////
//
// 4. module "database"
//
// Learn about:
// - snapcd_module_input_from_output
//
///////////////////////////////////////////////////////////////////////////////



resource "snapcd_module" "database" {
  name                     = "database"
  namespace_id             = snapcd_namespace.sample.id
  source_revision          = "main"
  source_url               = "https://github.com/snapcd-samples/mock-module-database.git"
  source_subdirectory      = ""
  runner_id                = data.snapcd_runner.sample.id

  // <NOTES>
  // By setting "apply_approval_threshold = 1" here, Snap CD will pause on a plan that would result in any changes. It will wait
  // until explicit approval has been granted before continuing with apply.
  //
  // Approval thresholds for "destroy" are handled separately. In this example, a "destroy" would require approvals from two 
  // seperate principals.
  //
  // Note this feature is only available in the "Lite" and "Enterpise" editions
  // 
  // </NOTES>

  apply_approval_threshold   = 1
  destroy_approval_threshold = 2
}


resource "snapcd_module_input_from_output" "private_subnet_id" {
  // <NOTES>
  //
  // This is an input into the above module, taking its value from an Output from the "vpc" module. It tells Snap CD to always take the value of 
  // Output "private_subnet_id" from the "vpc" module and using it as the input variable "deploy_to_subnet_id" on the "database" module. This
  // also creates a dependency, so Snap CD now knows (among other things) that if "vpc" produces changed outputs, it should rerun "database".
  // 
  // For more detail, see:
  // - https://docs.snapcd.io/how-it-works/outputs/
  // - https://docs.snapcd.io/how-it-works/orchestration/#trigger-on-source-changed
  // - https://registry.terraform.io/providers/schrieksoft/snapcd/latest/docs/resources/module_input_from_output
  //
  // </NOTES>

  input_kind       = "Param"
  module_id        = snapcd_module.database.id
  name             = "deploy_to_subnet_id"
  output_module_id = snapcd_module.vpc.id
  output_name      = "private_subnet_id"
}

resource "snapcd_module_input_from_literal" "database_params" {
  for_each = {
    database_name = "demo-db"
    database_sku  = "db.t3.micro"
  }
  input_kind    = "Param"
  module_id     = snapcd_module.database.id
  name          = each.key
  literal_value = each.value
  type          = "String"
}


////////////////////////////////////////////////////////////////////////////////
//
// 5. module "cluster"
//
// Learn about:
// - snapcd_module_input_from_output_set
//
///////////////////////////////////////////////////////////////////////////////



resource "snapcd_module" "cluster" {
  name                     = "cluster"
  namespace_id             = snapcd_namespace.sample.id
  source_revision          = "main"
  source_url               = "https://github.com/snapcd-samples/mock-module-kubernetes-cluster.git"
  source_subdirectory      = ""
  runner_id                = data.snapcd_runner.sample.id

}

resource "snapcd_module_input_from_literal" "cluster_params" {
  for_each = {
    cluster_name       = "demo-cluster"
    kubernetes_version = "1.28"
    node_instance_type = "m5.large"
    desired_capacity   = "3"
  }
  input_kind    = "Param"
  module_id     = snapcd_module.cluster.id
  name          = each.key
  literal_value = each.value
  type          = "String"
}

resource "snapcd_module_input_from_output_set" "cluster_params" {
  // <NOTES>
  //
  // This is an input into the "cluster" module, taking its value from the "vpc" module's OutputSet. It tells Snap CD to always take all outputs
  // produced by "vpc" and match them by name to the "cluster" module's input variables. For example, "vpc" outputs a value for "private_subnet_id"
  // and "cluster" expects an input variable by the same name, hence this variable will be pulled in as an input.
  // 
  // For more detail, see:
  // - https://docs.snapcd.io/how-it-works/configuration/module-inputs/#from-output-set
  // - https://registry.terraform.io/providers/schrieksoft/snapcd/latest/docs/resources/module_input_from_output_set
  //
  // </NOTES>

  input_kind       = "Param"
  module_id        = snapcd_module.cluster.id
  name             = "from_vpc"
  output_module_id = snapcd_module.vpc.id
}

resource "snapcd_module_terraform_flag" "upgrade" {
  // <NOTES>
  //
  // This instructs Snap CD to set the "-upgrade" flag when initializing Terraform/OpenTofu.
  //
  // For more detail, see:
  // - https://docs.snapcd.io/how-it-works/configuration/module-inputs/#from-output-set
  // - https://registry.terraform.io/providers/schrieksoft/snapcd/latest/docs/resources/module_terraform_flag
  //
  // </NOTES>

  module_id        = snapcd_module.cluster.id
  task             = "Init"
  flag             = "Upgrade"
}

resource "snapcd_module_hook" "cluster_apply_before" {
  // <NOTES>
  //
  // This is a module-level hook. It runs the given shell script just before the "apply" task
  // runs on the "cluster" module. A module hook overrides any namespace hook with the same
  // (task, phase). Use snapcd_module's `ignore_namespace_hooks = true` to suppress all
  // namespace-level hooks for this specific module.
  //
  // For more detail, see:
  // - https://registry.terraform.io/providers/schrieksoft/snapcd/latest/docs/resources/module_hook
  //
  // </NOTES>

  module_id = snapcd_module.cluster.id
  task      = "Apply"
  phase     = "Before"
  script    = "echo 'about to apply cluster changes'"
}

resource "snapcd_module_hook" "cluster_apply_after" {
  module_id = snapcd_module.cluster.id
  task      = "Apply"
  phase     = "After"
  script    = "echo 'cluster apply finished'"
}



////////////////////////////////////////////////////////////////////////////////
//
// 6. module "app"
//
// Learn about:
// - snapcd_module_input_from_secret
// - snapcd_module_input_from_literal (with type = "NotString" )
///////////////////////////////////////////////////////////////////////////////


resource "snapcd_module" "app" {
  name                     = "app"
  namespace_id             = snapcd_namespace.sample.id
  source_revision          = "main"
  source_url               = "https://github.com/snapcd-samples/mock-module-kubernetes-app-storefront.git"
  source_subdirectory      = ""
  runner_id                = data.snapcd_runner.sample.id

}


data "snapcd_stack_secret" "storefront_db_user_password" {  
  // <NOTES>
  //
  // This is a secret that has been set on the "stack", meaning all modules in the stack have access to it. (secrets can also 
  // be set on "namespace" or "module"). secrets can be read by the Terraform provider as data sources, but creating them
  // must be done manually via the snapcd.io portal, e.g. here: https://snapcd.io/stacks/samples?action=secrets
  // 
  // For more detail, see:
  // - https://docs.snapcd.io/how-it-works/configuration/secrets/
  // - https://registry.terraform.io/providers/schrieksoft/snapcd/latest/docs/data-sources/stack_secret
  // </NOTES>
  name     = var.sample_stack_secret_name 
  stack_id = data.snapcd_stack.sample.id
}


resource "snapcd_module_input_from_secret" "app_params_database_user_password" {
  // <NOTES>
  //
  // This is an input into the "app" module, taking its value from a stack secret. It tells Snap CD to always take the value of 
  // secret with id data.snapcd_stack_secret.storefront_db_user_password.id and input it into the variable "database_user_password"
  // on the "app" module.
  // 
  // For more detail, see:
  // - https://docs.snapcd.io/how-it-works/configuration/secrets/
  // - https://registry.terraform.io/providers/schrieksoft/snapcd/latest/docs/resources/module_input_from_secret
  //
  // </NOTES>

  input_kind = "Param"
  module_id  = snapcd_module.app.id
  name       = "database_user_password"
  secret_id  = data.snapcd_stack_secret.storefront_db_user_password.id
  type       = "String"
}


resource "snapcd_module_input_from_literal" "app_params_notstring" {
  // <NOTES>
  //
  // This is another "literal" input into the above module. Note that it uses a type "NotString". This is relevant when you need to 
  // pass in values like numbers as terraform variables.
  // "NotString" means: replicas=3
  // "String"    means: replicas="3"
  // 
  // </NOTES>

  for_each = {
    replicas = 3
  }
  input_kind    = "Param"
  module_id     = snapcd_module.app.id
  name          = each.key
  literal_value = each.value
  type          = "NotString"
}


resource "snapcd_module_input_from_literal" "app_params_string" {
  for_each = {
    app_url = "https://storefront.demo.com"
    database_user_name = "some-user"
  }
  input_kind    = "Param"
  module_id     = snapcd_module.app.id
  name          = each.key
  literal_value = each.value
  type          = "String"
}



resource "snapcd_module_input_from_output_set" "app_params_from_cluster" {
  input_kind       = "Param"
  module_id        = snapcd_module.app.id
  name             = "from_cluster"
  output_module_id = snapcd_module.cluster.id
}


resource "snapcd_module_input_from_output_set" "app_params_from_database" {
  input_kind       = "Param"
  module_id        = snapcd_module.app.id
  name             = "from_database"
  output_module_id = snapcd_module.database.id
}



////////////////////////////////////////////////////////////////////////////////
//
// 7. Agent & Missions
//
// Learn about:
// - snapcd_agent (as a data source — pre-registered in the Dashboard)
// - snapcd_agent_namespace_supply
// - snapcd_namespace_mission (SummarizeJob / AutoDiagnose / ApprovalRecommend)
//
// Missions are AI-driven recipes that run automatically against Job events
// (success → SummarizeJob, failure / cancel / decline → AutoDiagnose,
// awaiting-approval → ApprovalRecommend). They run inside an Agent that you
// host yourself, alongside one or more provider-specific Sidecars (the default
// being Claude).
//
// For background, see:
// - https://docs.snapcd.io/components/agent
//
///////////////////////////////////////////////////////////////////////////////


data "snapcd_agent" "sample" {
  // <NOTES>
  //
  // The Agent itself must already exist before this `terraform apply` runs.
  // Register one via the Dashboard at https://snapcd.io/Agents (Cloud) or your
  // Self-Hosted Server's `/Agents` page — name it, attach a Service Principal,
  // and deploy at least one Instance using one of the reference deployments
  // (https://github.com/schrieksoft/snapcd-deployment-docker etc.).
  //
  // We look it up by name here so the missions below can reference its ID
  // without you having to copy the GUID into your tfvars. Same shape as the
  // Runner section above.
  //
  // For more detail, see:
  // - https://registry.terraform.io/providers/schrieksoft/snapcd/latest/docs/data-sources/agent
  //
  // </NOTES>

  name = var.agent_name
}

resource "snapcd_agent_namespace_supply" "sample" {
  // <NOTES>
  //
  // Permits the Agent to handle Missions for any Module inside this Namespace.
  // Mirrors the snapcd_runner_namespace_supply pattern from section 2 —
  // namespace-scoped permission so you only have to write this once even if
  // the namespace grows to many modules.
  //
  // For more detail, see:
  // - https://registry.terraform.io/providers/schrieksoft/snapcd/latest/docs/resources/agent_namespace_assignment
  //
  // </NOTES>

  agent_id     = data.snapcd_agent.sample.id
  namespace_id = snapcd_namespace.sample.id
}


resource "snapcd_namespace_mission" "summarize_job" {
  // <NOTES>
  //
  // Fires after every successful Apply or Destroy on a Module in this
  // Namespace. The Agent reads the redacted logs + plan/apply summary + the
  // approval record and writes an audit-quality, human-readable summary that
  // appears on the Job's "Missions" tab in the Dashboard.
  //
  // Because the namespace contains the vpc / database / cluster / app modules
  // declared above, every one of their successful jobs produces a Mission run
  // automatically — no further wiring needed.
  //
  // For more detail, see:
  // - https://registry.terraform.io/providers/schrieksoft/snapcd/latest/docs/resources/namespace_mission
  //
  // </NOTES>

  namespace_id = snapcd_namespace.sample.id
  agent_id     = data.snapcd_agent.sample.id
  mission_type = "SummarizeJob"
}

