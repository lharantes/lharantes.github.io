---
title: "Azure Landing Zone: Virtual network & Subnet com Terraform"
date: 2025-07-22 01:00:00
categories: [Devops, Terraform]
tags: [devops, azure, terraform]
slug: 'azure-landing-zone-networking'
image:
  path: assets/img/41/41-header.webp
---

Olá pessoal! Blz?

Dando continuidade a série de artigos para automatizar a configuração de uma **Azure Landing Zone** através de Terraform, hoje vamos trazer a parte que eu acredito ser **a mais importante que é a definição/estruturação da rede virtual dentro do Azure**. 

Compartilho aqui a lista de artigos até aqui: 

* <a href="https://arantes.net.br/posts/azure-landing-zone-groups-and-role-assignments/" target="_blank">Azure Landing Zone: Criar grupos no Entra ID e adicionar permissões com Terraform</a>

* <a href="https://arantes.net.br/posts/azure-landing-zone-naming-tagging/" target="_blank">Azure Landing Zone: Como Nomenclatura e Tags Definem o Sucesso da sua Nuvem</a>

Acredito ser a parte mais importante, pois uma arquitetura bem definida nos poupa trabalho, pois sabemos exatamente para onde o tráfego de rede é direcionado, onde cada recurso se comunica com qual rede, e até mesmo para problemas de conectividade fica mais fácil de detectar e resolver.

A Microsoft recomenda como melhores práticas o uso de uma rede **Hub & Spoke**. O modelo Hub-Spoke é uma das arquiteturas mais utilizadas no **Azure Virtual Network (VNet)** para organizar e isolar ambientes de rede de forma escalável e segura.

Nesse modelo, temos uma rede central (Hub) que atua como ponto de conectividade compartilhado — geralmente responsável por serviços comuns como ***VPN Gateway, Firewall, DNS, e rotas centralizadas.***
As redes periféricas (Spokes) são redes virtuais conectadas ao Hub via peering (emparelhamento), usadas para hospedar cargas de trabalho específicas, como ambientes de desenvolvimento, produção ou bancos de dados.

> O melhor cenário é ter um Firewall na rede Hub onde ele faz o roteamento do tráfego, controle de acesso das redes e comunicação entre elas, mas para esse artigo não vamos considerar essa criação, pois cada empresa pode trabalhar com um firewall diferente.
{: .prompt-tip } 

Se você quer ter uma rede no Azure bem estruturada, mas não quer gastar com um Firewall nesse momento, temos uma opção de usar uma máquina virtual Linux fazendo o papel de roteador, segue um artigo de como fazer isso: <a href="https://arantes.net.br/posts/linux-as-router-azure/" target="_blank">Rede Hub-Spoke no Azure usando o Linux como roteador (NVA - Network Virtual Appliance)</a>.

## Arquitetura proposta nesse artigo

Para ter uma arquitetura seguindo as melhores práticas Hub & Spoke implementada por Terraform teremos a seguinte arquitetura:

![azure-landing-zone-networking](/assets/img/41/01.png){: .shadow .rounded-10}

> Seguindo a arquitetura acima não iremos criar o Azure Firewall e nem as máquinas virtuais
{: .prompt-info } 

Iremos criar uma rede Hub, duas redes spokes e realizar a ligação das redes spokes com a rede hub através de peering (emparelhamento).

## Organização do Terraform ao longo dos artigos

Seguindo a mesma premissa de outros artigos e seguindo também uma melhora prática que é criar módulos reutilizáveis de recursos, para esse nosso artigo terá os módulos de: **rede virtual** e **peering (emparelhamento)**. Como a rede virtual hub e spoke no final são redes virtuais iremos usar o mesmo módulo de rede virtual para todas as redes, onde teremos distribuidos da seguinte forma:

- **main.tf**: onde será criado o/os recursos
- **variables.tf**: onde ficará as variáveis necessárias
- **output.tf**: as saídas dos recursos para serem reutilizados por outros recursos

