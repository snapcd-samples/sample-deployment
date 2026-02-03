data "snapcd_stack" "sample_full" {
  name = var.stack_name
}

data "snapcd_runner" "sample_full" {
  // <NOTES>
  // This is a "Runner". We are fetching it by name so that we can get its ID. We need to pass into the "Module" definitions
  // so that Snap CD knows which runner pass the deployment jobs to.
  //
  // For more detail, see:
  // - https://docs.snapcd.io/how-it-works/configuration/runner/
  // - https://registry.terraform.io/providers/schrieksoft/snapcd/latest/docs/resources/runner
  //
  // </NOTES

  name = var.runner_name
}

data "snapcd_stack_secret" "storefront_db_user_password" {
  name     = var.sample_stack_secret_name 
  stack_id = data.snapcd_stack.sample_full.id
}
