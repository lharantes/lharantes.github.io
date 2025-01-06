---
#layout: post
title: 'Migrar um File Server local para o Azure - Parte 2' 
date: 2024-11-29 01:33:00
categories: [Azure]
tags: [azure, fileserver]
slug: 'migrate-file-server-to-azure-parte2'
image:
  path: assets/img/28/28-header.webp
---

Olá pessoal! Blz?

Nesse artigo iremos dar continuidade a migrar um file server on-premises para o Azure, no <a href="https://arantes.net.br/posts/migrate-file-server-to-azure-parte1/" target="_blank">artigo anterior</a> criamos a storage account, criamos um private endpoint para que a storage account seja acessada de forma privada e criamos o Azure file share.

Agora temos as seguintes tarefas: ingressar a storage account no domínio do Active Directory, definir as permissões de compartilhamento e copiar os arquivos para o Azure.

## Ingressar a Storage Account no domínio

O motivo que devemos/queremos ingressar a Storage account no domínio é para  habilitar a autenticação de AD DS (Active Directory Domain Services) na sua storage account para usar credenciais do AD (Active Directory) local para autenticação em Azure file share.

Para isso devemos usar o módulo do PowerShell **AzFilesHybrid** que fornece cmdlets para implantar e configurar o Azure file share. Ele inclui cmdlets para ingressar storage accounts no Active Directory local, você pode baixá-lo nesse <a href="https://github.com/Azure-Samples/azure-files-samples/releases" target="_blank">link do AzFilesHybrid</a> e descompactá-lo em uma pasta, exemplo: ***"c:\AzFilesHybrid"***.

Para executar o script devemos fazer isso de dentro de um computador que tenha acesso ao domínio e com uma conta de usuário com permissões de criar objetos dentro do domínio do Active Directory, precisamos ter o módulo do Azure powershell instalado <a href="https://arantes.net.br/posts/azure-powershell-commands/#1---instalar-o-m%C3%B3dulo-azure-powershell-e-azure-cli" target="_blank"> (pode consultar a instalação aqui)</a>, e dentro da pasta onde descompactamos o AzFilesHybrid devemos executar os seguintes comandos do powershell preenchendo o valor das variáveis de acordo com o seu ambiente:

```powershell
# Change the execution policy to unblock importing AzFilesHybrid.psm1 module
Set-ExecutionPolicy -ExecutionPolicy Unrestricted -Scope CurrentUser

# Navigate to where AzFilesHybrid is unzipped and stored and run to copy the files into your path
.\CopyToPSPath.ps1 

# Import AzFilesHybrid module
Import-Module -Name AzFilesHybrid
```

> Nunca vi falando para fechar e abrir a console do PowerShell após importar o módulo, mas já tive problemas por não fazer isso, então para garantir, recomendo que feche e abra uma nova console do PowerShell para continuar com os comandos abaixo.
{: .prompt-tip }

```powershell
# Login to Azure using a credential that has either storage account owner or contributor Azure role 
# assignment.
Connect-AzAccount

# Define parameters
$SubscriptionId      = "<your-subscription-id-here>"
$ResourceGroupName   = "<resource-group-name-here>"
$StorageAccountName  = "<storage-account-name-here>"
$DomainAccountType   = "ComputerAccount" # Default is set as ComputerAccount
$OuDistinguishedName = "<ou-distinguishedname-here>"

# Select the target subscription for the current session
Select-AzSubscription -SubscriptionId $SubscriptionId 

Join-AzStorageAccount `
        -ResourceGroupName $ResourceGroupName `
        -StorageAccountName $StorageAccountName `
        -DomainAccountType $DomainAccountType `
        -OrganizationalUnitDistinguishedName $OuDistinguishedName

# You can run the Debug-AzStorageAccountAuth cmdlet to conduct a set of basic checks on your AD configuration 
# with the logged on AD user.
Debug-AzStorageAccountAuth -StorageAccountName $StorageAccountName -ResourceGroupName $ResourceGroupName -Verbose
```

