terraform {
  required_providers {
    yandex = {
      source = "yandex-cloud/yandex"
    }
  }
  required_version = ">= 0.13"
}

provider "yandex" {
  zone = "ru-central1-b"
}

variable "cores" {
  description = "Number of cores"
  type = list(number)
}

variable "gigabytes" {
  description = "RAM size in gigabytes"
  type = list(number)
}

locals {
  instances = min(length(var.cores), length(var.gigabytes))
}

resource "yandex_compute_instance" "vm" {

  # Use `for_each` instead of `count` for better flexibility
  for_each = zipmap(range(local.instances), [for i in range(local.instances) : format("vm-%d", i + 1)])

  name = each.value

  hostname = each.value

  zone = "ru-central1-b"
  platform_id = "standard-v1"

  resources {
    cores  = var.cores[each.key]
    memory = var.gigabytes[each.key]
  }

  boot_disk {
    initialize_params {
      image_id = "fd8i352834u7dsm7rfbv" # This is for 20.04; for 24.04, use fd8tvc3529h2cpjvpkr5
    }
  }

  network_interface {
    subnet_id = "e2lgv5mqm56n8fjkt37q"
    nat = true
  }

  metadata = {
    ssh-keys = "ubuntu:${file("~/.ssh/id_ed25519.pub")}"
  }

}

resource "null_resource" "manage_inputs" {

  # Currently, Terraform asks for inputs at `destroy` and refuses to proceed if they don't match.
  # A corresponding bug was filed on GitHub long ago which is still not fixed.
  # This will handle writing and deleting the .auto.tfvars file so you can simply `terraform destroy`.

  provisioner "local-exec" {
    interpreter = ["bash", "-c"]
    command = <<-EOT
		printf "instances = %s\ncores = %s\ngigabytes = %s\n" "${local.instances}" "${var.cores}" "${var.gigabytes}" > vms.auto.tfvars
	EOT
    when = create
  }

  provisioner "local-exec" {
    interpreter = ["bash", "-c"]
    command = "rm -f vms.auto.tfvars"
    when = destroy
  }

  depends_on = [yandex_compute_instance.vm]
}