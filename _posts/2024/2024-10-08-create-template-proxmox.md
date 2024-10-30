---
#layout: post
title: 'Criar uma VM "template" Linux para usar no Proxmox' 
date: 2024-10-09 05:33:00
categories: [HomeLab, Proxmox]
tags: [homelab, proxmox]
slug: 'create-template-proxmox'
image:
  path: assets/img/25/25-header.webp
---

Olá pessoal! Blz?

Nesse artigo eu quero trazer a vocês como eu faço para criar uma imagem para usar como template das minhas máquinas virtuais que uso em meu HomeLab. Atualmente eu uso o Proxmox como plataforma de virtualização no meu homelab e hoje conta com somente 1 nó, pretendo no futuro comprar mais um "servidor" e criar um cluster para a brincadeira ficar mais divertida 😊 😜.

Rodando hoje no meu homelab eu tenho somente máquinas virtuais Linux, as distribuições que estou usando são Debian e Ubuntu, tendo uma tendência de usar mais o Ubuntu, mas minha base de conhecimento de longa data sempre foi o Debian.

## Introdução

Nesse artigo vou abordar o uso das 2 distribuições, mas você pode usar outras distribuições pois os passos a partir do download é o mesmo para todas. Para isso iremos usar **Cloud Images** que são pequenas imagens certificadas como prontas para a nuvem que têm o Cloud Init pré-instalado e usamos isso para a configuração inicial do template. Cloud Images e Cloud Init também funcionam com Proxmox e se você combinar os dois, terá um modelo de clone perfeito, pequeno, eficiente e otimizado para provisionar máquinas com suas chaves SSH e configurações de rede.

## Acessando o ambiente Proxmox para criar a imagem

Para criar o template devemos fazer isso no servidor Proxmox, você pode fazer isso pelo portal web do Proxmox usando o shell pelo portal ou acessar o servidor por ssh e fazer isso pelo seu terminal. Para se conectar ao servidor Proxmox por ssh deve acessar usando o usário **root**:

```shell
ssh root@pve.arantes.net.br
```

> Substitua após o "@" pelo endereço do seu servidor Proxmox
{: .prompt-info }

Pelo portal web do Proxmox você precisar ir no seu **servidor (pve)** -> **Shell**

![create-template-proxmox](/assets/img/25/01.png){: .shadow .rounded-10}

## Criar a imagem template  

O primeiro passo para criar o template é escolher qual será a base, ou seja, qual distribuição irá usar, vou deixar abaixo os links para os repositórios e poder escolher a imagem que você irá usar:

- <a href="https://cloud.debian.org/images/cloud/" target="_blank">Debian Official Cloud Images</a> 

- <a href="https://cloud-images.ubuntu.com/" target="_blank">Ubuntu Cloud Images</a> 

### Download da imagem

Nesse exemplo vou usar o link para uma imagem Ubuntu mas é só substituir pelo link da imagem que você escolher, usaremos o comando ```wget```para realizar o download:

```shell
wget https://cloud-images.ubuntu.com/noble/current/noble-server-cloudimg-amd64.img
```

### Criar e preparar a máquina virtual que será usada como template

```shell
qm create 5000 --name ubuntu-template --memory 2048 --core 2  --net0 virtio,bridge=vmbr0 --machine q35
```

> o número **"5000"** é o ID que irei dar a máquina virtual de template, eu uso um número alto para não ficar no range meio dos IDs das outras máquinas virtuais
{: .prompt-info }

Importe o disco do Ubuntu baixado para o armazenamento **local**:

```shell
qm disk import 5000 noble-server-cloudimg-amd64.img local
```
> Altere **local** para o armazenamento de sua escolha, no meu caso eu tenho isso em um disco separado para as máquinas virtuais com o nome **"vms-storage"**
{: .prompt-tip }

Para poder importar a imagem para o destino escolhido, precisamos habilitar o destino para receber o conteúdo de **ISO image**, para isso devemos ir em **Datacenter -> Storage -> "STORAGE ESCOLHIDA" -> Edit**

![create-template-proxmox](/assets/img/25/04.png){: .shadow .rounded-10}

![create-template-proxmox](/assets/img/25/05.png){: .shadow .rounded-10}

Anexe o novo disco à máquina virtual como uma unidade SCSI no controlador SCSI:

```shell
qm set 5000 --scsihw virtio-scsi-pci --scsi0 local:5000/vm-5000-disk-0.raw
```

Adicionar a unidade do Cloud Init:

```shell
qm set 5000 --ide2 local:cloudinit
```

Torne a unidade de Cloud Init bootável e restrinja o BIOS para inicializar somente a partir do disco:

```shell
qm set 5000 --boot c --bootdisk scsi0
```

Adicionar o serial console

```shell
qm set 5000 --serial0 socket --vga serial0
```

Habilitar o **QEMU Guest Agent** para uma melhor comunicação da máquina virtual com o HOST:

```shell
qm set 5000 --agent enabled=1
```

### Personalizar as configurações do Cloud-Init

Podemos personalizar as configurações do cloud-init de acordo com nossas necessidades. Acesse o console da máquina virtual que estamos usando como template para fazer as alterações necessárias, como configurações de rede, configurações de usuário, chave SSH, entre outras opções:

![create-template-proxmox](/assets/img/25/02.png){: .shadow .rounded-10}

> Você pode nesse passo ajustar as configurações de hardware e também ajustar o tamanho do disco da imagem, eu prefiro expandir o disco rígido depois de clonar uma nova máquina virtual, conforme a necessidade
{: .prompt-tip }

### Criando o template de máquina virtual

Para criar o template devemos usar o comando abaixo:

```shell
qm template 5000
```

## Criando uma máquina virtual a partir desse template

Para criar uma máquina virtual a partir desse template devemos na verdade fazer um ```clone``` desse template e temos 2 formas de se fazer isso, pelo shell ou pelo portal web, pelo shell podemos usar o comando abaixo:

```shell
qm clone 5000 100 --name ubuntu-vm-01 --full --description "Ubuntu Virtual Machine"
```

> O "100" é o ID da nova máquina virtual 
{: .prompt-info }

Pelo portal web do Proxmox devemos fazer o seguinte passo a passo abaixo, começando com **clicar com o botão direito no template e escolher a opção "Clone"**:

![create-template-proxmox](/assets/img/25/03.gif){: .shadow .rounded-10}

Com isso teremos nossa máquina virtual criada a partir do template que criamos, agora é só iniciar a máquina virtual pois já está pronta para o uso.

## Concluindo!

Este artigo será o primeiro de alguns que quero criar sobre o meu HomeLab, o próximo quero trazer algo sobre como criar a máquina virtual usando o Ansible ou Terraform, mas nesse primeiro onde criamos um template é muito útil pela facilidade de deixar isso pronto e ter isso fácil e rápido.

Bom pessoal, espero que tenha gostado e que esse artigo seja útil a vocês!

## Artigos relacionados

<a href="https://pve.proxmox.com/wiki/VM_Templates_and_Clones" target="_blank">VM Templates and Clones</a> 

<a href="https://pve.proxmox.com/wiki/Cloud-Init_Support" target="_blank">Cloud-Init Support</a> 


Compartilhe o artigo com seus amigos clicando nos icones abaixo!!!
