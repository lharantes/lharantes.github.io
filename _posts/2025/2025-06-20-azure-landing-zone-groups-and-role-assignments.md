---
title: "Azure Landing Zone: criar grupos no Entra ID e adicionar permissões com Terraform"
date: 2025-06-20 01:00:00
categories: [Devops, Terraform]
tags: [devops, azure, terraform]
slug: 'azure-landing-zone-groups-and-role-assignments'
image:
  path: assets/img/39/39-header.webp
---

Olá pessoal! Blz?

Eu quero trazer uma série de artigos em que tenho trabalhado que é a criação de código Terraform para setup de uma **Azure Landing Zone**, pouco tempo atrás a Microsoft disponibilizou o <a href="https://learn.microsoft.com/en-us/azure/cloud-adoption-framework/ready/landing-zone/deploy-landing-zones-with-terraform" target="_blank">Aceleradores de Landing Zone do Azure para Bicep e Terraform</a>, mas eu preferi criar meus próprios módulos conforme vou precisando e moldando eles da forma que preciso, com isso me forço a estudar e praticar o uso de Terraform.

Teremos um conjunto de artigos onde no final teremos a possibilidade de automatizar uma Azure Landing Zone e moldar isso como precisamos. Talvez esses meus artigos sejam para ambientes pequenos e médios, onde não temos uma Azure Landing Zone tão segregada com várias Assinaturas e Grupos de Gerenciamentos.

O primeiro artigo gostaria de demonstrar como ***criar um grupo no Microsoft Entra ID, adicionar membros a esse grupo e depois adicionar permissões Azure RBAC a esse grupo*** tudo isso através de Terraform.

> No último artigo vou "juntar" os módulos que criamos no decorrer dessa série e montar um projeto Terraform para automatizar a criação da Azure Landing Zone.
{: .prompt-tip }

Você pode ir conferindo o código no <a href="https://github.com/lharantes/azure-landing-zone-terraform" target="_blank">repositório no GitHub</a>.


## O que é uma Azure Landing Zone

Uma Azure Landing Zone é um conjunto de práticas, configurações e recursos pré-projetados no Microsoft Azure que serve como ponto de partida para implantar cargas de trabalho na nuvem de forma segura, escalável e alinhada a boas práticas de governança.

Você pode pensar nela como o terreno preparado antes de construir uma cidade: já vem com ruas, luz, água e regras de zoneamento. Na nuvem, isso significa que já existem configurações prontas para:

- **Estrutura de rede (VNets, sub-redes, conectividade híbrida etc.)**

- **Segurança (políticas, RBAC, controle de acesso e criptografia)**

- **Governança (Azure Policy, tagging e gerenciamento de assinaturas)**

- **Monitoramento (Log Analytics, alertas e diagnósticos)**

- **Identidade (integração com Azure AD, roles e MFA)**

O principal objetivo é garantir que todas as futuras cargas de trabalho implantadas no Azure sigam um padrão seguro, bem organizado e em conformidade com os requisitos da empresa ou regulatórios.

Abaixo uma imagem da Microsoft onde demonstra o uso de uma Azure Landing Zone:

![azure-landing-zone-groups-and-role-assignments](/assets/img/39/01.svg){: .shadow .rounded-10}

## Role-based access control (Azure RBAC) 

O gerenciamento de acesso para recursos de nuvem é uma função crítica para qualquer organização que esteja usando a nuvem. O RBAC do Azure (controle de acesso baseado em funções do Azure) ajuda a gerenciar quem tem acesso aos recursos do Azure, o que pode fazer com esses recursos e a quais áreas tem acesso.

Nesse artigo como mencionei acima vamos criar as permissões da forma que esperamos que ela seja gerenciada, ou seja, através de grupos e adicionando os usuários a esse grupo. Usar grupos para conceder permissões no Azure é considerado uma boa prática porque traz organização, segurança e eficiência, pois seria somente adicionar e/ou remover usuários dos grupos quando ele não mais precisa daquela permissão.

No Azure, você atribui permissões em um escopo e um escopo em quatro níveis: **grupo de gerenciamento**, **assinatura**, **grupo de recursos** ou **recurso**. Os escopos são estruturados em uma relação pai-filho. Você pode atribuir funções em qualquer um desses níveis de escopo que o nível abaixo irá herdar essas permissões.

