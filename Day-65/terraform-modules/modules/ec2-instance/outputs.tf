output "instance_id" {
  description = "The ID of the provisioned EC2 instance"
  value       = aws_instance.this.id
}

output "public_ip" {
  description = "The public IPv4 address assigned to the instance"
  value       = aws_instance.this.public_ip
}

output "private_ip" {
  description = "The private IPv4 address assigned to the instance"
  value       = aws_instance.this.private_ip
}
