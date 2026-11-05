variable "server_host" {
  type    = string
  default = "127.0.0.1"
}

variable "ssh_user" {
  type = string
}

variable "ssh_key_path" {
  type    = string
  default = "~/.ssh/devops-ansible"
}