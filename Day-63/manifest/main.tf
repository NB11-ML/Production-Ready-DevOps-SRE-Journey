locals {
  name_prefix = "${var.project_name}-${var.environment}"
  common_tags = {
    Project     = var.project_name
    Environment = var.environment
    ManagedBy   = "Terraform"
  }
}

data "aws_ami" "amazon_linux"{
  most_recent = true
  owners = ["amazon"]
  filter {
    name = "name"
    values = ["amzn2-ami-hvm-*-gp2"]
  }
}

data "aws_availability_zones" "available" {}


resource "aws_vpc" "terraformvpc" {
  cidr_block = var.vpc_cidr
  tags = {
    Name = "${local.name_prefix}-VPC"
  }
}

resource "aws_subnet" "terraformsubnet" {
  vpc_id                  = aws_vpc.terraformvpc.id
  cidr_block              = var.subnet_cidr             #"10.0.1.0/24"
  availability_zone       = var.region                  #"us-east-1a"
  map_public_ip_on_launch = true
  tags = {
    Name = "TerraWeek-Public-Subnet"
  }
}

resource "aws_internet_gateway" "terraformgateway" {
  vpc_id = aws_vpc.terraformvpc.id
}

resource "aws_route_table" "terraformroute" {
  vpc_id = aws_vpc.terraformvpc.id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.terraformgateway.id
  }
}

resource "aws_route_table_association" "terraform_route_table" {
  route_table_id = aws_route_table.terraformroute.id
  subnet_id      = aws_subnet.terraformsubnet.id
}

resource "aws_security_group" "terraformsg" {
    name = "terraformsecuritygroup"
    description = "Controls ingress and egress ports"
    vpc_id = aws_vpc.terraformvpc.id


  dynamic "ingress" {
    for_each = var.allowed_ports
    content {
      from_port = ingress.value
      to_port = ingress.value
      protocol = "tcp"
      cidr_blocks = ["0.0.0.0/0"]
    }
  }

  /*  ingress{
        cidr_blocks = ["0.0.0.0/0"]
        from_port = 80
        to_port = 80
        protocol = "tcp"
    }
    ingress{
        cidr_blocks = ["0.0.0.0/0"]
        from_port = 22
        to_port = 22
        protocol = "tcp"
    } 
*/
    egress{
        from_port = 0
        to_port = 0
        protocol = "-1"
        cidr_blocks = ["0.0.0.0/0"]
    }

    tags = {
        Name = "TerraWeek-SG"
    }
}

resource "aws_instance" "terraformec2" {
    #ami = "ami-0fef201115eefe936"
    #ami = "ami-0b6d9d3d33ba97d99" #Added to check lifecycle
    ami = data.aws_ami.amazon_linux.id
    availability_zone = data.aws_availability_zones.available.names[0]

    #instance_type = var.instance_type #"t3.micro"
    instance_type = var.environment == "prod" ? "t3.small" : "t2.micro"

    subnet_id = aws_subnet.terraformsubnet.id
    vpc_security_group_ids =[aws_security_group.terraformsg.id]

    associate_public_ip_address = true

    lifecycle {
        create_before_destroy = true
    }
    tags = {
      Name = "TerraWeek-Server" 
    }
}
resource "aws_s3_bucket" "terraformweekbucket" {
    bucket = "terraformweekbucket22092026"
    depends_on = [ aws_instance.terraformec2 ]
    
}