Com o sucesso dos comandos acima você deve ter uma conta de computador em seu Active Directory com o nome da storage account, e com isso a autenticação pelo Active Directory está habilitada.

![migrate-file-server-to-azure](/assets/img/28/01.png){: .shadow .rounded-10}

## Definir as permissões do compartilhamento

Nesse nosso exemplo iremos manter somente um Azure file share que criamos no artigo passado, e manteremos a estrutura de pastas do ambiente on-premises com uma pasta principal e as pastas dos departamentos abaixo dela, mas cada pasta tem a sua própria permissão restritiva, por exemplo, quem tem acesso a pasta da Diretoria não tem acesso a pasta do RH, ssim como está configurado no file server on-premises.

```
📦Departamentos
 ┣ 📂Compliance
 ┣ 📂Contabilidade
 ┣ 📂Diretoria
 ┣ 📂Financeiro
 ┣ 📂Marketing
 ┣ 📂RH
 ┣ 📂TI
```

Para conseguirmos isso a idéia segue a mesma de quando administramos um File Server on-premises, primeiro damos permissão no compartilhamento e depois a permissão NTFS nas pastas (que serão preservadas do File Server on-premises ao migrar para o Azure).

Para a permissão de compartilhamento devemos abrir o ***Azure file share que criamos -> Access Control (IAM) -> + Add -> Add role assignment:***

 ![migrate-file-server-to-azure](/assets/img/28/02.png){: .shadow .rounded-10}

Aqui devemos conceder duas permissões, que irei explicar cada uma:

- **Storage File Data SMB Share Elevated Contributor**: Permite Ler, Escrever, Apagar arquivos e modificar permissões NTFS de acesso. Damos essa permissão a quem irá administrar o Azure file share pois com essa permissão poderá conceder permissões aos usuários.

- **Storage File Data SMB Share Contributor**: Permite Ler, Escrever e Apagar arquivos. Essa permissão são para todos os usuários que irá acessar o Azure file share.

![migrate-file-server-to-azure](/assets/img/28/03.png){: .shadow .rounded-10}

No exemplo acima demos a permissão de Storage File Data SMB Share Elevated Contributor para o grupo GR-Admins, o processo é o mesmo para a permissão Storage File Data SMB Share Contributor mas deve selecionar os grupos dos usuários que irão acessar o compartilhamento, por exemplo: "GR-Financeiro, GR-RH ou GR-Diretoria".

Agora que as permissões no Azure file share estão prontas, precisamos "montar" o Azure file share em um servidor Windows que esteja ingressado no domínio apenas para ajustar as permissões para que fique mais seguro, para isso devemos copiar o script que faz a montagem, podemos fazer isso no mesmo servidor que executamos o script para ingressar a storage account no domínio.

Para isso no Azure file share vamos em ***Overview -> Connect -> Selecionamos Storage account key***:

![migrate-file-server-to-azure](/assets/img/28/04.png){: .shadow .rounded-10}

Copiamos o script gerado e executamos no servidor os comandos Powershell para mapearmos o Azure file share na unidade Z: do Windows:

![migrate-file-server-to-azure](/assets/img/28/05.png){: .shadow .rounded-10}

Para mantermos a mesma estrutura de pastas que temos no File Server on-premises que queremos migrar para o Azure vamos criar somente a pasta ***Departamentos*** pois as subpastas serão copiadas quando fomos migrar os arquivos.

![migrate-file-server-to-azure](/assets/img/28/06.png){: .shadow .rounded-10}

Na pasta criada, vamos ajustar a permissão para que todos os usuários consigam entrar nessa pasta, depois o acesso as subpastas será pela permissão NTFS que cada usuário possui. O primeiro passo será ***Desabilitar a herança e remover os usuários que não são administradores***:

![migrate-file-server-to-azure](/assets/img/28/video1.gif){: .shadow .rounded-10}

