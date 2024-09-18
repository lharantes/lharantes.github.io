---
#layout: post
title: 'Service principal: e-mail com secrets e certificados que irão expirar em alguns dias' 
date: 2024-09-17 11:33:00
categories: [Azure, Powershell]
tags: [azure, powershell]
slug: 'service-principal-secret-certificate-expire-report'
image:
  path: assets/img/23/23-header.webp
---

Olá pessoal! Blz?

Nesse artigo trago a vocês algo mais usado em ambientes corporativos, um relatório, mensal, semanal ou diário, que traga uma relação de todos os secrets e certificados dos Service Principals que irão vencer em uma **quantidade "x" de dias**. Mas se você está perguntado o porque disso é porque nunca passou por um sistema que para do nada e ninguém acha o defeito, e quando vai ver é porque o secret/certificado do service principal expirou 😆😆.

Usamos o service principal para dar acesso a algum recurso seja no **Microsoft Azure** ou **Microsoft ENTRA ID**, isso habilita recursos principais como a autenticação do usuário/aplicativo durante a entrada, bem como a autorização durante o acesso aos recursos.

Para criar um service principal fazemos isso pelo portal web ou por powershell/azure cli como descrevi <a href="https://arantes.net.br/posts/azure-powershell-commands/#4---criar-um-service-principal" target="_blank">nesse artigo</a>, o problema que vejo criando um service principal por linha de comando é que, pelo menos eu não consegui, não é possivel definir um **"Owner/Proprietário"** daquele service principal e quando esse expira não temos fácil a mão quem devemos procurar para saber se ainda é necessário ou não aquela credencial.

## Solução proposta

Não tem nada nativo pelo portal da Microsoft que traga esse relatório ou alerta, até mesmo o script powershell que a Microsoft disponibiliza no learn ela frisa bem que aquilo não é oficial, <a href="http://arantes.net.br/posts/service-principal-secret-certificate-expire-report/#artigos-relacionados"> deixarei o link abaixo </a>, o que eu fiz então foi pegar o script disponibilizado e adaptar para o que eu preciso. O e-mail que recebo semanalmente é o da imagem abaixo e que iremos fazer nesse artigo:

![service-principal](/assets/img/23/01.png)

Para receber o relatório eu estou usando um recurso do Azure chamado **Automation Account**, configurei para disparar o runbook semanalmente e defini o período para me avisar do que irá expirar nos próximos 30 dias, mas esse período você pode definir no script.

Nesse artigo irei demonstrar somente o script powershell que já é suficiente para você executar manualmente e no próximo artigo irei detalhar o uso do Azure Automation Account.

> Como meu ambiente é pequeno e a grande maioria dos recursos são para estudos e laboratórios o aviso de 30 dias funciona bem para mim
{: .prompt-tip }

## Criar um Service Principal com permissões nos Entra ID

Para conseguirmos extrair informações do Microsoft Entra ID iremos usar um service principal com algumas permissões específicas, vamos criar o service principal pelo portal pois é mais fácil dar as permissões. No portal do Microsoft Azure, digite ***"Entra ID"*** na caixa de pesquisa:

![service-principal](/assets/img/23/02.png)

<br>
Ao abrir o entra ID devemos escolher a opção **"App registrations"** e depois **"+ New registration"**:

![service-principal](/assets/img/23/03.png)

<br>
Para criar um service principal pelo portal precisamos para o nosso exemplo apenas das seguintes informações: Nome e tipo de contas suportadas, com isso podemos clicar no botão **"Register"**: 

![service-principal](/assets/img/23/04.png)

<br>
Com o service principal criado precisamos dar as permissões necessárias para que tenha acesso as informações das aplicações, para isso com o service principal aberto devemos ir em **"API permissions"** -> **" + Add a permission"** -> **"Microsoft Graph"**:

![service-principal](/assets/img/23/05.png)

<br>
Nessa tela iremos pesquisar e selecionar as permissões clicando em **"Application permission"**, no campo de pesquisa iremos pesquisar e selecionar as seguintes permissões:

- **Application.Read.All**
- **Mail.Send**

Depois de selecionado clicamos no botão **"Add permissions"**

![service-principal](/assets/img/23/06.png)

<br>

Com as permissões selecionadas devemos dar o  "consentimento" para as peermissões que selecionamos clicando em **"Grant admin consent for Arantes Tech"** e clicar em **"YES"**:

![service-principal](/assets/img/23/07.png)

<br>

Nesse exemplo usaremos um **Secret** para se conectar ao Entra ID, para isso devemos ir em **"Certificates & secrets"** -> na aba **"Client secrets"** -> **"+ New client secret"** -> Digitar uma descrição e escolher a duração do secret e depois clicar no botão **"Add"**: 

![service-principal](/assets/img/23/08.png)

> Copie o valor do secret pois não é possivel copiar novamente caso precise
{: .prompt-warning }

## Script para gerar o relatório

Para poder explicar melhor o script irei dividi-lo em 3 partes, a primeira parte para conexão com o Microsoft Entra ID, a segunda parte que é a extração das informações e a terceira parte que é o envio do e-mail. Deixo aqui o script completo em um único arquivo mas no formato txt: <a href="http://arantes.net.br/assets/img/23/sp-expire-connect-secret.txt" target="_blank">sp-expire-connect-secret.txt</a> onde você precisa depois de feito o download renomear para a extensão **.ps1**

### 1. Conexão com o Microsoft Entra ID

Nesse artigo iremos ver somente o script powershell para gerar o relatório, no próximo artigo será como automatizar isso usando o Azure Automation Account, no trecho abaixo temos como o script irá se conectar ao Entra ID:

