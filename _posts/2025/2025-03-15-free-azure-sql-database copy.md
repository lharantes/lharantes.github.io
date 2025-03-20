---
title: "Terraform: Configurando a saída de internet de VMs com Azure NAT Gateway"
date: 2025-03-15 01:33:00
categories: [Devops, Terraform]
tags: [azure, terraform, devops]
slug: 'outbound-internet-azure'
image:
  path: assets/img/34/34-header.webp
---

Olá pessoal! Blz?

Nesse artigo quero trazer a vocês a implementação do **Azure NAT Gateway** através do Terraform, usaremos em cenários onde precisamos de uma conexão com a internet e não queremos adicionar um IP público a máquina virtual ou colocá-la atrás de um Load Balancer (balanceador de carga), isso porque recentemente a Microsoft anunciou que irá retirar a saída padrão de internet nas máquinas virtuais no Microsoft Azure, a data prevista para a retirada será 30 de setembro de 2025 e você pode ler <a href="https://azure.microsoft.com/pt-br/updates?id=default-outbound-access-for-vms-in-azure-will-be-retired-transition-to-a-new-method-of-internet-access" target="_blank">aqui esse anúncio</a>, portanto, as máquinas virtuais criadas a partir dessa data não terão conectividade com a Internet e, se você precisar disso, precisará configurá-lo explicitamente.

O acesso explícito pode ser permitido através de firewalls de terceiros, por exemplo, Palo Alto, CheckPoint, Fortinet, etc, mas o Azure também fornece vários serviços que podem ajudar a controlar a conectividade de saída nativamente através dos seguintes serviços:

* **Máquinas virtuais com endereços IP públicos associados a elas.**
* **Criado dentro de uma sub-rede associada a um gateway NAT.**
* **No pool de backend de um balanceador de carga padrão com regras de saída definidas.**
* **No pool de backend de um balanceador de carga público básico.**

Segue uma imagem da documentação da Microsoft para ilustrar melhor:

![outbound-internet-azure](/assets/img/34/01.png){: .shadow .rounded-10}

Como mencionado acima, podemos ter o acesso a internet através de um Firewall ou um NVA (Network Virtual Appliance), isso é comum em ambientes corporativos onde temos uma estrutura de rede no formato **HUB-SPOKE** posicionando o Firewall/NVA na rede HUB e todo o tráfego de internet dos recursos que estão posicionados na rede spoke é direcionado para a rede hub através de uma **route table**. Com isso o controle de acesso a internet é administrado por esse recurso de maneira centralizada.

## Arquitetura proposta

Nesse artigo teremos algo mais simples, iremos configurar as máquinas virtuais para se conectarem a internet (outbound traffic) através de um **Azure NAT Gateway** e criar toda a infraestrutura através do Terraform, a arquitetura final será a seguinte:

![outbound-internet-azure](/assets/img/34/02.png){: .shadow .rounded-10}

## O que é o Azure NAT Gateway?

O Azure NAT Gateway é um serviço de conversão de endereços de rede (NAT) e é uma ótima solução para as máquinas virtuais que exigem apenas conectividade de saída.

Você pode usar o Azure NAT Gateway para permitir que todas as instâncias em uma subnet privada se conectem à Internet, mantendo-se totalmente privadas. Conexões de entrada vindas da Internet não são permitidas e somente os pacotes que chegam como pacotes de resposta a uma conexão de saída podem passar por um NAT Gateway.

Para a conectividade com a internet você deve associar ao Azure NAT Gateway um IP público ou um conjunto de IPs públicos (Prefix Public IP).

## Terraform para infraestrutura de Redes

No script Terraform abaixo iremos criar a infraestrutura de rede necessária para o nosso propósito:

- **Rede virtual e subnets**
- **NAT Gateway**
- **IP público para associar ao NAT Gateway**
- **Associar os recursos (IP púbico com o NAT Gateway e o NAT Gateway cm a subnet)**

> Não iremos usar variáveis no Terraform para o script abaixo ficar mais curto.
{: .prompt-info }

```hcl
resource "azurerm_resource_group" "rg" {
  name = "rg-lab-nat-gateway"
  location = "eastus2"
}

resource "azurerm_virtual_network" "vnet" {
  name                =  "vnet-lab-nat-gateway"
  address_space       = ["192.168.0.0/16"]
  resource_group_name = azurerm_resource_group.rg.name
  location = azurerm_resource_group.rg.location 
}

locals {
  subnets = {
    "snet-vms" = {
      address_prefix = ["192.168.0.0/24"]
    },
    "snet-app" = {
      address_prefix = ["192.168.1.0/24"]
    },
    "snet-pve" = {
      address_prefix = ["192.168.2.0/24"]
    }
  }
}

resource "azurerm_subnet" "subnet" {
  for_each             = local.subnets
  name                 = each.key
  address_prefixes     = each.value.address_prefix

  resource_group_name  = azurerm_resource_group.rg.name
  virtual_network_name = azurerm_virtual_network.vnet.name
}

resource "azurerm_public_ip" "public_ip" {
  name                = "pip-nat-gateway-vms"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  allocation_method   = "Static"
  sku                 = "Standard"
}

resource "azurerm_nat_gateway" "nat_gateway" {
  name                = "nat-gateway-vms"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
}

resource "azurerm_nat_gateway_public_ip_association" "nat_public_ip" {
  nat_gateway_id       = azurerm_nat_gateway.nat_gateway.id
  public_ip_address_id = azurerm_public_ip.public_ip.id
}

resource "azurerm_subnet_nat_gateway_association" "subnet_nat_gateway" {
  subnet_id      = azurerm_subnet.subnet["snet-vms"].id
  nat_gateway_id = azurerm_nat_gateway.nat_gateway.id
}
```

## Recursos criados

Com a execução do script temos os recursos criados e associados, na imagem abaixo temos as subnets que estão associadas com o Azure NAT Gateway, para esse exemplo associamos somente a subnet **snet-vms**, mas para associar outras subnets é só selecionar o "checkbox" da subnet que deseja associar.

![outbound-internet-azure](/assets/img/34/04.png){: .shadow .rounded-10}

<br>

Você pode consultar qual foi o IP público associado ao Azure NAT Gateway, será esse IP que as máquinas virtuais irão usar para acessar a internet.

![outbound-internet-azure](/assets/img/34/03.png){: .shadow .rounded-10}

<br>

Com uma máquina virtual criada na subnet (snet-vms) que associamos o Azure NAT Gateway testamos qual IP público está sendo usado para saída de internet e podemos ver que realmente foi o IP público que associamos ao NAT Gateway:

![outbound-internet-azure](/assets/img/34/05.png){: .shadow .rounded-10}

## Concluindo!

O uso do Azure NAT Gateway é um bom recurso para ambientes menores e que querem manter uma saída para a internet, mas é um recurso "caro", mas às vezes e dependendo do ambiente é melhor o uso do NAT Gateway por nao ter um trabalho de administração, onde você manter um firewall precisa de muito acompanhamento e administração.

Bom pessoal, eu tenho usado isso em alguns ambientes e acredito que possa ser bem útil a vocês!

## Artigos relacionados

<a href="https://learn.microsoft.com/en-us/azure/nat-gateway/nat-overview" target="_blank">O que é o Azure NAT Gateway</a>

<a href="https://learn.microsoft.com/en-us/azure/virtual-network/ip-services/default-outbound-access" target="_blank">Acesso de saída padrão no Azure</a>

Compartilhe o artigo com seus amigos clicando nos icones abaixo!!!
