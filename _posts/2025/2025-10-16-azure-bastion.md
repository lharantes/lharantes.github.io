---
title: "Azure Bastion: acesso seguro a máquinas virtuais no Azure e como automatizar a criação"
date: 2025-10-16 01:00:00
categories: [Azure]
tags: [azure, powershell, terraform]
slug: 'azure-bastion'
image:
  path: /assets/img/46/46-header.webp
---

Olá pessoal! Blz?

No artigo de hoje gostaria de trazer um assunto sobre um recurso bem conhecido já no mundo Microsoft Azure, sendo o **Azure Bastion** ou simplesmente **Bastions**, mas sabemos que esse recurso é um recurso caro para se manter memso trazendo um nível de segurança maior no acesso de nossas máquinas virtuais em nosso ambiente.

Primeiramente, vou trazer uma descrição sobre o recurso do Azure Bastion e depois deixar um script **powershell e terrraform** para podermos fazer a criação do Azure Bastion em um horário definido para termos esse recurso somente durante o horário comercial. Isso pode ajudar empresas menores a terem uma economia na utlização do recurso.

## O que é Azure Bastion?

O Azure Bastion é um serviço **PaaS (Platform as a Service)** do Microsoft Azure que permite acesso seguro a máquinas virtuais **Windows (RDP) e Linux (SSH)** diretamente pelo Azure Portal ou por cliente nativo, sem expor IP público na VM e **SEM ABRIR** portas 22 ou 3389 para a Internet.

Com o Azure Bastion, o acesso administrativo ocorre usando IP privado, a conexão via TLS (porta 443), reduzindo significativamente a superfície de ataque e eliminando a necessidade de jumpboxes tradicionais.

## Como o Azure Bastion funciona?

O funcionamento do Azure Bastion é simples:

- O serviço é implantado em uma VNet, em uma subnet dedicada chamada **AzureBastionSubnet**
- O administrador inicia a conexão pelo Azure Portal ou cliente nativo
- O tráfego entra pelo Bastion usando HTTPS (443)
- A conexão segue internamente até a VM via rede privada, a VM não precisa de IP público e as portas 22/3389 não ficam expostas

![azure-bastion](/assets/img/46/01.png){: .shadow .rounded-10}
_Fonte: Microsoft Learn — Documentação do Azure (© Microsoft)_

## Principais funcionalidades e melhorias do Azure Bastion nos últimos anos

Dependendo do SKU utilizado, o Azure Bastion oferece:

- Acesso RDP e SSH pelo navegador
- Conexão via cliente nativo (mstsc / ssh)
- Transferência segura de arquivos
- Links compartilháveis para acesso controlado
- Suporte a portas customizadas
- Session Recording (gravação de sessões)
- Integração com Microsoft Entra ID, MFA e Conditional Access
- Lançamento do SKU Developer (gratuito) para Dev/Test

Essas melhorias tornaram o Bastion uma solução madura para ambientes corporativos. Antigamente o Azure Bastion somente era possível acessar as máquinas virtuais na mesma rede virtual que ele estava criado, mas com a evolução desse serviço hoje é possível o acesso a máquinas virtuais em outras redes virtuais desde que estejam ligadas por um peering (emparelhamento), para isso devemos usar uma arquitetura **Hub & Spoke** na arquitetura de rede com isso fazendo o deploy do **Azure Bastion** na rede **HUB** todas as máquinas virtuais criadas nas ***redes spokes** também poderão ser acessadas.

## Diferenças entre os SKUs (Tier) do Azure Bastion

O Azure Bastion possui atualmente 04 (quatro) SKUs, cada um com sua característica e limitação, e com certeza cada um com seu preço, portanto, a escolha do SKU corrto para atender sua demanda não so impacta na **disponibilização da característica como o preço.**

| SKU               | Indicação             | Principais recursos                                                     |
|-------------------|-----------------------|-------------------------------------------------------------------------|
| Developer (Free)  | Dev/Test              | Acesso básico pelo portal                                               |
| Basic             | Produção simples      | Acesso dedicado                                                         |
| Standard          | Produção corporativa  | Cliente nativo, file transfer, shareable link, escala                   |
| Premium           | Compliance            | Tudo do Standard + Session Recording                                    |

