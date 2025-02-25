#################################################################################################################
# RESOURCE GROUP
#################################################################################################################

resource "azurerm_resource_group" "public" {
  location = var.location
  name     = "rg-cse-remote-exec-${var.prefix}"
  tags     = var.tags
}

#################################################################################################################
# VNET AND SUBNET
#################################################################################################################

resource "azurerm_virtual_network" "public" {
  name                = "vnet-${var.prefix}"
  address_space       = ["10.10.0.0/24"]
  location            = azurerm_resource_group.public.location
  resource_group_name = azurerm_resource_group.public.name
}

resource "azurerm_subnet" "internal" {
  name                 = "subnet-${var.prefix}"
  resource_group_name  = azurerm_resource_group.public.name
  virtual_network_name = azurerm_virtual_network.public.name
  address_prefixes     = ["10.10.0.0/26"]
}

#################################################################################################################
# UBUNTU VIRTUAL MACHINE
#################################################################################################################

module "linux_vm" {
  source                      = "github.com/kolosovpetro/AzureLinuxVMTerraform.git//modules/ubuntu-vm-key-auth?ref=master"
  resource_group_name         = azurerm_resource_group.public.name
  resource_group_location     = azurerm_resource_group.public.location
  subnet_id                   = azurerm_subnet.internal.id
  ip_configuration_name       = "ipc-key-auth-vm-${var.prefix}"
  network_interface_name      = "nic-key-auth-vm-${var.prefix}"
  os_profile_computer_name    = "vm-key-auth-${var.prefix}"
  storage_os_disk_name        = "osdisk-key-auth-vm-${var.prefix}"
  vm_name                     = "vm-key-auth-${var.prefix}"
  public_ip_name              = "pip-key-auth-vm-${var.prefix}"
  os_profile_admin_public_key = file("${path.root}/id_rsa.pub")
  os_profile_admin_username   = "razumovsky_r"
  network_security_group_id   = azurerm_network_security_group.public.id
  vm_size                     = "Standard_B2ms"
}


#################################################################################################################
# LINUX PROVISIONER
#################################################################################################################

module "linux_provisioner" {
  source                       = "../../modules/provisioner-linux"
  os_profile_admin_username    = "razumovsky_r"
  private_key_path             = "${path.root}/id_rsa"
  provision_script_destination = "/tmp/Install-Linux-Node-Exporter.sh"
  provision_script_path        = "${path.root}/scripts/Upgrade-System-Packages.sh"
  vm_public_ip_address         = module.linux_vm.public_ip

  depends_on = [
    azurerm_network_security_group.public,
    azurerm_network_security_rule.allow_ssh,
    module.linux_vm
  ]
}
