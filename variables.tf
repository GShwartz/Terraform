variable "vnet_name" {
  description = "Name of the Virtual Network"
  default = "Weight_Tracker_With_Terraform-vnet"
}

variable "rg_name" {
  description = "Resource Group Name"
  default     = "Weight_Tracker_With_Terraform"

}

variable "location" {
  description = "Set Location"
  default     = "East US"

}

variable "virtual_network_name" {
  description = "Name for the Virtual Network"
  default     = "WeightTracker-Vnet"
}

variable "admin_user" {
  description = "VM Admin User"
  default = "gstudent"

}

variable "admin_password" {
  description = "VM Admin Password"
  default = "SelaBootcamp4!"

}

variable "vm_type" {
  description = "VM Type (Usualy Standard_B1s)"
  default = "Standard_B1s"

}

variable "storage_os_disk_name" {
  description = "Disk Name"
  default = "WeightTrackerVM-Disk"

}

variable "publisher" {
  description = "OS Publisher"
  default = "Canonical"

}

variable "offer" {
  description = "Source"
  default = "0001-com-ubuntu-server-focal"

}

variable "linux_sku" {
  description = "Distribution"
  default = "20_04-lts-gen2"

}

variable "os_version" {
  description = "Version"
  default = "latest"

}

variable "managed_disk_type" {
  description = "Managed Disk Type"
  default = "Standard_LRS"

}

variable "create_option" {
  description = "Create Option"
  default = "FromImage"

}

variable "disk_catch" {
  description = "Disk Catch"
  default = "ReadWrite"

}

variable "disk_size_gb" {
  description = "Disk Size GB"
  default = 30

}

variable "disk_name" {
  description = "Disk Name"
  default = "Disk"

}