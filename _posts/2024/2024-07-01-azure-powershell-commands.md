---
#layout: post
title: 'Azure Powershell / Azure CLI: 10 comandos para ajudar no dia a dia com o Azure'
date: 2024-07-01 11:33:00
slug: 'azure-powershell-commands'
categories:  ['Azure', 'Powershell']
tags:  ['Azure', 'Powershell']
image:
  path: assets/img/15/15-header.webp
---

Olá pessoal! Blz?

Nesse artigo eu quero trazer alguns comandos e/ou pequenos scripts powershell ou Azure CLI que uso no meu dia a dia trabalhando com Microsoft Azure. Claro que são itens básicos e nada muito complexo, mas sempre me pego a procurar em meus arquivos quando preciso e por isso quis trazer alguns deles para deixar em um artigo.

Alguns comandos ou scripts ficam mais fáceis com Powershell e outros ficam melhores com Azure CLI, não trarei a discussão de qual é melhor pois é de cada um a uma melhor compreensão.

## 1 - Instalar o módulo Azure Powershell e Azure CLI

Quando estou trabalhando em uma máquina virtual no Azure e preciso instalar o módulo Azure Powershell ou Azure CLI nessa máquina virtual:

- **Powershell**
```powershell
Install-Module -Name Az -Repository PSGallery -Force
```

- **Azure CLI**
  - <a href="https://aka.ms/installazurecliwindowsx64" target="_blank">Windows x64</a>
  - MacOs com Brew: ``` brew update && brew install azure-cli ```
  - Linux: ```curl -L https://aka.ms/InstallAzureCli | bash ```

## 2 - Az Find - use a AI para encontrar o comando que você precisa

Esse comando eu gosto bastante e facilita quando estou trabalhando no shell e não quero ir para um navegador para procurar algo que preciso no Azure CLI, o comando **az find "texto"** faz uma busca baseado na documentação do Azure, bem como nos padrões de uso do Azure CLI e dos usuários do Azure ARM e traz como resultado como usarmos isso para o que precisamos.

No exemplo abaixo vou usar o az find para me ajudar como usar o Azure CLI para criar uma storage account no Azure:

```powershell
az find "How to create a storage account" 
```

Com o comando acima ele me traz qual comando e sintaxe que eu devo utlizar para criar uma Storage Account:

![azure-cli-az-find](/assets/img/15/01.png)

## 3 - Conectar a uma assinatura Microsoft Azure

- Conectando a um específico Tenant e Assinatura:

```powershell
Connect-AzAccount -Tenant 'xxxx-xxxx-xxxx-xxxx' -SubscriptionId 'yyyy-yyyy-yyyy-yyyy'
```

- Conectando usando um service principal

```powershell
$tenantId="xxxx-xxxx-xxxx-xxxx"
$clientId="xxxx-xxxx-xxxx-xxxx"
$clientSecret="xxxx-xxxx-xxxx-xxxx"
$subscriptionId = "xxxx-xxxx-xxxx-xxxx"
$secSecret = ConvertTo-SecureString $clientSecret -AsPlainText -Force

$pscredential = New-Object System.Management.Automation.PSCredential ($clientId, $secSecret)
Connect-AzAccount -ServicePrincipal -Credential $pscredential -Tenant $tenantId
Set-AzContext -Subscription $subscriptionId
```

- Conectando usando o Azure CLI

```powershell
az account set --subscription "<subscription ID ou nome>"
```

## 4 - Criar um Service Principal

Quando preciso de um Service Principal para usar em um código Terraform ou Azure Devops/GitHub Actions:

```powershell
az ad sp create-for-rbac --name myServicePrincipalName \
                         --role contributor \
                         --scopes /subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/myRG
```

O exemplo acima estou criando o Service Principal e já dando acesso de **contributor** no Resource Group **myRG**, se você precisa dar acesso a assinatura toda é só retirar a parte final do comando ***/resourceGroups/myRG***

## 5 - Instalar o IIS e criar uma página WEB de teste

Esse pequeno script eu uso quando preciso que o servidor Windows tenha uma página WEB ou estou testando algum balanceador de carga do Azure, como: Application Gateway, Load Balancer, Front Door ou o Traffic Manager:

```powershell
# Instalar IIS com Management Tools
Add-WindowsFeature Web-Server -IncludeManagementTools

# Remover a pagina padrão do IIS 
remove-item C:\inetpub\wwwroot\iisstart.htm

# Configurar uma página inicial
Add-Content -Path "C:\inetpub\wwwroot\Default.htm" -Value "Hostname $($env:computername)"
```

Se for para testar o multi path do Application Gateway o script pode adicionar as pastas e conteúdo:

