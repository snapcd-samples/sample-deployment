resource "snapcd_namespace" "sample" {
  // <NOTES>
  //
  // This is a Namespace. Use this to organize your Modules
  //
  // For more detail, see:
  // - https://docs.snapcd.io/how-it-works/configuration/stack-namespace-module/#namespace
  // - https://registry.terraform.io/providers/schrieksoft/snapcd/latest/docs/resources/namespace
  //
  // </NOTES


  name     = "sample-full"
  stack_id = data.snapcd_stack.sample_full.id
}

resource "snapcd_namespace_input_from_literal" "sample" {

  // <NOTES>
  //
  // This is a Namespace Input. Every Module within the Namespace will receive the input variable "resource_group_name" by default ever time
  // the Module is deployed. This behavious can be toggled with the "usage_mode" flag.
  //
  // This is Namespace Input is from a literal value. Namepsace Inputs can also be from "Defition" or "Secret".
  //
  // For more detail, see:
  // - https://docs.snapcd.io/how-it-works/configuration/namespace-inputs/
  // - https://registry.terraform.io/providers/schrieksoft/snapcd/latest/docs/resources/namespace_input_from_literal
  //
  // </NOTES


  input_kind    = "Param"
  name          = "resource_group_name"
  literal_value = "This will be the value of 'var.myvar'!"
  namespace_id  = snapcd_namespace.mynamespace.id
  usage_mode    = "UseByDefault"
}