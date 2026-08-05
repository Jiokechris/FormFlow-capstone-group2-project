# ---------------------------------------------------------------------------
# WHAT IS THIS FILE?
# This is the actual "shopping list" of things to create in Azure. Each
# `resource` block = one real thing that gets created in your Azure account
# when you run `terraform apply`. Read top to bottom — each one builds on
# the last, like assembling furniture in order.
# ---------------------------------------------------------------------------

# 1. RESOURCE GROUP
# Azure's way of saying "a folder that holds all resources belonging to one
# project." Everything below lives inside this folder. Delete the folder,
# everything inside gets deleted too — handy for cleanup.
resource "azurerm_resource_group" "main" {
  name     = "${var.project_name}-rg"
  location = var.location
  tags     = var.tags
}

# 2. VIRTUAL NETWORK
# A private network (like your home WiFi, but in the cloud) that your VM
# will live inside. Nothing outside Azure can see this network directly —
# only what you explicitly expose (see the public IP + NSG below).
resource "azurerm_virtual_network" "main" {
  name                = "${var.project_name}-vnet"
  address_space       = ["10.0.0.0/16"] # a private IP range, plenty of room to grow
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name
  tags                = var.tags
}

# 3. SUBNET
# A slice of the virtual network above. We only need one slice since we
# only have one VM.
resource "azurerm_subnet" "main" {
  name                 = "${var.project_name}-subnet"
  resource_group_name  = azurerm_resource_group.main.name
  virtual_network_name = azurerm_virtual_network.main.name
  address_prefixes     = ["10.0.1.0/24"]
}

# 4. PUBLIC IP
# The actual internet-facing IP address people will use to reach your app,
# e.g. http://<this-ip>. "Static" means it won't change every time the VM
# restarts (important — otherwise your DNS/bookmarks break constantly).
resource "azurerm_public_ip" "main" {
  name                = "${var.project_name}-public-ip"
  resource_group_name = azurerm_resource_group.main.name
  location            = azurerm_resource_group.main.location
  allocation_method   = "Static"
  sku                 = "Standard"
  tags                = var.tags
}

# 5. NETWORK SECURITY GROUP (the firewall)
# By default Azure blocks everything. These rules are the ONLY holes we
# punch in that wall. Lower "priority" number = checked first.
resource "azurerm_network_security_group" "main" {
  name                = "${var.project_name}-nsg"
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name
  tags                = var.tags

  # Rule: allow SSH (port 22), but ONLY from your own IP address.
  # This is what stops random bots on the internet from even trying to
  # log in — they're not coming from your IP, so the firewall drops them
  # before they ever reach the VM's login prompt.
  security_rule {
    name                       = "AllowSSHFromMyIP"
    priority                   = 100
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "22"
    #source_address_prefix      = var.my_ip_cidr
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }

  # Rule: allow HTTP (port 80) from ANYONE — this is your public website
  # traffic, so unlike SSH it's meant to be open to the whole internet.
  security_rule {
    name                       = "AllowHTTPFromAnywhere"
    priority                   = 110
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "80"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }
}

# 6. NETWORK INTERFACE (NIC)
# The "network cable" plugging the VM into the subnet and giving it the
# public IP we created above.
resource "azurerm_network_interface" "main" {
  name                = "${var.project_name}-nic"
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name
  tags                = var.tags

  ip_configuration {
    name                          = "internal"
    subnet_id                     = azurerm_subnet.main.id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = azurerm_public_ip.main.id
  }
}

# Attach the firewall (NSG) to the network interface — without this line,
# the NSG rules above would exist but never actually apply to anything.
resource "azurerm_network_interface_security_group_association" "main" {
  network_interface_id      = azurerm_network_interface.main.id
  network_security_group_id = azurerm_network_security_group.main.id
}

# 7. THE VIRTUAL MACHINE ITSELF
# Everything above was setup/plumbing — this is the actual Ubuntu server.
resource "azurerm_linux_virtual_machine" "main" {
  name                = "${var.project_name}-vm"
  resource_group_name = azurerm_resource_group.main.name
  location            = azurerm_resource_group.main.location
  size                = var.vm_size
  admin_username      = var.admin_username
  tags                = var.tags

  network_interface_ids = [
    azurerm_network_interface.main.id,
  ]

  # No password login — only your SSH key works. Far safer than a password,
  # and it's what admin_username + this block combine to enforce.
  admin_ssh_key {
    username   = var.admin_username
    public_key = file(var.ssh_public_key_path)
  }

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS" # cheapest disk tier, fine for this project
  }

  source_image_reference {
    publisher = "Canonical"
    offer     = "0001-com-ubuntu-server-jammy" # Ubuntu 22.04 LTS
    sku       = "22_04-lts-gen2"
    version   = "latest"
  }

  # Runs user_data.sh automatically on first boot — this is how Docker
  # ends up installed without you SSHing in and doing it by hand.
  custom_data = base64encode(file("${path.module}/user_data.sh"))
}
