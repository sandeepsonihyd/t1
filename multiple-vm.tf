# Create (and display) an SSH key
resource "tls_private_key" "mySSH" {
  algorithm = "RSA"
  rsa_bits  = 4096
}

resource "local_file" "private_key" {
  content         = tls_private_key.mySSH.private_key_pem
  filename        = "azure.pem"
  file_permission = "0600"
}

# Create virtual machine
resource "azurerm_linux_virtual_machine" "my_terraform_vm" {
  count = 2
  name                  = format("myVM%s-vm", count.index)
  location              = azurerm_resource_group.rg.location
  resource_group_name   = azurerm_resource_group.rg.name
  network_interface_ids = [azurerm_network_interface.myNICs[count.index].id]
  size                  = "Standard_DS1_v2"

  os_disk {
    name                 = format("myVM%s-OsDisk",count.index)
    caching              = "ReadWrite"
    storage_account_type = "Premium_LRS"
  }

  source_image_reference {
    publisher = "Canonical"
    offer     = "UbuntuServer"
    sku       = "18.04-LTS"
    version   = "latest"
  }

  computer_name                   = "myvm"
  admin_username                  = "azureuser"
  admin_password                  = "Password@123"
  disable_password_authentication = false

  admin_ssh_key {
    username   = "azureuser"
    public_key = tls_private_key.mySSH.public_key_openssh
  }
  depends_on = [
    azurerm_network_interface_security_group_association.example
  ]
}

output "virtual_machine_ip" {
  value = [
    for vm in azurerm_linux_virtual_machine.my_terraform_vm : vm.public_ip_address
  ]
  depends_on = [
    azurerm_linux_virtual_machine.my_terraform_vm
  ]
}