![azure-landing-zone-groups-and-role-assignments](/assets/img/39/02.png){: .shadow .rounded-10}

> Aqui estou dando as dicas de como fazer, procure estruturar isso da melhor forma para o seu ambiente, **SE** no seu ambiente a melhor opção é atribuir a permissão no **Grupo de Gerenciamento** então faça, tem ambientes que atribuir a permissão na Assinatura é o melhor cenário. Lembre-se antes de criticar: **"Cada ambiente tem a sua particularidade"**.
{: .prompt-info }

Abaixo algumas sugestões de como eu organizo os grupos e permissões iniciais, depois cada caso é um caso e vai adaptando conforme a necessidade:

| Nome do Grupo | Permissão | Descrição |
| ------------- | ------------ | --------- |
| GRP-Owner     | Owner     | Acesso Irrestrito no escopo definido |
| GRP-Infra     | Contributor     | Criar recursos no escopo definido |
| GRP-Sustentacao    | Reader     | Acesso de leitura no escopo definido |
| GRP-Finops    | Cost Management Contributor     | Administrar o custo no escopo definido |
| GRP-Terceiros    | Contributor     | Criar recursos no escopo definido |

## Organização do código Terraform

Nesses artigos vamos organizar nossos módulos Terraform da forma abaixo, onde temos uma pasta módulos e depois uma pasta para cada item que formos criar, onde teremos distribuidos da seguinte forma:

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
```

Os códigos abaixo estão separados para usarmos em módulos, e o principal objetivo do uso de módulos em Terraform é podermos reaproveitá-los.

## Automatizar a criação de Grupos no Entra Id com Terraform

> Em ambientes híbridos onde os grupos e usuários são geralmente sincronizados entre um **Active Directory local** e o **Azure** você não precisa recriar os grupos e sim **usar ele mais adiante** quando chegar na parte de dar permissões.
{: .prompt-info }

No Microsoft Azure você pode dar permissões usando usuário, grupos de usuários e service principal, nesse exemplo e como uma boa prática iremos dar permissões a grupos, para isso vamos criar um grupo de usuário e inserir usuários nesse grupo, e faremos isso usando Terraform.

**main.tf**

```hcl
# Recuperar do Entra ID os usuários que serão proprietários do grupo a ser criado
data "azuread_users" "owners" {
  user_principal_names = var.owners
}

# Recuperar do Entra ID os usuários que serãop membros do grupo que será criado
data "azuread_user" "user_id" {
  for_each            = toset(var.member_id)
  user_principal_name = each.key
}

resource "azuread_group" "this" {
  display_name            = var.group_name
  owners                  = data.azuread_users.owners.object_ids
  security_enabled        = var.security_enabled
  assignable_to_role      = var.assignable_to_role
  prevent_duplicate_names = true
  types                   = var.group_type

  # Example = "user.department -eq \"IT\""
  dynamic "dynamic_membership" {
    for_each = var.group_type != [] ? var.group_type : null
    content {
      enabled = true
      rule    = var.dynamic_membership_rule
    }
  }
}

# Adicionando os usuários ao grupo criado anteriormente
resource "azuread_group_member" "this" {
  for_each         = var.member_id == [] ? [] : toset(var.member_id)
  group_object_id  = azuread_group.this.object_id
  member_object_id = data.azuread_user.user_id[each.value].object_id
}
```

**variables.tf**

```hcl
variable "security_enabled" {
  type        = bool
  default     = true
  description = "Whether the group is a security group for controlling access to in-app resources"
}

variable "group_name" {
  type        = string
  description = "The display name for the group."
}

variable "assignable_to_role" {
  type        = bool
  default     = false
  description = "Indicates whether this group can be assigned to an Azure Active Directory role. Can only be set to true for security-enabled groups."
}

variable "owners" {
  type        = list(string)
  default     = []
  description = "A set of object IDs of principals that will be granted ownership of the group. Supported object types are users or service principals."
}

variable "group_type" {
  type    = list(string)
  default = []
  description = "A set of group types to configure for the group. Set it for DynamicMembership when want the group to be dynamic in Entra ID"
}

variable "dynamic_membership_rule" {
  type        = string
  default     = ""
  description = "Used when you want the group to be dynamic in Entra ID—that is, for membership to be automatically determined based on conditions and attributes of users or devices."
}

