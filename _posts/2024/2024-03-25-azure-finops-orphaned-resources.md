---
title: 'Azure FinOps: como diminuir custos removendo recursos órfãos'
date: 2024-03-25 10:33:00
slug: 'azure-finops-orphaned-resources'
categories:  ['Azure', 'Finops']
tags:  ['Azure', 'Finops']
image:
  path: assets/img/07/07-header.webp
---

Olá pessoal! Blz?

Esses dias pesquisando sobre relatórios para gerenciamento de custos no Microsoft Azure e estudando um pouco sobre Finops, encontrei um projeto no GitHub que achei muito interessante e decidi compartilhar com vocês. O projeto chama-se **Azure Orphaned Resources v2.0**, você pode ler mais no <a href="https://github.com/dolevshor/azure-orphan-resources" target="_blank">repositório do projeto no GitHub.</a> 

Ele usa um Azure Workbook para listar de forma visual em forma de dashboard os recursos órfãos em sua assinatura do Microsoft Azure e com esse dashboard você pode tomar uma decisão sobre esses recursos, desde excluir ou mover para outro local, ou quem sabe mesmo reutilizar esses recursos.

Como pode ver na imagem abaixo, na minha assinatura  tenho alguns recursos com custos sem uso que estão me gerando gastos desnecessários, ***App Service Plan***, ***Discos Gerenciados*** e ***IP Público***:

> 💲 Este simbolo na frente do tipo do recurso  mostra que esse recurso tem custo no Azure
{: .prompt-tip }

![finops](/assets/img/07/01.png)

## Como criar o Workbook em nosso ambiente

1 - Para criar o Workbook no Azure, digite na barra de pesquisa "Azure workbook" e clique no serviço para iniciar a configuração:

![finops](/assets/img/07/02.png)

2 - Clique no botão **"+ Create"** e depois em **"+ New"** para criar o recurso:

![finops](/assets/img/07/03.png)

3 - Depois clique no botão  **"</>"** que é o "Advanced Editor" para colarmos o código:

![finops](/assets/img/07/04.png)

4 - Apague o código que temos em "Template Type" => "Gallery Template" e cole o código que você pode baixar diretamente aqui: <a href="/assets/img/07/Azure_Orphaned_Resources_v2.0.workbook" target="_blank">Azure Orphaned Resources v2.0.workbook</a>.

Após colar o código no local informado abaixo clique em **"✓  Apply"**

![finops](/assets/img/07/05.png)

5 - Clique no botão **"Salvar"**, você precisa preencher o título do Workbook, Assinatura, Resource Group e Região e depois clique no botão **"Apply"**:

![finops](/assets/img/07/06.png)

6 - O seu Azure Workbook está pronto para uso, agora é so escolher o workbook criado e ver o Dashboard com os recursos órfãos:

> 💲 Lembrando que este simbolo na frente do tipo do recurso mostra que esse recurso tem custo no Azure
{: .prompt-tip }

![finops](/assets/img/07/09.PNG)

Se você tiver mais de uma assinatura você pode filtrar qual deseja ver os recursos ou selecionar todas assinaturas:

![finops](/assets/img/07/07.png)

Existem algumas abas separando por tipo de recurso onde é possivel ver o detalhe dos recursos, no caso abaixo estamos olhando os discos dentro da aba **"Storage"**:

![finops](/assets/img/07/08.png)

## Concluindo!

À medida que as organizações adotam serviços em nuvem para impulsionar sua infraestrutura, surgem novos desafios relacionados ao controle de custos e à otimização do uso dos recursos. Uma frase que já ouvi mas não lembro onde e muito importante: ***"A Cloud pode impulsionar seu negócio, mas o uso sem controle pode falir a sua empresa."***

Com a facilidade em criar recursos ter uma rotina de controle e/ou acompanhamento é fundamental. Mesmo acompanhando de perto meu ambiente, havia alguns recursos que eu não sabia que estavam órfãos, então todo controle é bem vindo!

Bom pessoal, espero que tenha gostado e que esse artigo seja util a voces!

## Artigos relacionados

<a href="https://github.com/dolevshor/azure-orphan-resources" target="_blank">Azure Orphaned Resources v2.0</a> 

<hr>

Compartilhe o artigo com seus amigos clicando nos icones abaixo!!!