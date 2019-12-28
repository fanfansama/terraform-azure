
# Create a resource group if it doesn’t exist
resource "azurerm_resource_group" "pocops" {
    name     = "poc-ops"
    location = "northeurope"

    tags = {
        environment = "Terraform Demo"
    }
}

# Create virtual network
resource "azurerm_virtual_network" "mypocnetwork" {
    name                = "myVnet"
    address_space       = ["10.0.0.0/16"]
    location            = "northeurope"
    resource_group_name = azurerm_resource_group.pocops.name

    tags = {
        environment = "Terraform Demo"
    }
}



# Create subnet
resource "azurerm_subnet" "mypocsubnet" {
    name                 = "mySubnet"
    resource_group_name  = azurerm_resource_group.pocops.name
    virtual_network_name = azurerm_virtual_network.mypocnetwork.name
    address_prefix       = "10.0.1.0/24"
}


# Create public IPs          ====================> ?????
resource "azurerm_public_ip" "mypocpublicip" {
    name                         = "myPublicIP"
    location                     = "northeurope"
    resource_group_name          = azurerm_resource_group.pocops.name
    allocation_method            = "Dynamic"

    tags = {
        environment = "Terraform Demo"
    }
}


# Create Network Security Group and rule
resource "azurerm_network_security_group" "mypocnsg" {
    name                = "myNetworkSecurityGroup"
    location            = "northeurope"
    resource_group_name = azurerm_resource_group.pocops.name
    
    security_rule {
        name                       = "SSH"
        priority                   = 1001
        direction                  = "Inbound"
        access                     = "Allow"
        protocol                   = "Tcp"
        source_port_range          = "*"
        destination_port_range     = "22"
        source_address_prefix      = "91.168.221.158"
        destination_address_prefix = "*"
    }

    tags = {
        environment = "Terraform Demo"
    }
}


# Create network interface
resource "azurerm_network_interface" "mypocnic" {
    name                      = "myNIC"
    location                  = "northeurope"
    resource_group_name       = azurerm_resource_group.pocops.name
    network_security_group_id = azurerm_network_security_group.mypocnsg.id

    enable_ip_forwarding     = false

    ip_configuration {
        name                          = "myNicConfiguration"
        subnet_id                     = azurerm_subnet.mypocsubnet.id
        private_ip_address_allocation = "Dynamic"
        public_ip_address_id          = azurerm_public_ip.mypocpublicip.id
    }

    tags = {
        environment = "Terraform Demo"
    }
}


# Generate random text for a unique storage account name
resource "random_id" "randomId" {
    keepers = {
        # Generate a new ID only when a new resource group is defined
        resource_group = azurerm_resource_group.pocops.name
    }
    
    byte_length = 8
}



# Create storage account for boot diagnostics       ==============>  ?????
resource "azurerm_storage_account" "mystorageaccount" {
    name                        = "diag${random_id.randomId.hex}"
    resource_group_name         = azurerm_resource_group.pocops.name
    location                    = "northeurope"
    account_tier                = "Standard"
    account_replication_type    = "LRS"

    tags = {
        environment = "Terraform Demo"
    }
}

## location : francecentral

# Create virtual machine
resource "azurerm_virtual_machine" "mypocvm" {
    name                  = "myVM"
    location              = "northeurope"
    resource_group_name   = azurerm_resource_group.pocops.name
    network_interface_ids = [azurerm_network_interface.mypocnic.id]
    vm_size               = "Standard_B1s"

    storage_os_disk {
        name              = "myOsDisk"
        caching           = "ReadWrite"
        create_option     = "FromImage"
        managed_disk_type = "Standard_LRS"
    }

    storage_image_reference {
        publisher = "Canonical"
        offer     = "UbuntuServer"
        sku       = "18.04-LTS"
        version   = "latest"
    }

    os_profile {
        computer_name  = "myvm"
        admin_username = "myadvisoryOps"
        admin_password = "Bonbon-2-Noel"
    }

    os_profile_linux_config {
         disable_password_authentication = false
#        disable_password_authentication = true
#        ssh_keys {
#            path     = "/home/vagrant/.ssh/authorized_keys"
#            key_data = "ssh-rsa AAAAB3Nz{snip}hwhqT9h"
#        }
    }

    boot_diagnostics {
        enabled = "true"
        storage_uri = azurerm_storage_account.mystorageaccount.primary_blob_endpoint
    }

    tags = {
        environment = "Terraform Demo"
    }
}







