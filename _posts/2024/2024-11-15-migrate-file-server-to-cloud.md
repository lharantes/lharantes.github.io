---
#layout: post
title: 'Migrar um File Server local para o Azure - Parte 1' 
date: 2024-11-15 01:33:00
categories: [Azure]
tags: [azure, fileserver]
slug: 'migrate-file-server-to-azure-parte1'
image:
  path: assets/img/27/27-header.webp
---

Olá pessoal! Blz?

Quero trazer em alguns artigos algumas experiências que tive com migrações de File Servers on-premises para cloud, a primeira vez que fiz isso foi em 2020 em uma migração para o SharePoint e depois com muita frequência para o Microsoft Azure, usando tecnologias como o **Azure File Sync** onde mantinha-se um servidor local fazendo cache aos arquivos e também **migrando 100% para o Azure file share**.

Eu prefiro a abordagem de migrar para um Azure File Share pois conseguimos manter as permissões atuais NTFS e a mesma forma de administrar as permissões, e com isso manter um nivel segregado de permissões, algo que com o SharePoint acho muito dificil!

Recentemente ajudei um amigo a migrar um File Server 100% para o Azure e confesso que fiquei surpreso, pois a muito tempo não via sobre migrações como essa, o que tenho visto muito são migrações para o SharePoint para ter uma mobilidade maior e com isso o acesso aos arquivos de uma forma mais fácil remotamente e de qualquer lugar. Mas nada que uma boa e velha VPN não resolva o acesso aos outros tipos de File Server 😊 😜.

Vou trazer em 2 artigos como **migrar um File Server local para 100% no Microsoft Azure** e com isso não precisar mais manter um servidor on-premises com essa função. A primeira parte irei criar a infraestrutura de Storage Account no Azure e na segunda parte incluir o File share no domínio do Active Directory e como fazer a movimentacão dos arquivos para a cloud.

> Gostaria de deixar claro que será a **minha** opinião e experiência, caso você tenha outra visão ou experiência, seja bem vindo a contribuir nos comentários ou em contato comigo. 
{: .prompt-info }

## Vantagens e desvantagens usando um File Server 100% Cloud

Todo projeto ou mudança em um ambiente de TI temos que pesar os prós e contras, para que futuramente não haja mais dor de cabeça do que ja temos no dia a dia 😊😊 e com isso até no limite extremo realizar um roll back do que planejamos.

### Vantagens

- **Redundância:** podemos ter uma redundância dos arquivos muito mais "simples" do que fariamos on-premises, na cloud podemos ter essa redundância localmente (LRS), em outra zona (ZRS) ou outra região do Azure (GRS).

- **Serverless:** não teriamos a necessidade de manter localmente um ou mais servidores com a função de File Server, com isso menos trabalho administrativo.

- **Segurança:** o acesso ao Azure File Share é sempre autenticado e todos os dados que são armazenados são criptografados em repouso usando a SSE (Criptografia do Serviço de Armazenamento) do Azure, além de ter criptografia em trânsito habilitada.

- **Permissionamento:** manter as permissões NTFS mesmo migrando os arquivos para a cloud.

- **Otimização de custos:** você paga o que consome ou o que provisiona se estiver usando uma Storage Account Premium, mas é muito mais fácil e barato quando é preciso aumentar a capacidade to que comprar discos para uma Storage local.

### Desvantagens

- **Não ter cache local:** acessando os arquivos diretamente no Azure File Share não temos um cache para acessar de forma mais rápidas os arquivos, ou seja, em todo o acesso é feito o "download" do arquivo.

## Arquitetura sugerida

Na arquitetura sugerida aqui tem como base que os acessos aos arquivos migrados para o Azure será somente a partir da rede on-premises da empresa, para isso iremos criar uma VPN Site to Site entre o ambiente local e o Microsoft Azure, mas podemos ter uma VPN Client to Site e com isso também acessar os arquivos remotamente, garantindo com isso que o acesso mesmo público esteja criptografado e dentro do controle da empresa.

![migrate-file-server-to-azure](/assets/img/27/01.png){: .shadow .rounded-10}

Temos também o Active Directory local em sincronia com o Microsoft Entra ID através do Microsoft Entra Connect.

## Infraestrutura no Microsoft Azure

Conforme a arquitetura sugerida, teriamos um ambiente on-premises ligado ao Microsoft Azure através de uma VPN (Virtual Private Network) para que tenhamos uma comunicação privada, em empresas com um ambiente grande é comum que invés de uma VPN tenha-se um ExpressRoute fazendo essa conexão. Não estarei demonstrando o processo de criação da VPN mas deixo aqui o link de como podem fazer isso: <a href="https://learn.microsoft.com/pt-pt/azure/vpn-gateway/" target="_blank">Tutorial: Criar uma conexão VPN site a site no portal do Azure.</a>

Precisamos também de uma Storage Account com um File Share para que façamos o mapeamento de rede através do protocolo SMB.

Partindo do princípio que temos uma VPN ligando nosso ambiente on-premises e o Azure vamos fazer toda essa comunicação de forma privada, caso você não tenha essa VPN você precisará deixar a Storage Account pública para poder acessá-la!

> Se estiver reproduzindo isso em laboratório para aprendizado, você pode criar uma máquina virtual para acessar a Storage Account de forma privada desde que as redes virtuais estejam interligadas (peering), simulando assim um ambiente real
{: .prompt-tip }

### Storage Account

Para criar a Storage Account podemos deixar alguns itens como default, mas outros precisamos definir no momento da criação do recurso, inicialmente precisamos definir o Resource Group, o nome da storage account e a localização.