```powershell
# Instalar IIS com Management Tools
Add-WindowsFeature Web-Server -IncludeManagementTools

# Remover a pagina padrão do IIS 
remove-item C:\inetpub\wwwroot\iisstart.htm

# Configurar uma página inicial
Add-Content -Path "C:\inetpub\wwwroot\Default.htm" -Value "Hostname $($env:computername)"

# Configurar a URL dos Paths
New-Item -ItemType directory -Path "C:\inetpub\wwwroot\images"
New-Item -ItemType directory -Path "C:\inetpub\wwwroot\video"

# Configurar Paginas baseadas no Path
Add-Content -Path "C:\inetpub\wwwroot\images\default.htm" -Value "Hostname URL-Path Images - $($env:computername)"
Add-Content -Path "C:\inetpub\wwwroot\video\default.htm" -Value "Hostname URL-Path Video - $($env:computername)"

```

## 6 - Desabilitando o Windows Firewall do Windows Server 

Muitas vezes quando estamos trabalhando ou realizando algum laboratório com máquinas virtuais Windows Server precisamos desabilitar o windows firewall para conseguir um simples "ping" para a máquina virtual, para isso podemos desativá-lo com o comando abaixo:

```powershell
Set-NetFirewallProfile -Profile Domain, Public, Private -Enabled False
```

Obs: Pense nesse comando mais para utilizar em ambiente de testes pois em produção acredito ser um pouco arriscado 😆 

## 7 - Armazenar o backend do Terraform em uma Storage Account no Azure

Quando preciso criar uma storage account no Azure para armazenar o backend do Terraform:

```powershell
$RESOURCE_GROUP_NAME='tfstate'
$STORAGE_ACCOUNT_NAME="<STORAGE_ACCOUNT_NAME>"
$CONTAINER_NAME='tfstate'

# Cria um resource group
New-AzResourceGroup -Name $RESOURCE_GROUP_NAME -Location eastus

# Cria uma storage account
$storageAccount = New-AzStorageAccount -ResourceGroupName $RESOURCE_GROUP_NAME -Name $STORAGE_ACCOUNT_NAME \
                  -SkuName Standard_LRS -Location eastus -AllowBlobPublicAccess $false

# Cria um blob container
New-AzStorageContainer -Name $CONTAINER_NAME -Context $storageAccount.context
```

Crie uma configuração do Terraform com um bloco de configuração de backend:

```HCL
backend "azurerm" {
      resource_group_name  = "tfstate"
      storage_account_name = "<storage_account_name>"
      container_name       = "tfstate"
      key                  = "terraform.tfstate"
  }
```

## 8 - Gerenciar máquinas virtuais

Para realizar alguma atividade em uma máquina virtual por Powershell:

| Tarefa | Comando |
| --- | --- |
| Iniciar uma VM | Start-AzVM -ResourceGroupName *"Resource Group Name"* -Name *"VM Name"* |
| Parar uma VM | Stop-AzVM -ResourceGroupName *"Resource Group Name"* -Name *"VM Name"* |
| Reiniciar uma VM | Restart-AzVM -ResourceGroupName *"Resource Group Name"* -Name *"VM Name"* |
| Apagar uma VM | Remove-AzVM -ResourceGroupName *"Resource Group Name"* -Name *"VM Name"* |
| Listar todas VMs na assinatura | Get-AzVM |


## 9 - Testar a conexão de um recurso do Azure 

Aas vezes nos batemos com problema de conexão a algum site ou URL de dentro de uma máquina virtual e o primeiro passo para detectar o problema é válida se há conexão ou não, o comando é simples, mas pode te ajudar muito, no exemplo abaixo estou validando se a máquina virtual tem acesso a URL e Porta para ativar a licença do Windows em uma máquina virtual:

```powershell
Test-NetConnection kms.core.windows.net -port 1688
```
Com isso voce pode validar se é problema na conexão com a internet ou tráfego de saída em alguma porta específica.

## 10 - Mover recursos de um Resource Group para outro com Powershell

Eu sempre achei um tanto chato mover recursos no Azure pelo portal, pois precisa validar e depois confirmar a movimentação, pelo powershell eu executo o comando e esqueço! Claro que deva levar em consideração que todos os recursos que está no Resource Group de origem são passiveis de movimentação. 

```powershell
#Da um GET em todos os recursos do Resource Group de origem
$Resource = Get-AzResource -ResourceGroupName "<RG-ORIGEM>"

# Move todos os recursos selecionados acima para o Resource Group de destino
Move-AzResource -ResourceId $Resource.ResourceId -DestinationResourceGroupName "<RG-DESTINO>" -force
```

> **-force** é quando eu não quero ver os recursos e nem ser perguntado para confirmar a movimentação
{: .prompt-tip }

## Concluindo!

Como falei acima para muitos pode parecer demasiados simples o que passei acima, mas eu mantenho isso em um local e digo que costumo usar pelo menos algum deles quase que diariamente e por isso acredito que possa ajudar alguém. Em um próximo artigo gostaria de trazer scripts mais complexos mas que tem como base os citados nesse artigo.

Scripts powershell ou Azure CLI nada mais é que um conjunto de comandos que vão se desenrolando em um propósito.

Bom pessoal, espero que tenha gostado e que esse artigo seja útil a vocês! Compartilhe o artigo com seus amigos clicando nos ícones abaixo!!!