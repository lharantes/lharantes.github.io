---
#layout: post
title: 'Mover assinaturas do Azure entre tenants do Microsoft Entra ID' 
date: 2024-09-08 01:03:00
categories: [Azure]
tags: [azure, migrate]
slug: 'move-azure-subscription-tenant'
image:
  path: /assets/img/21/21-header.webp
---

Olá pessoal! Blz?

Nesse artigo eu quero trazer uma atividade rotineira de um **Azure Cloud Engineer** que é mover uma assinatura de um diretório (tenant) para outro, os motivos podem ser por questões de organização, quando uma empresa é comprada, feita uma fusão entre empresas ou outro que seja o motivo.

As empresas podem ter várias assinaturas do Azure e cada assinatura é associada a um diretório (tenant) específico do Microsoft Entra ID. Quando você transfere uma assinatura para um diretório diferente do Microsoft Entra, alguns recursos não são transferidos para o diretório de destino. Por exemplo, todas as permissões do Azure são excluídas permanentemente do diretório de origem e não são transferidas para o diretório de destino.

> Assinaturas CSP (Cloud Solution Providers) que são assinaturas providas por um parceiro Microsoft não podem ser movidas entre tenants
{: .prompt-info }

Para essa atividade temos alguns pré-requisitos e alguns cuidados que devemos ter antes de realizar essa atividade.

## Pré-requisitos

* Permissão de **Billing account owner** ou **Owner** da assinatura que você deseja transferir no diretório de origem
* Uma conta de usuário no diretório de origem e de destino para o usuário que faz a alteração de diretório

> Tenha a certeza que você tenha acesso nos 2 diretórios, no de origem e no de destino
{: .prompt-warning }

Para verificar se tem acesso ao diretório (tenant) de origem e destino você pode verificar seguindo os passos da imagem abaixo:

![azure-tenant-subscription](/assets/img/21/05.png)

Caso não tenha acesso você terá que pedir que alguém desse diretório que você não tem acesso, que te adicione ou convide para esse diretório. 

## Cuidados antes de mover a assinatura

Antes de mover uma assinatura devemos ter o cuidado de salvar as permissões atribuídas da assinatura, as custom roles e as "managed identities", pois como dito acima, essas permissões são todas perdidas durante a movimentação. Irei mostrar como fazer isso pelo portal e algumas por Azure CLI.

### Exportar as permissões RBAC

Pelo portal do Azure podemos exportar as permissões atribuídas e para isso temos que ter a permissão para essa atividade e a permissão de **contributor** já é suficiente para isso, no portal do Azure devemos seguir o seguinte passo a passo:

Na barra de pesquisa devemos buscar pelas **assinaturas:**

![azure-tenant-subscription](/assets/img/21/01.png)

Com a assinatura selecionada que iremos mover devemos ir em **Access control (IAM)** e depois em **Download role assignments** e depois **Start**:

![azure-tenant-subscription](/assets/img/21/02.png)

Eu geralmente deixo o padrão que é selecionado as permissões **herdadas (Inherited)**, **da assinatura selecionada (At current scope)** e deixo o formato padrão que é **CSV** pois é, pelo menos para mim, mais fácil de trabalhar e visualizar.

Se você preferir exportar por Azure CLI o comando é:

```powershell
az role assignment list --all --include-inherited --output tsv > roleassignments.tsv
```

### Salvar as Custom Roles

Para listar as custom roles usamos o comando abaixo: 

```powershell
az role definition list --custom-role-only true --output json --query '[].{roleName:roleName, roleType:roleType}'
```

Salve cada função personalizada que será necessária no diretório de destino como um arquivo JSON separado.

```powershell
az role definition list --name <custom_role_name> > customrolename.json
```

Depois faça cópias dos arquivos das custom roles, onde cada **custom role** será um arquivo.

### Listar as permissões "managed identities"

Identidades gerenciadas não são atualizadas quando uma assinatura é transferida para outro diretório, ou seja, todas as identidades serão perdidas. Após a transferência, você pode reabilitar todas as identidades gerenciadas atribuídas pelo sistema. Para identidades gerenciadas atribuídas pelo usuário, você precisará recriá-las e anexá-las no diretório de destino. Use o comando abaixo para listar as identidades gerenciadas:

```powershell
az ad sp list --all --filter "servicePrincipalType eq 'ManagedIdentity'"
```

## Mover a assinatura para outro diretório (Tenant)

Após os passos anteriores já estarem feitos e termos todo o "backup" das permissões podemos iniciar a transferência da assinatura para o outro diretório (tenant), para isso no menu **"Overview"** devemos escolher a opção **"Change directory"** e em **"To"** escolher qual será o diretório de destino e clicar no botão **"Change"**:

![azure-tenant-subscription](/assets/img/21/03.png)

> No combobox **"Select a directory"** (item 2), se você não tiver acesso ao diretório de destino você não o verá nessa lista para onde podemos mover a assinatura.
{: .prompt-info }

Aguarde a mensagem de confirmação de que a assinatura está sendo migrada. Pode levar até 10 minutos para que você possa reutilizar todos os recursos. No entanto, os recursos **não estão offline**, simplesmente não são exibidos. Normalmente não há tempo de inatividade com esse tipo de migração.


<img src="/assets/img/21/04.png" alt="azure-tenant-subscription" width="500">

## Concluindo!

Após o término da movimentação da assinatura, teremos que restabelecer **TODAS** as permissões que exportamos, pois como falamos acima, todas as permissões são perdidas, para isso não há uma forma automática para importar as permissões do arquivo exportado, mas nada impede que você crie um script powershell para importar as permissões.

Além das permissões, temos também que recriar as **Custom Roles** e as **identidades gerenciadas** perdidas, ou seja, o maior trabalho é agora em restabelecer as permissões como estava antes da movimentação.

> Lembrando que para adicionar as permissões primeiro você precisa estar com a permissão de **Owner** para realizar essa atividade.
{: .prompt-info }

Bom pessoal, espero que tenha gostado e que esse artigo seja útil a vocês!

## Artigos relacionados

<a href="https://learn.microsoft.com/en-us/azure/role-based-access-control/transfer-subscription" target="_blank">Transfer an Azure subscription to a different Microsoft Entra directory</a> 

<a href="https://learn.microsoft.com/en-us/azure/role-based-access-control/transfer-subscription#understand-the-impact-of-transferring-a-subscription" target="_blank">Understand the impact of transferring a subscription</a> 

Compartilhe o artigo com seus amigos clicando nos icones abaixo!!!
