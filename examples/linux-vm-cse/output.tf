output "ssh_command" {
  value       = "ssh razumovsky_r@${module.linux_vm.public_ip}"
  description = "Command to SSH into the VM"
}
