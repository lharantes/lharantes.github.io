---
#layout: post
title: "Habilitando o meu HomeLab no Azure Arc"
date: 2025-01-24 01:33:00
categories: [Azure]
tags: [azure, arc, homelab]
slug: 'azure-arc-homelab'
image:
  path: assets/img/31/31-header.webp
---

Olá pessoal! Blz?

Nesse artigo vou trazer a vocês a minha "primeira" experiência com o Azure Arc, coloquei entre aspas pois no passado eu assisti alguns vídeos e até habilitei um servidor de testes, mas não explorei as características e dessa vez após um treinamento sobre esse recurso quis testar um pouco mais a fundo.

Eu poderia criar alguns servidores no Azure e usá-los para os testes, mas eu queria ir mais a fundo e não fazer somente um laboratório, eu queria ver isso no dia a dia a forma que funciona e ir explorando a funmdo o Azure Arc, então decidi habilitar o Azure Arc em alguns servidores que tenho no meu HomeLab, para a escolha eu me baseei em ter pelo menos uma versão de cada sistema operacional que tenho no meu HomeLab habilitado no Azure Arc, a escolha foi a seguinte:

- **Windows Server 2022**
- **Debian GNU/Linux 12**
- **Ubuntu 24.04.1 LTS (Cloud image)**

> Cloud images são snapshots leves (geralmente abaixo de 700 Mb) de um SO configurado criado por um publicador para uso com nuvens públicas e privadas. Essas imagens fornecem uma maneira de criar repetidamente cópias idênticas de uma máquina em todas as plataformas.
{: .prompt-info }

## Mas o que é o Azure Arc?

O **Azure Arc** é uma solução da Microsoft que permite estender os serviços e as capacidades do Microsoft Azure para ambientes on-premises, como datacenters locais, outras nuvens (AWS, GCP ou OCI) e dispositivos em borda (edge).

Ele basicamente permite que você gerencie e controle recursos de infraestrutura e aplicações que estão em diferentes ambientes, tudo a partir de um único painel do Azure. Atualmente, o Azure Arc permite que você gerencie os seguintes tipos de recursos hospedados fora do Azure: ***Servidores físicos e virtuais Linux e Windows***, ***Clusters de Kubernetes***, ***Servidores SQL Server*** e ***Hypervisors VMWare e Hyper-v***

Em resumo, o Azure Arc permite integrar e gerenciar recursos fora do Azure, mas de maneira centralizada e com as ferramentas que a Microsoft oferece na nuvem, sem perder a flexibilidade de trabalhar com múltiplos ambientes.

Uma imagem com os detalhes do que podemos conectar com o Azure Arc:

![azure-arc](/assets/img/31/01.png){: .shadow .rounded-10}

## O que podemos usar com o azure Arc

Ao conectar seu servidor ao Azure Arc, você pode executar muitas funções operacionais e algumas das principais são:

- **Controlar:** Atribua Configurações de servidor do Azure para auditar as configurações dentro do computador usando Azure Policy.
- **Proteger:** Proteja servidores que não são do Azure com o Microsoft Defender endpoint.
- **Configurar:** Use a Automation Account do Azure para tarefas de gerenciamento frequentes e demoradas com runbooks do PowerShell.
- **Usar o update Manager do Azure** para gerenciar atualizações do sistema operacional dos seus servidores Windows e Linux. 
- **Monitorar:** Monitore o desempenho do sistema operacional e descubra os componentes do aplicativo para monitorar os processos e dependências com outros recursos usando os insights da VM.

## Requisitos para usar o Azure Arc

O primeiro passo para usarmos o Azure Arc é registrar os providers na assinatura onde serão criados os recursos, para isso precisamos registrar as seguintes extensões:

- **Microsoft.HybridCompute**
- **Microsoft.GuestConfiguration**
- **Microsoft.HybridConnectivity**
- **Microsoft.AzureArcData (Se for usar Arc-enable SQL Servers)**
- **Microsoft.Compute (se for usar o Azure Update Manager)**

Para registrar os providers podemos fazer de algumas formas, pelo portal WEB ou por CLI, pelo portal WEB devemos ir na assinatura e escolher a opção **Resource providers:**

![azure-arc](/assets/img/31/02.png){: .shadow .rounded-10}

No campo de busca você digita o nome ou parte do nome do provider para localizá-lo e após selecioná-lo devemos clicar no botão **Registrar**.

Se você prefere usar CLI para registrar os provider vou deixar abaixo os comandos usando CLI:

```powershell
Connect-AzAccount
Set-AzContext -SubscriptionId [subscription you want to onboard]
Register-AzResourceProvider -ProviderNamespace Microsoft.HybridCompute
Register-AzResourceProvider -ProviderNamespace Microsoft.GuestConfiguration
Register-AzResourceProvider -ProviderNamespace Microsoft.HybridConnectivity
Register-AzResourceProvider -ProviderNamespace Microsoft.AzureArcData
```
**Usando o Azure CLI:**

```powershell
az account set --subscription "{Your Subscription Name}"
az provider register --namespace 'Microsoft.HybridCompute'
az provider register --namespace 'Microsoft.GuestConfiguration'
az provider register --namespace 'Microsoft.HybridConnectivity'
az provider register --namespace 'Microsoft.AzureArcData'
```

Você pode consultar na coloca **Status** se o provider foi registrado.

## Habilitando os servidores no Azure Arc

Para habilitar os servidores no Azure Arc usamos scripts, bash para Linux e powershell para Windows, para gerar o script devemos preencher algumas informações no portal do Azure e ele nos disponibilizar de forma rápida.

Abrindo o recurso no portal Azure Arc vamos expandir **Host environments** -> **Machines** -> **+ Add/Create** -> **Add a machine**:

![azure-arc](/assets/img/31/03.png){: .shadow .rounded-10}

![azure-arc](/assets/img/31/04.png){: .shadow .rounded-10}

Existem algumas formas de se adicionar servidores e isso depende de onde/o que você deseja estar habilitando, mas as opções que iremos usar hoje será de apenas adicionar os servidores, as duas primeiras opções são: **Add a single server** e **Add multiple server**, apesar do nome parecer simples e intuitivo é bom frisar a diferença:

- **Add a single server:** o script permitira você adicionar um servidor por vez, isso porque ele irá pedir que você se autentique no portal do Azure, ou seja, toda vez que você querer adicionar um servidor com esse script você precisará se autenticar, e após a autenticação ele registra o servidor no Azure Arc.

- **Add multiple server:** nessa opção durante o preenchimento das informações para gerar o script é criado um **Service principal** e configurada as permissões necessárias no escopo onde você definir para ele registrar os servidores no Azure Arc, essa opção é interessante se você usar por exemplo uma GPO do Active Directory local para registrar os servidores de sua rede on-premises, ou até mesmo personalizando o script para ele registrar vários servidores de uma vez.

## Gerando o script para habilitar os servidores

Nesse artigo vou demonstrar como gerar o script para ***Multiple servers***, pois há mais opções que no ***single server*** e fica coberto nesse artigo todas as opções.

Na parte de cima é o padrão para os recursos do Azure, selecionar a assinatura e o resource group que o recurso será criado, em **Server details** precisamos escolher a região que os metadados do servidor serão armazenados e para qual o sistema operacional estamos gerando o script.

> Mesmo escolhendo a opção de **Multiple servers** o script é gerado para somente um sistema operacional, você precisará manter um script para Windows e outro para Linux.
{: .prompt-warning }

Se esse servidor conter uma instalação do SQL Server você deve marcar esse checkbox **Connect SQL Server** e ele já irá instalar as extensões do Azure necessárias.

Em **Connectivity method** temos três opções e é a maneira que o seu ambiente irá se comunicar com o Azure:

- **Public endpoint:** todo o tráfego de comunicação entre o Azure e o servidor on-premises será pela internet.
- **Proxy server:** usar um servidor proxy para realizar a comunicação.
- **Private endpoint:** caso você tenha uma VPN ou Expressroute conectando o Azure e o ambiente on-premises você pode usar um private endpoint para essa comunicação.

![azure-arc](/assets/img/31/05.png){: .shadow .rounded-10}

A parte de autenticação para múltiplos servidores é feita por um Service principal e para isso podemos criá-lo diretamente na tela de gerar o script caso não tenha um já existente com as permissões necessárias:

![azure-arc](/assets/img/31/06.png){: .shadow .rounded-10}

> Podemos (devemos 😁) ter somente um service principal para servidores Windows e Linux mesmo que usamos scripts separados para habilitá-los no Azure Arc.
{: .prompt-tip }

Temos alguns campos para preencher com as informações e configurações do Service principal como:

#### Service principal details:

-**Nome:** escolha um nome que identifique de forma clara o propósito do service principal que está criando.

-**Scope assignment level:** se a permissão do service principal será em toda a assinatura ou somente no resource group que estamos colocando os servidores.

#### Cliente secret:

