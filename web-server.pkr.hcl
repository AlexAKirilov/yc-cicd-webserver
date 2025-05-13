# YC PLUGINS

packer {
  required_plugins {
    yandex = {
      version = " >= 1.1.2"
      source  = "github.com/hashicorp/yandex"
    }
  }
}


# VARIABLES

# YC
variable "YC_FOLDER_ID" {
  type    = string
  default = ""
}

variable "YC_ZONE" {
  type    = string
  default = "ru-central1-b"
}

variable "YC_SUBNET_ID" {
  type    = string
  default = ""
}

variable "YC_TOKEN" {
  type      = string
  default   = ""
  sensitive = true
}

# IMAGE DESCRIPTION
variable "IMAGE_NAME" {
  type    = string
  default = "web-server"
}

variable "IMAGE_DESCRIPTION" {
  type    = string
  default = ""
}

# OS
variable "SOURCE_UBUNTU_FAMILY" {
  type    = string
  default = "2204-lts"
}

variable "OUTPUT_IMAGE_FAMILY" {
  type    = string
  default = "web"   
}

# VM
variable "INSTANCE_CORES" {
  type    = number
  default = 4  
}

variable "INSTANCE_MEM_GB" {
  type    = number
  default = 4  
}

variable "DISK_TYPE" {
  type    = string
  default = "network-hdd"   
}

variable "DISK_SIZE_GB" {
  type    = number
  default = 10
}

# SSH
variable "SSH_USERNAME" {
  type    = string
  default = "ubuntu"
}

variable "SSH_PASSWORD" {
  type      = string
  default   = "ubuntu"
  sensitive = true
}


source "yandex" "yc" {
  folder_id            = var.YC_FOLDER_ID
  zone                 = var.YC_ZONE
  subnet_id            = var.YC_SUBNET_ID
  token                = var.YC_TOKEN

  image_name           = var.IMAGE_NAME
  image_description    = var.IMAGE_DESCRIPTION

  source_image_family  = "ubuntu-${var.SOURCE_UBUNTU_FAMILY}"
  image_family         = var.OUTPUT_IMAGE_FAMILY

  instance_cores       = var.INSTANCE_CORES
  instance_mem_gb      = var.INSTANCE_MEM_GB

  disk_type            = var.DISK_TYPE
  disk_size_gb         = var.DISK_SIZE_GB

  ssh_username         = var.SSH_USERNAME
  ssh_password         = var.SSH_PASSWORD

  use_ipv4_nat         = true
}


build {
  name = "${var.IMAGE_NAME}-build"

  sources = ["source.yandex.yc"]

  provisioner "shell" {
    inline = [
      "sudo mkdir -p /tmp/scripts",
      "sudo mkdir -p /tmp/resources",
      "sudo chown -R ${var.SSH_USERNAME}:${var.SSH_USERNAME} /tmp/scripts /tmp/resources",
      "sudo chmod -R 775 /tmp/scripts /tmp/resources"
    ]
  }

  provisioner "file" {
    source      = "scripts/"
    destination = "/tmp/scripts/"
  }

  provisioner "file" {
    source      = "resources/"
    destination = "/tmp/resources/"
  }

  provisioner "shell" {
    inline = [
      "sudo chmod -R +x /tmp/scripts/",
      "sudo /tmp/scripts/setup.sh"
    ]
  }

  post-processor "manifest" {
    output = "yc-manifest.json"
  }
}