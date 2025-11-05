---
title: "Azure Landing Zone: Azure Backup com Terraform"
date: 2025-08-09 01:00:00
categories: [Devops, Terraform]
tags: [devops, azure, terraform]
slug: 'azure-landing-recovery-service-vault-backup-policy'
image:
  path: /assets/img/42/42-header.webp
---

Olá pessoal! Blz?

Dando continuidade a série de artigos para automatizar a configuração de uma **Azure Landing Zone** através de Terraform, neste artigo, vamos ver como criar um **Recovery Services Vault** e configurar uma **política de backup** para máquinas virtuais usando Terraform. A ideia é mostrar, de maneira prática, como a infraestrutura como código (IaC) facilita a automação, padronização e manutenção dos seus ambientes, evitando tarefas manuais repetitivas e aumentando a confiabilidade das suas operações na nuvem.

Compartilho aqui a lista de artigos até aqui para criarmos nossa **Azure Landing Zone com Terraform**: 

- <a href="https://arantes.net.br/posts/azure-landing-zone-groups-and-role-assignments/" target="_blank">Azure Landing Zone: Criar grupos no Entra ID e adicionar permissões com Terraform</a>

- <a href="https://arantes.net.br/posts/azure-landing-zone-naming-tagging/" target="_blank">Azure Landing Zone: Como Nomenclatura e Tags Definem o Sucesso da sua Nuvem</a>

- <a href="https://arantes.net.br/posts/azure-landing-zone-networking/" target="_blank">Azure Landing Zone: Virtual network & Subnet com Terraform</a>

Proteger dados e garantir a disponibilidade de máquinas virtuais é essencial em qualquer ambiente na nuvem. No Microsoft Azure, o **Recovery Services Vault** é o serviço responsável por centralizar e gerenciar backups de forma simples e segura.

A ideia nesse artigo é criar um cofre de backup por região que iremos utilizar, o cofre de backup é um recurso regional e iremos criar uma política de backup,  de acordo com as necessidades de cada ambiente você pode adaptar a política para ficar de acordo com o compliance do ramo de atividade e/ou empresa.

> Com o serviço de backup no Azure é possível realizar backups também de recursos do ambiente on-premises.
{: .prompt-tip } 

## O que é o Azure Recovery Services Vault

O Azure Recovery Services Vault é um cofre de armazenamento seguro e gerenciado pela Microsoft Azure, usado para armazenar dados de backup e informações de recuperação.
Ele é amplamente utilizado para proteger cargas de trabalho em nuvem e locais (on-premises).

**Principais funções:**

- **Backup:** Armazena backups de máquinas virtuais (VMs), bancos de dados, arquivos, e outros recursos do Azure.

- **Recuperação (Recovery):** Permite restaurar dados em caso de falha, exclusão acidental, ataque ransomware ou corrupção de dados.

- **Centralização:** Gerencia múltiplas fontes de backup em um único cofre.

- **Criptografia:** Os dados são criptografados em trânsito e em repouso (com chaves gerenciadas pelo Azure ou pelo cliente).

- **Retenção de longo prazo:** Mantém backups por períodos definidos (dias, semanas, meses ou anos).

**O que pode ser protegido:**

- Máquinas Virtuais do Azure (Azure VMs)

- Servidores locais (usando o agente MARS ou Azure Backup Server)

- Bancos de dados SQL e SAP HANA

- Compartilhamentos de arquivos (Azure Files)

- Workloads híbridos (on-premises + nuvem)

## Políticas de Backup (Backup Policies)

As **políticas de backup** definem **como, quando e por quanto tempo** os backups são executados e mantidos no cofre.

**Componentes principais de uma política de backup:**

- **Agendamento de Backup**

  * Define quando o backup é executado (por exemplo, diariamente às 22h).

  * Pode incluir múltiplos pontos de backup diários (até 3 por dia, dependendo do tipo de recurso).

