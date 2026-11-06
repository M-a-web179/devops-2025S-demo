resource "local_file" "inventory" {
  filename        = "${path.module}/../ansible/inventory.ini"
  file_permission = "0644"
  content         = <<-EOT
    [app]
    nairobipulse ansible_host=${var.server_host} ansible_user=${var.ssh_user} ansible_ssh_private_key_file=${var.ssh_key_path}

    [app:vars]
    ansible_python_interpreter=/usr/bin/python3
  EOT
}

output "inventory_path" {
  value = local_file.inventory.filename
}