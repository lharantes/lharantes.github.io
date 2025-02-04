---
title: "Terraform validando nome de recursos Azure com expressões regex"
date: 2025-01-29 01:33:00
categories: [Devops, Terraform]
tags: [devops, terraform, azure]
slug: 'azure-naming-terraform-regex'
image:
  path: assets/img/32/32-header.webp
---

Olá pessoal! Blz?

Nesse artigo quero trazer a vocês como eu verifico o conteúdo das minhas variáveis de nome de recursos Azure no Terraform. No Microsoft Azure cada recurso tem uma regra e/ou restrição no nome a ser usado durante a criação do recurso e podemos fazer essa validação no Terraform usando expressões ***REGEX***.

Mas antes de iniciarmos, precisamos falar de dois pontos: **padrão de nomenclatura no Microsoft Azure** e **validação de variável no Terraform.**

## Nomenclatura de recursos no Microsoft Azure

Já tenho trabalhado com TI a alguns anos e já vi muitos padrões de nomenclaturas em ambientes on-premises e em cloud, para ambientes on-premises nunca vi uma preocupação com isso e sempre eram algo do tipo ***arantes-s001, arantes-d001***, no máximo colocando uma letra para diferenciar desktop e servidor.

Mas para a cloud sempre há/deveria ter uma nomenclatura fácil de identificar do que se trata o recurso em um simples bater de olhos, itens que você pode identificar pelo nome do recurso: o tipo de recurso, seu ambiente e a região do Azure em que ele é executado. 

A realidade é bem diferente e são poucas empresas que quando você pergunta: "Vocês têm algum padrão de nomenclatura de recursos no Microsoft Azure?" Te respondem positivamente, então para isso a Microsoft disponibiliza uma vasta documentação para adoção de cloud para a empresa, aqui você pode dar uma olhada nessa documentação chamada de <a href="https://learn.microsoft.com/pt-br/azure/cloud-adoption-framework/" target="_blank">CAF (Cloud Adoption Framework)</a>.

Por exemplo, um endereço IP público (PIP) para uma carga de trabalho de produção do SharePoint na região Oeste dos EUA pode ser **pip-sharepoint-prod-westus-001** e, com isso, ao bater o olho no nome do recurso, fica fácil identificar as informações necessárias para identificar o propósito do recurso.

![azure-terraform-regex](/assets/img/32/01.png){: .shadow .rounded-10}

Aqui você pode consultar a documentação da Microsoft com as <a href="https://learn.microsoft.com/pt-br/azure/cloud-adoption-framework/ready/azure-best-practices/resource-abbreviations" target="_blank">recomendações de abreviações para recursos do Azure.</a>

Cada recurso no Microsoft Azure tem uma regra ou restrição no nome que pode ser dado a ele, por isso ter como controlar quando usamos o Terraform para criar o recurso evita problemas "simples" de execução, direcionando e controlando o nome do recurso, para ficar mais claro, vou dar o exemplo de um recurso no Azure como uma **Storage Account** onde é permitida somente <ins>**letras minúsculas e números com tamanho de 3 a 24 caracteres**</ins>:

![azure-terraform-regex](/assets/img/32/02.png){: .shadow .rounded-10}

Documentação da Microsoft com as <a href="https://learn.microsoft.com/pt-br/azure/azure-resource-manager/management/resource-name-rules" target="_blank">regras de nomenclatura e restrições para recursos do Azure.</a>

## Validação de variável de entrada

O Terraform permite você validar o valor inserido para uma variável através de um bloco de validação, cada validação requer um argumento/condição para ser validada e, retornando verdadeiro está ok e caso contrário, podemos personalizar uma mensagem de erro. 

Abaixo você pode consultar um exemplo que podemos usar durante a criação de um Azure Storage Account onde o valor aceito está em uma lista ***"BlobStorage|BlockBlobStorage|FileStorage|Storage|StorageV2"*** caso seja inserido um valor diferente desses, é exibida uma mensagem de erro definida em **error_message**:

```hcl
variable "storage_account_kind" {
  type        = string
  description = "Storage Account kind"
  validation {
    condition     = can(regex("BlobStorage|BlockBlobStorage|FileStorage|Storage|StorageV2", var.storage_account_kind))
    error_message = "Values allowed as Storage Account kind: BlobStorage, BlockBlobStorage, FileStorage, Storage and StorageV2."
  }
}
```