- **Retenção**

  * Determina por quanto tempo cada backup será mantido.

  * Pode incluir políticas diferentes:

  * Retenção diária (ex: manter por 30 dias)

  * Retenção semanal (ex: manter por 12 semanas)

  * Retenção mensal (ex: manter por 12 meses)

  * Retenção anual (ex: manter por 7 anos)

- **Tipo de backup**

  * Full (completo)

  * Incremental (somente mudanças desde o último backup, padrão do Azure)

  * Differential (dependendo do tipo de workload)

- **Consistência dos dados**

  * Opções para garantir backup consistente com o aplicativo (ex: usar VSS para VMs Windows).

## Vamos imaginar o seguinte cenário

Você tem uma **máquina virtual (VM)** no Azure chamada **vm-financeira01** e deseja:

- Fazer **backup diário** às 22h.

- Reter backups por **30 dias**.

- Manter uma cópia mensal por 12 meses.

- Armazenar tudo no **Recovery Services Vault** chamado **rsv-brs-prd-bck-grs**.

Para implantar esse cenário usaremos o Terraform para criar o cofre de backup (Recovery Services Vault), a política de backup e habilitar o backup em uma máquina virtual.

## Script Terraform para criar os recursos

Irei separar os recursos para ir explicando e comentando as mudanças e como o código está escrito para que cso deseje você altere para sua realidade.

### Azure Recovery Services Vault

Os códigos abaixo serão usados para criar um módulo responsávem em criar um cofre de backup e a política, depois mostraremos como realizar a chamada ao módulo.

Eu gosto de criar um arquivo como ***locals.tf*** para definir alguns parâmetros que usarei no decorrer do código, tenho usado também para ter uma abreviação da região onde será criado o recurso e usar essa abreviação no nome:

***locals.tf***

```hcl
locals {
  regions = {
    "brazilsouth"  = "brs"
    "Brazil South" = "brs"
    "northeurope"  = "ne"
    "North Europe" = "ne"
  }

  replication_type = var.storage_mode_type == "GeoRedundant" ? "grs" : var.storage_mode_type == "LocallyRedundant" ? "lrs : "zrs" 
  short_region     = lookup(local.regions, var.location, false)
  vault_name       = var.environment != null ? lower("rsv-${local.short_region}-${var.environment}-bck-${local.replication_type}") : lower("rsv-${local.short_region}-bck-${local.replication_type}")
}
```

Com a abreviação da região (estamos exemplificando somente a região Brazil South e North Europe) e definindo um padrão de nomenclatura onde eu não pergunto ao usuário o nome do recurso e sim eu faço uma junção de palavras e variáveis, no nosso exemplo acima e usando como exemplo um ambiente de **prd**, a região **Brazil South** e uma replicação **GeoRedundant**, o nome do cofre de backup ficaria: **rsv-brs-prd-bck-grs**, e se não passarmos o ambiente ele não colocará o **prd** no nome.

> Eu gosto de usar também o **locals** para a partir de um valor de variável transforma em outro, no exemplo acima estou recebendo o valor **GeoRedundant** na variável **storage_mode_type** e transformando em **grs** para usar na composição do nome do cofre de backup.
{: .prompt-tip } 

***vault.tf***

```hcl
resource "azurerm_recovery_services_vault" "this" {
  name                = local.vault_name
  location            = var.location
  resource_group_name = var.resource_group_name
  sku                 = var.sku

  public_network_access_enabled = var.public_network_access_enabled
  storage_mode_type             = var.storage_mode_type
  cross_region_restore_enabled  = var.cross_region_restore_enabled
  soft_delete_enabled           = var.soft_delete_enabled
  immutability                  = var.immutability

  monitoring {
    alerts_for_all_job_failures_enabled            = true
    alerts_for_critical_operation_failures_enabled = true
  }

  tags = var.tags
}
```

***backup_policy***