variable "member_id" {
  type    = list(string)
  default = []
  description = "A set of members who should be present in this group. Supported object types are Users, Groups or Service Principals. Cannot be used with the dynamic_membership block."
}
```

**output.tf**

```hcl
output "group_objecti_id" {
  value       = azuread_group.this.object_id
  description = "Group object ID"
}

output "group_name" {
  value       = azuread_group.this.display_name
  description = "Group name"
}

```

## Dar permissão RBAC no Azure usando Terraform

No código acima criamos o grupo no Entra ID e inserimos os membros dentro do grupo, no código Terraform abaixo iremos dar permissão a esse grupo no Microsoft Azure. 

Já explicamos que a permissão é concedida ao nível de escopo, para isso devemos ter um cuidado a usar a formatação necessárias para especificar os escopos, pois é necessário que estejam da maneira abaixo:

- **Assinaturas:** /subscriptions/0b1f6471-1bf0-4dda-aec3-111122223333
- **Grupo de Recurso:** /subscriptions/0b1f6471-1bf0-4dda-aec3-111122223333/resourceGroups/**myGroup**
- **Recurso:** /subscriptions/0b1f6471-1bf0-4dda-aec3-111122223333/resourceGroups/myGroup/providers/Microsoft.Compute/virtualMachines/**myVM**
- **Grupo de Gerenciuamento:** /providers/Microsoft.Management/managementGroups/**myMG**

> O negrito no final do exemplo de escopo é o nome do recurso.
{: .prompt-tip }


Abaixo o código Terraform para criarmos o módulo de **role assignment:**

**locals.tf**
```hcl
locals {
  role_definition_resource_substring = "/providers/Microsoft.Authorization/roleDefinitions"
}
```

**main.tf**
```hcl
resource "azurerm_role_assignment" "this" {
  for_each = var.role_assignments

  principal_id                     = each.value.principal_id
  scope                            = var.scope
  principal_type                   = each.value.principal_type
  role_definition_id               = strcontains(lower(each.value.role_definition_id_or_name), lower(local.role_definition_resource_substring)) ? each.value.role_definition_id_or_name : null
  role_definition_name             = strcontains(lower(each.value.role_definition_id_or_name), lower(local.role_definition_resource_substring)) ? null : each.value.role_definition_id_or_name
  skip_service_principal_aad_check = each.value.skip_service_principal_aad_check
}
```

**variables.tf**
```hcl
variable "scope" {
  type        = string
  description = <<DESCRIPTION
  The scope at which the Role Assignment applies to, such as /subscriptions/0b1f6471-1bf0-4dda-aec3-111122223333, /subscriptions/0b1f6471-1bf0-4dda-aec3-111122223333/resourceGroups/myGroup, or /subscriptions/0b1f6471-1bf0-4dda-aec3-111122223333/resourceGroups/myGroup/providers/Microsoft.Compute/virtualMachines/myVM, or /providers/Microsoft.Management/managementGroups/myMG.
  DESCRIPTION
}

variable "role_assignments" {
  type = map(object({
    role_definition_id_or_name       = string
    principal_id                     = string
    description                      = optional(string, null)
    skip_service_principal_aad_check = optional(bool, false)
    principal_type                   = optional(string, null)
  }))
  default     = {}
  description = <<DESCRIPTION
A map of role assignments to create on the Key Vault. The map key is deliberately arbitrary to avoid issues where map keys maybe unknown at plan time.

- `role_definition_id_or_name` - The ID or name of the role definition to assign to the principal.
- `principal_id` - The ID of the principal to assign the role to.
- `description` - The description of the role assignment.
- `skip_service_principal_aad_check` - If set to true, skips the Azure Active Directory check for the service principal in the tenant. Defaults to false.

> Note: only set `skip_service_principal_aad_check` to true if you are assigning a role to a service principal.
DESCRIPTION
  nullable    = false
}
```

## Como usar os módulos Terraform

Nesse primeiro artigo já temos dois módulos construídos, uma para criar grupos no Entra Id e adicionar usuários ao grupo e outro para adicionar a permissão ao Microsoft Azure, para usarmos esses módulos tem um arquivo ***main.tf*** fora da pasta módulos (root folder) onde iremos fazer a chamada aos módulos criados:

```shell
📦Azure_Landing_Zone
 ┣ 📂modules
 ┃ ┣ 📂az_role_assignment
 ┃ ┃ ┣ 📜locals.tf
 ┃ ┃ ┣ 📜main.tf
 ┃ ┃ ┗ 📜variables.tf
 ┃ ┗ 📂entra_id_groups
 ┃ ┃ ┣ 📜main.tf
 ┃ ┃ ┣ 📜output.tf
 ┃ ┃ ┗ 📜variables.tf
 ┣ 📜main.tf <----------
