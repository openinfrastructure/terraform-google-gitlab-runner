variable "project" {
  description = "The project id to create resources in"
  type        = string
}

variable "name" {
  description = "The name to use for resources managed.  The value serves as a common prefix."
  default     = "gitlab-runner"
}

variable "gitlab-runner-url" {
  description = "The source URL used to install the gitlab-runner onto the VM host os.  Passed to curl via cloud-config runcmd."
  default     = "https://gitlab-runner-downloads.s3.amazonaws.com/latest/binaries/gitlab-runner-linux-amd64"
}

variable "gitlab-url" {
  description = "The URL to the GitLab instance"
  default     = "https://gitlab.com"
}

variable "registration_token" {
  description = "The Gitlab registration token used to register this runner, found via /settings/ci_cd in the GitLab Web UI"
  default     = ""
}

variable "tag-list" {
  description = "The gitlab-runner tag list, passed to the --tag-list arugment of the registration command"
  type        = list
  default     = ["docker", "gcp"]
}

variable "service_account_email" {
  description = "The service account bound to the instances.  If unset, set to <name>@<projed_id>.iam.gserviceaccount.com"
  type        = string
  default     = null
}

variable "region" {
  description = "The region to deploy resources into."
  default     = "us-west1"
}

variable "zone" {
  description = "The zone to deploy resources into."
  default     = "us-west1-b"
}

variable "os_image" {
  description = "The OS image for VM instances"
  default     = "cos-cloud/cos-stable"
}

variable "subnetwork" {
  description = "The name of the subnet the primary interface each instance will use.  Do not specify as a fully qualified name."
  default     = "default"
}

variable "subnetwork_project" {
  description = "The project hosting the subnet"
  type        = "string"
  default     = null
}

variable "machine_type" {
  description = "The machine type of each IP Router Bridge instance"
  default     = "n1-standard-1"
}

variable "num_instances" {
  description = "The number of instances in the instance group"
  default     = 1
}

variable "hc_initial_delay_secs" {
  description = "The number of seconds that the managed instance group waits before it applies autohealing policies to new instances or recently recreated instances."
  default     = 60
}

variable "hc_interval" {
  description = "Health check, check interval in seconds."
  default     = 3
}

variable "hc_timeout" {
  description = "Health check, timeout in seconds."
  default     = 2
}

variable "hc_healthy_threshold" {
  description = "A so-far unhealthy instance will be marked healthy after this many consecutive successes. The default value is 2."
  default     = 2
}

variable "hc_unhealthy_threshold" {
  description = "A so-far healthy instance will be marked unhealthy after this many consecutive failures. The default value is 2."
  default     = 2
}

variable "hc_port" {
  description = "Health check port"
  default     = "9252"
}

variable "hc_path" {
  description = "Health check, the http path to check."
  default     = "/metrics"
}

variable "tags" {
  description = "Additional network tags added to instances.  Intended for opening VPC firewall access for health checks."
  default     = ["allow-health-check"]
}

variable "update_policy_type" {
  description = "The type of update. Valid values are 'OPPORTUNISTIC', 'PROACTIVE'"
  default     = "OPPORTUNISTIC"
}

variable "automatic_restart" {
  description = "If true, automatically restart instances on maintenance events.  See https://cloud.google.com/compute/docs/instances/live-migration#autorestart"
  type        = bool
  default     = false
}

variable "preemptible" {
  description = "If true, create preemptible VM instances intended to reduce cost.  Note, the MIG will recreate pre-empted instnaces.  See https://cloud.google.com/compute/docs/instances/preemptible"
  type        = bool
  default     = true
}
