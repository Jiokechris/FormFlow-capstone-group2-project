# ---------------------------------------------------------------------------
# WHAT IS THIS FILE?
# After `terraform apply` finishes, Terraform can print out useful info
# instead of you having to dig through the Azure Portal. These are the
# values you'll actually need: the IP to visit in a browser, and the IP
# to SSH into (same address, different use).
# ---------------------------------------------------------------------------

output "vm_public_ip" {
  description = "The public IP address of the VM — visit http://<this> in a browser once the app is deployed."
  value       = azurerm_public_ip.main.ip_address
}

output "ssh_command" {
  description = "Copy-paste this to log into the VM."
  value       = "ssh ${var.admin_username}@${azurerm_public_ip.main.ip_address}"
}
