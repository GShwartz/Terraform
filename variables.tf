# Define Resource Group Name
variable "rgname" {
  description = "Set the name for the Resource Group"

}

# Define Location
variable "location" {
  description = "set the location"
  type        = string

}

# Define Virtual Network Name
variable "vnet_name" {
  description = "Set Name for Virtual Network"

}

# Define Applications Subnet Name
variable "applications_subnet_name" {
  description = "Set Name for Applications Subnet"

}

# Define Databases Subnet Name
variable "db_subnet_name" {
  description = "Set Name for Databases Subnet"

}

# Define Public IP Name
variable "pip_name" {
  description = "Set Name for NAT Gateway Public IP"

}

variable "web_port" {
  description = "port to expose to external lb"

}

variable "ssh_port" {
  description = "SSH port to expose"

}

variable "admin_user" {
  description = "VM Admin user"

}

variable "admin_password" {
  description = "VM Admin Password"

}

variable "vnet_address_space" {
  description = "Vnet Address Space"

}

variable "frontend_address_prefix" {
  description = "Frontend Address Prefix"

}

variable "webapp_nsg_name" {
  description = "Network Security Group for Applications Subnet"

}

variable "db_nsg_name" {
  description = "Network Security Group for Databases Subnet"

}

variable "pip_sku" {
  description = "Public IP SKU"

}

variable "pip_allocation" {
  description = "Public IP allocation"

}

variable "privip_allocation" {
  description = "Private IP allocation"
}

variable "vm_type" {
  description = "VM Type (B1s, B1ms, etc)"

}

variable "storage_os_disk_name" {
  description = "Storage OS Disk Name"

}

variable "publisher" {
  description = "OS Publusher"

}

variable "offer" {
  description = "OS Offer"

}

variable "linux_sku" {
  description = "SKU - Distribution"

}

variable "os_version" {
  description = "OS Version"

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
  description = "Disk Size in GB"

}

# ====================================================== #
# Network Interfaces #
# ====================================================== #

variable "nics" {
  description = "Network Interfaces"
  type    = list(string)

}

variable "vnet_prefix" {
  description = "Vnet Address Space Prefix"

}

variable "subnet_prefix" {
  description = "Subnet Prefix"
}

# ======================================================= #

variable "disk_name" {
  description = "VM Disk Name"
  type    = string

}

variable "machine_name" {
  description = "VM Machine Name"
  type    = string

}

variable "db_user" {
  description = "Username for PostgreSQL"

}

variable "db_password" {
  description = "Password for PostgreSQL"

}
