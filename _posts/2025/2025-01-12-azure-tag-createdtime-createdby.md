---
#layout: post
title: "Azure Tag: Inserir tags 'createdOnDate' e 'createdBy' nos recursos de forma automática"
date: 2025-01-12 01:33:00
categories: [Azure]
tags: [azure, tag]
slug: 'azure-tag-createdondate-createdby'
image:
  path: /assets/img/30/30-header.webp
---

Olá pessoal! Blz?

Nesse artigo quero trazer algo a vocês que tenho feito em ambientes Azure onde passo, que é criar duas tags para identificar quem criou o recurso através da tag **createdBy** e quando foi criado o recurso com a tag **createdOnDate**, nós todos sabemos da importância de nos habituarmos a colocar tag em todos os recursos para que com isso possamos identificar de forma fácil os recursos, relatórios de custo e tantas outras formas que podemos fazer e/ou identificar com as tags. As tags podem ser aplicadas aos recursos do Azure, grupos de recursos e assinaturas, mas não aos grupos de gerenciamento.

Mas o porque de criar essas tags, por padrão o log de deployments no Azure são armazenados por 90 dias e uma maneira de se manter isso são pelas tags, onde facilmente você consegue identificar quem e quando o recurso foi criado. As tags seriam algo como na imagem abaixo:

![azure-tag-createdondate-createdby](/assets/img/30/01.png){: .shadow .rounded-10}

Para conseguir isso de forma automática a forma que encontrei foi para a tag **createdonDate** usar uma Azure Policy e para a tag **createdBy** um script PowerShell executado diariamente através de uma Azure Automation Account, entao vamos dividir o artigo em duas partes para ficar melhor explicado.

## Tag createdOnDate com Azure Policy

Nessa policy para inserir a tag **createdOnDate** ela é executada ao criar um recurso, ela verifica que o recurso não terá a tag **createdOnDate** e irá inserir a tag **createdOnDate** e a data e hora atual. Para criarmos a policy no portal do Microsoft Azure buscamos por Azure policy e com o recurso aberto vamos em **Definitions** e **+ Policy definition**:

![azure-tag-createdondate-createdby](/assets/img/30/02.png){: .shadow .rounded-10}

Na tela a seguir temos o campo ***Definition location*** que é onde escolhemos o escopo que será aplicado a policy clicando nos ***"..."***, podemos selecionar um Management Group ou uma Subscription, depois de selecionar onde deseja aplicar a policy devemos clicar no botão ***Select***.

![azure-tag-createdondate-createdby](/assets/img/30/03.png){: .shadow .rounded-10}

Depois temos que escolher um nome que identifique de forma fácil o que a tag faz e para complementar isso podemos definir uma descrição mas isso é opcional. Em ***Categoria*** você pode definir uma nova categoria como uma categoria para as policies criadas para sua empresa ou escolher uma existente:

![azure-tag-createdondate-createdby](/assets/img/30/04.png){: .shadow .rounded-10}

Em ***Policy rule*** vamos limpar todo o conteúdo e colar o seguinte JSON, e depois para concluir clicar no botão **Save**.

```json
{
  "mode": "All",
  "policyRule": {
    "if": {
      "allOf": [
        {
          "field": "tags['CreatedOnDate']",
          "exists": "false"
        }
      ]
    },
    "then": {
      "effect": "append",
      "details": [
        {
          "field": "tags['CreatedOnDate']",
          "value": "[concat(substring(utcNow(),5,2),'-', substring(utcNow(),8,2),'-',substring(utcNow(),0,4),' - ',substring(utcNow(),11,8))]"
        }
      ]
    }
  },
  "parameters": {}
}
```

Com a policy criada temos que fazer o ***Assign policy*** da mesma forma que fazemos com qualquer policy, para isso devemos ir no botão **Assign policy** e o único ponto que devemos/precisamos alterar caso você precise é alterar o escopo, por exemplo caso você queira testar a policy em somente um resource group, caso contrário é só ir avançando e concluir para ser aplicada:

