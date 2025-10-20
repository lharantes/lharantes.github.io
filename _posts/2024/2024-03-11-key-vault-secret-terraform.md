---
title: 'Referenciando secrets do Azure Key Vault no Terraform'
date: 2024-03-11 10:33:00
slug: 'key-vault-secret-terraform'
categories:  ['Azure', 'Terraform']
tags:  ['Azure', 'Terraform', 'Key Vault']
image:
  path: /assets/img/05/05-header.webp
---

Olá pessoal! Blz?

Hoje trarei uma dica para quem está estudando Terraform e já começar com melhores práticas de não deixar "hard coded" secrets/senhas diretamente no código.

Como melhor prática, devemos criar um secret em um Azure Key Vault e no código terraform referenciar esse secret na criação dos recursos, por exemplo, uma senha de usuário na criação de uma máquina virtual.

![azure-keyvault-terraform](/assets/img/05/01.svg)

## Por que o Azure Key Vault?

O Azure Key Vault é uma ótima maneira de armazenar segredos, certificados e chaves no Azure, ou seja, pense nele como um cofre seguro para armazenar itens que devam permanecer seguros.

O Azure Key Vault tem duas camadas de serviço: **Standard**, que faz a criptografia com uma chave de software, e uma camada **Premium**, que inclui chaves protegidas por HSM (módulo de segurança de hardware). Nesse exemplo vamos usar a camada de serviço **Standard.**

## O código Terraform para nosso artigo

Nesse artigo vou demonstrar como usar um Azure Key Vault já existente com uma secret que será usado como senha para o usuário da máquina virtual e somente o trecho de referenciar ao criar uma máquina virtual, não irei usar variáveis e os pré-requisitos de providers, o código completo você pode acessar no repositório GitHub: <a href="https://github.com/lharantes/key-vault-secret-terraform" target="_blank">lharantes/key-vault-secret-terraform</a>

Para usar um Azure Key Vault já existente vamos usar o seguinte código:

```hcl
data "azurerm_resource_group" "rg" {
  name     = "RG-KEY-VAULT"
}

data "azurerm_key_vault" "kv_example" {
  name                = "mykeyvault"
  resource_group_name = data.azurerm_resource_group.rg.name
}

data "azurerm_key_vault_secret" "secretget" {
  name         = "secret-vms"
  key_vault_id = data.azurerm_key_vault.kv_example.id
}

```

> **Lembrando que o usuário / service principal / managed identity precisa ter permissão para acessar o key vault e consequentemente o secret que você esta querendo referenciar**
{: .prompt-info }

Com o trecho de código acima já podemos usar o conteúdo do secret **"secret-vms"** através do output **.value** que está armazenado dentro do Key Vault usando o seguinte trecho terraform:

<mark> <b> data.azurerm_key_vault_secret.secretget.value </b></mark>

## Referenciar o secret

Ao criar uma máquina virtual com terraform e a forma de autenticação do usuário for com password, teremos 2 campos obrigatórios:

  - admin_username
  - admin_password

E para não deixar o campo admin_password com uma senha explicita no código referenciamos o secret que pegamos no trecho de código acima com o valor de output (value) retornado.

No campo **admin_password** (linha 7) está com a forma que referenciamos o secret:

```hcl
resource "azurerm_windows_virtual_machine" "vm_example" {
  name                = "example-machine"
  resource_group_name = "RG-VMS-Windows"
  location            = "West Europe"
  size                = "Standard_F2"
  admin_username      = "adminuser"
  admin_password      = data.azurerm_key_vault_secret.secretget.value

  ... o código continua a partir daqui

```

Com isso podemos compartilhar o código entre amigos ou dentro da empresa e somente quem realmente precisa saberá qual o valor da senha para acessar a máquina virtual, ou seja, quem está escrevendo o código não saberá.

Nesse artigo demos o exemplo de uso com a criação de máquina virtual, mas caso precise usar em outro recurso a maneira de referenciar o secret será a mesma.

Outras formas de uso são em Banco de dados, par de chaves em uma conexão do Virtual Network Gateway, ou outro recurso que você não deseje compartilhar algum parâmetro/valor.

## Concluindo!

Bom pessoal, espero que gostem do artigo e que seja útil nos projetos de terraform de vocês, seja em ambiente de testes, estudo ou até em ambiente de trabalho.

Seguindo dessa forma você pode tranquilamente publicar seu código em um repositório GIt sem medo de sua senha "padrão" esteja exposta 😊 

## Artigos relacionados

<a href="https://learn.microsoft.com/pt-br/azure/key-vault/general/overview" target="_blank">Conceitos básicos do Azure Key Vault</a>

<a href="https://learn.microsoft.com/pt-br/azure/key-vault/general/about-keys-secrets-certificates" target="_blank">Visão geral das chaves, dos segredos e dos certificados do Azure Key Vault</a>

Bom pessoal, espero que tenha gostado e que esse artigo seja útil a vocês!

Compartilhe o artigo com seus amigos clicando nos icones abaixo!!!
<hr>