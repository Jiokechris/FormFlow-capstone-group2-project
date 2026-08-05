# ---------------------------------------------------------------------------
# WHAT IS THIS FILE?
# These are "fill in the blanks" — knobs you (or terraform.tfvars) set
# without touching the actual resource code in main.tf. Keeps main.tf
# reusable and keeps your personal values (like your IP address) out of
# the logic.
# ---------------------------------------------------------------------------

variable "project_name" {
  description = "Short name used as a prefix on every Azure resource, so you can tell what belongs to this project in the Azure Portal."
  type        = string
  default     = "formflow"
}

variable "location" {
  description = "Which Azure datacenter region to create things in. Pick one physically close to you for lower latency."
  type        = string
  default     = "westeurope"
}

variable "vm_size" {
  description = "How big/powerful the VM is (CPU/RAM). B1s is Azure's cheapest 'burstable' size — fine for a small app + MySQL for a class project."
  type        = string
  default     = "Standard_D2s_v3"
}

variable "admin_username" {
  description = "The Linux user account created on the VM that you'll SSH in as."
  type        = string
  default     = "azureuser"
}

variable "ssh_public_key_path" {
  description = "Path to YOUR public key file (not private!). Azure uses this instead of a password to let you log in — safer than passwords."
  type        = string
  default     = "~/.ssh/id_rsa.pub"
}

variable "my_ip_cidr" {
  description = "Your home/office public IP, in CIDR form (e.g. \"203.0.113.5/32\"). The firewall only allows SSH (port 22) from this address, so randoms on the internet can't even attempt to log in. Find yours at https://whatismyip.com and add /32 to the end."
  type        = string
}

variable "tags" {
  description = "Labels attached to every resource — just for organization in the Azure Portal, no functional effect."
  type        = map(string)
  default = {
    project    = "formflow"
    managed_by = "terraform"
  }
}
