# Azure Provider source and version being used
terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "=3.0.0"
    }
  }
}
# Configure the Microsoft Azure Provider
provider "azurerm"  {
  features{}
  subscription_id   = "98d245a3-6198-4d11-b689-397118e4e967"
  client_id         = "e4cd8dc2-0329-4584-aba5-1ce59139ad35"
  client_secret     = "hAx8Q~9j_2GKdIzLBGNRK_7czAsZDRS2UqW54dxV"
  tenant_id         = "c4bca605-7506-48d3-8dd7-8d0b3f150bff"  
}
#create resource group
resource "azurerm_resource_group" "rg" {
name      = "RG-Non-PROD-E1"
location  = "East US"
}

resource "azurerm_virtual_network" "vnet1" {
  name                    = "VNET-Non-PROD-E1"
  location                = azurerm_resource_group.rg.location
  resource_group_name     = azurerm_resource_group.rg.name
  address_space           = ["10.10.0.0/16"]
    
}

resource "azurerm_subnet" "subnet1" {
name                    = "SNET-APP-Non-PROD-E1"
resource_group_name     = azurerm_resource_group.rg.name
virtual_network_name    = azurerm_virtual_network.vnet1.name
address_prefixes        = ["10.10.1.0/24"]
  
}

resource "azurerm_network_security_group" "nsg1" {
  name                = "NSG-Non-PROD-E1"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  
}
#NOTE: this allow RDP from any network
resource "azurerm_network_security_rule" "example" {
  name                        = "rdp"
  resource_group_name         = azurerm_resource_group.rg.name
  network_security_group_name = azurerm_network_security_group.nsg1.name
  priority                    = 100
  direction                   = "Inbound"
  access                      = "Allow"
  protocol                    = "Tcp"
  source_port_range           = "*"
  destination_port_range      = "3389"
  source_address_prefix       = "*"
  destination_address_prefix  = "*"
  
}

resource "azurerm_subnet_network_security_group_association" "nsg_subnet_assoc1" {
  subnet_id                 = azurerm_subnet.subnet1.id
  network_security_group_id = azurerm_network_security_group.nsg1.id
}

resource "azurerm_network_interface" "nic1" {
  name                = "VM01-nic"
  location            = azurerm_resource_group.rg.location  
  resource_group_name = azurerm_resource_group.rg.name

  ip_configuration {
    name                          = "internal"
    subnet_id                     = azurerm_subnet.subnet1.id
    private_ip_address_allocation = "Dynamic"
  }
}

resource "azurerm_windows_virtual_machine" "machine" {
  name                = "VM01"
  resource_group_name = azurerm_resource_group.rg.name
  location            = azurerm_resource_group.rg.location
  size                = "Standard_B1s"
  admin_username      = "adminuser"
  admin_password      = "T0TheCloud22"
  network_interface_ids = [azurerm_network_interface.nic1.id]

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }

  source_image_reference {
    publisher = "MicrosoftWindowsServer"
    offer     = "WindowsServer"
    sku       = "2016-Datacenter"
    version   = "latest"
  }
}