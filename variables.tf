// The default variables below are set to work out of the box with the pre-configured "snapcd-selfhosted-deployment-docker"

//// Needed to init provider
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
  default = "http://localhost:5000"
  // The URL you use to reach the Snap CD Server from where you run `terraform apply`.
  // - snapcd-deployment-docker: "http://localhost:5000"
  // - SnapCd.Server.Host (C# project): "https://localhost:20002"
  // - SaaS subscription: "https://snapcd.io"
}


//// Passed into module

variable "snapcd_server_url_from_runner" {
  default = "http://snapcd-server:5000"
  // The URL the Runner uses to reach the Snap CD Server. This is used in the
  // State Store backend config — Terraform runs inside the Runner container, so
  // the URL must be reachable from there (e.g. a Docker network hostname).
  // - snapcd-deployment-docker: "http://snapcd-server:5000"
  // - SnapCd.Server.Host (C# project): "https://localhost:20002"
  // - SaaS subscription: "https://snapcd.io"
}
variable "runner_name" {
  default = "default"
}
variable "agent_name" {
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
