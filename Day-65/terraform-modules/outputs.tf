output "vpc_id" {
  description = "The ID of the provisioned VPC"
  value       = module.vpc.vpc_id
}

output "web_server_public_ip" {
  description = "Public IP of the web server"
  value       = module.web_server.public_ip
}

output "api_server_public_ip" {
  description = "Public IP of the API server"
  value       = module.api_server.public_ip
}