![azure-tag-createdondate-createdby](/assets/img/30/05.png){: .shadow .rounded-10}

Com isso ao criar qualquer recurso a tag **createdOnDate** é adicionada com a data e hora atual.

## Tag createdBy com PowerShell

Eu pesquisei e tentei criar essa tag como fizemos na outra tag acima usando uma Azure Policy, que é simples e funcional, mas realmente não consegui, mas se você tiver isso implementado ou alguma idéia de como fazer por favor me avise 🤩🤩.

Bom para o PowerShell, o que ele faz é buscar nos logs dos recursos quem criou o recurso através do campo **Caller**, eu personalizo depois com esse campo buscar o **Display Name** no Microsoft Entra ID, mas para usuários externos (convidados) eu deixo o e-mail porque um dia quando a pessoa não estiver mais prestando serviço e não pertencer mais ao meu Tenant ao olhar para o nome dela pode ser que eu não me recorde de imediato. Você pode contornar o caso que falei agora criando também uma tag com o nome do Departamento ou Empresa, algo do tipo para identificar quem é a pessoa que criou o recurso.

```powershell
$resources = Get-AzResource
$resources += Get-AzResourceGroup
foreach ($resource in $resources) {
  $tags = $resource.Tags

  if (!($tags.ContainsKey("createdBy"))) {

    $endTime = (Get-Date)
    $startTime = $endTime.AddDays(-1)

    $caller = Get-AzLog -ResourceId $resource.ResourceId -StartTime $startTime -EndTime $endTime |
      Where-Object {$_.Authorization.Action -like "*/write*"} |
      Select-Object -ExpandProperty Caller |
      Group-Object |
      Sort-Object  |
      Select-Object -ExpandProperty Name 

    $caller = $caller | select-Object -first 1

    $createdBy = Get-AzAdUser -Filter "userPrincipalName eq '$caller'" 
    if ($createdBy -ne $null) {
      $createdby = $createdby.displayName
    } else {
      $createdBy = $caller
    }

    $modifiedTags = @{
            "createdBy" = $createdby
    }
    # Merge existing tags with new tags
    $allTags = $tags + $modifiedTags
    Update-AzTag -ResourceId $resource.ResourceId -Tag $allTags -Operation Merge
  }
}
```

Você vai ver a variável **$resources** duas vezes, isso porque o comando ***get-aAzResource*** não seleciona os resource groups então eu incremento a consulta os resource groups com o comando ***get-AzResourceGroup***. 

> Não sou especialista em PowerShell então se você tiver alguma sugestão de alguma melhoria ficarei agradecido com a dica e o script acima dá alguns erros de output mas funciona para o que queremos, então não se preocupe 😂😂
{: .prompt-info }

No script eu pesquiso nos logs de todos os recursos criados no último dia com a variável `$startTime = $endTime.AddDays(-1)` e crio um Azure Automation Account para executar todos os dias, você pode conferir como criar o <a href="https://arantes.net.br/posts/azure-automation-account" target="_blank">Azure Automation Account nesse artigo.</a>

## Concluindo!

Com os passos acima conseguimos começar a ter um padrão de Tags em nosso ambiente Microsoft Azure, o obrjetivo é que conseguindo identificar quem criou e quando o recurso pode nos ajudar em um relatório ou identificar quem anda a criar recursos na assinatura, com isso podendo remover acessos de pessoas que não deveriam ter.

Com emncionado no começo do artigo o resultado esperado é esse: 

![azure-tag-createdondate-createdby](/assets/img/30/01.png){: .shadow .rounded-10}

Bom pessoal, eu tenho usado isso em alguns ambientes e acredito que possa ser bem útil a vocês!

## Artigos relacionados

<a href="https://learn.microsoft.com/en-us/azure/azure-resource-manager/management/tag-resources" target="_blank">Azure Tags  </a> 

<a href="https://learn.microsoft.com/en-us/azure/governance/policy/overview" target="_blank">Azure Policy</a> 

Compartilhe o artigo com seus amigos clicando nos icones abaixo!!!
