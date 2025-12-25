---
title: "Azure Landing Zone: Azure Policy com Terraform"
date: 2025-08-29 01:00:00
categories: [Devops, Terraform]
tags: [devops, azure, terraform]
slug: 'azure-landing-azure-policy'
image:
  path: /assets/img/43/43-header.webp
---

Olá pessoal! Blz?

Dando continuidade a série de artigos para automatizar a configuração de uma **Azure Landing Zone** através de Terraform, neste artigo, vamos ver como associar **Azure Policies** a algum escopo, seja nossa ***assinatura, grupo de gerenciamente, grupo de recurso***. A ideia é mostrar, de maneira prática, como a infraestrutura como código (IaC) facilita a automação, padronização e manutenção dos seus ambientes, evitando tarefas manuais repetitivas e aumentando a confiabilidade das suas operações na nuvem.

> Geralmente, dependendo do tamanho do ambiente a melhor forma seja habilitar essas políticas no **grupo de gerenciamento** e a cada **nova assinatura** herdará essas políticas, mas vou mostrar como podemos fazer isso com Terraform e depois você pode decidir se usará isso por Terraform ou diretamente no portal do Azure.
{: .prompt-info }

Compartilho aqui a lista de artigos até aqui para criarmos nossa **Azure Landing Zone com Terraform**: 

- <a href="https://arantes.net.br/posts/azure-landing-zone-groups-and-role-assignments/" target="_blank">Azure Landing Zone: Criar grupos no Entra ID e adicionar permissões com Terraform</a>

- <a href="https://arantes.net.br/posts/azure-landing-zone-naming-tagging/" target="_blank">Azure Landing Zone: Como Nomenclatura e Tags Definem o Sucesso da sua Nuvem</a>

- <a href="https://arantes.net.br/posts/azure-landing-zone-networking/" target="_blank">Azure Landing Zone: Virtual network & Subnet com Terraform</a>

- <a href="https://arantes.net.br/posts/azure-landing-recovery-service-vault-backup-policy/" target="_blank">Azure Landing Zone: Azure Backup com Terraform</a>

## O que são as Azure Policies

**Azure Policies** é um serviço nativo de governança do Microsoft Azure que permite definir, aplicar e monitorar regras automáticas para controlar a criação, configuração e conformidade dos recursos na nuvem. Por meio dessas políticas, as organizações conseguem padronizar ambientes, reforçar requisitos de segurança, atender normas de compliance e reduzir riscos operacionais causados por configurações inadequadas.

Em termos simples: ***elas controlam o que pode ou não ser criado e como os recursos devem ser configurados no Azure.***

As **Azure Policies** são aplicadas em um escopo, os escopos (scopes) em uma Azure Policy definem onde uma política será aplicada dentro da hierarquia do Azure. Eles determinam quais recursos serão avaliados e impactados pela policy, permitindo aplicar regras de governança de forma granular ou abrangente, conforme a necessidade da organização. Em resumo devemos realizar a seguinte pergunta: ***“Em qual nível da estrutura do Azure essa policy deve valer?”***

Uma Azure Policy pode ser atribuída aos seguintes escopos:

- **Management Group:** Escopo mais alto da hierarquia, ideal para políticas globais, como padrões de segurança e compliance corporativo.

- **Subscription:** Aplica a policy a todos os recursos dentro de uma assinatura específica, muito usado para separar ambientes como dev, homologação e produção.

- **Resource Group:** Permite aplicar políticas a um conjunto específico de recursos, útil para regras específicas de aplicações ou times.

- **Resource (recurso individual):** Escopo mais granular, normalmente usado em cenários pontuais ou exceções controladas.

Podemos usar Azure Policies já pré-definidas no Microsoft Azure ou podemos personalizar e criarmos nossas próprias políticas. Para usarmos as políticas existentes com Terraform podemos usar o ID para referenciar em nosso código e para isso usamos as **Policies Definitions**.

## O que são Policy Definitions no Azure?

Policy Definitions são os blocos fundamentais do Azure Policy. Elas descrevem, de forma declarativa, quais regras devem ser avaliadas, em quais condições e qual ação (effect) deve ser aplicada quando um recurso não estiver em conformidade.

Em outras palavras, a policy definition define o que é permitido, proibido ou obrigatório  no ambiente Azure.

Uma policy definition é escrita em JSON e geralmente inclui:

- Condições (if)
  - Determinam quais recursos ou propriedades serão avaliados
  - Ex.: tipo de recurso, localização, SKU, tags

- Efeito (then / effect)
  - Define a ação tomada quando a condição é atendida
  - Ex.: Deny, Audit, Modify, DeployIfNotExists

- Parâmetros (opcional)
  - Tornam a policy reutilizável e flexível
  - Ex.: lista de regiões permitidas

## Como criar Azure Policies com Terraform

Nesta seção, veremos como utilizar o Terraform para criar e gerenciar Azure Policies, abordando desde a definição da policy (Policy Definition) até sua atribuição (Policy Assignment). Ao adotar essa abordagem, é possível padronizar regras de governança, reduzir erros manuais e integrar o controle de conformidade diretamente aos pipelines de entrega de infraestrutura.

No exemplo abaixo iremos abordar como criar uma **Azure Policy Definition** personalizada com um código JSON para forçar uma Azure TAG obrigatória em nosso ambiente cloud:

```hcl
resource "azurerm_policy_definition" "policy" {
  name         = "enforceTagPolicy"
  policy_type  = "Custom"
  mode         = "All"
  display_name = "Request a specific tag on Resources Groups"

  policy_rule = <<POLICY_RULE
    {
        "if": {
            "allOf": [
            {
                "field": "type",
                "equals": "Microsoft.Resources/subscriptions/resourceGroups"
            },
            {
                "anyOf": [
                {
                    "field": "[concat('tags[', parameters('tagName'), ']')]",
                    "exists": false
                },
                {
                    "field": "[concat('tags[', parameters('tagName'), ']')]",
                    "equals": ""
                }
                ]
            }
            ]
        },
        "then": {
            "effect": "deny"
        }
    }
  POLICY_RULE

  parameters = <<PARAMETERS
    {
        "tagName": {
            "type": "String",
            "metadata": {
            "displayName": "Tag Name",
            "description": "Name of the tag, such as 'CostCenter'"
            }
        }
    }
  PARAMETERS
}
```

Mas e se quisermos usar alguma Azure Policy já existente precisamos saber do ID, eu geralmente exporto uma lista de ID, descrição e o nome para identificar usando um comando powershell para isso:

```powershell
Get-AzPolicyDefinition | Select-Object -Property Name, DisplayName, Description, PolicyType, Metadata | Format-List
```

Se precisarmos usar um filtro para selecionar um tipo de política, filtrando por categoria podemos usar o seguinte comando:

```powershell
Get-AzPolicyDefinition | Select-Object -Property Name, DisplayName, Description, PolicyType, Metadata | Where-Object {$_.metadata.category -eq 'Tags'} 
```

Teriamos como saída do comando acima onde filtramos a categoria **Tag** uma relaçao das políticas existentes dentro dessa categoria, abaixo uma pequena amostra do resultado do comando exportado para um arquivo csv:

```plaitext
Name;DisplayName;Description;PolicyType;Metadata
b27a0cbd-a167-4dfa-ae64-4337be671140;Inherit a tag from the subscription;Adds or replaces the specified tag and value from the containing subscription when any resource is created or updated. Existing resources can be remediated by triggering a remediation task.;BuiltIn;@{category=Tags
cd3aa116-8754-49c9-a813-ad46512ece54;Inherit a tag from the resource group;Adds or replaces the specified tag and value from the parent resource group when any resource is created or updated. Existing resources can be remediated by triggering a remediation task.;BuiltIn;@{version=1.0.0
cd8dc879-a2ae-43c3-8211-1877c5755064;[Deprecated]: Allow resource creation if 'department' tag set;Allows resource creation only if the 'department' tag is set;BuiltIn;@{version=1.0.0-deprecated
d157c373-a6c4-483d-aaad-570756956268;Add or replace a tag on resource groups;Adds or replaces the specified tag and value when any resource group is created or updated. Existing resource groups can be remediated by triggering a remediation task.;BuiltIn;@{version=1.0.0
ea3f2387-9b95-492a-a190-fcdc54f7b070;Inherit a tag from the resource group if missing;Adds the specified tag with its value from the parent resource group when any resource missing this tag is created or updated. Existing resources can be remediated by triggering a remediation task. If the tag exists with a different value it will not be changed.;BuiltIn;@{version=1.0.0
247cb490-7575-4ecc-82a2-08a1a62f79e6;Require a tag CentroCusto on Resource Groups;;Custom;@{category=Tags
f4cb980f-56e2-4f0d-bdcc-12aeb7917870;Require a specific tag and value on Resource Groups;;Custom;@{category=Tags
``` 

> Lembrando que o primeiro campo é o ID que devemos referenciar no Terraform
{: .prompt-tip } 

Como já temos o código (ID) da política devemos usar o exemplo abaixo para associar a **política** a um **escopo**: 

```hcl
resource "azurerm_subscription_policy_assignment" "enforceTagPolicy" {
  name                 = "enforceTagPolicy"
  policy_definition_id = "f4cb980f-56e2-4f0d-bdcc-12aeb7917870"
  subscription_id      = "xxxxx-xxxxx-xxxxx-xxxxxx-xxxxxxxxxx-xxxx"
  display_name = "Request a specific tag on Resources Groups"
  description =  "Request a specific tag on Resources Groups"
}
``` 

> No exemplo acima estamo aplicando uma política no escopo da **Assinatura (Subscription)**
{: .prompt-info } 

## Concluindo!

O **Azure Policy** é um componente essencial da governança no Azure, permitindo aplicar regras de forma consistente e automatizada em toda a hierarquia de recursos. Com ele, é possível garantir padronização, segurança e conformidade, reduzindo erros manuais e riscos operacionais.

A combinação de **Policy Definitions, escopos bem definidos e automação com Terraform** torna a governança mais eficiente, escalável e alinhada às práticas de Infrastructure as Code. Adotar Azure Policy não é apenas uma questão de controle, mas um passo estratégico para manter ambientes Azure organizados e sustentáveis.

Bom pessoal, eu tenho usado isso em alguns ambientes e acredito que possa ser bem útil a vocês!

## Artigos relacionados

<a href="https://learn.microsoft.com/en-us/azure/governance/policy/overview" target="_blank">Azure Policy</a>

Compartilhe o artigo com seus amigos clicando nos icones abaixo!!!