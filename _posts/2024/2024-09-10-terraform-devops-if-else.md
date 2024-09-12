---
#layout: post
title: 'Terraform: Como usar if/else para controlar deployments' 
date: 2024-09-10 11:33:00
categories: [Devops, Terraform]
tags: [devops, terraform]
slug: 'terraform-devops-if-else'
image:
  path: assets/img/22/22-header.webp
---

Olá pessoal! Blz?

Nesse artigo eu quero trazer para vocês como usar **if / else** para controlar deployments com o Terraform. O engraçado é que não existe o **if / else** no Terraform 😆 😜, mas há algo "parecido" onde seguimos a mesma lógica condicional.

Eu costumo usar essa expressão condicional para controlar se devo ou não criar um recurso, para utilizar um valor de variável de acordo com uma validação e entre outras situações que irei exemplificar aqui.

## Como usar essa expressão condicional?

A sintaxe da expressão é de fácil compreensão já que diferente de linguagens de programação não podemos executar blocos de comandos dentro do if else como nas linguagens. A sintaxe que devemos usar é:

```
condição ? valor se a condição for verdadeira : valor se a condição for falsa
```

Uma expressão condicional usa o valor de uma expressão booleana para selecionar um de dois valores. Esta expressão é avaliada como **valor verdadeiro** se o valor da condição for verdadeiro e, caso contrário, como **valor falso**. Isso é equivalente a uma instrução If.

## Como validar as condições

Para validar a condição devemos usar um operado para comparar valores e tomar uma decisão, podemos usar:

- **Operadores de Igualdade**

  - Os operadores de igualdade aceitam dois valores de qualquer tipo e produzem valores booleanos como resultados.

    - a **==** b retorna verdadeiro se ***a*** e ***b*** tiverem o mesmo tipo e o mesmo valor, ou falso caso contrário.
    - a **!=** b é o oposto de ***a == b***.

- **Operadores de comparação**

  - Todos os operadores de comparação esperam valores numéricos e produzem valores booleanos como resultados.

    - **a < b** retorna verdadeiro se ***a*** for menor que ***b***, ou falso caso contrário.
    - **a <= b** retorna verdadeiro se ***a*** for menor ou igual a ***b***, ou falso caso contrário.
    - **a > b** retorna verdadeiro se ***a*** for maior que ***b***, ou falso caso contrário.
    - **a >= b** retorna verdadeiro se ***a*** for maior ou igual a ***b***, ou falso caso contrário.

## Vamos a alguns exemplos

### 1. Definir a região de acordo com o ambiente

No exemplo abaixo vamos supor que: se uma empresa está localizada no Brasil e para ambiente de produção devemos criar os recursos na região "brazilsouth" para termos uma latência baixa, mas para qualquer outro ambiente (DEV ou HML) onde a latência é menos importante do que o custo, devemos usar uma região mais barata como "astus2", podemos usar o seguinte exemplo:

```hcl
variable "environment" {
  type    = string
  default = "PRD"
} 

resource "azurerm_resource_group" "rg" {
  name     = "rg-teste"
  location = var.environment == "PRD" ? "brazilsouth" : "eastus2"
}
```

![terraform-devops-if-else](/assets/img/22/01.png)

### 2. Uso do COUNT para determinar se criamos ou não um IP público para uma máquina virtual

No exemplo abaixo estamos usando o **count**, que de uma forma grosseira de explicar, é essencialmente um valor numérico que determina quantas instâncias de um recurso criar, no exemplo abaixo só irá executar se a variável **public_ip** for **verdadeira** e como o default é ***false*** o **count** terá o valor de **0** e o recurso não será criado pois o bloco não será executado:

```hcl
variable "public_ip" {
  type    = bool
  default = false
} 

resource "azurerm_public_ip" "ip_public" {
  count               = var.public_ip ? 1 : 0 
  name                = "pip-vm-windows-01"
  resource_group_name = "rg-teste"
  location            = "eastus"
  allocation_method   = "Dynamic"
}
```