Agora vamos adicionar somente a permissão de ***List*** para que os usuários possam pelo menos abrir a pasta "Departamentos":

![migrate-file-server-to-azure](/assets/img/28/video2.gif){: .shadow .rounded-10}


## Copiar os arquivos para o Azure

Com as permissões ajustadas vamos agora copiar os arquivos do servidor file server on-premises para o Azure File Share, para isso vamos usar o comando "Robocop", eu gosto de usar o robocop pois além de conseguir preservar as permissões, ele tem alguns parâmetros bem úteis, ao final da execução ele exibe um resumo e também tem a opção de salvar em um arquivo os logs que seria essencial em uma migração muito grande para acompanhar o que falhou.

A sintaxe que usaremos seria o seguinte:

```shell
ROBOCOPY ORIGEM DESTINO /Z /B /MT:80 /E /COPY:DATSO /R:0 /W:0 /TEE /LOG+:C:\temp\mig-dados.log
```

Alterando para a unidade "Z:" que é a unidade que mapeamos o Azure file share e a origem colocamos o caminho do file server on-premises:

````
ROBOCOPY "\\FILE-SERVER\E$\DEPARTAMENTOS" "Z:\DEPARTAMENTOS" /Z /B /MT:80 /E /COPY:DATSO /R:0 /W:0 /TEE /LOG+:C:\temp\mig-dados.log
````

Temos a seguinte saída do comando acima após a copia dos arquivos:

![migrate-file-server-to-azure](/assets/img/28/07.png){: .shadow .rounded-10}

Como podemos ver na imagem abaixo, após a cópias dos arquivos para o Azure file share as permissões foram mantidas:

![migrate-file-server-to-azure](/assets/img/28/08.png){: .shadow .rounded-10}

## Mapear o File share para o usuário

Existem várias maneiras de mapear unidade de rede para os usuários, já trabalhei em empresas que era feito por GPO (Objeto de diretiva de grupo) e também por script de logon, das duas maneiras você precisará do caminho para mapear, vou mostrar como você pode pegar esse caminho.

Para fazer isso você deve abrir o Azure file share e seguir o passo a passo abaixo:

![migrate-file-server-to-azure](/assets/img/28/video3.gif){: .shadow .rounded-10}

No exemplo que estou dando o caminho copiado é o seguinte **https://stoarantes.file.core.windows.net/fileserver/Departamentos**, o que devemos fazer é trocar o ***https://*** ficando da seguinte forma: **\\\stoarantes.file.core.windows.net\fileserver\Departamentos**

## Concluindo!

Nesses 2 artigos, parte 1 e parte 2, eu quis trazer como fazer uma migração de um file server on-premises para a Cloud, com esse tipo de migração não há mais a preocupação de hardware on-premises para o file server ou manter o ambiente (Sistema Operacional) mas ainda precisamos nos atentar ao backup dos arquivos que ainda é nossa responsabilidade mesmo os arquivos estando na cloud, tentei pegar nos detalhes mas pode ter faltado algum item mas a base com certeza está nos dois artigos e se tiverem qualquer dúvida estarei a disposição.

Bom pessoal, espero que tenha gostado e que esse artigo seja útil a vocês!

## Artigos relacionados

<a href="https://learn.microsoft.com/en-gb/azure/storage/files/storage-files-identity-ad-ds-enable?WT.mc_id=Portal-Microsoft_Azure_FileStorage" target="_blank">Enable Active Directory Domain Services authentication for Azure file shares</a> 

<a href="https://github.com/Azure-Samples/azure-files-samples" target="_blank">This repository contains supporting code (PowerShell modules/scripts, ARM templates, etc.) for deploying, configuring, and using Azure Filese</a> 

<a href="https://learn.microsoft.com/en-us/azure/storage/files/storage-files-planning" target="_blank">Plan to deploy Azure Files</a> 

Compartilhe o artigo com seus amigos clicando nos icones abaixo!!!
