---
title: 'Azure Application Gateway path based routing com Terraform'
date: 2024-02-15 10:33:00
slug: 'appgw-path-based'
categories:  ['Azure', 'Terraform']
tags:  ['Azure', 'Terraform', 'Application Gateway']
image:
  path: assets/img/03/03-header.webp
---

Olá pessoal! Blz?

Esses dias em um projeto esbarrei em uma dificuldade de criar um Azure Application Gateway com regras do tipo “Path-based” e a documentação do Terraform não me ajudou muito e/ou eu que não soube como interpreta-la. E com isso decidir escrever um artigo de como superei essa dificuldade.

## Um pouco sobre o funcionamento do Application Gateway

Primeiro, vou dar uma pequena introdução ao que iremos desenvolver aqui e o conceito básico de Azure Application Gateway, deixrei também links no final do artigo sobre o recurso.

O Azure Application Gateway é um balanceador de carga de tráfego da Web que atua na camada 7 do modelo OSI, que com isso permite que você gerencie o tráfego para seus aplicativos Web. Os balanceadores de carga tradicionais operam na camada de transporte (camada OSI 4 – TCP e UDP).

O Azure Application Gateway pode tomar decisões de destinos com base em outros atributos de uma solicitação HTTP de acordo com o caminho de URI. Por exemplo, você pode encaminhar o tráfego com base na URL de entrada. Portanto, se /imagens estiver na URL de entrada, você poderá encaminhar o tráfego para um backend pool específico de servidores/WebApps configurado para as imagens. Se /video estiver na URL, esse tráfego será encaminhado para outro backend pool otimizado para vídeos. Abaixo uma imagem que nos ajuda a entender melhor.

![appgw](/assets/img/03/01.png)

Agora vamos ao código Terraform para a solução da imagem acima, para isso precisamos criar alguns recursos necessários para a criação do Azure Application Gateway, como: Grupo de Recurso, a Rede Virtual e a Subrede e o IP Público.

## Código Terraform para criarmos os recursos

O código usado nesse artigo já com a melhor prática usando variáveis pode ser encontrado nesse link do GitHub: <a href="https://github.com/lharantes/appgw.pathbased.terraform" target="_blank">lharantes/appgw.pathbased.terraform</a>

> Para a crição do Application Gateway precisamos de alguns recursos básicos antes
{: .prompt-info }

```hcl
resource "azurerm_resource_group" "rg" {
  name     = "RG-APP-GATEWAY"
  location = "West Europe"
}

resource "azurerm_virtual_network" "vnet" {
  name                = "vnet-westeurope-app-gw"
  resource_group_name = azurerm_resource_group.rg.name
  location            = azurerm_resource_group.rg.location
  address_space       = ["192.168.0.0/16"]
}

resource "azurerm_subnet" "subnet" {
  name                 = "snet-app-gw"
  resource_group_name  = azurerm_resource_group.rg.name
  virtual_network_name = azurerm_virtual_network.vnet.name
  address_prefixes     = ["192.168.0.0/24"]
}

resource "azurerm_public_ip" "pip" {
  name                = "pip-westeurope-app-gw"
  resource_group_name = azurerm_resource_group.rg.name
  location            = azurerm_resource_group.rg.location
  allocation_method   = "Static"
  sku                 = "Standard"
}
```
Com isso ja temos os recursos básicos para começarmos a escrever o código para criar o Azure Application Gateway.

```hcl
locals {
  agw_backend_address_pools = {
    imagens = {
      backend_address_pool_name  = "backend-pool-imagens"
      backend_address_pool_fqdns = ["vm-01-imagens"]
    }
    videos = {
      backend_address_pool_name  = "backend-pool-videos"
      backend_address_pool_fqdns = ["vm-02-videos"]
    }
    url_default = {
      backend_address_pool_name  = "backend-pool-default"
      backend_address_pool_fqdns = ["vm-03-default"]
    }
  }
}
resource "azurerm_application_gateway" "appgw" {
  name                = "appgw-westeurope-01"
  resource_group_name = azurerm_resource_group.rg.name
  location            = azurerm_resource_group.rg.location
  sku {
    name     = "Standard_v2"
    tier     = "Standard_v2"
    capacity = 1
  }
  gateway_ip_configuration {
    name      = "my-gateway-ip-configuration"
    subnet_id = azurerm_subnet.subnet.id
  }
  frontend_port {
    name = "FE-PORT-HTTP"
    port = 80
  }
  frontend_ip_configuration {
    name                 = "FE-Public-IP"
    public_ip_address_id = azurerm_public_ip.pip.id
  }
  dynamic "backend_address_pool" {
    for_each = local.agw_backend_address_pools
    content {
     name  = backend_address_pool.value["backend_address_pool_name"]
     fqdns = backend_address_pool.value["backend_address_pool_fqdns"]
    }
  }
  backend_http_settings {
    name                  = "HTTP-Default"
    cookie_based_affinity = "Disabled"
    port                  = 80
    protocol              = "Http"
  }
  http_listener {
    name                           = "LT-HTTP"
    frontend_ip_configuration_name = "FE-Public-IP"
    frontend_port_name             = "FE-PORT-HTTP"
    protocol                       = "Http"
  }
  request_routing_rule {
    name               = "Rule-Http"
    rule_type          = "PathBasedRouting"
    http_listener_name = "LT-HTTP"
    priority           = 10
    url_path_map_name  = "path_map"
  }
  url_path_map {
    name                               = "path_map"
    default_backend_address_pool_name  = "backend-pool-default"
    default_backend_http_settings_name = "HTTP-Default"
    path_rule {
      name                       = "imagens-path"
      paths                      = ["/imagens/*"]
      backend_address_pool_name  = "backend-pool-imagens"
      backend_http_settings_name = "HTTP-Default"
    }
    path_rule {
      name                       = "videos-path"
      paths                      = ["/videos/*"]
      backend_address_pool_name  = "backend-pool-videos"
      backend_http_settings_name = "HTTP-Default"
    }
  }
}
```

O que eu não havia entendido como deveria usar e referenciar era o bloco **url_path_map**, onde eu tinha que criar os blocos de código com os caminhos (path) personalizados que eu precisava e para qual backend pool seria direcionado.

Com o **url_path_map** todo o trafego é direcionado de acordo com a URI para o servidor especifico, por exemplo: **site.com.br/videos/video01.mp4**, usando coringas como o que usamos no exemplo **"/videos/*"**, tudo o que estiver dentro da pasta videos sera representado pelo coringa e direcionado para o servidor correspondente.

Após a construção do bloco url_path_map eu precisava referencia-lo no bloco **request_routing_rule** com o campo **url_path_map_name** com o nome do bloco url_path_map que criamos.

O Backend Settings terá a seguinte configuração olhando pelo portal do Azure:

![appgw](/assets/img/03/02.png)

## Concluindo!

O uso de path-based routing é muito utilizado quando não queremos disponibilizar o mesmo conteudo em todos os servidores que hospedam um site ou aplicação, com isso diminuimos a carga de processamento dos servidores, deixando servidores especificos para cada tipo de conteúdo.

## Artigos relacionados

<a href="https://learn.microsoft.com/en-us/azure/application-gateway/overview" target="_blank">O que é Azure Application Gateway?</a>

<hr>
Bom pessoal, espero que tenha gostado e que esse artigo seja útil a vocês!


Compartilhe o artigo com seus amigos clicando nos icones abaixo!!!
<hr>