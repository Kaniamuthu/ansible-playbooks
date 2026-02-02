terraform {
  required_version = ">= 1.0"
  
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region = var.aws_region
}

###################
# VPC Configuration
###################
resource "aws_vpc" "main" {
  cidr_block           = "10.0.0.0/16"
  enable_dns_hostnames = true
  enable_dns_support   = true

  tags = {
    Name        = "${var.project_name}-vpc"
    Environment = var.environment
    ManagedBy   = "Terraform"
  }
}

resource "aws_internet_gateway" "main" {
  vpc_id = aws_vpc.main.id

  tags = {
    Name = "${var.project_name}-igw"
  }
}

resource "aws_subnet" "public" {
  vpc_id                  = aws_vpc.main.id
  cidr_block              = "10.0.1.0/24"
  availability_zone       = "${var.aws_region}a"
  map_public_ip_on_launch = true

  tags = {
    Name = "${var.project_name}-public-subnet"
  }
}

resource "aws_route_table" "public" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.main.id
  }

  tags = {
    Name = "${var.project_name}-public-rt"
  }
}

resource "aws_route_table_association" "public" {
  subnet_id      = aws_subnet.public.id
  route_table_id = aws_route_table.public.id
}

###################
# Security Groups
###################
resource "aws_security_group" "web" {
  name        = "${var.project_name}-web-sg"
  description = "Web server SG"
  vpc_id      = aws_vpc.main.id

  # HTTP
  ingress {
    description = "HTTP from anywhere"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # HTTPS
  ingress {
    description = "HTTPS from anywhere"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # SSH from Jenkins only
  ingress {
    description = "SSH from Jenkins"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["${var.jenkins_ip}/32"]
  }

  # Outbound all
  egress {
    description = "Allow all outbound"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "${var.project_name}-web-sg"
  }
}

###################
# Key Pair
###################
resource "aws_key_pair" "deployer" {
  key_name   = "webserver-key"
  public_key = file(var.public_key_path)

  tags = {
    Name = "webserver-deploy-key"
  }
}

###################
# EC2 Instances - Apache
###################
resource "aws_instance" "apache" {
  count                  = var.apache_instance_count
  ami                    = var.ami_id
  instance_type          = var.instance_type
  key_name               = aws_key_pair.deployer.key_name
  vpc_security_group_ids = [aws_security_group.web.id]
  subnet_id              = aws_subnet.public.id

  user_data = <<-EOF
              #!/bin/bash
              apt-get update -y
              apt-get upgrade -y
              apt-get install -y apache2 python3 python3-pip
              systemctl enable apache2
              systemctl start apache2
              echo "<h1>Apache Server ${count.index + 1}</h1>" > /var/www/html/index.html
EOF

  tags = {
    Name        = "apache-server-${count.index + 1}"
    Role        = "webserver"
    Environment = var.environment
    ManagedBy   = "Terraform"
  }
}

###################
# EC2 Instances - Nginx
###################
resource "aws_instance" "nginx" {
  count                  = var.nginx_instance_count
  ami                    = var.ami_id
  instance_type          = var.instance_type
  key_name               = aws_key_pair.deployer.key_name
  vpc_security_group_ids = [aws_security_group.web.id]
  subnet_id              = aws_subnet.public.id

  user_data = <<-EOF
              #!/bin/bash
              apt-get update -y
              apt-get upgrade -y
              apt-get install -y nginx python3 python3-pip
              systemctl enable nginx
              systemctl start nginx
              echo "<h1>Nginx Server ${count.index + 1}</h1>" > /var/www/html/index.html
EOF

  tags = {
    Name        = "nginx-server-${count.index + 1}"
    Role        = "webserver"
    Environment = var.environment
    ManagedBy   = "Terraform"
  }
}

###################
# Generate Ansible Inventory
###################
resource "local_file" "ansible_inventory" {
  content = templatefile("${path.module}/templates/inventory.tftpl", {
    apache_ips = aws_instance.apache[*].public_ip
    nginx_ips  = aws_instance.nginx[*].public_ip
  })
  filename = "${path.module}/ansible-playbooks/inventory/hosts.ini"

  depends_on = [aws_instance.apache, aws_instance.nginx]
}
