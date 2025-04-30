---
#layout: post
title: 'Automatizar tarefas com o Azure Automation Account' 
date: 2024-10-01 01:33:00
categories: [Azure]
tags: [azure, automation]
slug: 'azure-automation-account'
image:
  path: assets/img/24/24-header.webp
---

Olá pessoal! Blz?

Nesse artigo eu quero trazer como criar um **Azure Automation Account** para automatizar rotinas ou tarefas no Microsoft Azure, e será uma continuação do artigo anterior onde falamos sobre <a href="https://arantes.net.br/posts/service-principal-secret-certificate-expire-report/" target="_blank">como enviar e-mail com secrets e certificados que irão expirar em alguns dias </a>. Iremos criar o Azure automation account, criar um runbook (script) e agendar a execução do script.

Mas além do exemplo que iremos abordar você pode automatizar a execução de qualquer script, um uso muito comum é o de dar start/stop em máquinas virtuais nos horário em que não são utilizadas e com isso economizando algum valor financeiro, aqui tem um vídeo muito bom sobre <a href="https://youtu.be/HkW5zpGx40w?feature=shared" target="_blank"> o uso de start e stop em máquinas virtuais</a>.

## Criar o Azure Automation Account

Para criar uma Automation Account, no portal do Microsoft Azure, digite ***"Automation Account"*** na caixa de pesquisa:

![azure-automation-account](/assets/img/24/00.png){: .shadow .rounded-10}

E depois clicar no botão **"+ Create"**, para criar esse recurso são poucos campos que precisamos preencher, na primeira aba **"Basics"** temos as seguintes opções:

![azure-automation-account](/assets/img/24/01.png){: .shadow .rounded-10}

Já na aba **"Advanced"** devemos escolher se iremos usar ou não **Identidades gerenciadas**, uma identidade gerenciada do Microsoft Entra ID permite que seu runbook acesse facilmente outros recursos protegidos pelo Microsoft Entra ou recursos do Microsoft Azure, ela pode ser: 

- Uma **identidade atribuída pelo sistema (System assigned)** é vinculada ao seu aplicativo e é excluída se o seu aplicativo for excluído. Um aplicativo só pode ter uma identidade atribuída pelo sistema.

- Uma **identidade atribuída pelo usuário (User assigned)** é um recurso independente do Azure que pode ser atribuído ao seu aplicativo. Um aplicativo pode ter várias identidades atribuídas pelo usuário.

![azure-automation-account](/assets/img/24/02.png){: .shadow .rounded-10}

Depois de escolhido ou desmarcado as 2 opções podemos clicar no botão **"Review + create"**

## Criando um Runbook

**Runbooks** são instruções de código ou rotinas para você automatizar alguma tarefa, você pode adicionar um runbook à Azure Automation Account criando um novo ou importando um existente de um arquivo ou da Galeria de Runbooks, a automação de processos na Azure Automation Account permite que você crie e gerencie runbooks gráficos, do PowerShell, Python e de Fluxo de Trabalho do PowerShell.

Para criar um Runbook devemos ir abaixo de **"Process Automation"** -> **"Runbooks"** -> **"Create a runbook"**:

![azure-automation-account](/assets/img/24/03.png){: .shadow .rounded-10}

<hr>

Na criação do Runbook temos 3 itens obrigatórios para escolha:

- **Nome do runbook**

- **Tipo do runbook (runtime)**

- **Versão do runtime**

E depois podemos clicar no botão **"Review + create"**

![azure-automation-account](/assets/img/24/04.png){: .shadow .rounded-10}

## Configurando o Runbook

Com o runbook criado e selecionando-o, em overview temos uma visão geral e algumas informações importantes como: ***Status, Runbook type e o Status dos jobs recentes***. No menu superior temos opções para ***executar, visualizar e editar o código e excluir o runbook.***, além de conseguir visualizar de forma rápida o status dos últimos jobs em **"Recent jobs"**.

![azure-automation-account](/assets/img/24/05.png)

Para inserirmos o script que queremos que execute devemos ir no menu superior em **"+ Edit"** -> **"Edit in portal"**, no editor colamos o código e clicamos no botão **"Save"** -> **"Publish"** 

![azure-automation-account](/assets/img/24/06.png)

> O script que usamos no artigo anterior para enviar um relatório por e-mail podemos baixar nesse link <a href="https://arantes.net.br/assets/img/23/sp-expire-connect-secret.txt" target="_blank">sp-expire-connect-secret.txt</a>
{: .prompt-tip }

## Agendando a execução

O agendamento nada mais é que como o nome diz, quando a nossa automação irá ser executada e com qual frenquência, para isso na tela inicial da Azure Automation Account criada temos que ir abaixo de **"shared resources"** -> **"Schedules"** -> **"Add a schedule"**, os campos que devemos preencher são:

- **Nome do agendamento**

- **Data e hora de inicio que o agendamento irá estar válido a executar**

- **Recorrência (uma única vez ou recorrente)**

- **Se será recorrente qual será a frequência, exemplo: 1x por hora, dia, semana, ou 2x por hora**

