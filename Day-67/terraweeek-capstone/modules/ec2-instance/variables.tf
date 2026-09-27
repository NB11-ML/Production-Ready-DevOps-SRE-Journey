variable "ami_id" {}
variable "instance_type" {}
variable "subnet_id" {}
variable "security_group_ids" { type = list(string) }
variable "environment" {}
variable "project_name" {}
