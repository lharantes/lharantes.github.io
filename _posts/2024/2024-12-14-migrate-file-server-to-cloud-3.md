---
#layout: post
title: 'Backup do nosso Azure File Share migrado para o Azure' 
date: 2024-12-14 01:33:00
categories: [Azure]
tags: [azure, fileserver, backup]
slug: 'migrate-file-server-to-azure-parte3'
image:
  path: assets/img/29/29-header.webp
---

Olá pessoal! Blz?

Nos dois artigos anteriores onde migramos nosso file server on-premises para o Azure já estaria completo se não fosse a parte importante do processo que é o backup dos dados, que aposto que esse é um serviço que você tinha no on-premises.

Aqui vou demonstrar de forma rápida e simples como fazer o backup do Azure file share que estamos usando agora para o nosso file server 100% cloud, usaremos a ferramenta nativa do Microsoft Azure para realizar o backup. 

> Você pode usar outra ferramenta de backup que possa ser integrada com o Microsoft Azure.
{: .prompt-info }


## Habilitando o backup no Azure File Share

O Azure usa um recurso para armazenar os backup chamado "Recovery services vault", que nada mais é que um cofre de backup, ele faz backup de vários recursos no Azure incluindo o Azure file share. Para habilitarmos o backup em nosso nosso Azure file share primeiro devemos abri-lo seguindo os passos:

![migrate-file-server-to-azure](/assets/img/29/00.png){: .shadow .rounded-10}

Agora para habilitar propriamente o backup devem os no lado esquerdo selecionar a opção **Backup** e depois temos que definir alguns parâmetros:

![migrate-file-server-to-azure](/assets/img/29/01.png){: .shadow .rounded-10}

- **Recovery services vault**: devemos selecionar um existente ou podemos criar um novo cofre informando o nome no campo "Vault name".

> O cofre deve estar na mesma região que o recurso que você está habilitando o backup
{: .prompt-info }

- **Resource group**: caso esteja criando um cofre novo

- **Choose backup policy**: você pode escolher uma política de backup existente ou criar uma personalizada para o recurso que você esteja habilitando o backup, <a href="https://arantes.net.br/posts/migrate-file-server-to-azure-parte3/#personalizando-a-pol%C3%ADtica-de-backup">vou demonstrar isso mais abaixo.</a>

- **Storage account lock**: Para proteger seus snapshots contra exclusão acidental da storage account.


Depois de configurado só clicar no botão **"Enable backup"** que o backup para o Azure file share estará habilitado.

## Personalizando a política de backup

Para sairmos da política padrão podemos personalizar e deixar de forma que atenda ao que realmente precisamos, ou o que o negócio em que trabalhamos precisa. Por exemplo, eu prefiro deixar agendado o backup em um horário onde o acesso aos arquivos é menos frequente, geralmente mais para o final da noite, portanto, você pode alterar a frequência, o fuso horário (timezone) e o horário do backup.

No exemplo padrão do Azure ele traz uma retenção diária por 30 dias e não faz retenções semanais e mensais, é aqui que eu digo que ***você precisa alterar para atender as necessidades do seu negócio!***

![migrate-file-server-to-azure](/assets/img/29/02.png){: .shadow .rounded-10}

## Restaurando um backup

Se tivermos algum problema e precisarmos restaurar algum backup podemos fazer de duas formas: **Restaurar o compartilhamento todo (Restore Share)** ou **Restaurar algum arquivo ou pasta individualmente(File Recovery)**.

![migrate-file-server-to-azure](/assets/img/29/03.png){: .shadow .rounded-10}

Para ambos os casos precisamos escolher um ponto de recuperação e o método que pode ser no local original, e caso escolha essa opção precisa definir o que será feito em caso de conflito, sobrescrever ou pular, ou em outro local:

![migrate-file-server-to-azure](/assets/img/29/04.png){: .shadow .rounded-10}

Se formos restaurar um arquivo ou pasta individualmente, temos que escolher os arquivos ou pastas a serem restauradas:

![migrate-file-server-to-azure](/assets/img/29/05.png){: .shadow .rounded-10}

> Na imagem acima esta mostrando somente as pastas, caso precise restaurar algum arquivo é so clicar na pasta desejada e ir até o lcoal do arquivo.
{: .prompt-info }

## Concluindo!

Pode parecer simples mas o backup do Microsoft Azure é muito eficiente, e manter um backup de um file share é muito importante pois nunca se sabe o que pode acontecer, seja por um descuido do usuário ou de quem esteja administrando o ambiente.

Caso precise de uma ferramenta mais robusta é possível desde que seja compatível com o Azure.

Bom pessoal, espero que tenha gostado e que esse artigo seja útil a vocês!

## Artigos relacionados

<a href="https://learn.microsoft.com/en-us/azure/backup/backup-overview" target="_blank">What is the Azure Backup service?</a> 

<a href="https://learn.microsoft.com/en-us/azure/backup/azure-file-share-backup-overview?tabs=snapshot" target="_blank">About Azure File share backup</a> 

Compartilhe o artigo com seus amigos clicando nos icones abaixo!!!
