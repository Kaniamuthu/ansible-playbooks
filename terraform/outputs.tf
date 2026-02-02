output "apache_public_ips" {
  value = aws_instance.apache[*].public_ip
}

output "nginx_public_ips" {
  value = aws_instance.nginx[*].public_ip
}

output "all_servers" {
  value = concat(aws_instance.apache[*].public_ip, aws_instance.nginx[*].public_ip)
}

output "ansible_inventory_path" {
  value = local_file.ansible_inventory.filename
}