```powershell
# Variables to connect to Entra ID
$ClientId     = "xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx"
$TenantId     = "xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx"
$ClientSecret = "xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx"

# Convert the client secret to a secure string
$ClientSecretPass = ConvertTo-SecureString -String $ClientSecret -AsPlainText -Force

# Create a credential object using the client ID and secure string
$ClientSecretCredential = New-Object `
    -TypeName System.Management.Automation.PSCredential `
    -ArgumentList $ClientId, $ClientSecretPass

# Connect to Microsoft Graph with Client Secret
Connect-MgGraph -TenantId $TenantId -ClientSecretCredential $ClientSecretCredential
```

### 2. Selecionando os certificados e secrets 

Nesse trecho do script temos a comparação da data de expiração dos certificados e secrets com a data atual menos a quantidade de dias que definimos na variável **$DaysUntilExpiration**, caso você não precise de listar os secrets ou certificados você pode remover o trecho respectivo do ***for_each*** do certificado ou do secret:

```powershell
# Days until expiration
$DaysUntilExpiration = 30

$Now = Get-Date

$Applications = Get-MgApplication -all
$Logs = @()

foreach ($App in $Applications) {
    $AppName = $App.DisplayName
    $AppID   = $App.Id
    $ApplID  = $App.AppId

    $AppCreds = Get-MgApplication -ApplicationId $AppID |
        Select-Object PasswordCredentials, KeyCredentials

    $Secrets = $AppCreds.PasswordCredentials
    $Certs   = $AppCreds.KeyCredentials

# Get the secrets
    foreach ($Secret in $Secrets) {
        $StartDate  = $Secret.StartDateTime
        $EndDate    = $Secret.EndDateTime
        $SecretName = [string]$Secret.DisplayName

        $Owner     = Get-MgApplicationOwner -ApplicationId $App.Id
        $Username  = $Owner.AdditionalProperties.displayName

        $RemainingDaysCount = ($EndDate - $Now).Days

        if ($RemainingDaysCount -le $DaysUntilExpiration -and $RemainingDaysCount -ge 0) {
            $Logs += [PSCustomObject]@{
                'ApplicationName'        = $AppName
                'ApplicationID'          = $ApplID
                'Expiration Date'        = $EndDate.ToString("dd/MM/yyyy HH:mm:ss")
                'Owner'                  = [string]$Username
            }
        }
    }
# Get the certificates
    foreach ($Cert in $Certs) {
        $StartDate = $Cert.StartDateTime
        $EndDate   = $Cert.EndDateTime
        $CertName  = $Cert.DisplayName

        $Owner     = Get-MgApplicationOwner -ApplicationId $App.Id
        $Username  = $Owner.AdditionalProperties.displayName

        $RemainingDaysCount = ($EndDate - $Now).Days

        if ($RemainingDaysCount -le $DaysUntilExpiration -and $RemainingDaysCount -ge 0) {
            $Logs += [PSCustomObject]@{
                'ApplicationName'        = $AppName
                'ApplicationID'          = $ApplID
                'Expiration Date'        = $EndDate.ToString("dd/MM/yyyy HH:mm:ss")
                'Owner'                  = [string]$Username
            }
        }
    }
}

```

> Lembrando que a variável **$DaysUntilExpiration** é onde determinamos a quantidade de dias antes de expirar
{: .prompt-tip }

### 3. Enviando o e-mail com o relatório

Para enviar o relatório que nada mais é uma tabela com o resultado da busca acima no formato HTML, criei um css simples para dar uma aparência melhor e alguns parâmetros. A primeira parte precisamos definir algumas variáveis que são valores de quem irá enviar e receber o relatório, assunto do e-mail, tipo de envio e se irá salvar o e-mail nos "Itens enviados":

```powershell
# Email details
$sender    = "no-reply@arantes.net.br"
$recipient = "luiz@arantes.net.br"
$subject   = "Service Principal expiring date report"
$type      = "HTML"   # pode ser Text
$save      = "false"  # salvar o e-mail nos "Itens enviados"

# Html CSS style
$Style = @"
<style>
table { 
    border-collapse: collapse;
}
td, th { 
    border: 1px solid #ddd;
    padding: 8px;
}
th {
    padding-top: 12px;
    padding-bottom: 12px;
    text-align: left;
    background-color: #2864c7;
    color: white;
}
</style>
"@

$body = $Logs | ConvertTo-Html -Property 'ApplicationName','ApplicationID','Expiration Date','Owner' -PreContent "<h3>Service Principal - Expira nos prÃ³ximos $($DaysUntilExpiration) dias</h3>"  -Head $Style |
        Out-String

$params = @{
    Message           = @{
        Subject       = $subject
        Body          = @{
            ContentType = $type
            Content     = $body
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

# Send message
Send-MgUserMail -UserId $sender -BodyParameter $params

```

## Concluindo!

Como falei acima, esse script me ajuda muito para ter um relatório dos secrets e certificados que irão expirar em Service principals, e tendo essa informação com antecedência fica mais fácil de se planejar para alterar isso. 

Da forma que uso hoje com o Azure Automation account para automatizar o envio ficaria muito grande em um artigo, portanto, irei criar na sequência o artigo de como automatizar isso.

Bom pessoal, espero que tenha gostado e que esse artigo seja útil a vocês!

## Artigos relacionados

<a href="https://learn.microsoft.com/en-us/entra/identity/enterprise-apps/scripts/powershell-export-apps-with-expiring-secrets" target="_blank">Export app registrations with expiring secrets and certificates</a> 

Compartilhe o artigo com seus amigos clicando nos icones abaixo!!!