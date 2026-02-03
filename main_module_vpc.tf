resource "snapcd_module" "vpc" {
  // <NOTES>
  //
  // This is a "Module". It tells Snap CD to keep an eye on the code at the location you've specified, and keep your deployed 
  // infrastructure in line with it.
  //
  // For more detail, see:
  // - https://docs.snapcd.io/how-it-works/configuration/stack-namespace-module/#module
  // - https://registry.terraform.io/providers/schrieksoft/snapcd/latest/docs/resources/module
  //
  // </NOTES

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
  // This is an "Input" into the above "Module". More specifically, it is a "literal" input to be used as a variable. Here we are
  // telling Snap CD to always pass these exact values in as inputs into the variables "vpc_name", "vpc_cidr_block" etc.
  //
  // For more detail, see https://registry.terraform.io/providers/schrieksoft/snapcd/latest/docs/resources/module_input_from_literal
  // 
  // </NOTES

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
  // This also an "Input" into the above "Module", but by setting input_kind equal to "EnvVar" (as opposed to "Param") we are 
  // instructing Snap CD to use the literal value below to populate the "SOME_ENV_VAR" environment variable with the value "Hello World!"
  // </NOTES

  for_each = {
    SOME_ENV_VAR = "Hello World!"
  }
  input_kind    = "EnvVar"
  module_id     = snapcd_module.vpc.id
  name          = each.key
  literal_value = each.value
  type          = "String"
}