```

No exemplo abaixo estamos dando permissão de **Reader** ao grupo **GRP-TI** a uma Assinatura do Azure:

```hcl
variable "subscription_id" {
  type    = string
  default = "12345678-0000-1111-2222-123456789098"
}

module "group_ti" {
  source = "./entra_id_groups"

  group_name = "GRP-TI"
  owners     = ["luiz@arantes.net.br"]
  member_id  = ["luiz@arantes.net.br", "julia@arantes.net.br"]
}

module "subscription_assignment" {
  source = "./az_role_assignment"

  scope = "/subscriptions/${var.subscription_id}"
  role_assignments = {
    subscription = {
      principal_id               = module.group_ti.group_objecti_id
      role_definition_id_or_name = "Reader"
    }
  }
}
```

> Lembrando que para dar permissões no Microsoft Azure precisamos ter a permissão de **Owner** ou **User Access Administrator** para quem estiver executando o código.
{: .prompt-warning }

Verificando no Microsoft Entra ID se o grupo foi criado e os membros associados:

![azure-landing-zone-groups-and-role-assignments](/assets/img/39/03.png){: .shadow .rounded-10}

E verificando também se a permissão foi dada na Assinatura no Microsoft Azure:

![azure-landing-zone-groups-and-role-assignments](/assets/img/39/04.png){: .shadow .rounded-10}

## Atribuindo permissões a grupos em um ambiente híbrido

Se você tem um ambiente híbrido onde há a sincronização do Active directory local com o Azure você não irá recriar os grupos existentes, você precisa apenas do **object ID** desse grupo e referenciar esse ID no terraform ao dar permissão no Microsoft Azure.

Para pegar esse ID você deve ir no ***Microsoft Entra ID -> Grupos -> Todos os grupos*** e selecionar o grupo que deseja visualizar o ID:

![azure-landing-zone-groups-and-role-assignments](/assets/img/39/05.png){: .shadow .rounded-10}

Para pegar o Object Id é mais fácil abrir o grupo clicando nele e copiar como a imagem abaixo:

![azure-landing-zone-groups-and-role-assignments](/assets/img/39/06.png){: .shadow .rounded-10}

Com o ID copiado é só inserir em uma variável no Terraform ou diretamente na chamada do módulo:

```hcl
module "subscription_assignment" {
  source = "./az_role_assignment"

  scope = "/subscriptions/${var.subscription_id}"
  role_assignments = {
    subscription = {
      principal_id               = "822c0768-938e-4af7-a068-6432f7584cbd"
      role_definition_id_or_name = "Reader"
    }
  }
}
```

Após executar o Terraform teremos a permissão atribuida:

![azure-landing-zone-groups-and-role-assignments](/assets/img/39/07.png){: .shadow .rounded-10}

## Concluindo!

Pode parecer uma coisa simples e sem utilidade, mas quando é necessário automatizar a criação de vários grupos e adicionar usuários a eles, automatizar esse tipo de tarefa nos reduz um grande esforço. E ter uma Azure Landing Zone com os acessos automatizados nos ajuda a seguir um processo e não ter algum erro manual, pense que ao criar uma assinatura nova você já tem todos os passos para automatizar isso, e nesse primeiro artigo começam os demonstrando como criar os grupos no Microsoft Entra ID e dar acesso a eles na assinatura do Microsoft Azure.

Bom pessoal, eu tenho usado isso em alguns ambientes e acredito que possa ser bem útil a vocês!

## Artigos relacionados

<a href="https://learn.microsoft.com/en-us/azure/cloud-adoption-framework/ready/landing-zone/" target="_blank">What is an Azure landing zone?</a>

<a href="https://learn.microsoft.com/en-us/azure/cloud-adoption-framework/scenarios/app-platform/app-services/landing-zone-accelerator" target="_blank">Deploy Azure App Service at scale with the landing zone accelerator</a>

Compartilhe o artigo com seus amigos clicando nos icones abaixo!!!