```hcl
resource "azurerm_backup_policy_vm" "backup_policy" {
  for_each                       = var.backup_type == "vm" ? var.backup_policies_vm : {}
  name                           = each.key
  resource_group_name            = azurerm_recovery_services_vault.this.resource_group_name
  recovery_vault_name            = azurerm_recovery_services_vault.this.name
  timezone                       = each.value.timezone
  policy_type                    = each.value.policy_type
  instant_restore_retention_days = each.value.instant_restore_retention_days

  backup {
    frequency     = each.value.backup_frequency
    time          = each.value.backup_time
    hour_interval = each.value.backup_frequency == "Daily" ? each.value.backup_hour_interval : null
    hour_duration = each.value.backup_frequency == "Daily" ? each.value.backup_hour_duration : null
    weekdays      = each.value.backup_frequency == "Weekly" ? each.value.retention.weekdays : null
  }

  instant_restore_resource_group {
    prefix = "${azurerm_recovery_services_vault.this.resource_group_name}-"
  }

  dynamic "retention_daily" {
    for_each = each.value.backup_frequency == "Daily" || each.value.retention.daily_backups_retention != null ? [""] : []
    content {
      count = each.value.retention.daily_backups_retention
    }
  }

  dynamic "retention_weekly" {
    for_each = each.value.backup_frequency == "Weekly" || each.value.retention.weekly_backups_retention != null ? [""] : []
    content {
      count    = each.value.retention.weekly_backups_retention
      weekdays = each.value.retention.weekdays
    }
  }

  dynamic "retention_monthly" {
    for_each = each.value.retention.monthly_backups_retention != null ? [""] : []
    content {
      count             = each.value.retention.monthly_backups_retention
      weekdays          = each.value.retention.months_weekdays
      weeks             = each.value.retention.months_weeks
      days              = each.value.retention.months_days
      include_last_days = each.value.retention.include_last_days
    }
  }

  dynamic "retention_yearly" {
    for_each = each.value.retention.yearly_backups_retention != null ? [""] : []
    content {
      count             = each.value.retention.yearly_backups_retention
      months            = each.value.retention.yearly_months
      weekdays          = each.value.retention.yearly_weekdays
      weeks             = each.value.retention.yearly_weeks
      days              = each.value.retention.yearly_days
      include_last_days = each.value.retention.include_last_days
    }
  }
}
```

Abaixo o arquivo de variáveis usadas no código e cada uma tem a descrição para ficar fácil a identificaçao e propósito:

***variables.tf***

