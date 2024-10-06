provider "azurerm" {
  features {}
  use_cli = true
  subscription_id = "Your sub id"
}

resource "azurerm_resource_group" "kafka_rg" {
  name = "kafka-ressource-group"
  location = "westeurope"
}

resource "azurerm_virtual_network" "kafka_vnet" {
  name = "kafka-vnet"
  address_space = ["10.0.0.0/16"]
  location = azurerm_resource_group.kafka_rg.location
  resource_group_name = azurerm_resource_group.kafka_rg.name
}

resource "azurerm_subnet" "kafka_subnet" {
  name = "kafka-subnet"
  resource_group_name = azurerm_resource_group.kafka_rg.name
  virtual_network_name = azurerm_virtual_network.kafka_vnet.name
  address_prefixes = ["10.0.1.0/24"]
}

resource "azurerm_network_security_group" "kafka_nsg" {
  name = "kafka-nsg"
  location = azurerm_resource_group.kafka_rg.location
  resource_group_name = azurerm_resource_group.kafka_rg.name
}

resource "azurerm_network_interface" "kafka_nic" {
  name = "kafka-nic"
  location = azurerm_resource_group.kafka_rg.location
  resource_group_name = azurerm_resource_group.kafka_rg.name


  ip_configuration {
    name = "kafka-ip-config"
    subnet_id = azurerm_subnet.kafka_subnet.id
    private_ip_address_allocation = "Dynamic"
  }
}

resource "azurerm_linux_virtual_machine" "kafka_vm" {
  name = "kafka-vm"
  resource_group_name = azurerm_resource_group.kafka_rg.name
  location = azurerm_resource_group.kafka_rg.location
  size = "Standard_DS1_v2"
  disable_password_authentication = false
  admin_username = "adminuser"
  admin_password = "P@ss1234!"
  network_interface_ids = [azurerm_network_interface.kafka_nic.id]

  os_disk {
    caching = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }

  source_image_reference {
    publisher = "Canonical"
    offer = "UbuntuServer"
    sku = "18.04-LTS"
    version = "latest"
  }

  provision_vm_agent = true

  custom_data = base64encode(<<-EOT
                #!/bin/bash
                sudo apt-get update
                sudo apt-get install -y default-jdk
                wget http://apache.mirrors.pair.com/kafka/3.3.1/kafka_2.12-3.3.1.tgz
                tar -xzf kafka_2.12-3.3.1.tgz
                cd kafka_2.12-3.3.1
                nohup bin/zookeeper-server-start.sh config/zookeeper.properties &
                nohup bin/kafka-server-start.sh config/server.properties &
                EOT
  )
}

output "kafka_vm_public_ip" {
  value = azurerm_network_interface.kafka_nic.private_ip_address
  
}