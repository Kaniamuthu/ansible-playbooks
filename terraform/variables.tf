variable "aws_region" {
  description = "AWS region where resources will be created"
  type        = string
  default     = "ap-south-1"
}

variable "apache_instance_count" {
  description = "Number of Apache web server instances"
  type        = number
  default     = 2
}

variable "nginx_instance_count" {
  description = "Number of Nginx web server instances"
  type        = number
  default     = 2
}

variable "instance_type" {
  description = "EC2 instance type for web servers"
  type        = string
  default     = "t3.micro"
}

variable "ami_id" {
  description = "AMI ID for Ubuntu 22.04 LTS"
  type        = string
  default     = "ami-019715e0d74f695be"
}

variable "jenkins_ip" {
  description = "Public IP of Jenkins server"
  type        = string
}

variable "public_key_path" {
  description = "Path to SSH public key"
  type        = string
  default     = "/var/lib/jenkins/.ssh/webserver-key.pub"
}

variable "environment" {
  description = "Environment name"
  type        = string
  default     = "production"
}

variable "project_name" {
  description = "Project name for tagging"
  type        = string
  default     = "devops-webapp"
}
