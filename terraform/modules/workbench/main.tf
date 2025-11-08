terraform {
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = ">= 4.0"
    }
  }
}

resource "google_workbench_instance" "instance" {
  name     = var.instance_name
  location = var.zone
  project  = var.project_id

  gce_setup {
    machine_type = var.enable_gpu ? var.gpu_machine_type : var.cpu_machine_type

    dynamic "accelerator_configs" {
      for_each = var.enable_gpu ? [1] : []
      content {
        core_count = var.gpu_count
        type       = var.gpu_type
      }
    }

    vm_image {
      project = "cloud-notebooks-managed"
      family  = "workbench-instances"
    }

    metadata = var.metadata

    service_accounts {
      email = var.service_account_email
    }

    disable_public_ip = var.disable_public_ip
  }

  desired_state = var.desired_state

  labels = var.labels
}
