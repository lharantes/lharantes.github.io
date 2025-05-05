---
title: "Relatório diário de custos no Microsoft Azure"
date: 2025-04-20 01:00:00
categories: [Azure]
tags: [azure, powershell]
slug: 'daily-azure-cost-report'
image:
  path: assets/img/36/36-header.webp
---

Olá pessoal! Blz?

O que trago nesse artigo foi algo para a minha necessidade, mas pode ser útil a vocês, eu tenho 02 (duas) assinaturas Visual Studio do Microsoft Azure onde tenho créditos mensais para testes e laboratórios, elas possuem um crédito mensal de $150.00, em Reais é liberado R$ 860.00, mas não sei quando eles atualizam a cotação.

Vira e mexe com a correria do dia a dia eu crio um recurso ou monto um ambiente para laboratório e esqueço de apagar ou desligar, com isso fica consumindo os créditos sem necessidade. Outro ponto também que às vezes com o dia ocupado eu não acesso minhas assinaturas e não vejo como está ou o que tem lá. 

Eu já criei um artigo sobre o <a href="https://arantes.net.br/posts/azure-budget/" target="_blank">Orçamento/Budget no Azure</a> e tenho isso configurado, mas eu deixo configurado alerta de 50% e 80%, só que eu não quero que chegue nesse ponto, pois já terá consumido algo sem necessidade e que poderia ser evitado😊😊.

Foi aí que tive a ideia de criar um relatório diário com o custo atual da assinatura, uma previsão dos gastos no mês e receber isso por e-mail, fazendo isso em PowerShell, eu tenho o hábito de toda manhã ler os meus e-mails e recebendo o relatório de gastos do Azure logo no início do dia eu já abro o portal do Microsoft Azure e apago ou desligo o recurso que está sendo usado sem necessidade.

O e-mail que recebo com o relatório é o da imagem abaixo:

![daily-azure-cost-report](/assets/img/36/01.png){: .shadow .rounded-10}

Olhando para o grupo de recurso eu consigo saber o custo e se ele ainda deveria ou não estar lá 😜😜.

> O próximo passo **talvez** será aprender PowerBi e ter isso mais bonito com gráficos e um layout mais bonito.
{: .prompt-info } 

## Explicando os campos do relatório

#### Período

O primeiro campo "Período" se refere ao período atual que está sendo gerado os valores, o relatório como falei acima foi pensado em me dar o valor atual da assinatura, porém, as minhas assinaturas não têm o mesmo período de custo, por exemplo, a do MCT ela segue "normal" do dia 01 ate o último dia do mês, mas a minha outra assinatura é algo como dia 08 à 07 do próximo mês, então precisei pegar essa informação da assinatura e fazer baseado nesse período de custo. 

#### Custo atual

Aqui não tem muito segredo, é o custo atual até o momento da geração do relatório. Vale lembrar que o custo atual não se refere apenas aos custos dos recursos que existem atualmente, se você criou um recurso no passado, mas o removeu ele teve um custo e isso tem que ser computado, e no relatório está sendo considerado isso.

#### Custo previsto

O script faz uma chamada API Rest para pegar essa informação, ela a previsão de custo dos recursos que existem atualmente na assinatura dentro do período de custo.

#### Saldo crédito

Como falei acima, minhas assinatura possuem um crédito de $150 dolares e é creditado R$ 860. Como não sei qual conversão é utilizada e não sei se é atualizada a cotação durante o mês eu simplesmente deixei uma varável fixa no script com o valor, isso quero entender melhor como funciona e ajustar o script para ficar mais correto possível.

> Se você estiver usando uma assinatura PAYG (Pay as you go) eu vou deixar abaixo também o script para remover esse campo, pois não fará sentido para quem usa esse tipo de assinatura.
{: .prompt-tip } 

## Script para gerar o relatório

O script abaixo em PowerShell, basicamente, se conecta a assinatura que deseja extrair as informações usando um Service Principal preenchendo as primeiras variáveis, gera uma página HTML e a envia para o e-mail configurado no script. 