> Standard é o SKU mais usado em produção e o Premium é ideal para auditoria e compliance
{: .prompt-tip } 

## Passo a passo: como criar o Azure Bastion (Portal)

O primeiro passo é pesquisar **Bastions** pela barra de pesquisa no portal do:

![azure-bastion](/assets/img/46/02.png){: .shadow .rounded-10}

Na tela do **Bastions** podemos ver todos os recurso que temo em nosso ambiente, para cria um novo basta clicar no botão **"+ Create"** e teremos a tela de criação:

A primeira guia **Basic** traz o itens principais de configuração, como em todos os recurso no Microsoft Azure devemos inicialmente escolher qual sera a **Assinatura** e qual **Grupo de Recurso** que o Azure Bastion será criado, depois temos s seguintes informações:

- **Name:** nome do recurso para melhor indicar a utilização, para o nome podemos ter de 1-80 caracteres e 	Alfanuméricos, sublinhados, pontos e hifens.
- **Region:** região que o recurso será criado, lembre-se que escolhendo a região ele irá listar somente as redes virtuais cridas nessa região.
- **Availability Zone:** se teremos o recurso em zonas de disponibilidade, podendo escolher entre 0 (Nenhuma), 1, 2 ou 3 zonas.
- **Tier:** Podemos escolher entre os 04 SKUs disponíveis: Developer (Free), Basic, Standard ou Premium.
- **Instance count:** a quantidade de instâncias do Bastion só pdoe ser definida para os SKUs **Standard** ou **Premium**, podendo ser de 2-50 instâncias.
- **Virtual Network** qual será a rede virtual que teremos o Azure Bastion criado.
- **Subnet:** o Bastion tem um nome de subnet exclusivo **AzureBastionSubnet** e já devera existir se você selecionar uma rede virtual existente.
- **IP Address:** O Bastion permite a conexão via **IP público ou privado.** Se você escolher o IP Público como frontend de acesso poderá escolher um IP Público existente ou criar um novo.

![azure-bastion](/assets/img/46/03.png){: .shadow .rounded-10}

<b>

Na segunda guia **Advanced** temos as características que iremos disponibilizar, lembrando que nem todas estarão disponíveis de acordo com o SKU escolhido:

**Copy and paste**: se poderemos usar a função de copiar e colar na sessão com a máquina virtual.
**IP-based connection**: conectar-se a uma VM por meio do endereço IP privado especificado
**Kerberos authentication**: conectar usando autenticação Kerberos.
**Native client support**: configurar o Bastion para conexões de cliente nativo (SSH ou RDP) em seu computador local para VMs 
**Shareable Link**: criar um link compartilhável para o Bastion.
**Session recording**: configurar gravação de sessão Bastion

![azure-bastion](/assets/img/46/04.png){: .shadow .rounded-10}

> O **Azure Bastion** tem um deploy demorado podendo levar de 10-20 minutos para ser criado.
{: .prompt-warning } 

Depois de concluido o deployment temos o nosso Azure Bastion pronto para ser usado:

![azure-bastion](/assets/img/46/05.png){: .shadow .rounded-10}

<b>

## Como acessar o Azure Bastion

Para acessar uma máquina virtual com o Azure Bastion devemos ir até à máquina virtual que queremos acessar, ir no botão **"Connect""**, escolhe a opção **"Connect via Bastion"**:

![azure-bastion](/assets/img/46/06.png){: .shadow .rounded-10}

<b>

Na tela de conexão usando o Azure Bastions escolhemos o layout do teclado, a forma que vamos nos conectar, no meu Lab eu uso o **SKU Basic** e acesso através de usuário e senha, como deixei marcado para **Abrir em uma nova Guia no navegador** será criada uma nova guia:

![azure-bastion](/assets/img/46/07.png){: .shadow .rounded-10}

![azure-bastion](/assets/img/46/08.png){: .shadow .rounded-10}

## Como alterar o SKU (Tier) do Azure Bastion

