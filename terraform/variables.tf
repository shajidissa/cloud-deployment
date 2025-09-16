variable "region"            { description = "OCI region (e.g. uk-london-1)" type = string }
variable "compartment_ocid"  { description = "Target compartment OCID" type = string }

variable "vcn_cidr"           { type = string default = "10.0.0.0/16" }
variable "public_subnet_cidr" { type = string default = "10.0.1.0/24" }

variable "ssh_public_key" { description = "Paste your ~/.ssh/*.pub contents" type = string }
variable "ssh_cidr"       { description = "CIDR allowed for SSH" type = string default = "0.0.0.0/0" }

variable "instance_shape"      { type = string default = "VM.Standard.A1.Flex" }
variable "instance_ocpus"      { type = number default = 1 }
variable "instance_memory_gbs" { type = number default = 2 }

variable "app_port" { type = number default = 3000 }

variable "mysql_admin_username" { type = string default = "admin" }
variable "mysql_admin_password" { type = string sensitive = true }
variable "db_name"              { type = string default = "appdb" }