Para o envio diário do e-mail estou usando uma Azure Automation Account e você pode consultar como fazer isso no artigo <a href="https://arantes.net.br/posts/azure-automation-account/" target="_blank">Automatizar tarefas com o Azure Automation Account</a>.

### Pré-requisitos

- Powershell instalado se for executar localmente ou Azure Automation Account se for automatizar o envio.
- Permissões da identidade gerenciada: `Cost management reader` nas Assinaturas que irá gerar o custo.
- Azure PowerShell Modules: `Microsoft.Graph.Applications`, `Microsoft.Graph.Authentication`, `Microsoft.Graph.Mail` e `Microsoft.Graph.Users.Actions`.

Abaixo o script completo para gerar o relatório:

```powershell
# Variaveis para conectar ao Entra ID
$ClientId       = "xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx"
$TenantId       = "xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx"
$SecretId       = "xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx"
$SubscriptionId = "xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx"

$Secret = ConvertTo-SecureString -String $SecretId -AsPlainText -Force
$Credential = New-Object -TypeName System.Management.Automation.PSCredential -ArgumentList $ClientId, $Secret
Connect-AzAccount -ServicePrincipal -TenantId $TenantId -Credential $Credential

$azContext            = Set-AzContext -Subscription $SubscriptionId
$subscriptionName     = (Get-AzSubscription -SubscriptionId $SubscriptionId).name 
$currentBillingPeriod = Get-AzBillingPeriod -MaxCount 1
$startDate            = $currentBillingPeriod.BillingPeriodStartDate.ToString("yyyy-MM-dd") 
$endDate              = $currentBillingPeriod.BillingPeriodEndDate.ToString("yyyy-MM-dd") 
$currentCost          = (Get-AzConsumptionUsageDetail -StartDate $startDate -EndDate $endDate | Measure-Object -Property PretaxCost -Sum).sum
$currentCost          = ([Math]::Round($currentCost, 2))
$currency             = (Get-AzConsumptionusagedetail | Select-Object -First 1).Currency

# Atualmente é o valor creditado todo mês para uso em R$
$creditAzure = "860"

# API RESP para consultar e calcular a previsao dos custos ate o final do periodo com os recursos atuais
$azProfile = [Microsoft.Azure.Commands.Common.Authentication.Abstractions.AzureRmProfileProvider]::Instance.Profile
$profileClient = New-Object -TypeName Microsoft.Azure.Commands.ResourceManager.Common.RMProfileClient -ArgumentList ($azProfile)
$token = $profileClient.AcquireAccessToken($azContext.Subscription.TenantId)

$authHeader = @{                                                                                                                                    
    'Content-Type'='application/json'  
    'Authorization'='Bearer ' + $token.AccessToken  
} 
$body = @"
{
    type: "Usage",
    dataset: {
              "granularity": "none",
              "aggregation":{
                             "totalCost":{
                                          "name":"Cost",
                                          "function":"Sum"
                                          }
                             }
             },
    timeframe: "MonthToDate",
    timePeriod: {
                 from: "$startDate",
                 to: "$endDate"
                 }
}
"@

$url = "https://management.azure.com/subscriptions/$SubscriptionId/providers/Microsoft.CostManagement/forecast?api-version=2024-08-01"

$UsageData = Invoke-RestMethod `
-Method Post `
-Uri $url `
-ContentType application/json `
-Headers $authHeader `
-Body $body

$forecastData = $UsageData.properties.rows

Foreach ($forecast in $forecastData){
       $forecastCost = $forecast[0]
}
$forecastTotal = ([Math]::Round($forecastCost + $currentCost, 2))

# Calculo para os creditos restantes
$creditRemain = $creditAzure - $currentCost

# Aqui é somente para estetica para exibir a data no formato dia/MES
$startDate = $currentBillingPeriod.BillingPeriodStartDate.ToString("dd/MM") 
$endDate = $currentBillingPeriod.BillingPeriodEndDate.ToString("dd/MM") 