![terraform-devops-if-else](/assets/img/22/02.png)

> No exemplo acima definimos a variável **public_ip** com o tipo ***bool***, como a validação da condição é ***verdadeiro*** ou ***falso*** não precisamos comparar se verdadeiro ***é igual a*** verdadeiro, por isso só colocamos o nome da variável e se ela for verdadeira já valida a condição.
{: .prompt-tip }

### 3. Usando os 2 exemplos acima juntos

No exemplo abaixo vamos usar a condição para o count e se for ser executado teremos uma condição para a região do IP público, como o valor da váriavel ***public_ip*** é ***"true"*** o recurso será criado e com o valor da variável ***environment*** é ***"DEV"*** a região será eastus2 porque a condição é ***falsa***:

```hcl
variable "environment" {
  type    = string
  default = "DEV"
}

variable "public_ip" {
  type    = bool
  default = true
}

resource "azurerm_public_ip" "ip_public" {
  count               = var.public_ip ? 1 : 0 
  name                = "pip-vm-windows-01"
  resource_group_name = "rg-teste"
  location            = var.environment == "PRD" ? "brazilsouth" : "eastus2"
  allocation_method   = "Dynamic"
}
```

![azure-avd-mfa](/assets/img/22/03.png)


### 4. Definir quantas máquinas virtuais serão criadas

Podemos usar o valor de uma variável para controlar quantas máquinas virtuais iremos criar, no exemplo abaixo se a variável ***vm_type*** for **diferente** de "Cluster" irá criar somente 1 máquina virtual senão irá criar 2 máquinas virtuais.

> Usei o modo de comparação "**!= (diferente)**" para mudar o que usamos acima que foi a comparação de "**== (igual)**".
{: .prompt-tip }

```hcl

variable "vm_type" {
  type    = string
  default = "Cluster"
}

resource "azurerm_linux_virtual_machine" "example" {
  count               = var.vm_type != "Cluster" ? 1 : 2
  name                = "vm-linux-app-0${count.index+1}"
  resource_group_name = "RG-APPLICATION"
  location            = "westus"
  size                = "Standard_F2"
...
```

![azure-avd-mfa](/assets/img/22/04.png)
![azure-avd-mfa](/assets/img/22/05.png)

### 5. Controlando dynamic blocks

Nesse exemplo abaixo dynamic bloco cria uma instância do network_rules somente se a variável **"public_access"** for definida como ***"true"*** com isso é criado uma regra liberando o IP informado: 

```hcl
variable "public_access" {
  type    = bool
  default = true
}
resource "azurerm_storage_account" "example" {
 
  name                     = "stoterraformtest"
  resource_group_name      = azurerm_resource_group.rg.name
  location                 = azurerm_resource_group.rg.location
  account_tier             = "Standard"
  account_replication_type = "LRS"
 
  dynamic "network_rules" {
    for_each = public_access ? [1] : []
 
    content {
    default_action             = "Allow"
    ip_rules                   = ["100.200.250.1"]
    }
  }
}
```
![azure-avd-mfa](/assets/img/22/06.png)

## Concluindo!

Terraform usa lógica de expressão condicional para construir instruções If. Isto pode ser combinado com outras funções para formar expressões mais complexas. O domínio dessas técnicas ajudará você a criar um código de infraestrutura adaptável, multi ambientes e muito mais eficiente.

Bom pessoal, espero que tenha gostado e que esse artigo seja útil a vocês!

## Artigos relacionados

<a href="https://developer.hashicorp.com/terraform/language/expressions/conditionals" target="_blank">Conditional Expressions</a> 

<a href="https://developer.hashicorp.com/terraform/language/expressions/operators" target="_blank">Arithmetic and Logical Operators</a> 

Compartilhe o artigo com seus amigos clicando nos icones abaixo!!!