Para o nome da Storage Account temos que definir um nome que seja único em todo o Azure, e mesmo que o tamanho padrão do nome desse recurso seja de 3 a 24 caracteres, precismos definir até no **máximo 15 caracteres**, isso porque iremos ingressar essa storage account no domínio do Active Directory e com isso a limitação do tamanho de 15 caracteres do NETBIOS, o nome deve conter apenas números e letras em minúsculo.

![migrate-file-server-to-azure](/assets/img/27/05.png){: .shadow .rounded-10}

O passo/decisão mais importante é na escolha do tipo (Performance) da Storage Account pois é muito relevante para o custo e latência. No próprio portal do Azure ao criar uma storage account e escolhermos o serviço principal já temos algumas informações que nos ajudará a escolher:

![migrate-file-server-to-azure](/assets/img/27/02.png){: .shadow .rounded-10}

Você lendo o que o portal informa você tende a escolher uma storage account do tipo ***premium*** mas não nos diz o mais importante e "perigoso" que é a forma de cobrança entre os tipos de desempenho:

- **Standard:** recomendável para usos gerais e o desempenho é como um HD do tipo HDD, a forma de cobrança é pelo o que você esta consumindo, exemplo: se alocou 1TB e está usando 500GB pagará somente os 500GB.

- **Premium:** recomendável para baixa latência e alta velocidade de rede e é como um disco SSD, porém, a forma de cobrança é pelo o que você está alocando de espaço ao file Share, exemplo: e alocou 1TB e está usando 500GB **pagará o 1TB alocado**.

> Isso já vi acontecer muito, quando chega a conta o susto é grande, por isso cuidado e planejamento é muito importante nessa decisão.
{: .prompt-warning }

Uma parte também considerável no custo e a forma de redundância do seu dado, abaixo as opções que temos que escolher e já vem com uma breve descrição, o mais barato é o LRS (Locally redundant storage) que copia seus dados de forma síncrona três vezes em um único local físico na região primária.

![migrate-file-server-to-azure](/assets/img/27/03.png){: .shadow .rounded-10}

### Networking (modo de acesso)

Na aba "Networking" você deve configurar como será o acesso a Storage Account, e em um ambiente corporativo a recomendação é que se mantenha privada e o acesso seja feito por private endpoints como foi sugerido a criação na imagem abaixo, agora se você está apenas praticando pode ignorar esse passo e deixar ela de forma pública pois acredito que os arquivos não sejam confidenciais.

> Na criação do private endpoint é importante escolher a opção **file** em "Storage sub-resource"".
{: .prompt-info }

** R E P E T I N D O **

> Se estiver reproduzindo isso em laboratório para aprendizado, você pode criar uma máquina virtual para acessar a Storage Account de forma privada desde que estejam na mesma VNET, simulando assim um ambiente real.
{: .prompt-tip }

![migrate-file-server-to-azure](/assets/img/27/04.png){: .shadow .rounded-10}

Após essas configurações pode finalizar a criação da Storage Account.

### Criando o file share

O Azure File Share oferece compartilhamento de arquivos totalmente gerenciados na nuvem que são acessíveis por meio do ***protocolo SMB***, do ***protocolo NFS (Network File System)*** e por ***API REST***. É possível acessar Azure File Share através do protocolo SMB em clientes Windows, Linux e macOS e é possível acessar os compartilhamentos de arquivo do Azure do protocolo NFS de clientes Linux.

Para criar um File Share, na storage account que criamos acima vamos embaixo de **Data storage** -> **File shares** -> **+ File share**:

![migrate-file-server-to-azure](/assets/img/27/06.png){: .shadow .rounded-10}

Depois de digitado o **Nome** e escolhido o **Access tier** de acordo com sua necessidade entre performance e custo, clique no botão **Review + Create**:

![migrate-file-server-to-azure](/assets/img/27/07.png){: .shadow .rounded-10}

Se no momento de criar a Storage Account você escolher o tipo **Standard** você não precisa se preocupar com o espaço pois só pagará pelo que estiver armazenado mas se escolheu o tipo **Premium**, onde pagará pelo que está alocado, você precisa definir o tamanho durante a criação do File Share mas pode diminuir ou aumentar o espaço do File Share da seguinte forma, clicando em **Save** para confirmar:

> Lembrando que o tamanho mínimo do File share do tipo Premium é 100GiB.
{: .prompt-info }

![migrate-file-server-to-azure](/assets/img/27/08.png){: .shadow .rounded-10}

![migrate-file-server-to-azure](/assets/img/27/09.png){: .shadow .rounded-10}

## Concluindo!

Suponhando que já tinhamos uma rede virtual no nosso ambiente Azure, criamos a Storage Account com um private endpoint para manter a conexão aos arquivos de forma privada e criamos o file share que é onde os arquivos ficarão armazenados dentro da Stora Account.

No próximo artigo iremos ingressar a storage account no domínio do Active Directory e copiar os arquivos para o Azure através do Robocop.

Bom pessoal, espero que tenha gostado e que esse artigo seja útil a vocês!

## Artigos relacionados

<a href="https://learn.microsoft.com/en-us/azure/storage/files/storage-files-introduction" target="_blank">What is Azure Files?</a> 

<a href="https://learn.microsoft.com/en-us/azure/storage/files/storage-how-to-create-file-share?tabs=azure-portal" target="_blank">How to create an SMB Azure file share</a> 

<a href="https://learn.microsoft.com/en-us/azure/storage/files/storage-files-planning" target="_blank">Plan to deploy Azure Files</a> 

Compartilhe o artigo com seus amigos clicando nos icones abaixo!!!
