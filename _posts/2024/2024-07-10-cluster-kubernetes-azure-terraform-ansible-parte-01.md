---
#layout: post
title: 'Cluster Kubernetes com Terraform e Ansible - parte 1' 
date: 2024-07-10 00:01:00
categories: ['Azure', 'Devops', 'Kubernetes', 'Ansible']
tags: ['Azure', 'Devops', 'Kubernetes', 'Ansible']
slug: 'cluster-kubernetes-azure-terraform-ansible-parte-01'
image:
  path: /assets/img/16/16-header.webp
---

Olá Pessoal! Blz?

No momento que escrevo esse artigo estou estudando para o exame <a href="https://training.linuxfoundation.org/certification/certified-kubernetes-administrator-cka/" target="_blank">CKA (Certified Kubernetes Administrator)</a>, tentando entender melhor o mundo de micro serviços e toda a estrutura por trás de um cluster Kubernetes, e devido a grande quantidade de cagadas durante o estudo já precisei recriar o ambiente algumas vezes !!! 😆😆

Como a instalação do cluster é um dos itens do exame e com certeza é uma coisa que preciso conhecer, não é de todo ruim, porém, para unir o útil ao "necessário" eu decidi automatizar a criação do cluster usando Terraform para fazer o deploy das máquinas virtuais no Microsoft Azure e o Ansible para realizar a instalação e configuração dos pacotes necessários dentro das máquinas virtuais, ou seja, o terraform para prover a infraestrutura e o ansible para realizar toda a configuração.

Eu sei que vocês podem estar pensando que eu poderia/deveria criar as máquinas virtuais no meu computador usando o Virtual Box, Vagrant ou outra ferramenta, como tenho créditos no Microsoft Azure para testes e laboratórios, como o meu dia a dia é Microsoft Azure, Terraform e estou tentando aprimorar os conhecimentos em Ansible, decidi seguir dessa maneira criando todo o ambiente na cloud.

Irei dividir esse artigo em duas partes, a primeira parte com o provisionamento da infraestrutura com terraform e na segunda parte a configuração dos servidores para compor o cluster kubernetes, faremos essa configuração usando o ansible para automatizar essa tarefa.

## Planejamento do ambiente

Para instalar e configurar as máquinas virtuais segui a documentação oficial que é bem clara e ajuda muito, deixarei os links abaixo:

- <a href="https://v1-29.docs.kubernetes.io/docs/setup/production-environment/tools/kubeadm/install-kubeadm/" target="_blank">Installing kubeadm</a>
- <a href="https://v1-29.docs.kubernetes.io/docs/setup/production-environment/container-runtimes/" target="_blank">Installing Container Runtimes</a>

Como nesse primeiro momento eu não irei focar em HA (High Availability) terei um cluster com 03 máquinas virtuais **Ubuntu Server 22.04** divididas da seguinte forma:

- **Master Node (Control Plane)**
- **Worker Node 01**
- **Worker node 02**

![azure-terraform](/assets/img/16/01.png)

O fluxo que pensei em seguir seria o básico digamos assim, código da infra no Terraform e playbook do Ansible e executar um shell script diretamente na linha de comando do meu computador para executar os 2 comandos (terraform apply e ansible-playbook), mas posso futuramente criar uma pipeline no Azure Devops ou GitHub Actions para ficar mais "automático".

## Códigos Terraform par criar o ambiente no Azure

Como mencionado acima, usaremos o terraform para deploy da infraestrutura do cluster, para a criação de máquinas virtuais no Microsoft Azure precisamos de alguns recursos, como: **Rede virtual, Subnet, NSG (Network security group) e IPs públicos** para as máquinas virtuais pois não tenho uma VPN estabelecida com a cloud.

> A melhor maneira de usar terraform é sem dúvida utilizando módulos e variáveis para serem reaproveitados, mas para o artigo deixarei os valores ***"hard coded"***. O código melhor estruturado você pode consultar no meu GitHub: <a href="https://github.com/lharantes/terraform-azure" target="_blank">lharantes/terraform-azure</a>
{: .prompt-info }

### 1 - Criando o Resource Group

Criaremos todos os recursos na região **EastUs** que é uma região barata e com isso conseguimos economizar um pouco já que como é um ambiente de estudos a latência não é importante:

```hcl
# -- Nome das máquinas virtuais
locals {
  vm_names = ["vm-master", "vm-worker01", "vm-worker02"]
}

resource "azurerm_resource_group" "rg" {
  name     = "rg-cluster-k8s"
  location = "eastus"
}
```

### 2 - Rede virtual, subnet, IPs públicos e interfaces de rede

A rede virtual e subnet para as máquinas virtuais usaremos o endereço de rede **192.168.0.0/24**:

```hcl
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
```

### 3 - NSG (Network Security Group) e associar o nsg na subnet criada acima

Como as máquinas virtuais terão IPs públicos e estarão expostas na internet, deixarei configurado para pegar o IP público do meu computador e colocar isso NSG, permitindo o acesso as máquinas virtuais somente quando a origem for do meu IP. Vou deixar o link do artigo onde demonstrei o funcionamento disso: <a href="https://blog.arantes.net.br/posts/terraform-own-public-ip/" target="_blank">Adicionando o próprio IP público a uma regra de entrada com Terraform.</a>

```hcl
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

```

### 4 - Máquinas virtuais Linux

Pessoal, uma ressalva no trecho de código das máquinas virtuais, eu uso somente chave ssh para me conectar as minhas máquinas virtuais, nesse artigo deixarei somente a opção de se conectar com senha, mas caso deseje acessar com chave ssh, é só retirar o campo **admin_password**, alterar o campo **disable_password_authentication** para **true** e adicionar o trecho: 

```hcl
  admin_ssh_key {
    username   = "adminuser"
    public_key = file("~/.ssh/id_rsa.pub")
  }
```

Aqui o código para criar 03 máquinas virtuais Ubuntu Server 22.04:

```hcl
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
```

> Com os trechos de código acima, copie todos e salve em um único arquivo com extensão **.tf**, ou você pode baixar o arquivo pronto <a href="/assets/img/16/main.tf" target="_blank">nesse link.</a>
{: .prompt-tip }

## Criando os recursos

Para criarmos os recursos devemos executar os comandos:

- Use o comando **terraform init** no terminal para inicializar o terraform e baixar os arquivos de configuração.
- Com o comando **terraform plan** temos uma prévia das alterações que serão feitas em seu ambiente Azure.

![azure-terraform](/assets/img/16/03.png)

- Por fim, execute o comando **terraform apply** para implantar a infraestrutura no Azure. O Terraform executará o plano e fará as alterações no seu ambiente Azure.

![azure-terraform](/assets/img/16/04.png)

<hr>
Após a execução dos comandos acima podemos ver no Microsoft Azure os recursos criados na assinatura, e com isso já temos nosso ambiente todo provisionado:
<br>

![azure-terraform](/assets/img/16/02.png)

## Concluindo!

Como falei acima esse artigo será dividido em 2 partes, essa primeira parte criamos os recursos usando IaC (Infraestructure as Code) com a ferramenta **Terraform**, no próximo artigo trarei a parte 2 que é a configuração das máquinas virtuais para compor o cluster Kubernetes, como instalação e configuração dos pacotes necessários.
<hr>

Compartilhe o artigo com seus amigos clicando nos ícones abaixo!!!
<hr>