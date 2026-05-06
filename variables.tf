// The default variables below are set to work out of the box with the pre-configured "snapcd-selfhosted-deployment-docker"

// Needed to init provider
variable "client_id" {
  default = "default"
}
variable "client_secret" {
  default   = "default"
  sensitive = true
}
variable "organization_id" {
  default = "10000000-0000-0000-0000-000000000000"
}

variable "insecure_skip_verify" {
  default = true
  // set to false if server has valid certifcate; e.g. if snapcd_server_url==https://snapcd.io
}
variable "snapcd_server_url" {
  default = "http://localhost:8080"
  // the URL if deploying with snapcd-selfhosted-deployment-docker is "http://localhost:8080", we use that as default here
  // the URL if starting SnapCd.Server.Host C# project is https://localhost:20002 
  // the URL if making use of a SaaS subscription is https://snapcd.io
}

// Passed into module
variable "runner_name" {
  default = "default"
}
variable "stack_name" {
  default = "default"
}
variable "sample_stack_secret_name" {
  default = "sample"
}
variable "namespace_name" {
  default = "my-sample-namespace"
}
