
///////////////////////////////////////////////////////////////////////////////
//
// 1. namespace
//
// Learn about:
// - snapcd_stack
// - snapcd_namespace
//
///////////////////////////////////////////////////////////////////////////////


data "snapcd_stack" "sample_full" {
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


  name     = "sample-full"
  stack_id = data.snapcd_stack.sample_full.id
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


///////////////////////////////////////////////////////////////////////////////
//
// 2. module "vpc"
//
// Learn about:
// - snapcd_module
// - snapcd_module_input_from_literal (Params and EnvVars)
//
///////////////////////////////////////////////////////////////////////////////


data "snapcd_runner" "sample_full" {
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
  runner_id                = data.snapcd_runner.sample_full.id
  auto_upgrade_enabled     = true
  auto_reconfigure_enabled = true
  auto_migrate_enabled     = false
  clean_init_enabled       = false
  init_before_hook         = "echo $SOME_ENV_VAR"
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
// 3. module "database"
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
  runner_id                = data.snapcd_runner.sample_full.id
  auto_upgrade_enabled     = true
  auto_reconfigure_enabled = true
  auto_migrate_enabled     = false
  clean_init_enabled       = false
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
// 4. module "cluster"
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
  runner_id                = data.snapcd_runner.sample_full.id
  auto_upgrade_enabled     = true
  auto_reconfigure_enabled = true
  auto_migrate_enabled     = false
  clean_init_enabled       = false
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



////////////////////////////////////////////////////////////////////////////////
//
// 5. module "app"
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
  runner_id                = data.snapcd_runner.sample_full.id
  auto_upgrade_enabled     = true
  auto_reconfigure_enabled = true
  auto_migrate_enabled     = false
  clean_init_enabled       = false
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
  stack_id = data.snapcd_stack.sample_full.id
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

