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
# WINDOWS VIRTUAL MACHINE
#################################################################################################################

module "windows_vm" {
  source                      = "git::git@github.com:kolosovpetro/AzureWindowsVMTerraform.git//modules/windows-vm?ref=master"
  ip_configuration_name       = "ipc-${var.prefix}"
  network_interface_name      = "nic-${var.prefix}"
  network_security_group_id   = azurerm_network_security_group.public.id
  os_profile_admin_password   = trimspace(file("${path.root}/password.txt"))
  os_profile_admin_username   = "razumovsky_r"
  os_profile_computer_name    = "vm-${var.prefix}"
  public_ip_name              = "pip-${var.prefix}"
  location                    = azurerm_resource_group.public.location
  resource_group_name         = azurerm_resource_group.public.name
  storage_image_reference_sku = "2022-Datacenter"
  storage_os_disk_name        = "osdisk-${var.prefix}"
  subnet_id                   = azurerm_subnet.internal.id
  vm_name                     = "vm-${var.prefix}"
}
#################################################################################################################
# STORAGE ACCOUNT AND CONTAINER
#################################################################################################################

resource "azurerm_storage_account" "public" {
  name                     = "stscewin${var.prefix}"
  resource_group_name      = azurerm_resource_group.public.name
  location                 = azurerm_resource_group.public.location
  account_tier             = "Standard"
  account_replication_type = "GRS"
}

resource "azurerm_storage_container" "public" {
  name                  = "contscewin${var.prefix}"
  storage_account_id    = azurerm_storage_account.public.id
  container_access_type = "blob"
}

#################################################################################################################
# CUSTOM SCRIPT EXTENSION
#################################################################################################################

module "cse_linux" {
  source                                = "../../modules/custom-script-extension-windows"
  custom_script_extension_file_name     = "Configure-WinRM.ps1"
  custom_script_extension_path          = "${path.root}/scripts/Configure-WinRM.ps1"
  extension_name                        = "Configure-WinRM"
  storage_account_name                  = azurerm_storage_account.public.name
  storage_container_name                = azurerm_storage_container.public.name
  virtual_machine_id                    = module.windows_vm.id
}
