variable "prefix" {
  type = string
  description = "This is the VM prefix name"
}

variable "list_instances" {
  type = set(string)
  description = "This is the list of VM names"
}

variable "instance_types" {
  type = map(list(string))
  description = "This is the VM types"
}

variable "region_name" {
  type = string
  description = "This is the VM region"
}

variable "chk" {
  type = bool
  description = "This is a check variable, yes if create vm"
}
