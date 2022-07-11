packer {
  required_version = "~> 1.8"

  required_plugins {
    parallels = {
      version = ">= 1.0.3"
      source  = "github.com/hashicorp/parallels"
    }
  }
}

variable "os_name" {
  description = "The name of version of macOS."
  type        = string
}

variable "source_vm" {
  description = "The path to the source VM."
  type        = string
}

variable "ssh_password" {
  description = "The password of the user connecting to the VM via SSH."
  type        = string
  sensitive   = true
}

locals {
  ssh_username = "packer"
}

source "parallels-pvm" "main" {
  vm_name              = "ticksmith-${var.os_name}-executor"
  source_path          = var.source_vm
  output_directory     = "vms"
  parallels_tools_mode = "disable"
  ssh_username         = local.ssh_username
  ssh_password         = var.ssh_password
  ssh_timeout          = "5m"
  shutdown_command     = "echo '${var.ssh_password}' | sudo -S shutdown -h now"
  shutdown_timeout     = "10m"
  skip_compaction      = true
}

build {
  sources = [
    "source.parallels-pvm.main",
  ]

  provisioner "ansible" {
    playbook_file = "./ansible/playbook.yaml"
    groups        = [var.os_name]
    user          = local.ssh_username

    extra_arguments = [
      # "-vvvv",
      "--extra-vars",
      "ansible_become_pass=${var.ssh_password}",
    ]

    ansible_env_vars = [
      "ANSIBLE_CONFIG=./ansible/ansible.cfg"
    ]
  }
}
