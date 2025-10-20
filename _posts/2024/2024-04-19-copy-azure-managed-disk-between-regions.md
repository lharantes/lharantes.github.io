---
title: 'Copiar uma VM para outra região do Azure copiando os discos com PowerShell'
date: 2024-04-19 10:33:00
slug: 'copy-azure-managed-disk-between-regions'
categories: ['Azure', 'Powershell']
tags: ['Azure', 'Powershell']
image:
  path: /assets/img/10/10-header.webp
---

Olá pessoal! Blz?

Gostaria de compartilhar com vocês uma alternativa ao <a href="https://learn.microsoft.com/pt-br/azure/resource-mover/overview" target="_blank">Azure Resource Mover </a> quando precisamos mover poucas máquinas virtuais de uma região para outra. Eu não gosto de usar Azure Resource Mover pela complexidade de coisas a configurar, prefiro fazer isso com Powershell criando o(s) disco(s) na região que desejo e com isso recriar a máquina virtual a partir desse(s) disco(s) se forem poucas máquinas virtuais, pois se forem muitas, por exemplo mais de 5, ai temos que considerar o Azure Resource Mover 😆😆.

Ai você vai me falar: ***"Ahh, mas o Azure Resource Mover já cria a máquina virtual para você!!"***, bom, pode até ser, mas eu acho muito mais rápido e prático usando o Powershell e depois pelo portal ou adicionar a criação de máquina virtual no script quando são poucas máquinas virtuais.

Eu sempre usei, digamos de uma forma "antiga", o PowerShell para me ajudar nessa tarefa que era: ***criar um snapshot do disco, gerar um VHD a partir do snapshot, copiar o VHD para uma storage account na região de destino, criar um disco com a origem sendo esse VHD e com isso criar a máquina virtual***. Junto com meu amigo  <a href="https://www.linkedin.com/in/thiago-fernandes-de-oliveira-833011180/" target="_blank">Thiago Fernandes Oliveira </a> ele melhorou o processo/script deixando o mais coerente e rápido, eliminando ter que criar um VHD para usar como origem do novo disco, deixando isso mais fácil, rápido e usando menos recursos (com isso mais barato 💰💰).

## Primeiros passos

- Usaremos o **AZCopy** para copiar os dados de um disco para outro, portanto é necessário realizar o download da última versão do <a href="https://learn.microsoft.com/pt-pt/azure/storage/common/storage-use-azcopy-v10#download-azcopy" target="_blank">AzCopy</a>, no link tem as versões para os Sistemas Operacionais suportados.

-  <a href="https://learn.microsoft.com/pt-br/powershell/azure/install-azure-powershell?view=azps-11.5.0" target="_blank">Módulo Azure PowerShell</a>

- **Desalocar a máquina virtual**, pois fazendo isso com a máquina ligada pode ter problemas e você estará copiando dados desatualizados caso alguma informação seja alterada durante o processo de cópia e com isso o Sistema Operacional pode não ser iniciado, já tive problemas fazendo com a máquina ligada tanto com Sistema Operacional Linux e Windows.

## Comandos PowerShell

Aqui é a gosto de cada pessoa, você pode alterar os dados das variáveis e ir executando linha a linha, bloco a bloco ou salvar tudo em um arquivo ***.ps1*** e executar o script de uma vez só. 

No exemplo abaixo iremos criar um disco com destino no **EastUs** a patir de um disco que está na região **BrazilSouth.**

