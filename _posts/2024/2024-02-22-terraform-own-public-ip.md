---
title: 'Adicionando o próprio IP público a uma regra de entrada com Terraform'
date: 2024-02-22 10:33:00
slug: 'terraform-own-public-ip'
categories: ['Azure', 'Terraform']
tags: ['Azure', 'Terraform']
image:
  path: /assets/img/01/01-header.webp
---

Olá pessoal! Blz?

Quando estamos aprendendo uma nova cloud, seja Microsoft Azure, AWS, GCP ou outras clouds, acredito que o primeiro recurso que nos vem a mente seja: “Vou criar uma máquina virtual para ver como é!”, ainda mais quem vem do mundo on premises e criar máquinas virtuais é uma rotina cotidiana.

E quando estamos estudando Terraform começamos criando ambientes de estudos e laboratórios, inclusive recursos que podem estar expostos a internet como por exemplo uma máquina virtual na porta 3389 (RDP) ou 22 (SSH).

O intuito é que mesmo usando os recursos para testes, que esse permaneça de maneira segura, possibilitando a conexão somente do computador que estamos usando para executar o código Terraform.

Mas o que quero demonstrar aqui não se aplica somente para máquinas virtuais, pode ser usados em outros recursos onde temos a possibilidade de restringir o acesso através de definição de IP públicos para conexão de entrada.

Temos o serviço <a href="https://icanhazip.com/" target="_blank">icanhazip</a> que nos retorna nosso IP púbico atual e com esse seerviço diremos ao Terraform para usar esse retorno como nosso IP Público de origem.

![icanhazip](/assets/img/01/02.png)

## Script Terraform

Bom, chega de conversa e vamos por a mão na massa, e o código completo voce pode acessar em meu repositório GitHub: <a href="https://github.com/lharantes/get-our-public-ip-terraform" target="_blank">lharantes/get-our-public-ip-terraform</a>

[link-github]: https://github.com/lharantes/get-our-public-ip-terraform

```hcl
terraform {
  required_providers {
    http = {
      source = "hashicorp/http"
      version = "3.4.1"
    }
  }
}
provider azurerm {
  features {}
}

data "http" "myip" {
  url = "http://ipv4.icanhazip.com"
}
```

O código acima pode ser usado para qualquer provider cloud: Azure, AWS, GCP e etc, mas nesse artigo irei usar para criar um Azure NSG (Network Security Group) mas com a idéia voce pode adaptar a Cloud e recurso que necessita:

No trecho de código abaixo, na linha 19 eu associo o IP público com o resultado do bloco **data.http.myip** acima pegando o retorno **response_body**: “${chomp(data.http.myip.response_body)}”. O uso do **chomp** é para retirar todo espaço em branco que possa haver.

```hcl
resource "azurerm_resource_group" "rg" {
  name     = "rg-exemplo"
  location = "West Europe"
}

resource "azurerm_network_security_group" "nsg" {
  name                = "nsg_exemplo"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name

  security_rule {
    name                       = "AllowInboundRDP"
    priority                   = 100
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "3389"
    source_address_prefix      ="${chomp(data.http.myip.response_body)}"
    destination_address_prefix = "*"
  }
}
```

Após executar o código Terraform o nosso IP público é adicionado a regra de entrada do NSG como pode abaixo na coluna “source”:

![NSG](/assets/img/01/01.png)

## Concluindo!

Como deixar uma máquina virtual exposta para internet é muito perigoso, o uso acima restringe o acesso somente do computador que executamos o código e mesmo sendo uma máquina de testes/laboratório aumentamos um pouco a segurança.

<hr>
Bom pessoal, espero que tenha gostado e que esse artigo seja util a voces!
<br>

Compartilhe o artigo com seus amigos clicando nos icones abaixo!!!
<hr>