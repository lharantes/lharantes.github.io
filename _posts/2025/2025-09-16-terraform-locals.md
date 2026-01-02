---
title: "Usando Terraform Locals para Padronização e Governança no Microsoft Azure"
date: 2025-09-16 01:00:00
categories: [Terraform]
tags: [devops, azure, terraform]
slug: 'terraform-locals'
image:
  path: /assets/img/44/44-header.webp
---

Olá pessoal! Blz?

**Terraform** é algo que você só aprende com o uso e no dia a dia, podemos até saber a teoria com o uso/estudo sempre vamos melhorando algo, eu ainda tenho muito que aprender mas gostaria de compartilhar como isso tem me ajudado e como estou fazendo para que além de ajudar algumas pessoas outras tragam formas de como eu posso melhorar e com essa troca de conhecimentos todos nós crescermos.

Ao trabalhar com Terraform para provisionar recursos em Microsoft Azure, é comum lidar com configurações repetitivas, nomes padronizados, tags, convenções de ambientes e valores derivados de múltiplas variáveis.
É nesse cenário que os **blocos Locals** se tornam essenciais para manter o ***código limpo, legível, reutilizável e fácil de manter.***

Este artigo explora o conceito de **locals**, boas práticas, exemplos reais e use cases aplicados ao Azure.

## O que são Locals no Terraform?

**Locals** são valores nomeados definidos no Terraform que permitem armazenar **expressões calculadas**, **strings compostas**, **mapas**, **listas** ou qualquer valor reutilizável dentro de um módulo.

Eles funcionam como **constantes internas**, reduzindo duplicação e melhorando a clareza do código. Podemos usar para centralizar em um único local os seguintes itens:

- Abstração de regras corporativas
- Normalização de inputs inconsistentes
- Padronização de naming convention
- Centralização de decisões condicionais
- Redução de complexidade em módulos reutilizáveis

### Exemplo básico

```hcl
locals {
  environment = "dev"
  location    = "eastus"
}
```

Uso:

```hcl
Copy code
resource "azurerm_resource_group" "rg" {
  name     = "rg-${local.environment}"
  location = local.location
}
```

> No exemplo acima estamos utilizando o valor definido dentro do **locals** do valor ***environment***, note que quando voce referencia o valor a palavra **local** fica no singular enquando na definição o bloco inicia-se no plural **locals{}**
{: .prompt-info } 

### Exemplo um pouco mais avançado

```hcl
locals {
  # Contexto geral
  environment = lower(var.environment)
  location    = lower(var.location)

  # Identidade da aplicação
  application = "portal"
  domain      = "finance"

  # Prefixo padrão corporativo
  resource_prefix = "${local.domain}-${local.application}-${local.environment}"
}
```

> No exemplo acima estamos para formar um valor que podemos usar depois nos nomes dos recursos e com isso manter em um único ponto a definição e padronização de nomenclatura.
{: .prompt-info } 

## Quando usar Locals (e quando não usar)

✅ **Use locals quando:**

- Um valor é derivado de variáveis

- Um valor é usado várias vezes

- Você precisa padronizar nomes

- Deseja centralizar regras de negócio

- Trabalha com tags, nomes e convenções

❌ **Evite usar locals quando:**

- O valor deve ser configurável externamente → use variable

- O valor precisa ser exportado → use output

- O valor é usado apenas uma vez

## Estrutura recomendada para Locals

Boas práticas indicam separar os locals em um arquivo dedicado, eu prefiro dessa forma pois você não precisa ficar a procura de onde declarou o **locals** dentro de um arquivo terraform, tendo isso separado fica muito mais fácil quando outra pessoa da equipe precisa mentar e/ou realizar updates:

```shell
📦
 ┣ 📜main.tf
 ┣ 📜locals.tf
 ┣ 📜output.tf
 ┗ 📜variables.tf
```

## Como eu tenho usado o Locals em meus projetos

Basicamente tenho usado o Terraform Locals para me ajudar na definição de nomenclatura de recursos, centralizar as TAGs e para um ambiente onde podemos ter diferentes **SKUs** para cada ambiente nos ajuda também nessa definição. Abaixo vou demonstrar de forma **básica** alguns usos que tenho feito:

### 1. Padrão Corporativo de Tags

```hcl
locals {
  governance_tags = {
    Environment   = local.environment
    Application   = local.application
    Domain        = local.domain
    ManagedBy     = "Terraform"
    CostCenter    = var.cost_center
    Owner         = var.owner
    DataClass     = var.data_classification
  }

  effective_tags = merge(
    local.governance_tags,
    var.extra_tags
  )
}
```

> No recurso que precisamos definir as TAGs colocamos apenas a linha `tags = local.effective_tags`.
{: .prompt-tip } 

### 2. Naming Convention Corporativo (Azure)

O Azure impõe restrições específicas de naming (tamanho, caracteres, unicidade global). Usar locals para encapsular isso é obrigatório em escala.

```hcl
locals {
  sanitized_prefix = replace(local.resource_prefix, "-", "")

  names = {
    resource_group = "rg-${local.resource_prefix}"
    storage        = "sa${local.sanitized_prefix}"
    key_vault      = "kv-${local.resource_prefix}"
    log_analytics  = "log-${local.resource_prefix}"
  }
}
```

> Por exemplo ao criar uma Azure Storage Account colocamos apenas a linha `name = local.names.storage`.
{: .prompt-tip } 

### 3. Definições baseadas em ambiente

Em Landing Zones baseadas no CAF, decisões variam conforme o ambiente. No exemplo abaixo para ambientes de **produção** temos um padrão e para ambientes **não produção** outros padrões:

```hcl
locals {
  backup = {
    prod = {
      backup_enabled = true
      log_retention  = 90
      sku            = "Premium"
    }
    nonprod = {
      backup_enabled = false
      log_retention  = 30
      sku            = "Standard"
    }
  }

  backup_profile = local.environment == "prod" ? local.backup.prod : local.backup.nonprod
}
```

> Para usar os valores podemos definir da seguinte forma onde for necessário:
{: .prompt-tip } 

```hcl
  backup_enabled = local.caf_profile.backup_enabled
  sku_name       = local.caf_profile.sku
```

## Concluindo!

À medida que ambientes Azure crescem em complexidade, a infraestrutura como código deixa de ser apenas um mecanismo de provisionamento e passa a representar uma **camada estratégica de governança e padronização.** Nesse contexto, **o Locals** assumem um papel fundamental ao permitir que regras corporativas, convenções de nomenclatura, políticas de tagging e decisões condicionais sejam centralizadas e declaradas de forma clara e reutilizável.

Mais do que simplificar o código, locals viabilizam consistência em escala, reduzem erros operacionais e facilitam a adoção de modelos como Azure Landing Zones e Cloud Adoption Framework. Utilizá-los de forma consciente é um dos principais diferenciais entre implementações Terraform pontuais e plataformas maduras, preparadas para crescer de forma segura, governada e sustentável.

Bom pessoal, eu tenho usado isso em alguns ambientes e acredito que possa ser bem útil a vocês!

## Artigos relacionados

<a href="https://developer.hashicorp.com/terraform/language/block/locals" target="_blank">Locals block</a>

Compartilhe o artigo com seus amigos clicando nos icones abaixo!!!