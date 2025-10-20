---
title: "Azure Landing Zone: Como Nomenclatura e Tags Definem o Sucesso da sua Nuvem"
date: 2025-07-07 01:00:00
categories: [Devops, Terraform]
tags: [devops, azure, terraform]
slug: 'azure-landing-zone-naming-tagging'
image:
  path: /assets/img/40/40-header.webp
---

Olá pessoal! Blz?

Na sequência do artigo passado onde falamos sobre <a href="https://arantes.net.br/posts/azure-landing-zone-groups-and-role-assignments/" target="_blank">Azure Landing Zone: criar grupos no Entra ID e adicionar permissões com Terraform</a> o assunto de hoje será sobre a importância da definição e/ou estratégia bem definida para uma Nomenclatura e Tagging para recursos Microsoft Azure.

Em ambientes de nuvem cada vez mais complexos, a organização tornou-se um elemento crítico para o sucesso operacional. No Microsoft Azure, onde recursos são provisionados dinamicamente e em escala, a definição de uma nomenclatura consistente para os recursos não são apenas uma recomendação de boas práticas, mas uma necessidade estratégica para empresas que buscam eficiência, segurança e controle de custos.

Nesse artigo quero trazer alguns exemplos de uma política de nomenclatura e tagging que podemos forçar quando usamos Terraform para criar os recursos e com isso ter o tão sonhado ambiente organizado.

## Nomenclatura no Azure

Recomendamos adotar uma nomenclatura para compor os nomes de recursos a partir de informações sobre cada recurso para auxiliar na identificação rápida do tipo de recurso, sua carga de trabalho associada, seu ambiente de implantação e região do Azure onde está hospedado o recurso.
Abaixo um exemplo de um recurso de IP público para uma carga SharePoint de produção que reside na região Oeste dos EUA:

![azure-landing-naming-tagging](/assets/img/40/01.png){: .shadow .rounded-10}

**Como podemos ver no exemplo acima o nome do recurso é um conjunto de partes que identificam o propósito do recurso**.

**A primeira parte seria uma abreviação do tipo de recurso, na tabela abaixo podemos ver alguns exemplos:**

| Recurso | Tipo recurso | Abreviação |
| ------------- | ------------ | --------- |
| Managed disk (OS) | `Microsoft.Compute/disks` | `osdisk` |
| Managed disk (data) | `Microsoft.Compute/disks` | `disk` |
| Virtual machine | `Microsoft.Compute/virtualMachines` | `vm` |
| Resource group | `Microsoft.Resources/resourceGroups` | `rg` |
| Virtual network | `Microsoft.Network/virtualNetworks` | `vnet`|
| Virtual network subnet | `Microsoft.Network/virtualNetworks/subnets` | `snet`|

> Esses são somente alguns exemplos, a lista completa você pode consultar em <a href="https://learn.microsoft.com/en-us/azure/cloud-adoption-framework/ready/azure-best-practices/resource-abbreviations" target="_blank">Recomendações de abreviações para recursos do Azure</a>.
{: .prompt-tip }

**Para o ambiente (environment) podemos usar os seguintes exemplos:**

| Ambiente | Abreviação |
| ------------- | ------------ | --------- |
| Produção | prod ou prd |
| Homologação | hml |
| Desenvolvimento | dev |
| Prova de conceito | poc |

**Para regiões podemos usar algumas abreviações:**

| Região | Abreviação |
| ------------- | ------------ | --------- |
| Brazil South | brs |
| East US | eus |
| East US 2 | eus2 |
| North Europe | ne |
| UK South | uks |

> Aqui eu mantenho um arquivo <a href="https://arantes.net.br/assets/img/40/locals.tf" target="_blank">locals.tf </a> para meus projetos Terraform.
{: .prompt-tip }

## Nomenclatura de recursos Azure com Terraform

Como já temos e/ou deveríamos ter definido a nomenclatura que iremos adotar, o próximo passo é como controlar isso usando o Terraform. Em meus projetos Terraform eu costumo ter algumas variáveis que me ajudam a compor os nomes e tags, além de valores obrigatórios para criar recursos como a região.

No exemplo abaixo no campo `name` temos um exemplo de código Terraform para definir o nome de uma Rede Virtual no Azure, para isso concatenamos algumas palavras como: **vnet**, **abreviação da região**, **um nome curto do projeto ou propósito** e o **ambiente (dev, hml ou prd)**. A função `lower` é para deixar tudo minúsculo:

`lower("vnet-${lookup(local.regions, var.location, false)}-${var.project}-${var.environment}")`

```hcl
locals {
  regions = {
    "brazilsouth"          = "brs"
    "Brazil South"         = "brs"
    "northeurope"          = "ne"
    "North Europe"         = "ne"
  }
}

resource "azurerm_virtual_network" "vnet" {
  name                = lower("vnet-${lookup(local.regions, var.location, false)}-${var.project}-${var.environment}")
  address_space       = [var.vnet_address_prefix]
  location            = var.location
  resource_group_name = var.resource_group_name
  dns_servers         = var.dns_servers
  tags = var.tags
}
```