-**Description:** Um nome amigável para ajudar a gerencia do seu client secret gerado. Se não for fornecido, um será gerado automaticamente para você.

-**Expires:** A duração pela qual o client secret será válido para uso. A validade pode ser 1 dia, 1 semana, 1 mês ou você pode personalizar a validade.

#### Role assignment

Aqui será onde iremos escolher a permissão que o Service principal terá, ou seja, para mim é a parte mais importante pois eu sempre assumo na criação dos meus recursos o **least privilege access**, vou descrever cada opção para ficar mais claro cada permissão:

-**Azure Connected Machine Onboarding:** Pode integrar máquinas conectadas do Azure.  

-**Kubernetes Cluster - Azure Arc Onboarding:** Role para autorizar qualquer usuário/serviço a criar o recurso ***connectedClusters.***

-**Azure Connected Machine Resource Administrator:** Pode ler, gravar, excluir e reintegrar Máquinas Conectadas do Azure.

![azure-arc](/assets/img/31/08.png){: .shadow .rounded-10}

> Eu recomendo o uso da permissão **Azure Connected Machine Onboarding** para o Service principal somente habilitar os servidores no Azure Arc se não for o caso de cluster Kubernetes.
{: .prompt-danger }

Ao criar o Service principal é aberto uma tela para realizar o download do client secret e do client Id, essa tela não aparecerá novamente e se você perder precisará recriar o client secret no Microsoft Entra ID. ***Iremos usar essas informações mais para frente no script.***

![azure-arc](/assets/img/31/09.png){: .shadow .rounded-10}

Na última parte temos o script propriamente e dependendo do sistema operacional ele irá dar opções de como gerar o script, temos as seguintes opções:

![azure-arc](/assets/img/31/10.png){: .shadow .rounded-10}

> A imagem acima é para gerar um script para servidores **Windows**, para linux temos somente a opção **Basic script** e **Ansible**.
{: .prompt-info }

Lembra que falei que teriamos que fazer o download do client secret? Temos que procurar pela variável no script e substituir o **\<ENTER SECRET HERE\>** pelo conteúdo do arquivo .txt que fizemos download:

```powershell
    # Add the service principal application ID and secret here
    $ServicePrincipalId="443a3c0a-9753-4b00-b328-a389d1340135";
    $ServicePrincipalClientSecret="<ENTER SECRET HERE>";
```

Após a alteração você pode fazer o Download do script ou copiar clicando no botão.

![azure-arc](/assets/img/31/11.png){: .shadow .rounded-10}

## Executando o script no Linux e no Windows

Pessoal aqui não tem segredo: é executar o script, mas gostaria de mostrar a tela com o resultado para qualquer dúvida vocês compararem com a de vocês:

### Linux

![azure-arc](/assets/img/31/13.png){: .shadow .rounded-10}

### Windows Server

![azure-arc](/assets/img/31/14.png){: .shadow .rounded-10}

## Como ficaram os servidores no Azure Arc 

Se estiver dado tudo certo os scripts poderemos ver no portal do Azure os servidores e o status de **conectado**, isso quer dizer que a comunicação entre o Azure e os servidores estão ok. O Azure Arc tem algumas funções e é difícil explorar aqui em um único artigo, segue o status dos servidores:

![azure-arc](/assets/img/31/15.png){: .shadow .rounded-10}

<br><br>

Nesse primeiro momento estou habilitando a coleta de logs em um Log Analytics do Azure para mais métricas dos servidores, só para ter uma primeira impressão e após alguns minutos já é possível ver alguns gráficos:

#### Servidor Linux
![azure-arc](/assets/img/31/12.png){: .shadow .rounded-10}

#### Servidor Windows
![azure-arc](/assets/img/31/16.png){: .shadow .rounded-10}

## Concluindo!

Nesse artigo eu habilitei três servidores para ir acompanhando e testando algumas funções do Azure Arc e quero trazer em outro artigo os updates desse ambiente que foi criado, quero também explorar um pouco mais o Update Manager do Azure para os servidores on-premises.

Bom pessoal, eu tenho usado isso em alguns ambientes e acredito que possa ser bem útil a vocês!

## Artigos relacionados

<a href="https://learn.microsoft.com/en-us/azure/azure-arc/servers/overview" target="_blank">What is Azure Arc-enabled servers?</a> 

<a href="https://learn.microsoft.com/en-us/azure/azure-arc/servers/onboard-service-principal" target="_blank">Connect hybrid machines to Azure at scale</a> 

Compartilhe o artigo com seus amigos clicando nos icones abaixo!!!
