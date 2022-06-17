variable "vnet_name" {
  description = "Name of the Virtual Network"
  
}

variable "rg_name" {
  description = "Resource Group Name"
  
}

variable "location" {
  description = "Set Location"

}

variable "virtual_network_name" {
  description = "Name for the Virtual Network"

}

variable "admin_user" {
  description = "VM Admin User"

}

variable "admin_password" {
  description = "VM Admin Password"

}

variable "vm_type" {
  description = "VM Type (Usualy Standard_B1s)"

}

variable "storage_os_disk_name" {
  description = "Disk Name"

}

variable "publisher" {
  description = "OS Publisher"

}

variable "offer" {
  description = "Source"

}

variable "linux_sku" {
  description = "Distribution"

}

variable "os_version" {
  description = "Version"

}

variable "managed_disk_type" {
  description = "Managed Disk Type"

}

variable "create_option" {
  description = "Create Option"

}

variable "disk_catch" {
  description = "Disk Catch"

}

variable "disk_size_gb" {
  description = "Disk Size GB"

}

variable "disk_name" {
  description = "Disk Name"

}
