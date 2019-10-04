# Overview

This module creates a managed instance group of VM instances running
gitlab-runner instances.  [Container Optimized OS][cos] images are used to
simplify updates and management of the Docker host.  [gitlab-runner][1] is
installed into the VM host (not as a container) and registered to gitlab via
[cloud-init][2].

# Features

 1. Automatic gitlab-runner registration to gitlab.com
 2. Instances are preemptible by default, [reducing cost by 70 to
    80%][discount].
 2. Automatically unregister on [preemption][preemption], reboot, shutdown to
    clean up.
 3. Managed instance group automatically restarts preempted instances.
 4. Health checking against the gitlab-runner Prometheus metrics endpoint.
 5. Unhealthy instances are terminated and re-created.

# Example Usage

```terraform
variable "project" {
  description = "The instance group project"
}

variable "registration_token" {
  description = "The Gitlab registration token used to register this runner, found via /settings/ci_cd in the GitLab Web UI"
}

module gitlab-runner-public {
  name                  = "gitlab-runner-public"
  source                = "git::https://gitlab.com/openinfrastructure/code/terraform-google-gitlab-runner.git?ref=v0.1.0"
  project               = var.project
  registration_token    = var.registration_token
  tag-list              = ["docker", "gcp", "public"]
  service_account_email = "gitlab-runner-public@${var.project}.iam.gserviceaccount.com"
  machine_type          = "f1-micro"
}

module gitlab-runner-private {
  name                  = "gitlab-runner-private"
  source                = "git::https://gitlab.com/openinfrastructure/code/terraform-google-gitlab-runner.git?ref=v0.1.0"
  project               = var.project
  registration_token    = var.registration_token
  tag-list              = ["docker", "gcp", "private"]
  service_account_email = "gitlab-runner-private@${var.project}.iam.gserviceaccount.com"
  machine_type          = "f1-micro"
}
```

# Operational Playbook

## Update instances

Run terraform apply to update the instance template, then replace the instances
with new ones using:

```bash
gcloud compute instance-groups managed rolling-action replace gitlab-runner
```

# Logs

## cloud-init Logs

Container Optimizes OS uses systemd-journal for all logs.  Log into an instance
and run `sudo journalctl` to view system boot logs including cloud-init
execution steps.

[cos]: https://cloud.google.com/container-optimized-os/docs/how-to/run-container-instance
[1]: https://docs.gitlab.com/runner/
[2]: https://cloudinit.readthedocs.io/en/latest/
[preempt]: https://cloud.google.com/compute/docs/instances/preemptible#preemption_process
[discount]: https://cloud.google.com/preemptible-vms/