# Conteudo para gerar uma pagina HTML
$bodyEmail = @"
<!DOCTYPE html>
<html>
<head>
    <style>
        body { font-family: Arial, sans-serif; margin: 0; padding: 0;  background-color: black}
        table { border-collapse: collapse; width: 100%; }
        td { padding: 10px; }
        .header { background-color: #009879; color: white; font-weight: bold; }
        .dark-bg { background-color: #282C34; color: white; }
        .card-title { color: #B0B0B0; font-size: 14px; font-weight: bold; }
        .card-value { font-size: 24px; font-weight: bold; color: white; }
        .circle-red { background-color: #d63031; width: 36px; height: 36px; border-radius: 50%; text-align: center; color: white; }
        .circle-blue { background-color: #0984e3; width: 36px; height: 36px; border-radius: 50%; text-align: center; color: white; }
        .circle-orange { background-color: #ff7675; width: 36px; height: 36px; border-radius: 50%; text-align: center; color: white; }
        .circle-green { background-color: #00b894; width: 36px; height: 36px; border-radius: 50%; text-align: center; color: white; }
        .border-left-red { border-left: 5px solid #d63031; }
        .border-left-blue { border-left: 5px solid #0984e3; }
        .border-left-orange { border-left: 5px solid #ff7675; }
        .border-left-green { border-left: 5px solid #00b894; }
        .resource-table th { border-bottom: 1px solid #3e3e56; color: white; text-align: left; padding: 10px; }
        .resource-table td { border-bottom: 1px solid #3e3e56; color: white; padding: 10px; }
    </style>
</head>
<body>
    <table>
        <tr class="header">
            <td style="font-size: 25px;">$subscriptionName</td>
        </tr>
    </table>

    <table style=" background-color: black; padding: 20px;">
        <tr>
            <td>
                <table>
                    <tr>
                        <td width="25%" style="padding: 10px;">
                            <table class="dark-bg border-left-orange" style="width: 100%;">
                                <tr>
                                    <td style="padding: 20px;">
                                        <p class="card-title">PERÍODO</p>
                                        <p class="card-value">$StartDate - $EndDate</p>
                                    </td>
                                    <td style="width: 50px; vertical-align: top; padding-top: 20px;">
                                        <div class="circle-orange" style="display: flex; align-items: center; justify-content: center;">
                                            <span style="font-size: 20px;">&#128197;</span>
                                        </div>
                                    </td>
                                </tr>
                            </table>
                        </td>

                        <td width="25%" style="padding: 10px;">
                            <table class="dark-bg border-left-blue" style="width: 100%;">
                                <tr>
                                    <td style="padding: 20px;">
                                        <p class="card-title">CUSTO ATUAL</p>
                                        <p class="card-value">$currency $currentCost</p>
                                    </td>
                                    <td style="width: 50px; vertical-align: top; padding-top: 20px;">
                                        <div class="circle-blue" style="display: flex; align-items: center; justify-content: center;">
                                            <span style="font-size: 20px;">&#128176;</span>
                                        </div>
                                    </td>
                                </tr>
                            </table>
                        </td>

                        <td width="25%" style="padding: 10px;">
                            <table class="dark-bg border-left-red" style="width: 100%;">
                                <tr>
                                    <td style="padding: 20px;">
                                        <p class="card-title">CUSTO PREVISTO</p>
                                        <p class="card-value">$currency $forecastTotal</p>
                                    </td>
                                    <td style="width: 50px; vertical-align: top; padding-top: 20px;">
                                        <div class="circle-red" style="display: flex; align-items: center; justify-content: center;">
                                            <span style="font-size: 20px;">&#128181;</span>
                                        </div>
                                    </td>
                                </tr>
                            </table>
                        </td>
                        <td width="25%" style="padding: 10px;">
                            <table class="dark-bg border-left-green" style="width: 100%;">
                                <tr>
                                    <td style="padding: 20px;">
                                        <p class="card-title">SALDO CRÉDITO</p>
                                        <p class="card-value">$currency $creditRemain</p>
                                    </td>
                                    <td style="width: 50px; vertical-align: top; padding-top: 20px;">
                                        <div class="circle-green" style="display: flex; align-items: center; justify-content: center;">
                                            <span style="font-size: 20px;">&#128178;</span>
                                        </div>
                                    </td>
                                </tr>
                            </table>
                        </td>
                    </tr>
                </table>

                <table style="height: 30px;"><tr><td></td></tr></table>

                <table class="dark-bg" style="width: 100%;">
                    <tr>
                        <td style="padding: 20px;">
                            <h2 style="text-align: center; color: white; margin-top: 0;">CUSTO POR GRUPO DE RECURSO</h2>
                            <table class="resource-table" style="width: 100%;">
                                <tr>
                                    <th>GRUPO DE RECURSO</th>
                                    <th>REGIÃO</th>
                                    <th>CUSTO - $currency</th>
                                </tr>
"@

# Para calcular o custo de cada Resource Group
$rgs = get-azresourcegroup

# quando temos muitos Resource Groups ele da o erro de "too request" então a cada 5 RGs eu dou uma pausa de 60 segundos
$i = 0

foreach ($rg in $rgs) {
    $currentRgCost = Get-AzConsumptionUsageDetail -StartDate $currentBillingPeriod.BillingPeriodStartDate -EndDate $currentBillingPeriod.BillingPeriodEndDate -ResourceGroup  $rg.resourcegroupname | Measure-Object -Property PretaxCost -Sum 
    $totalRgCost   = ([Math]::Round($currentRgCost.Sum, 2))
    $i++
    if ($i -eq 5 -Or $i -eq 10 -Or $i -eq 15) {
        Start-Sleep -Seconds 60
    }
    $bodyEmail += '<tr><td style="padding: 10px; font-size: 15px">'+($rg.resourcegroupname).ToUpper()+'</td><td>'+($rg.location).ToUpper()+'</td><td>'+$totalRgCost+'</td></tr>'
}

# Salva tudo em uma variavel para o corpo do e-mail
$bodyEmail += "</table></div></div></main></div></body></html>"

# Conectar ao Microsoft Graph 
Connect-MgGraph -TenantId $TenantId -ClientSecretCredential $Credential

# Detalhes do E-mail 
$sender    = "no-reply@arantes.net.br"
$recipient = "luiz@arantes.net.br"
$subject   = "Cost Report - $subscriptionName"
$type      = "HTML"   # pode ser Text
$save      = "false"  # salvar o e-mail nos "Itens enviados"

$params = @{
    Message           = @{
        Subject       = $subject
        Body          = @{
            ContentType = $type
            Content     = $bodyEmail 
        }
        ToRecipients  = @(
            @{
                EmailAddress = @{
                    Address  = $recipient
                }
            }
        )
    }
    SaveToSentItems = $save
}

# Envia o e-mail
Send-MgUserMail -UserId $sender -BodyParameter $params
```

## Relatório para assinaturas sem créditos

Para assinaturas onde não temos créditos, assinaturas do tipo **PAYG** (Pay As You GO), **CSP** (Cloud Solution Provider) ou **EA** (Enterprise Agreement), podemos usar o script que não calcula os crédito restante, <a href="https://github.com/lharantes/arquivos-blog/blob/main/daily-azure-cost-report/daily-report-no-credit.ps1" target="_blank">
podemos baixar nesse link.</a>

![daily-azure-cost-report](/assets/img/36/02.png){: .shadow .rounded-10}

## Concluindo!

Custo em ambientes Cloud é um assunto delicado em qualquer cloud, e controlar ou acompanhar os custos é sempre uma tarefa que devemos ter isso de forma bem controlada. Esse script não foi feito para ambientes corporativos, mas pode ajudar como um ponto de partida e qualquer dúvida estou a disposição para melhorá-lo.

Bom pessoal, eu tenho usado isso em alguns ambientes e acredito que possa ser bem útil a vocês!

## Artigos relacionados

<a href="https://learn.microsoft.com/en-us/rest/api/cost-management/" target="_blank">Microsoft Cost Management</a>

<a href="https://learn.microsoft.com/en-us/powershell/module/az.costmanagement/?view=azps-13.4.0&viewFallbackFrom=azps-13.2.0" target="_blank">Az.CostManagement</a>

Compartilhe o artigo com seus amigos clicando nos icones abaixo!!!