Para meus recursos de Rede Virtual no Azure eu adotei as seguintes regras de nomenclatura:

* Todas as letras minúsculas.
* Deve iniciar com o prefixo **vnet** e para isso eu deixo como no código acima para forçar que fique dessa maneira.
* A região que o recurso será criado e com isso eu faço um `lookup` no locals para buscar a abreviação da região.
* Para qual projeto aquele recurso pertence e para isso eu tenho uma variável para indicar o nome do projeto.
* Ambiente do recurso, podendo ser alguns dos exemplos que mencionei acima.

> Seguindo o código de exemplo **forçamos** o padrão de nomenclatura que definimos e quem executar esse código não conseguirá alterar isso.
{: .prompt-info }

## Definindo as TAGs obrigatórias no Azure

No Microsoft Azure, o uso de **tags em recursos** é uma prática recomendada de governança e organização. Tags são pares **chave-valor** que você aplica a recursos, grupos de recursos ou assinaturas.

Para forçar o uso de TAGs podemos usar Azure Policy para forçar isso, mas o objetivo aqui é definir um padrão já que estamos falando de **Azure Landing Zone**, e um ponto importante é ter isso pensado e definido.

Aqui estão os principais motivos para utilizá-las:

**Organização e Classificação**

* Permite classificar recursos por **departamento**, **ambiente (dev/hml/prod)**, **projeto**, **aplicação**.

**Gestão de Custos**

* É possível aplicar tags como **"CostCenter=TI"** ou **"Projeto=AppX"**, permitindo gerar relatórios de custos detalhados por área/projeto.

* O Azure Cost Management utiliza tags para segmentar e analisar os gastos.

**Governança e Conformidade**

* Ajuda a aplicar políticas de conformidade: por exemplo, exigir que todo recurso tenha a tag **"Owner"** para identificar o responsável.

* Pode ser usado em conjunto com o Azure Policy para garantir consistência.

**Automação**

* Scripts, runbooks e pipelines de CI/CD podem usar tags para filtrar recursos e aplicar ações específicas.

* Exemplo: desligar automaticamente todas as VMs com o horário em uma tag **"Stop=20:00"**.

> O mais importante é definir quais serão as TAGs obrigatórias que faz sentido para o seu ambiente, definido isso o mais importante é tentar automatizar a sua utilização.
{: .prompt-tip }

## Aplicando TAGs com Terraform

Diferentemente do nome dos recursos não temos muito como controlar ou forçar o valor das TAGs, em Terraform realmente precisamos que esse input seja fornecido pelo usuário através de uma ou mais variáveis.

Vou citar alguns exemplos de como podemos trabalhar com as TAGs em Terraform, e de acordo com a exigência de cada projeto você pode ir alterando e/ou adaptando.

Em um primeiro exemplo, para formar o nome do recurso usamos as variáveis **project** e **environment** então podemos usar o seguinte código Terraform para uma mistura de valores através de variáveis e valores usados através de um `locals`:

```hcl
locals {
  tags_common = {
    Owner        = "Luiz Henrique"
    Departamento = "TI"
  }
}

# adicionalmente em cada recurso criado pelo terraform
...
  tags = merge(local.tags_common, {
    Ambiente     = var.environment
    Projeto      = var.project
  })
```

Podemos definir as TAGs através de uma única variável e obrigar o preenchimento:

```hcl
variable "tags_common" {
  type = object({
    Ambiente     = string
    Projeto      = string
    Owner        = string
    Departamento = string
  })
}
```

Para o exemplo acima teremos que ter um input da variável **tags_coomon** conforme o exemplo abaixo:

```hcl
tags_common = { 
  Ambiente     = "dev""
  Projeto      = "AppX"
  Owner        = "Luiz Henrique"
  Departamento = "TI"
}
```

## Concluindo!

Ter uma política de nomenclatura e de uso de tags no Microsoft Azure ajuda a manter o ambiente organizado, facilita a gestão dos recursos e evita retrabalho. Com nomes e tags padronizados, fica mais simples identificar recursos, controlar custos, aplicar automações e garantir que todos sigam as mesmas regras. Definir essas práticas logo no início é um passo simples que traz benefícios duradouros para a administração da nuvem.

Usar o Terraform para ajudar nesse controle além de evitar erros manuais ajuda a manter um controle e padrão.

Bom pessoal, eu tenho usado isso em alguns ambientes e acredito que possa ser bem útil a vocês!

## Artigos relacionados

<a href="https://learn.microsoft.com/en-us/azure/cloud-adoption-framework/ready/azure-best-practices/resource-naming" target="_blank">Define your naming convention</a>

<a href="https://learn.microsoft.com/en-us/azure/cloud-adoption-framework/ready/azure-best-practices/resource-tagging" target="_blank">Define your tagging strategy</a>

Compartilhe o artigo com seus amigos clicando nos icones abaixo!!!