```hcl
variable "environment" {
  type        = string
  description = "Environment project (dev, qua or prd)."
  default     = null
}

variable "backup_type" {
  type        = string
  description = "Type of resources to be backed up. Supported values are 'vm' or 'sql'"
  default     = "vm"

  validation {
    condition     = contains(["vm", "sql"], var.backup_type)
    error_message = "var.backup_type must be one of 'vm' or 'sql'"
  }
}

variable "resource_group_name" {
  description = "The name of the resource group in which to deploy the backup resources."
  type        = string
}

variable "location" {
  description = "Name of location to where backups will be stored"
  type        = string
}

variable "sku" {
  type        = string
  description = "SKU of Recovery Services Vault, either 'Standard' or 'RS0'."
  default     = "Standard"

  validation {
    condition     = contains(["Standard", "RS0"], var.sku)
    error_message = "var.sku must be set to either 'Standard' or 'RS0'"
  }
}

variable "soft_delete_enabled" {
  type        = bool
  description = "Whether to enable soft delete on Recovery Services Vault"
  default     = true
}

variable "storage_mode_type" {
  type        = string
  description = "Storage type of the Recovery Services Vault. Must be one of 'GeoRedundant', 'LocallyRedundant' or 'ZoneRedundant'."
  default     = "LocallyRedundant"

  validation {
    condition     = contains(["GeoRedundant", "LocallyRedundant", "ZoneRedundant"], var.storage_mode_type)
    error_message = "var.storage_mode_type must be one of 'GeoRedundant', 'LocallyRedundant' or 'ZoneRedundant'"
  }
}

variable "cross_region_restore_enabled" {
  type        = bool
  description = "Whether to enable cross region restore for Recovery Services Vault. For this to be true var.storage_mode_type must be set to GeoRedundant"
  default     = false
}

variable "immutability" {
  type        = string
  description = "Whether you want vault to be immutable. Allowed values are: 'Locked', 'Unlocked' or 'Disabled'."
  default     = "Disabled"

  validation {
    condition     = contains(["Locked", "Unlocked", "Disabled"], var.immutability)
    error_message = "var.immutability must be one of 'Locked', 'Unlocked' or 'Disabled'"
  }
}

### Recovery Services Vault monitoring configuration
variable "rsv_alerts_for_all_job_failures_enabled" {
  type        = bool
  description = "Enabling/Disabling built-in Azure Monitor alerts for security scenarios and job failure scenarios."
  default     = true
}

variable "rsv_alerts_for_critical_operation_failures_enabled" {
  type        = bool
  description = "Enabling/Disabling alerts from the older (classic alerts) solution."
  default     = true
}

## Backup policy and direct assignment configuration
variable "backup_policies_vm" {
  description = "A map of backup policy objects where the key is the name of the policy."
  type = map(object({
    timezone                       = optional(string, "UTC") # [Allowed values](https://jackstromberg.com/2017/01/list-of-time-zones-consumed-by-azure/)
    backup_time                    = string                  # Time of day to perform backup in 24h format, e.g. 23:00
    backup_frequency               = string                  # Frequency of backup, supported values 'Hourly', 'Daily', 'Weekly'
    policy_type                    = optional(string, "V2")  # set to V1 or V2, see [here](https://learn.microsoft.com/en-us/azure/backup/backup-azure-vms-enhanced-policy?tabs=azure-portal)
    instant_restore_retention_days = optional(number)        # Between 1-5 for var.policy_type V1, 1-30 for V2
    backup_hour_interval           = optional(number)        # Interval of which backup is triggered. Allowed values are: 4, 6, 8 or 12. Used if backup_frequency is set to Hourly.
    backup_hour_duration           = optional(number)        # Duration of the backup window in hours. Value between 4 and 24. Used if backup_frequency is Hourly. Must be a multiplier of backup_hour_interval
    retention = optional(object({
      daily_backups_retention = optional(number) # Number of daily backups to retain, must be between 7-9999. Required if backup_frequency is Daily

      weekly_backups_retention = optional(number)       # Number of weekly backups to retain, must be between 1-9999. 
      weekdays                 = optional(list(string)) # The day in the week of backups to retain. Used for weekly retention.

      monthly_backups_retention = optional(number)       # Number of monthly backups to retain, must be between 1-9999. 
      months_weekdays           = optional(list(string)) # The day in the week of backups to retain. Used for monthly retention configuration
      months_weeks              = optional(list(string)) # Weeks of the month to retain backup of. Must be First, Second, Third or Last. Used for monthly retention configuration
      months_days               = optional(list(number)) # The days in the month to retain backups of. Must be between 1-31. Used for monthly retenion configuration
      months_include_last_days  = optional(bool, false)  # Whether to include last day of month, used if either months_weekdays, months_weeks or months_days is set. 

      yearly_backups_retention = optional(number)       # Number of yearly backups to retain, must be between 1-9999. 
      yearly_months            = optional(list(string)) # The months of the year to retain backups of. Values most be names of the month with capital case. Used for yearly retention configuration
      yearly_weekdays          = optional(list(string)) # The day in the week of backups to retain. Used for yearly retention configuration
      yearly_weeks             = optional(list(string)) # Weeks of the month to retain backup of. Must be First, Second, Third or Last. Used for yearly retention configuration
      yearly_days              = optional(list(number)) # The days in the month to retain backups of. Must be between 1-31. Used for monthly retention configuration
      yearly_include_last_days = optional(bool, false)  # Whether to include last day of month, used if either months_weekdays, months_weeks or months_days is set. 

    }))
  }))
}

variable "tags" {
  type        = map(string)
  description = "(Optional) Tags that will be applied to all deployed resources."
  default     = {}
}
```

