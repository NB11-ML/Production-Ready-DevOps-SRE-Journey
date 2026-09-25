variable "ami_id" {
  description = "The AMI ID to use for the EC2 instance"
  type        = string
}

variable "instance_type" {
  description = "The EC2 instance type"
  type        = string
  default     = "t3.small"
}

variable "subnet_id" {
  description = "The VPC Subnet ID to launch the instance into"
  type        = string
}

variable "security_group_ids" {
  description = "List of Security Group IDs to associate with the instance"
  type        = list(string)
}

variable "instance_name" {
  description = "Name tag for the EC2 instance"
  type        = string
}

variable "tags" {
  description = "Additional tags to merge with the instance Name tag"
  type        = map(string)
  default     = {}
}
