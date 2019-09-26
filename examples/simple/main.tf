variable "registration_token" {
  description = "The registration token used to register the runners, e.g. 'xxxxxxxxxxxxxxxxxxxx'"
  type        = string
}

variable "project" {
  description = "The instance group project id, e.g. 'control-123456'"
  type        = string
}

module "gitlab-runner" {
  source             = "../../"
  project            = var.project
  registration_token = var.registration_token
  machine_type       = "f1-micro"
}