```shell
📦modules
 ┗ 📂entra_id_groups
 ┃ ┣ 📜main.tf
 ┃ ┣ 📜output.tf
 ┃ ┗ 📜variables.tf
 ┃ 📂az_role_assignment
 ┃ ┣ 📜main.tf
 ┃ ┣ 📜output.tf
 ┃ ┗ 📜variables.tf
 ┃ 📂az_virtual_network
 ┃ ┣ 📜main.tf
 ┃ ┣ 📜output.tf
 ┃ ┗ 📜variables.tf
  ┃ 📂az_vnet_peering
 ┃ ┣ 📜main.tf
 ┃ ┣ 📜output.tf
 ┃ ┗ 📜variables.tf
```

## Módulo para criar as redes virtuais

Eu gosto de ter o módulo de virtual network em que seja possível também criar as subnets, acho que fica mais fácil de gerir pois, com somente uma chamada ao módulo você já criar uma estrutura de rede da forma que precisa.


**locals.tf** 
```hcl
locals {
  regions = {
    "brazilsouth"          = "brs"
    "Brazil South"         = "brs"
    "northeurope"          = "ne"
    "North Europe"         = "ne"
  }
  short_region = lookup(local.regions, var.location, false)
}
```

**main.tf**

```hcl
resource "azurerm_virtual_network" "vnet" {
  name                = var.environment != null ? lower("vnet-${local.short_region}-${var.service_prefix}-${var.environment}") : lower("vnet-${local.short_region}-${var.service_prefix}")
  address_space       = [var.address_space]
  location            = var.location
  resource_group_name = var.resource_group_name
  dns_servers         = var.dns_servers

  tags = var.tags
}

resource "azurerm_subnet" "this" {
  for_each = var.subnet

  name                 = each.value.name != null ? each.value.name : lower("snet-${local.short_region}-${var.service_prefix}-${each.key}")
  resource_group_name  = var.resource_group_name
  virtual_network_name = azurerm_virtual_network.vnet.name
  address_prefixes     = [each.value.address_prefixes]
  service_endpoints    = each.value.service_endpoints != null ? each.value.service_endpoints : null
}
```

**variables.tf**

```hcl
variable "environment" {
  type        = string
  description = "Environment project (dev, qua or prd)."
  default     = null
}

variable "service_prefix" {
  type        = string
  description = "Prefix or name of the project."
}

variable "location" {
  type        = string
  description = "Specifies the supported Azure location where the resource exists."
}

variable "resource_group_name" {
  type        = string
  description = "The name of the Resource Group where the resources should exist."
}

variable "tags" {
  type        = map(string)
  default     = {}
  description = "Optional tags to add to resources."
}

variable "address_space" {
  type        = string
  description = "Virtual Network address prefix"
}

variable "dns_servers" {
  type        = list(string)
  description = "Virtual Network DNS Server"
  default     = []
}

# Subnets
variable "subnet" {
  type = map(object({
    address_prefixes  = string
    name              = optional(string, null)
    service_endpoints = optional(list(string), null)
  }))
  description = "A map of subnets for Virtual Network"
}
```

**output.tf**

```hcl
output "name" {
  value = azurerm_virtual_network.vnet.name
}

output "id" {
  value = azurerm_virtual_network.vnet.id
}

output "subnet_id" {
  value = { for subnet in azurerm_subnet.this : subnet.name => subnet.id }
}
```

## Módulo para criar o peering entre as redes virtuais

O **Azure VNet Peering** é um recurso que permite **conectar duas redes virtuais (VNets)** no Azure de forma privada e direta, **usando a infraestrutura interna da Microsoft**, sem precisar passar pela internet pública. Abaixo a criação do módulo para criar o peering entre as redes virtuais:

**main.tf**