Como eu mencionei acima eu estou usando o SKU Basic em meu laboratótio mas se caso você precise alterar o Tier para ter mais funções você pode ir no Azure Bastion que você deseja alterar no menu: **Settings** -> **Configuration**, depois de ecolhido o novo **Tier** você pode habilitar mais alguma funcionalidade do Tier que você escolheu, no exemplo abaixo eu escolhi a opção **"Shareable Link** e depois clicar em **Apply** para aplicar as modificações:

![azure-bastion](/assets/img/46/09.png){: .shadow .rounded-10}

> O **Azure Bastion** levará alguns minutos para ficar diponível pois, ele precisa alterar o deployment.
{: .prompt-info } 

<b>

Eu habilitei a função que me permite gerar um link compartilhável, mas em que casos eu poderia usar isso?? Vamos suor o seguinte cenário:

***"Eu preciso que um parceiro externo se conecte em uma máquina virtual para instalar/modificar algum software, mas não quero dar acesso ao Azure ou atribuir um IP Público na máquina virtual"***

Então no meu Azure Bastion eu tenho agora a opção de gerar esse link e compartilhar com esse parceiro, para fazer isso vamos até o Azure Bastion que estamos usando e clicamos em **"Shareable Link"**:

![azure-bastion](/assets/img/46/10.png){: .shadow .rounded-10}

<b>

Agora você pode copiar o link e compartilhar com a pessoa/empresa que deseja e ela irá se conectar a essa máquina virtual de forma segura sem expor as portas **RDP ou SSH** de forma pública:

![azure-bastion](/assets/img/46/11.png){: .shadow .rounded-10}

## Automatizar a criação do Azure Bastion

Como falei no começo do artigo o Azure Bastion não é um recurso barato, então você poderia criar uma **Azure Automation Account** para criar o Azure Bastion antes de iniciar o expediente e remover no final do expediente, para ficar disponível somente no horário comercial, caso precise de alguma manutenção fora do horário comercial teria que pensar em alguma outra maneira: IP público em uma máquina virtual **Jump box** ou através de uma VPN.

> **Sendo sincero, na minha opinião em ambientes de produção devemos deixar o Azure Bastion disponível 24 horas.**
{: .prompt-danger } 

Mas como gosto sempre de disponibilizar a parte de automação seja com **PowerShell** ou **Terraform** vou deixar o script de maneira simples de como criar usando essas tecnologias:

### PowerShell

```powershell
& {
  $subId = "";  # opcional: "00000000-0000-0000-0000-000000000000"
  $loc   = "westeurope";
  $rg    = "rg-bastion-demo";
  $vnet  = "vnet-demo";
  $vnetCidr = "10.10.0.0/16";
  $snetWorkName = "snet-workload";
  $snetWorkCidr = "10.10.1.0/24";
  $snetBasName  = "AzureBastionSubnet";
  $snetBasCidr  = "10.10.10.0/26";
  $pipName = "pip-bastion-demo";
  $basName = "bas-demo";

  Set-StrictMode -Version Latest; $ErrorActionPreference = "Stop";

  if ($subId -and $subId.Trim().Length -gt 0) { Set-AzContext -SubscriptionId $subId | Out-Null }

  if (-not (Get-AzResourceGroup -Name $rg -ErrorAction SilentlyContinue)) {
    New-AzResourceGroup -Name $rg -Location $loc | Out-Null
  }

  $v = Get-AzVirtualNetwork -Name $vnet -ResourceGroupName $rg -ErrorAction SilentlyContinue
  if (-not $v) {
    $s1 = New-AzVirtualNetworkSubnetConfig -Name $snetWorkName -AddressPrefix $snetWorkCidr
    $s2 = New-AzVirtualNetworkSubnetConfig -Name $snetBasName  -AddressPrefix $snetBasCidr
    $v  = New-AzVirtualNetwork -Name $vnet -ResourceGroupName $rg -Location $loc -AddressPrefix $vnetCidr -Subnet $s1,$s2
  } else {
    if (-not ($v.Subnets | Where-Object Name -eq $snetBasName)) {
      Add-AzVirtualNetworkSubnetConfig -VirtualNetwork $v -Name $snetBasName -AddressPrefix $snetBasCidr | Out-Null
      $v | Set-AzVirtualNetwork | Out-Null
      $v = Get-AzVirtualNetwork -Name $vnet -ResourceGroupName $rg
    }
  }

  $pip = Get-AzPublicIpAddress -Name $pipName -ResourceGroupName $rg -ErrorAction SilentlyContinue
  if (-not $pip) {
    $pip = New-AzPublicIpAddress -Name $pipName -ResourceGroupName $rg -Location $loc -Sku Standard -AllocationMethod Static
  }

  if (-not (Get-AzBastion -Name $basName -ResourceGroupName $rg -ErrorAction SilentlyContinue)) {
    $bs = $v.Subnets | Where-Object Name -eq $snetBasName
    $ipcfg = New-AzBastionIpConfiguration -Name "bastion-ipcfg" -SubnetId $bs.Id -PublicIpAddressId $pip.Id
    New-AzBastion -Name $basName -ResourceGroupName $rg -Location $loc -Sku "Standard" -IpConfiguration $ipcfg | Out-Null
  }

  "OK - Bastion criado/validado: RG=$rg | VNet=$vnet | Bastion=$basName | PIP=$pipName | Location=$loc"
}
```

