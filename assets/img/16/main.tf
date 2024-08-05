# -- Nome das máquinas virtuais
locals {
  vm_names = ["vm-master", "vm-worker01", "vm-worker02"]
}

resource "azurerm_resource_group" "rg" {
  name     = "rg-cluster-k8s"
  location = "eastus"
}

resource "azurerm_virtual_network" "vnet" {
  resource_group_name = azurerm_resource_group.rg.name
  location            = azurerm_resource_group.rg.location
  name                = "vnet-cluster-k8s-eastus"
  address_space       = ["192.168.0.0/24"]
  depends_on          = [azurerm_resource_group.rg]
}

resource "azurerm_subnet" "subnet" {
  name                 = "snet-vms"
  resource_group_name  = azurerm_resource_group.rg.name
  virtual_network_name = azurerm_virtual_network.vnet.name
  address_prefixes     = ["192.168.0.0/24"]
  depends_on = [azurerm_resource_group.rg, azurerm_virtual_network.vnet]
}

resource "azurerm_public_ip" "ip_public" {
  count = length(local.vm_names)

  name                = "pip-${local.vm_names[count.index]}"
  resource_group_name = azurerm_resource_group.rg.name
  location            = azurerm_resource_group.rg.location
  allocation_method   = "Dynamic"
  domain_name_label   = local.vm_names[count.index]
}

resource "azurerm_network_interface" "nic" {
  count               = length(local.vm_names)
  name                = "nic-${local.vm_names[count.index]}"
  resource_group_name = azurerm_resource_group.rg.name
  location            = azurerm_resource_group.rg.location

  ip_configuration {
    name                          = "internal"
    subnet_id                     = azurerm_subnet.subnet.id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = azurerm_public_ip.ip_public[count.index].id
  }
}

data "http" "myip" {
  url = "http://ipv4.icanhazip.com"
}

resource "azurerm_network_security_group" "nsg" {
  name                = "nsg-cluster-k8s-subnet-vms"
  resource_group_name = azurerm_resource_group.rg.name
  location            = azurerm_resource_group.rg.location
}

resource "azurerm_network_security_rule" "rule" {
  name                        = "allow-ssh"
  priority                    = 100
  direction                   = "Inbound"
  access                      = "Allow"
  protocol                    = "Tcp"
  source_port_range           = "*"
  destination_port_range      = "22"
  source_address_prefix       = "${chomp(data.http.myip.response_body)}"
  destination_address_prefix  = "*"
  resource_group_name         = azurerm_resource_group.rg.name
  network_security_group_name = azurerm_network_security_group.nsg.name
}

resource "azurerm_subnet_network_security_group_association" "nsg_subnet" {
  subnet_id                 = azurerm_subnet.subnet.id
  network_security_group_id = azurerm_network_security_group.nsg.id
}

resource "azurerm_linux_virtual_machine" "vms" {
  count = length(local.vm_names)

  resource_group_name = azurerm_resource_group.rg.name
  location            = azurerm_resource_group.rg.location

  name                  = local.vm_names[count.index]
  size                  = "Standard_B2s"
  network_interface_ids = [azurerm_network_interface.nic[count.index].id]

  admin_username                  = "adminazure"
  admin_password                  = "P@ssw0rd@2024"
  disable_password_authentication = false

  source_image_reference {
    publisher = "Canonical"
    offer     = "0001-com-ubuntu-server-jammy"
    sku       = "22_04-lts-gen2"
    version   = "latest"
  }

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "StandardSSD_LRS"
  }

  depends_on = [azurerm_resource_group.rg, azurerm_virtual_network.vnet, azurerm_subnet.subnet]
}