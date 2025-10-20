---
title: "Listar e Inserir TAGs em recursos Azure já existentes com powershell"
date: 2025-05-20 01:00:00
categories: [Azure, Finops]
tags: [finops, azure]
slug: 'update-tags'
image:
  path: /assets/img/38/38-header.webp
---

Olá pessoal! Blz?

Às vezes não nos preocupamos com as TAGs quando criamos recursos no Microsoft Azure, seja por não ter um padrão definido e/ou ter que ficar pensando no que colocar e com certeza isso será ignorado e o recurso será criado sem TAGs.

Na minha opinião definir quais serão as TAGs deve ser um dos primeiros passos definidos em um planejamento do ambiente Azure, mas pode acontecer de você pegar um ambiente já com vários e vários recursos criados e em um certo momento você quer padronizar o uso de TAGs e com isso precisa preencher as TAGs nos recursos existentes.

Mas uma vez que o padrão seja definido e você já possui vários recursos criados seria trabalhoso fazer isso de forma manual, para isso podemos criar um script powershell para exportar as TAGs existentes para um arquivo CSV, preencher esse arquivo com as TAGs que precisamos e depois atualizar os recursos com as TAGs novas ou atualizadas.

Primeiramente, abaixo temos alguns casos de uso para TAGs, somente para dar uma ideia de onde podemos utilizar.

## Uso de TAGs no Azure

Usar tags (marcações) no Azure é uma prática recomendada por várias razões importantes, principalmente para melhorar a organização, o gerenciamento de custos, a governança e a operação dos recursos na nuvem. Aqui tem alguns exemplos que você pode usar as tags no Azure:

### Organização e Identificação de Recursos

- As tags permitem categorizar recursos de forma lógica, como por:

  - Projeto (ex: **projeto:marketing**)

  - Departamento (ex: **departamento:financeiro**)

  - Ambiente (ex: **ambiente:producao**, **ambiente:homologacao**)

  - Responsável (ex: **owner:joao.silva**)

- Facilita a busca e filtragem de recursos no portal do Azure, CLI ou PowerShell.

### Gestão de Custos e Otimização de Gastos

- Você pode agrupar custos por tags no Azure Cost Management, permitindo:

  - Identificar quais projetos/departamentos consomem mais recursos.

  - Gerar relatórios financeiros detalhados.

  - Alocar custos internamente

- Exemplo: Filtrar todos os custos com a tag **projeto:ecommerce.**

### Governança e Conformidade

- Políticas do Azure (Azure Policy) podem exigir tags para garantir padronização.

  - Exemplo: Bloquear a criação de recursos sem a tag ambiente.

- Ajuda a auditar recursos e aplicar normas de segurança (ex: **criticidade:alta**).

### Automação e Operações

- Scripts (Azure PowerShell, CLI) podem usar tags para automatizar ações, como:

- Parar/Iniciar VMs com a tag **ambiente:dev** fora do horário comercial.

- Aplicar backups apenas a recursos com **backup:sim**.

### Segurança e Controle de Acesso

- Tags podem ser usadas em RBAC (Role-Based Access Control) para restringir acesso a recursos específicos.

- Exemplo: Permitir que apenas a equipe de **departamento:ti** gerencie recursos com essa tag.

### Recuperação de Desastres e Gerenciamento de Recursos

- Em cenários de falha, tags ajudam a identificar rapidamente recursos críticos (ex: **prioridade:alta**).

## Exportar os recursos com suas TAGs

O primeiro passo vamos exportar os recursos existentes no Azure com suas TAGs para que de uma maneira mais fácil possamos atualizar e incluir os valores, para isso vamos usar um código PowerShell:

