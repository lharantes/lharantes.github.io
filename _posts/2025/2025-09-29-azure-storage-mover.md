---
title: "Azure Storage Mover: Migração de arquivos do AWS S3 Bucket para o Azure Storage Account"
date: 2025-09-30 01:00:00
categories: [Azure]
tags: [azure]
slug: 'azure-storage-mover'
image:
  path: /assets/img/45/45-header.webp
---

Olá pessoal! Blz?

Com a adoção crescente de estratégias multicloud, muitas organizações enfrentam o desafio de centralizar, modernizar ou migrar dados entre diferentes provedores de nuvem, além de ambientes on-premises.
Nesse contexto, o **Azure Storage Mover** se destaca como uma solução nativa do Microsoft Azure para migração de dados baseados em arquivos, permitindo cenários que vão além do datacenter local, incluindo outras nuvens públicas como a AWS.

O **Azure Storage Mover** é um serviço gerenciado do Azure projetado para **orquestrar e automatizar migrações de file shares para o Azure**, a partir de:

- **Servidores on-premises**

- **Storages Accounts em outras nuvens (ex: AWS, GCP)**

- **Ambientes híbridos**

## Origens e destinos com suporte

A versão atual do **Azure Storage Mover** dá suporte a migrações de fidelidade total para combinações específicas de par de destino de origem. Sempre utilize a versão mais recente do agente para se beneficiar dessas fontes e destinos com suporte:

| Protocolo de Origem | Destino no Azure           | Observações                                                                           |
| ------------------- | -------------------------- | ------------------------------------------------------------------------------------- |
| AWS S3              | Azure Blob Container       | Buckets S3 com classes **Glacier** ou **Glacier Deep Archive** **não são suportados** |
| SMB 2.x / 3.x       | Azure File Share (SMB)     | SMB 1.x e Azure Files via NFS não são suportados                                      |
| SMB 2.x / 3.x       | Azure Blob Container       | Suporte a **FNS** e **HNS (ADLS Gen2)** via API REST                                  |
| NFS 3 / 4           | Azure Blob Container       | Suporte a **FNS** e **HNS (ADLS Gen2)** via API REST                                  |
| NFS 3 / 4           | Azure File Share (NFS 4.1) | Suporte a origens NFS v3/v4                                                           |

## Migrar arquivos da AWS para o Azure

Nesse artigo vamos demonstrar uma migração **cloud-to-cloud** onde vamos copiar arquivos a partir de um **AWS S3 Bucket** para uma **Azure Storage Account**, vamos usar um blob container, mas os passos são os mesmos se precisarem copiar para File Share.

O primeiro passo é criar o **Azure Storage Mover** que você pode localizar pela barra de pesquisa no portal do Azure ou no **Storage Center** -> **Migration** -> **Storage Mover** e depois **+ Create** como na imagem abaixo:

![azure-storage-mover](/assets/img/45/01a.png){: .shadow .rounded-10}

Na tela de deployment precisamos escolher poucas opções, as essenciais são as demonstradas na imagem abaixo, iremos realizar a criação no modo simples, ou seja, sem integrar os logs com o Azure Log Analytics:

![azure-storage-mover](/assets/img/45/01.png){: .shadow .rounded-10}

<br>

Na tela de Overview além das informações essenciais de todos os recursos Azure temos as opções de como podemos usar o **Storage Mover**, são essas opções:

- **On-premises migration**
- **Azure to Azure**, essa opção ainda está em preview no momento que escrevo esse artigo.
- **Multicloud migration**

![azure-storage-mover](/assets/img/45/02.png){: .shadow .rounded-10}

<br>

Como iremos fazer uma migração de arquivos da AWS para o Azure devemos selecionar a opção **Multicloud migration** e após isso clicar na opção **Create multicloud connector**:

![azure-storage-mover](/assets/img/45/3a.png){: .shadow .rounded-10}

<br>

Temos que preencher os campos requeridos, tendo o cuidado para selecionar o **Account type** correto para a conta AWS e depois o **AWS Account ID** onde está localizado o AWS S3 bucket:

![azure-storage-mover](/assets/img/45/03.png){: .shadow .rounded-10}

<br>

A próxima aba iremos escolher a solução que iremos usar, nesse exemplo estamos configurando 2 (duas) opções: **Inventory** e **Storage - Data Management**

![azure-storage-mover](/assets/img/45/04.png){: .shadow .rounded-10}

<br>

Na tela de **Inventory settings** escolhemos primeiramente qual serviço iremos adicionar, por padrão vem selecionado todos **"AWS Services"**, mas como iremos migrar os arquivos a partir de um AWS S3 bucket podemos selecionar somente esse serviço na lista, a permissão podemos escolher **Least privilege access** para termos acesso somente ao serviço que selecionamos na lista, devemos habilitar ou não o sincronismo automático e o período em horas e por último quais regiões da AWS iremos buscar os S3 buckets:

![azure-storage-mover](/assets/img/45/05.png){: .shadow .rounded-10}

<br>

Para a opção **Storage - Data Management** só precisamos clicar no link **+ Add**.

Na próxima aba temos o template para criamos uma política de acesso na AWS para ser permitido realizarmos a listagem dos S3 Buckets e a leitura dos arquivos que iremos copiar:

![azure-storage-mover](/assets/img/45/06.png){: .shadow .rounded-10}

Para os passos **2. Create a stack in AWS** e **3. Create a StckSet in AWS** devemos seguir os passos no portal AWS seguindo o que as tasks estão no pedindo para criar. 

O próximo passo é criar um **Source endpoint**, será onde iremos escolher qual será a **origem**, ou seja, de qual S3 Bucket iremos copiar os arquivos:

