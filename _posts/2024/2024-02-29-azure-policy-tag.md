---
title: 'Azure Policy para exigir uma Tag e não permitir que o valor dela fique em branco'
date: 2024-02-29
slug: 'azure-policy-tag'
categories:  ['Azure']
tags: ['Azure', 'Policy']
image:
  path: /assets/img/02/02-header.webp
---

Olá pessoal! Blz?

Primeiramente, gostaria de deixar claro que esse artigo não é sobre como usar o Azure Policy, para isso eu irei deixar alguns links de referência, mas sim descrever uma solução para ambientes onde precisamos exigir que uma TAG seja criada e **NÃO PERMITA** que o valor fique em branco.

Sei que existe algumas Policies Definitions para uso de TAG no Azure Policy que requerem o uso de TAG mas o problema é que essas Policies exigem que voce apenas use a TAG mas permite que seja criada com o valor em branco.

Primeiro vamos demonstrar um Assignments de uma Policy existente que não atende o que precisamos e depois um personalizado com o objetivo desse artigo.

## Assignments de uma Policy existente que permite não preencher o valor da tag

No portal do Microsoft Azure, pesquise por Azure Policy, depois clique em **“Assignments” -> “Assign policy”** para que possamos atribuir uma policy:

![azure-policy-tag](/assets/img/02/01.png)

Pesquisando por TAG no campo de busca voce filtra todas as policies relacionadas a TAG, usaremos nesse exemplo a policy **“Require a tag on resource groups”** e o escopo será na Assinatura toda.

![azure-policy-tag](/assets/img/02/02.png)

Irei especificar a TAG **CentroCusto** que foi a tag especifica que me pediram em um projeto em que trabalhei e após especificar o nome da tag pode clicar em “Salvar”.

![azure-policy-tag](/assets/img/02/03.png)

Da forma que configuramos ao criar um Resource Group, o Azure não deixara criarmos o Resource Group sem a tag “CentroCusto” mas permitirá criar o recurso sem preencher o valor da tag conforme vimos na imagem abaixo:

![azure-policy-tag](/assets/img/02/04.png)

Abaixo o Resource Group criado com a tag mas com o valor vazio:

![azure-policy-tag](/assets/img/02/05.png)

## Criando uma Policy personalizada

Para criarmos policies personalizadas devemos ir no menu **“Definitions” -> “+ Policy definition”** conforme imagem abaixo:

![azure-policy-tag](/assets/img/02/06.png)

Para criar uma policy definition temos alguns campos obrigatórios como location (Assinatura) nome, qual a categoria e nesse caso usaremos uma categoria já existente **“Tags”** e abaixo voce deve preencher com o código JSON com a definição do que queremos:

![azure-policy-tag](/assets/img/02/07.png)
<br>
```json
{
  "properties": {
    "mode": "All",
    "parameters": {
      "tagName": {
        "type": "String",
        "metadata": {
          "displayName": "Tag Name",
          "description": "Name of the tag, such as 'CostCenter'"
        }
      }
    },
    "policyRule": {
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
  }
}
```

Após colar o código, clicar no botão “Salvar” e o processo para realizar o Assignments da Policy é como fizemos na primeira parte desse artigo.

Como podem ver na imagem abaixo ao criar um Resource Group onde especificamos a tag “CentroCusto” mas deixamos o valor vazio e o Azure ja da o alerta de falha e com isso nos obriga a preencher o valor da tag para poder criar o Resource Group:

![azure-policy-tag](/assets/img/02/08.png)

E com o preenchimento do valor o Resource Group é criado:

![azure-policy-tag](/assets/img/02/09.png)

## Concluindo!

Bom pessoal, espero que esse artigo seja util a voces, para mim serviu muito e uso em todos os projetos que trabalho onde o cliente exige o preenchimento de tags especificas.

Antes eu tinha que contar com a boa vontade do usuário preencher o valor da tag 😉

## Artigos relacionados

<a href="https://learn.microsoft.com/pt-br/azure/governance/policy/overview" target="_blank">O que é o Azure Policy?</a>

<a href="ttps://learn.microsoft.com/pt-br/azure/governance/policy/assign-policy-portal" target="_blank">Criar uma atribuição de política para identificar recursos fora de conformidade.</a>

<hr>
Bom pessoal, espero que tenha gostado e que esse artigo seja útil a vocês!

Compartilhe o artigo com seus amigos clicando nos icones abaixo!!!
<hr>