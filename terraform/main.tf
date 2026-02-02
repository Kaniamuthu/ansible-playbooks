resource "aws_instance" "apache" {
  ami           = "ami-005ffcc4bd3136964"
  instance_type = "t2.micro"
  key_name      = "webserver-key"

  tags = {
    Name = "apache-server"
  }
}

resource "aws_instance" "nginx" {
  ami           = "ami-005ffcc4bd3136964"
  instance_type = "t2.micro"
  key_name      = "webserver-key"

  tags = {
    Name = "nginx-server"
  }
}

resource "local_file" "ansible_inventory" {
  filename = "../ansible-playbooks/inventory/hosts.ini"

  content = <<EOF
[apache_servers]
${aws_instance.apache.public_ip} ansible_user=ubuntu

[nginx_servers]
${aws_instance.nginx.public_ip} ansible_user=ubuntu
EOF
}