```powershell
# Variáveis do disco de origem
$sourceDiskName = "VM-Desktop_brsouth_OsDisk"
$sourceRG = "rg-vm-brsouth"

# Variáveis do disco de destino
$targetDiskName = "VM-Desktop_eastus_OsDisk"
$targetRG = "rg-vm-eastus"

# Região que o disco de destino será criado 
$targetLocation = "EastUS"

# Coletando informações sobre o disco de origem
$sourceDisk = Get-AzDisk -ResourceGroupName $sourceRG -DiskName $sourceDiskName

# Criar a configuração do disco de destino. Para discos de dados retire o parâmetro: -OsType $sourceDisk.OsType
$targetDiskconfig = New-AzDiskConfig -SkuName 'Premium_LRS' -UploadSizeInBytes $($sourceDisk.DiskSizeBytes+512) -OsType $sourceDisk.OsType -Location $targetLocation -CreateOption 'Upload'

# Criar o disco de destino
$targetDisk = New-AzDisk -ResourceGroupName $targetRG -DiskName $targetDiskName -Disk $targetDiskconfig

# Criar um SAS token com acesso de "Leitura"
$sourceDiskSas = Grant-AzDiskAccess -ResourceGroupName $sourceRG -DiskName $sourceDiskName -DurationInSecond 86400 -Access 'Read'

# Criar um SAS token com acesso de "Escrita"
$targetDiskSas = Grant-AzDiskAccess -ResourceGroupName $targetRG -DiskName $targetDiskName -DurationInSecond 86400 -Access 'Write'

# copiando os dados do disco de origem para o disco de destino
.\azcopy copy $sourceDiskSas.AccessSAS $targetDiskSas.AccessSAS --blob-type PageBlob

# Revogar os SAS tokens criados
Revoke-AzDiskAccess -ResourceGroupName $sourceRG -DiskName $sourceDiskName
Revoke-AzDiskAccess -ResourceGroupName $targetRG -DiskName $targetDiskName
```

> Temos algumas opções de parâmetros importantes para os comandos acima:
> * **-SkuName** aceita os valores: ***Standard_LRS, Premium_LRS, StandardSSD_LRS, e UltraSSD_LRS, Premium_ZRS e StandardSSD_ZRS***. UltraSSD_LRS pode apenas ser usado com valor vazio para o parâmetro "CreateOption".
> * **86400**: É a quantidade de tempo em segundos que o SAS Token terá validade para a duração da atividade de cópia, isso precisa ser ajustado de acordo com o tamanho do seu disco, o valor 86400 equivale a 24 horas e isso pode ser tempo demais para o SAS token.
> * **Location**: Você pode consultar as regiões do Azure com o comando: ***az account list-locations -o table***, mas deixo uma lista (ano 2024) aqui: <a href="/assets/img/10/lista_regioes_azure.html" target="_blank">Regiões do Azure</a>
{: .prompt-tip }

Com a execução do script acima teremos a saída abaixo que é o processo de cópia dos dados entre os discos, como pode ver destacado na imagem abaixo o throughput é alto pois eu prefiro executar isso através do Cloud Shell no portal do Azure, pois usando o backend da Microsoft conseguimos essas velocidades mais altas e com isso levando menos tempo para concluir a tarefa.

![powershell-test-connection](/assets/img/10/02.png)


A tarefa de cópia de um disco de 128GB levou 24 minutos:

![powershell-test-connection](/assets/img/10/03.png)


## Criar a máquina virtual a partir do disco

Como podem ver ja temos o nosso disco na região de destino **EastUs** (1) e que este disco não está anexado a nenhuma máquina virtual (2).

![powershell-test-connection](/assets/img/10/04.png)


Para criar a máquina virtual devemos clicar no botão **"+ Create VM"** como na imagem abaixo:

![powershell-test-connection](/assets/img/10/05.png)


Os próximos passos são exatamente iguais na criação de uma máquina virtual, com a excessão que como o disco usado veio a partir de outro disco não iremos escolher o Sistema Operacional, ele irá usar o que já esta no outro disco que usamos de origem.

![powershell-test-connection](/assets/img/10/06.png)


## Concluindo

Bom pessoal! No meu modo de pensar, não existe jeito certo ou errado de ser fazer algo na TI, dando certo o resultado esperado é o que importa! E nesse artigo eu trouxe como eu prefiro mover um disco de uma região para outra quando não é possível recriar a máquina virtual do zero.

Espero que tenha gostado e que esse artigo seja util a vocês!

## Artigos relacionados

<a href="https://learn.microsoft.com/pt-br/azure/virtual-machines/windows/disks-upload-vhd-to-managed-disk-powershell" target="_blank">Carregar um VHD no Azure ou copiar um disco gerenciado para outra região - Azure PowerShell </a>

<a href="https://learn.microsoft.com/pt-br/azure/virtual-machines/windows/attach-disk-ps" target="_blank">Anexar um disco de dados a uma VM do Windows com o PowerShell </a>

<a href="https://learn.microsoft.com/pt-br/azure/virtual-machines/attach-os-disk?tabs=portal#create-the-new-vm" target="_blank">Criar uma VM a partir de um disco especializado usando o PowerShell </a>

Compartilhe o artigo com seus amigos clicando nos icones abaixo!!!
<hr>