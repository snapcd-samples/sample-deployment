output "scoped_runner_id" {
  // The Runner created in section 8 is only its registration in the control
  // plane. A Runner process must still be deployed and pointed at this ID
  // before any Module can deploy with it, using one of the reference
  // deployments (Docker, Kubernetes, local).
  value       = snapcd_runner.scoped.id
  description = "ID of the Runner created in section 8, to configure a deployed Runner process with."
}

output "scoped_namespace_id" {
  value       = snapcd_namespace.scoped.id
  description = "ID of the Namespace created in section 8."
}
