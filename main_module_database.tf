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
  // This is an Input into the above Module, taking its value from an Output from the "vpc" Module. It tells Snap CD to always take the value of 
  // Output "private_subnet_id" from the "vpc" Module and using it as the input variable "deploy_to_subnet_id" on the "database" Module. This
  // also creates a depedency, so Snap CD now knows (among other things) that if "vpc" produces changed outputs, it should rerun "database".
  // 
  // For more detail, see:
  // - https://docs.snapcd.io/how-it-works/outputs/
  // - https://docs.snapcd.io/how-it-works/orchestration/#trigger-on-source-changed
  // - https://registry.terraform.io/providers/schrieksoft/snapcd/latest/docs/resources/module_input_from_output
  //
  // </NOTES

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