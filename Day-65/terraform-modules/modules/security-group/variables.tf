variable "vpc_id" {
  description = "The target VPC ID where the security group will reside"
  type        = string
}

variable "sg_name" {
  description = "Name identifier for the security group"
  type        = string
}

variable "ingress_ports" {
  description = "List of inbound TCP ports to open"
  type        = list(number)
  default     = [22, 80]
}

variable "tags" {
  description = "Tags applied to the security group"
  type        = map(string)
  default     = {}
}
