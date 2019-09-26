# Overview

This module creates a managed instance group of VM instances running
gilab-runner instances.  [Container Optimized OS][cos] images are used to
simplify updates and management of the Docker host.  [gitlab-runner][1] is
installed into the VM host (not as a container) and registered to gitlab via
[cloud-init][2].

# Operational Playbook

## Update instances

Run terraform apply to update the instance teplate, then replace the instances
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
