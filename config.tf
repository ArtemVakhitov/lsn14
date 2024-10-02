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
  type = number
  default = 2
}

variable "gigabytes" {
  description = "RAM size in gigabytes"
  type = number
  default = 2
}

resource "yandex_compute_instance" "first" {

  name = "first"

  zone = "ru-central1-b"
  platform_id = "standard-v1"

  resources {
    cores  = var.cores
    memory = var.gigabytes
  }

  boot_disk {
    initialize_params {
      image_id = "fd8tvc3529h2cpjvpkr5"
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