- **Set expiration: caso você queira que o runbook seja executado somente por um período de tempo aqui você define esse prazo**

E depois de configurado clicar no botão **"Create"**.

![azure-automation-account](/assets/img/24/07.png)

## Associar o agendamento com um runbook

Uma vez criado o agendamento devemos fazer a associação com o runbook, com isso o runbook será executado de acordo com o horário agendado, para isso vamos entrar no runbook novamente e vamos em **"Schedules"** -> **"Add a schedule"** -> **"Link a schedule to your runbook"** -> escolha na lista o agendamento que você deseja associar e clicar no botão **"OK" para terminar a associação do agendamento:

![azure-automation-account](/assets/img/24/08.png){: .shadow .rounded-10 w='750' h='405' }

| ![azure-automation-account](/assets/img/24/09.png){: .shadow .rounded-10 } | ![azure-automation-account](/assets/img/24/10.png){: .shadow .rounded-10 } |

> O agendamento pode ser compartilhado com um ou mais runbooks
{: .prompt-info }

## Usando variáveis no script

Uma dica legal e recomendada é não usar valores como senha e segredos diretamente no código, para isso podemos usar variáveis, para criar uma variável devemos ir em **"shared resources"** -> **"Variables"** -> **"Add a variable"**, devemos preencher os seguintes campos:

- **Nome da variável**

- **Descrição**

- **Tipo da variável**

- **Valor**

- **Se a variável será encriptada ou não**

<hr>

![azure-automation-account](/assets/img/24/11.png){: .shadow .rounded-10}

<hr>

Para referenciar as variáveis no código podemos usar o exemplo abaixo:

```powershell
$ClientId = Get-AutomationVariable -Name 'ClientId'
$TenantId = Get-AutomationVariable -Name 'TenantId'
$Secret = Get-AutomationVariable -Name 'Secret'
```

> Para valores de senhas ou algo que não queira que fique visível você pode deixar a opção **"Encrypted"** como **"Yes"**
{: .prompt-tip }

## Instalando módulos necessários

O Azure Automation Account ja trás alguns modulos do powershell instalados, mas pode acontecer de o seu script usar algum módulo que não vem, abaixo deixo um exemplo dos módulos que foram necessários no artigo anterior sobre <a href="https://arantes.net.br/posts/service-principal-secret-certificate-expire-report/" target="_blank">enviar um e-mail com o Services principals e certificados perto de expirarem</a>, com isso é preciso fazer a instalação para que o script execute com sucesso. Para instalar módulos temos que ir em **"shared resources"** -> **"Modules"** -> **"Add a module"**

Lista de módulos que usamos no artigo anterior:
- **Microsoft.Graph.Applications**
- **Microsoft.Graph.Authentication**
- **Microsoft.Graph.Mail**
- **Microsoft.Graph.Users.Actions**

![azure-automation-account](/assets/img/24/12.png){: .shadow .rounded-10}

<hr>

Podemos incluir um módulo a partir de um arquivo ou importar da Galeria, para isso devemos selecionar a opção desejada:

![azure-automation-account](/assets/img/24/13.png){: .shadow .rounded-10}

Na automação do artigo anterior onde enviamos um e-mail com o resultado da consulta precisamos instalar um módulo que não vem por padrão e importamos ele da galeria, no campo de busca digitamos o nome do módulo ou parte do nome e selecionamos o módulo que precisamos:

![azure-automation-account](/assets/img/24/14.png){: .shadow .rounded-10}

<hr>

Em **"Content"** temos todos os comandos pertencentes a esse módulo que estamos querendo instalar, se o comando que você precisa nao estiver listado, provavelmente, você está com o módulo errado selecionado. Se é o que você precisa é só clicar em **"Select"** e na tela seguinte devemos escolher a versão do runtime e clicar em **"Import"**:

![azure-automation-account](/assets/img/24/15.png){: .shadow .rounded-10}


## Concluindo!

Nesse artigo vimos como agendar tarefas no Microsoft Azure e mostrar como eu agendei o script do <a href="https://arantes.net.br/posts/service-principal-secret-certificate-expire-report/" target="_blank">artigo anterior</a> para enviar um e-mail semanal com um relatório, aqui foi somente uma idéia e vocês podem explorar esse recurso para outras necessidades. Como falei no início do artigo esse recurso é muito usado para dar o start e stop em máquinas virtuais em determinados horários. Eu tenho usado mais para disparar relatórios mas o recurso de forma alguma se limita a isso!!

Bom pessoal, espero que tenha gostado e que esse artigo seja útil a vocês!

## Artigos relacionados

<a href="https://learn.microsoft.com/en-us/azure/automation/automation-create-standalone-account?tabs=azureportal" target="_blank">Create a standalone Azure Automation account</a> 

<a href="https://learn.microsoft.com/en-us/azure/automation/learn/powershell-runbook-managed-identity" target="_blank">Tutorial: Create Automation PowerShell runbook using managed identity</a> 


Compartilhe o artigo com seus amigos clicando nos icones abaixo!!!
