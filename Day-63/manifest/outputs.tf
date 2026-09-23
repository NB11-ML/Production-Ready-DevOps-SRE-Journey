output "vpc_id" {
    value = aws_vpc.terraformvpc.id 
}

output "subnet_id" {
    value = aws_subnet.terraformsubnet.id
}

output "instance_id" {
    value = aws_instance.terraformec2.id
}

output "instance_public_ip" {
    value = aws_instance.terraformec2.public_ip
}

output "instance_public_dns" {
    value = aws_instance.terraformec2.public_dns
}

output "security_group_id" {
    value = aws_security_group.terraformsg.id
}