## Validando o nome dos recursos Azure

Com essa validação do valor da variável, podemos começar a usar isso para validarmos se o nome dos recursos a serem criados no Azure segue a regra/restrição que mencionamos acima e, com isso, personalizar a mensagem de erro, ficando de forma mais explícita para a pessoa que utilizar o código Terraform.

Uma forma de validar isso é usar REGEX e confesso que isso não é uma maneira que me agrade porque corro de REGEX de uma forma que vocês nem imaginam 😁😁😁.

Vamos assumir o exemplo que demos acima para a criar uma Storage Account, temos como regra para esse recurso que podemos usar caracteres alfanuméricos, mas o tamanho deve ser entre 3 e 24 caracteres, para termos isso usando a condição `"^[a-z0-9]{3,24}$"`, passando isso para o terraform ficaria:

```hcl
variable storage_account_name {
    type = string
    default = "aaaaaaaaaaaaaaaaaaaaaaaa"
    validation {
      condition     = can(regex("^[a-z0-9]{3,24}$", var.storage_account_name))
      error_message = "Storage account name must start with letter or number, only contain letters, numbers and must be between 3 and 24 characters."
    }
}
```

Caso seja inserido um valor no conteúdo da variável que retorne falso na condição, como por exemplo o uso de algum simbolo iremos receber a mensagem de erro que definimos em **error_message**.

Eu entendo que não é fácil montar expressões regex e eu uso <a href="https://regexr.com/" target="_blank"> esse site para validar a expressão regex </a> e para consultar o que cada item significa, temos <a href="https://www3.ntu.edu.sg/home/ehchua/programming/howto/Regexe.html" target="_blank"> esse site sobre regex. </a>

Para não ficar montando as expressões regex sempre do zero, tem um repositório do <a href="https://github.com/Azure/terraform-azurerm-naming/blob/master/main.tf" target="_blank"> Azure no GitHub </a> e eu consulto e adapto ao que preciso, por exemplo:

Desejo criar uma virtual network, eu busco no documento da Microsoft que deixei acima qual a regra/requisito para o nome desse recurso, a regra é **Caracteres alfanuméricos, sublinhados, pontos e hífens**, com o tamanho de 2 a 64 caracteres, então eu vou à página do GitHub que deixei acima e procuro pelo recurso de virtual network como na imagem abaixo:

![azure-terraform-regex](/assets/img/32/03.png){: .shadow .rounded-10}

Com a expressão em mãos, eu apenas preciso acrescentar o tamanho mínimo e máximo à expressão, colocando  da seguinte forma **{min,max}**, e uso os sites para validar a expressão se está correta e implemento isso no Terraform:

```hcl
variable vnet_name {
    type = string
    validation {
      condition     = can(regex("^[a-zA-Z0-9][a-zA-Z0-9-._]{2,64}[a-zA-Z0-9_]$", var.vnet_name))
      error_message = "Virtual network name must start with letter or number, contain letters, numbers, dashes, undescore and popints and must be between 2 and 64 characters."
    }
}
```

Agora se o valor inserido não for aceito uma mensagem de erro mais intuitiva nos será apresentada e podemos de forma rápida identificar o problema.

## Concluindo!

Eu quis trazer como eu crio os meus recursos Terraform tentando ter um código mais indicativo a outras pessoas que possam utilizar, claro que funciona sem isso, podem até achar frescura, mas eu acho importante ter isso para facilitar em caso de erros, pois com uma mensagem mais clara do erro você já saberá onde começar a resolver o problema.

Bom pessoal, eu tenho usado isso em alguns ambientes e acredito que possa ser bem útil a vocês!

## Artigos relacionados

<a href="https://learn.microsoft.com/pt-br/azure/cloud-adoption-framework/" target="_blank">CAF (Cloud Adoption Framework)</a>

<a href="https://learn.microsoft.com/pt-br/azure/cloud-adoption-framework/ready/azure-best-practices/resource-abbreviations" target="_blank">recomendações de abreviações para recursos do Azure</a>

Compartilhe o artigo com seus amigos clicando nos icones abaixo!!!