> O AWS S3 bucket pode levar 1 hora para aparecer na lista, eu achei que tinha feito algo errado, mas depois de 1 hora de espera o bucket apareceu na lista.
{: .prompt-tip } 

![azure-storage-mover](/assets/img/45/07.png){: .shadow .rounded-10}

<br>

O próximo passo é criar um **Project** para organizarmos os workloads:

![azure-storage-mover](/assets/img/45/08.png){: .shadow .rounded-10}

![azure-storage-mover](/assets/img/45/09.png){: .shadow .rounded-10}

> Os workloads podem ser várias origens (AWS S3 buckets) e vários destinos (Azure Storage Accouhnts)
{: .prompt-tip } 

Com o projeto criado, temos que criar um **Job definition**:

![azure-storage-mover](/assets/img/45/10.png){: .shadow .rounded-10}

<br>

Esse **Job definition** será **Cloud-to-Cloud**, pois iremos migrar entre as clouds AWS e Azure e depois clicar no botão **Next**:

![azure-storage-mover](/assets/img/45/11.png){: .shadow .rounded-10}

<br>

Na aba **Source** iremos selecionar a origem, com isso devemos escolher o **connector** que criamos nos passos anteriores e qual será o **S3 bucket** de que iremos copiar os arquivos: 

![azure-storage-mover](/assets/img/45/12.png){: .shadow .rounded-10}

<br>

Na aba **Target** iremos escolher o destino dos arquivos, aqui podemos criar um **Target endpoint** existente ou criar um, será escolher qual a Azure Storage Account de destino dos arquivos migrados. 

![azure-storage-mover](/assets/img/45/13.png){: .shadow .rounded-10}

<br>

Abaixo a tela para criar um **Target Endpoint**:

![azure-storage-mover](/assets/img/45/07a.png){: .shadow .rounded-10}

<br>

Na aba **Settings** iremos escolher qual será o modo de cópia dos arquivos, temos 2 (duas) opções:

- **Merge content into target:** Os arquivos serão mantidos no destino, mesmo que não existam na origem. Arquivos com nomes e caminhos correspondentes serão atualizados para corresponder à origem. Renomeações de pastas entre cópias podem levar a conteúdo duplicado no destino.

- **Mirror source to target:** Os arquivos no destino serão excluídos se não existirem na origem. Os arquivos e pastas no destino serão atualizados para corresponder à origem.

Por útimo, na aba **Review** será somente um resumo do que escolhemos.

![azure-storage-mover](/assets/img/45/14.png){: .shadow .rounded-10}

<br>

Na listagem podemos ver todos os criados tal como a informação de cada um, podemos clicar se desejamos executar ou ver mais detalhes:

![azure-storage-mover](/assets/img/45/21.png){: .shadow .rounded-10}

<br>

Clicando no recurso criado podemos ver o status **Never ran**, indicando que o **Job definition** nunca foi executado, para a primeira execução pode escolher o botão: **Start job**:

![azure-storage-mover](/assets/img/45/15.png){: .shadow .rounded-10}

<br>

Antes de iniciar a tarefa é realizado uma verificação se as permissões estão todas OK e somente se estiverem como **Successfully** podemos clicar no botão **Start**

![azure-storage-mover](/assets/img/45/20.png){: .shadow .rounded-10}

<br>

O status é alterado para **Running** e podemos ver em **Files and folders** o total de arquivos/pastas que foi detectado na origem (S3 Bucket):

![azure-storage-mover](/assets/img/45/16.png){: .shadow .rounded-10}

<br>

Se tudo correr bem o status passa para **Success** e podemos ver o resumo da tarefa como a quantidade de **arquivos processados** e o **volume de dados copiados:**

![azure-storage-mover](/assets/img/45/17.png){: .shadow .rounded-10}

<br>

Como um ***double check*** podemos ir até a **Azure Storage Account** escolhida como destino e ver se realmente os arquivos foram copiados para lá:

![azure-storage-mover](/assets/img/45/18.png){: .shadow .rounded-10}

<br>

E se compararmos com o conteúdo do **S3 Bucket** iremos ver que temos os mesmos arquivos na origem e no destino:

![azure-storage-mover](/assets/img/45/19.png){: .shadow .rounded-10}

## Concluindo!

O **Azure Storage Mover** se consolida como uma solução estratégica para organizações que buscam **modernizar, consolidar ou migrar dados baseados em arquivos para o Microsoft Azure**, indo muito além dos cenários tradicionais de on-premises.
Sua capacidade de operar em ambientes híbridos e multicloud, incluindo origens em outras nuvens como a Amazon Web Services, torna a ferramenta especialmente relevante em arquiteturas modernas e estratégias de cloud exit.

Ao oferecer orquestração centralizada, migração incremental, suporte a múltiplos protocolos **(SMB, NFS e S3)** e integração nativa com os serviços de armazenamento do Azure, o Storage Mover reduz significativamente a complexidade operacional e os riscos associados a projetos de migração de dados em larga escala.

Bom pessoal, eu tenho usado isso em alguns ambientes e acredito que possa ser bem útil a vocês!

## Artigos relacionados

<a href="https://youtu.be/bJL0JsRyP6c" target="_blank">Migrate from AWS S3 to Azure Blob | Cloud-to-Cloud Migration with Azure Storage Mover</a>

<a href="https://learn.microsoft.com/en-us/azure/storage-mover/service-overview" target="_blank">What is Azure Storage Mover?</a>

Compartilhe o artigo com seus amigos clicando nos icones abaixo!!!