***vm_backup_enable.tf***

Aqui pessoal eu irei demonstrar de forma simples como é feito para habilitar o backup em uma máquina virtual no cofre de backup e política criado acima com terraform:

```hcl
data "azurerm_virtual_machine" "vm" {
  name                = "vm-financeira01"
  resource_group_name = azurerm_resource_group.this.name
}

resource "azurerm_backup_protected_vm" "vm1" {
  resource_group_name = azurerm_resource_group.this.name.           # Resource Group onde está o cofre de backup
  recovery_vault_name = azurerm_recovery_services_vault.this.name.  # Nome do cofre de backup
  source_vm_id        = data.azurerm_virtual_machine.vm.id          # ID da VM que desejamos associar/habilitar o backup, está sendo recuperada a partir do bloco Data acima
  backup_policy_id    = azurerm_backup_policy_vm.backup_policy.id.  # ID dapolítica de backup
}
```

## Como usar os módulos Terraform

Em Terraform temos o que é chamado de stack que seria o arquivo onde é feita a chamada aos módulos/recursos que você quer ter no seu deployment, para usarmos esses módulos geralmente criamos um arquivo main.tf fora da pasta módulos (root folder) onde iremos fazer a chamada aos módulos criados:

```hcl
module "rsv_ne_vm" {
  source = "./modules/az_recovery_services_vault"

  location            = var.location
  environment         = var.environment
  resource_group_name = azurerm_resource_group.this.name
  backup_type         = "vm"
  tags                = var.tags

  backup_policies_vm = {
    "bkpol-vm-${var.environment}" = {
      backup_time      = "20:00"
      backup_frequency = "Daily"

      instant_restore_retention_days = 3

      retention = {
        daily_backups_retention  = 8
      }
    }
  }
}
```

## Organização do Terraform ao longo dos artigos

Seguindo a mesma premissa de outros artigos e seguindo também uma melhora prática que é criar módulos reutilizáveis de recursos, para esse nosso artigo terá os módulos de: **recovery services vault e politíca de backup**. 

- **main.tf**: onde será criado o/os recursos
- **locals.tf**: para manter alguns valores que usaremos no restante do código
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
 ┃ 📂az_recovery_services_vault
 ┃ ┣ 📜locals.tf
 ┃ ┣ 📜main.tf
 ┃ ┣ 📜output.tf
 ┃ ┗ 📜variables.tf
```

## Concluindo!

Neste artigo, vimos como é possível criar um Azure Recovery Services Vault e configurar uma política de backup para máquinas virtuais utilizando Terraform. Essa abordagem mostra na prática como a infraestrutura como código (IaC) simplifica tarefas que, manualmente, seriam mais demoradas e suscetíveis a erros.

Adotar Terraform para gerenciar backups no Azure não é apenas uma questão de praticidade, mas também de maturidade operacional. Essa prática ajuda a construir uma base sólida de governança e segurança, reduzindo riscos e permitindo que as equipes foquem em inovação e melhoria contínua.

Bom pessoal, eu tenho usado isso em alguns ambientes e acredito que possa ser bem útil a vocês!

## Artigos relacionados

<a href="https://learn.microsoft.com/en-us/azure/backup/backup-overview" target="_blank">What is the Azure Backup service?</a>

<a href="https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/recovery_services_vault" target="_blank">Manages a Recovery Services Vault.</a>

<a href="https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/backup_policy_vm" target="_blank">Manages an Azure Backup VM Backup Policy.</a>

<a href="https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/backup_protected_vm" target="_blank">Manages an Azure Backup Protected Virtual Machine.</a>

Compartilhe o artigo com seus amigos clicando nos icones abaixo!!!