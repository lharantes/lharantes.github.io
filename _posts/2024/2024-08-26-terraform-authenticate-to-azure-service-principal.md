---
#layout: post
title: 'Terraform autenticando no Microsoft Azure com service principal' 
date: 2024-08-25 11:33:00
categories: [Terraform, Azure]
tags: [azure, terraform]
slug: 'terraform-authenticate-to-azure-service-principal'
image:
  path: /assets/img/20/20-header.webp
---

Olá pessoal! Blz?

Nesse artigo eu quero trazer como se conectar ao Microsoft Azure com o terraform usando um service principal, e é claro que em ambiente corporativo você irá fazer essa conexão através de ferramentas de Devops, seja com o ***Jenkins, Azure Devops, GitHub Actions, GitLab ou outras ferramentas***, mas quando você está no começo do código ou esteja em seu computador pessoal estudando, fazer o deploy por pipelines não é necessário e demandaria mais tempo.

Você pode estar se perguntando, por que usar um service principal para se conectar se eu posso diretamente na linha de comando me conectar usando o powershell ou Azure cli? Bem, a resposta para o meu caso é simples: **"Garantir que voce está fazendo o deploy na Assinatura do Microsoft Azure correta!".**

Eu ainda não sei o porque, mas tive problema no passado quando eu me conectava usando o ```Connect-AzAccount``` e ```Set-AzContext -Subscription "<subscription_id_or_subscription_name>"``` no terminal do Vs Code mas ao alternar para outra Assinatura Azure no navegador o meu VS Code assumia que a Assinatura Azure alvo seria a que eu alternei no navegador, com isso eu acabava fazendo o deploy em uma assinatura que eu não queria.

<img src="/assets/img/20/01.png" alt="Se tem placa tem história" width="400" height="400">

> Se tem placa tem história!!! 😊 😜
{: .prompt-info }

Bom, o que precisamos então para fazer essa conexão e autenticação? No Microsoft Azure precisaremos de um **service principal** e que esse service principal tenha **permissão na Assinatura e/ou no Resource Group** que iremos realizar o deploy.

## Criando um Service Principal

Eu prefiro criar pela linha de comando mas caso queiram criar o service principal pelo portal do Microsoft Azure podem usar esse <a href="https://learn.microsoft.com/en-us/entra/identity-platform/howto-create-service-principal-portal" target="_blank">link.</a> de como criar usando o portal.

O comando para criar o service principal e já dar permissão é esse:

```powershell
az ad sp create-for-rbac --name myServicePrincipalName \
                         --role contributor \
                         --scopes /subscriptions/00000000-0000-0000-0000-000000000000
```

O exemplo acima estou criando o Service Principal e já dando acesso de **contributor** na assinatura toda, mas se você quer dar acesso somente a um Resource Group específico é só adicional a parte final do comando o trecho ***/resourceGroups/myRG***.

## Autenticando usando variáveis de ambiente

Se estiver usando o Linux com o **bash** edite o arquivo **~/.bashrc** adicionando as variáveis de ambiente a seguir:

```bash
export ARM_SUBSCRIPTION_ID="<azure_subscription_id>"
export ARM_TENANT_ID="<azure_subscription_tenant_id>"
export ARM_CLIENT_ID="<service_principal_appid>"
export ARM_CLIENT_SECRET="<service_principal_password>"
```

Para executar o script ~/.bashrc, execute ***source ~/.bashrc*** e você também pode sair e reabrir o Cloud Shell para que o script seja executado automaticamente.

Com o comando abaixo você pod consultar os valores:

```bash
printenv | grep ^ARM
```

Mas se estiver usando o **POWERSHELL** use os comandos abaixo para definir as variáveis de ambiente:

```powershell
$env:ARM_CLIENT_ID="<service_principal_app_id>"
$env:ARM_SUBSCRIPTION_ID="<azure_subscription_id>"
$env:ARM_TENANT_ID="<azure_subscription_tenant_id>"
$env:ARM_CLIENT_SECRET="<service_principal_password>"
```

Para consultar as variáveis de ambiente você pode usar o seguinte comando:

```powershell
Get-Childitem Env:ARM
```

## Usando as credenciais no código Terraform

Você pode especificar dentro do código os valores para se conectar a uma Assinatura do Microsoft Azure, isso **não é uma boa prática e não é recomendada**, mas confesso que uso as vezes disso quando estou criando algo simples ou estudando algum recurso. Mas o que faço é colocar no ***.gitignore*** o nome do arquivo que contém o bloco com essa configuração e assim esse arquivo não é mantido no histórico de commits.

> Por mais que disse que uso e adiciono o nome do arquivo ao .gitignore não é recomendado essa abordagem
{: .prompt-danger }

Abaixo como definimos isso dentro de um arquivo ***.tf***:

```hcl
terraform {
  required_providers {
    azurerm = {
      source = "hashicorp/azurerm"
      version = "~>3.0"
    }
  }
}

provider "azurerm" {
  features {}

  subscription_id   = "<azure_subscription_id>"
  tenant_id         = "<azure_subscription_tenant_id>"
  client_id         = "<service_principal_appid>"
  client_secret     = "<service_principal_password>"
}

# Your code goes here
```

## Conectando o Terraform com AWS

Primeiramente gostaria de deixar claro que meu uso de terraform é 100% com Microsoft Azure mas gostaria de deixar nesse artigo como configurar a autenticação com outro cloud provider como AWS, porém, posso estar fazendo algo errado que não seja mais utilizado e/ou não seja a forma correta de se fazer. Se isso estiver errado por favor me avise:

Para se conectar AWS no bash e terraform com as variáveis a serem configuradas são:

```bash
export AWS_ACCESS_KEY_ID="anaccesskey"
export AWS_SECRET_ACCESS_KEY="asecretkey"
```

```powershell
$env:AWS_ACCESS_KEY_ID="anaccesskey"
$env:AWS_SECRET_ACCESS_KEY="asecretkey"
```
Usando no bloco de configuração, tão errado como com Microsoft Azure:

```hcl
terraform {
    required_providers {
      aws = {
        source = "hashicorp/aws"
        version = "~> 4.0.0"
      }
    }
}

provider "aws" {
    region = "us-east-1"
    access_key = "your_aws_access_key"
    secret_key = "your_aws_secret_access_key"
}
```

## Concluindo!

Eu quis compartilhar com vocês como configuro o ambiente quando estou trabalhando **localmente** com o terraform em meu computador, em um próximo artigo irei trazer como fazer a mesma autenticação no Azure Devops e no GitHub Actions.

Bom pessoal, espero que tenha gostado e que esse artigo seja útil a vocês!

Compartilhe o artigo com seus amigos clicando nos icones abaixo!!!