```hcl
resource "azurerm_virtual_network_peering" "aro_vnet_to_resources_vnet" {
  name                = var.peering_name
  resource_group_name = var.resource_group_name

  virtual_network_name      = var.virtual_network_name
  remote_virtual_network_id = var.remote_virtual_network_id

  allow_virtual_network_access = var.allow_virtual_network_access
  allow_forwarded_traffic      = var.allow_forwarded_traffic
  allow_gateway_transit        = var.allow_gateway_transit
  use_remote_gateways          = var.use_remote_gateways
}
```

**variables.tf**

```hcl
variable "resource_group_name" {
  type        = string
  description = "The name of the Resource Group where the resources should exist."
}

variable "virtual_network_name" {
  type = string
}

variable "remote_virtual_network_id" {
  type = string
}

variable "allow_virtual_network_access" {
  type    = bool
  default = true
}

variable "allow_forwarded_traffic" {
  type    = bool
  default = true
}

variable "allow_gateway_transit" {
  type    = bool
  default = false
}

variable "use_remote_gateways" {
  type    = bool
  default = false
}
```

## Como usar os módulos Terraform

Em Terraform temos o que é chamado de **stack** que seria o arquivo onde é feita a chamada aos módulos/recursos que você quer ter no seu deployment, para usarmos esses módulos geralmente criamos um arquivo ***main.tf***  fora da pasta módulos (root folder) onde iremos fazer a chamada aos módulos criados:

```hcl
# Modulos para as virtual networks

module "vnet_hub" {
  source = "./modules/az_virtual_network"

  service_prefix            = var.service_prefix
  location                  = azurerm_resource_group.this.location
  resource_group_name       = azurerm_resource_group.this.name
  dns_server                = ["10.0.0.0/16"]
  address_space             = var.address_space

  subnet                    = {
    resources = {
        address_prefixes    = "10.0.0.0/24"
    }
  }
}

module "vnet_spoke_01" {
  source = "./modules/az_virtual_network"

  service_prefix            = var.service_prefix
  location                  = azurerm_resource_group.this.location
  resource_group_name       = azurerm_resource_group.this.name
  dns_server                = ["10.1.0.0/16"]
  address_space             = var.address_space

  subnet                    = {
    resources = {
        address_prefixes    = "10.1.0.0/24"
        service_endpoints   = ["Microsoft.Storage", "Microsoft.ContainerRegistry"]
    }
  }
}

# Módulo para o peering entre as rede HUB e a rede SPOKE 
# Já está contemplando os 2 sentidos do peering

module "vnet_peering_hub_spoke_01" {
  source = "./modules/vnet_peering"

  resource_group_name = azurerm_resource_group.this.name
  vnet_01_name        = module.vnet_hub.virtual_network_name
  vnet_01_id          = module.vnet_hub.virtual_network_id
  vnet_02_name        = module.vnet_spoke_01.virtual_network_name
  vnet_02_id          = module.vnet_spoke_01.virtual_network_id

  allow_virtual_network_access = true
  allow_forwarded_traffic      = true
  allow_gateway_transit        = false
  use_remote_gateways          = false
}
```

> A chamado ao módulo acima uma parte está usando variáveis e outra não, seria mais para fim didático para entender como o módulo funciona, é recomendável sempre o uso de variáveis para ter uma stack agnóstica.
{: .prompt-tip } 

## Concluindo!

A criação de redes virtuais e sub-redes no Azure com Terraform oferece uma abordagem padronizada, automatizada e reproduzível para o provisionamento de infraestrutura em nuvem, reduzindo erros e aumentando a eficiência operacional.

Bom pessoal, eu tenho usado isso em alguns ambientes e acredito que possa ser bem útil a vocês!

## Artigos relacionados

<a href="https://learn.microsoft.com/pt-br/azure/architecture/networking/architecture/hub-spoke" target="_blank">Topologia de rede hub-spoke no Azure</a>

<a href="https://developer.hashicorp.com/terraform/language/modules/configuration" target="_blank">Use modules in your configuration</a>

Compartilhe o artigo com seus amigos clicando nos icones abaixo!!!