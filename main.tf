# Copyright 2019 Open Infrastructure Services LLC
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#      http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

locals {
  service_account_email = "${var.service_account_email == "" ? "${var.name}@${var.project}" : var.service_account_email}"
  tags                  = var.tags
  tag-list              = "${join(",", concat(list(var.name), var.tag-list))}"
  subnetwork_project    = "${var.subnetwork_project == "" ? var.subnetwork_project : var.project}"
}

# Main cloud-init config
data "template_file" "cloud-init" {
  template = "${file("${path.module}/templates/init.cfg.tpl")}"

  vars = {
    gitlab-runner-url  = var.gitlab-runner-url
    gitlab-url         = var.gitlab-url
    registration_token = var.registration_token
    tag-list           = local.tag-list
    hc_port            = var.hc_port
    concurrent         = var.concurrent
  }
}

# Multi-part cloud-init config
data "template_cloudinit_config" "cloud-config" {
  gzip          = false
  base64_encode = false

  # Main cloud-config configuration file
  part {
    filename     = "init.cfg"
    content_type = "text/cloud-config"
    content      = data.template_file.cloud-init.rendered
  }
}

# Shutdown script to de-register the runner when preempted.
data "template_file" "shutdown-script" {
  template = "${file("${path.module}/templates/shutdown-script.tpl")}"
}

resource google_compute_instance_template "gitlab-runner" {
  name_prefix  = "${var.name}-"
  machine_type = var.machine_type
  region       = var.region
  project      = var.project

  tags = local.tags

  network_interface {
    subnetwork         = var.subnetwork
    subnetwork_project = local.subnetwork_project
  }

  disk {
    auto_delete  = true
    boot         = true
    source_image = var.os_image
    type         = "PERSISTENT"
    disk_size_gb = "100"
  }

  metadata = {
    # cloud-init used to setup gitlab-runner
    user-data = data.template_cloudinit_config.cloud-config.rendered
    # de-register on shutdown
    shutdown-script = data.template_file.shutdown-script.rendered
  }

  scheduling {
    preemptible       = var.preemptible
    automatic_restart = var.automatic_restart
  }

  lifecycle {
    create_before_destroy = true
  }

  service_account {
    email  = local.service_account_email
    scopes = ["cloud-platform"]
  }
}

resource "google_compute_region_instance_group_manager" "gitlab-runner" {
  project  = var.project
  name     = var.name

  base_instance_name = var.name

  region = var.region
  distribution_policy_zones = [
    "${var.region}-a",
    "${var.region}-b",
    "${var.region}-c",
  ]

  update_policy {
    type            = var.update_policy_type
    minimal_action  = "REPLACE"
    max_surge_fixed = 3
    min_ready_sec   = 30
  }

  target_size = var.num_instances

  named_port {
    name = "gitlab-runner"
    port = var.hc_port
  }

  auto_healing_policies {
    health_check      = google_compute_health_check.gitlab-runner.self_link
    initial_delay_sec = var.hc_initial_delay_secs
  }

  version {
    name              = var.name
    instance_template = google_compute_instance_template.gitlab-runner.self_link
  }
}

resource google_compute_health_check "gitlab-runner" {
  name    = var.name
  project = var.project

  check_interval_sec  = var.hc_interval
  timeout_sec         = var.hc_timeout
  healthy_threshold   = var.hc_healthy_threshold
  unhealthy_threshold = var.hc_unhealthy_threshold

  http_health_check {
    port         = var.hc_port
    request_path = var.hc_path
  }
}
