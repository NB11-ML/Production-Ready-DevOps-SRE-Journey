output "environment_details" {
  description = "Active Workspace Deployment Details"
  value = {
    active_workspace = local.environment
    vpc_id           = module.vpc.vpc_id
    instance_id      = module.ec2_instance.instance_id
    server_public_ip = module.ec2_instance.public_ip
  }
}