```powershell
connect-azaccount -Tenant "xxxxxxx-xxxxxx-xxxxxx-xxxxxx"
$SubscriptionId = "xxxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx"
$azContext = Set-AzContext -Subscription $SubscriptionId

$Output = @()
$Resources = Get-AzResource
$UniqueTags = $Resources.Tags.GetEnumerator().Keys | Get-Unique -AsString | Sort-Object | Select-Object -Unique | Where-Object {$_ -notlike "hidden-*" }

foreach ($Resource in $Resources) {
    $Hashtable = New-Object System.Collections.Specialized.OrderedDictionary
    $Hashtable.Add("ResourceId",$Resource.ResourceId)
    $Hashtable.Add("ResourceName",$Resource.ResourceName)
    $Hashtable.Add("ResourceType",$Resource.ResourceType)

    if ($Resource.Tags.Count -ne 0) {
        $UniqueTags | Foreach-Object {
            if ($Resource.Tags[$_]) {
                $Hashtable.Add($_,$Resource.Tags[$_])
            }
            else {
                $Hashtable.Add($_,"")
            }
        }
    }
    else {
        $UniqueTags | Foreach-Object { $Hashtable.Add($_,"") }
    }
    $Output += New-Object psobject -Property $Hashtable
}
$Output | Export-Csv -Path "tag-resources.csv" -append -NoClobber -NoTypeInformation -Encoding UTF8 -Force
```

Será gerado um arquivo CSV como a imagem abaixo, o arquivo contém alguns campos como Nome do recurso, ID do Recurso e as TAGs já existentes:

![update-tags](/assets/img/38/01.png){: .shadow .rounded-10}

## Preencher a planilha com os valores

A ideia é preencher as tags que estão faltando e nesse nosso caso de exemplo iremos adicionar uma tag **"costCenter"** para podermos depois em um exemplo ver os custos separados por essa tag, abaixo a planilha preenchida:

![update-tags](/assets/img/38/02.png){: .shadow .rounded-10}

## Atualizar os recursos com as TAGs

Após o preenchimento da planilha com as tags que estavam faltando e adicionar a tag que gostaríamos temos que realizar o **"update"** do recurso no Azure com esses valores, no script abaixo vamos ler essa planilha e fazer o **merge** com os valores já existentes:

```powershell
$ResourcesCsv = import-csv -path "tag-resources.csv" -delimiter ";"

foreach ($Resource in $ResourcesCsv) {
  $tags = @{}
  if ($resource.Ambiente) {
    $tags["Ambiente"] = $resource.Ambiente
  }

  if ($resource.Owner) {
    $tags["Owner"] = $resource.Owner
  }

  if ($resource.Stop) {
    $tags["Stop"] = $resource.Stop
  }

  if ($resource.costCenter) {
    $tags["costCenter"] = $resource.costCenter
  }
  
  # Atualiza as TAGs do recursos preservando as existentes, por isso escolhemos o modo de operação "merge"
  Update-AzTag -ResourceId $resource.ResourceId -Tag $tags -Operation Merge

}
```

Após executar o script podemos ver os recursos onde não possuía as TAGs com os valores que preenchemos na planilha:

![update-tags](/assets/img/38/03.png){: .shadow .rounded-10}

## Uso de TAGs para gestão de custos  

Após o preenchimento da TAG **costCenter** vamos realizar um filtro e ver qual o custo para todos os recursos que possuem a tag **costCenter:seguranca**

![update-tags](/assets/img/38/04.png){: .shadow .rounded-10}

> Identificando a área responsável do recurso no Azure através de uma TAG específica podemos realizar um "rateio" de custo e enviar a fatura para essa área.
{: .prompt-tip } 

## Concluindo!

Em um ambiente de nuvem cada vez mais complexo, as tags no Azure se destacam como uma ferramenta simples, porém poderosa, para transformar a gestão de recursos. Elas vão além da organização básica, tornando-se aliadas essenciais no controle de custos, na governança automatizada, na segurança granular e até mesmo na otimização de operações.

Ao adotar uma estratégia bem definida de tags — com padrões claros, políticas de enforcement e integração a ferramentas como Azure Policy e Cost Management — empresas conseguem não apenas reduzir desperdícios, mas também acelerar processos, melhorar a visibilidade e garantir conformidade sem sacrificar a agilidade.

Bom pessoal, eu tenho usado isso em alguns ambientes e acredito que possa ser bem útil a vocês!

## Artigos relacionados

<a href="https://learn.microsoft.com/en-us/azure/cloud-adoption-framework/ready/azure-best-practices/resource-tagging" target="_blank">Define your tagging strategy</a>

<a href="https://learn.microsoft.com/en-us/azure/azure-resource-manager/management/tag-resources" target="_blank">Use tags to organize your Azure resources and management hierarchy</a>

Compartilhe o artigo com seus amigos clicando nos icones abaixo!!!