Para remover o Azure Bastion no final do expediente:

```powershell
& {
  $rg="rg-bastion-demo"
  $basName="bas-demo"
  $pipName="pip-bastion-demo"

  Set-StrictMode -Version Latest; $ErrorActionPreference="Stop"

  $b = Get-AzBastion -ResourceGroupName $rg -Name $basName -ErrorAction SilentlyContinue
  if ($b) { Remove-AzBastion -ResourceGroupName $rg -Name $basName -Force }

  $pip = Get-AzPublicIpAddress -ResourceGroupName $rg -Name $pipName -ErrorAction SilentlyContinue
  if ($pip) { Remove-AzPublicIpAddress -ResourceGroupName $rg -Name $pipName -Force }

  "OK - Bastion e Public IP removidos (se existiam): RG=$rg | Bastion=$basName | PIP=$pipName"
}
```

### Terraform

Caso deseje automatizar com Terraform segue o exemplo de como fazer:

```hcl
resource "azurerm_resource_group" "example" {
  name     = "example-resources"
  location = "West Europe"
}

resource "azurerm_virtual_network" "example" {
  name                = "examplevnet"
  address_space       = ["192.168.1.0/24"]
  location            = azurerm_resource_group.example.location
  resource_group_name = azurerm_resource_group.example.name
}

resource "azurerm_subnet" "example" {
  name                 = "AzureBastionSubnet"
  resource_group_name  = azurerm_resource_group.example.name
  virtual_network_name = azurerm_virtual_network.example.name
  address_prefixes     = ["192.168.1.224/27"]
}

resource "azurerm_public_ip" "example" {
  name                = "examplepip"
  location            = azurerm_resource_group.example.location
  resource_group_name = azurerm_resource_group.example.name
  allocation_method   = "Static"
  sku                 = "Standard"
}

resource "azurerm_bastion_host" "example" {
  name                = "examplebastion"
  location            = azurerm_resource_group.example.location
  resource_group_name = azurerm_resource_group.example.name

  ip_configuration {
    name                 = "configuration"
    subnet_id            = azurerm_subnet.example.id
    public_ip_address_id = azurerm_public_ip.example.id
  }
}
```

## Concluindo!

O **Azure Bastion** é hoje uma das **melhores práticas de segurança no Azure** para acesso administrativo a VMs. Ele elimina exposição desnecessária, reduz riscos operacionais e se integra perfeitamente com o ecossistema de segurança da Microsoft.

Se você busca **simplicidade, segurança e governança**, o Azure Bastion deve ser parte do seu baseline de arquitetura no Azure.

Bom pessoal, eu tenho usado isso em alguns ambientes e acredito que possa ser bem útil a vocês!

## Artigos relacionados

<a href="https://learn.microsoft.com/en-us/azure/bastion/bastion-overview" target="_blank">What is Azure Bastion?</a>

<a href="https://learn.microsoft.com/en-us/azure/bastion/bastion-sku-comparison" target="_blank">Choose the right Azure Bastion SKU to meet your needs</a>

Compartilhe o artigo com seus amigos clicando nos icones abaixo!!!